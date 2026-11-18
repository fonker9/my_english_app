import '../../data/models/user_stats.dart';
import '../../data/models/word_progress.dart';
import '../../data/sources/local/hive_progress_source.dart';
import '../../data/sources/remote/firestore_progress_source.dart';

/// Сервис двусторонней синхронизации прогресса между Hive и Cloud Firestore.
class SyncService {
  final HiveProgressSource _localSource;
  final FirestoreProgressSource _remoteSource;

  SyncService(this._localSource, this._remoteSource);

  /// Разрешает конфликт между локальной и облачной записью прогресса.
  /// При конфликте побеждает запись с более поздним [WordProgress.lastReviewed].
  static WordProgress resolveConflict(
    WordProgress local,
    WordProgress remote,
  ) {
    final localDate = local.lastReviewed;
    final remoteDate = remote.lastReviewed;

    if (remoteDate == null) return local;
    if (localDate == null || remoteDate.isAfter(localDate)) {
      return remote.copyWith(isSynced: true);
    }
    return local;
  }

  /// Отправляет все несинхронизированные локальные записи (`isSynced == false`) в Firestore.
  Future<void> pushUnsyncedChanges(String uid) async {
    final unsynced = _localSource.getUnsyncedProgress(uid);
    if (unsynced.isEmpty) return;

    await _remoteSource.setBatchWordProgress(uid, unsynced);
    final syncedMap = <int, WordProgress>{
      for (final item in unsynced) item.wordId: item.copyWith(isSynced: true),
    };
    await _localSource.putAllProgress(uid, syncedMap);
  }

  /// Синхронизирует прогресс одного слова с Firestore и помечает запись в Hive как `isSynced = true`.
  Future<void> syncSingleWord(String uid, WordProgress progress) async {
    await _remoteSource.setWordProgress(uid, progress);
    await _localSource.putWordProgress(
      uid,
      progress.copyWith(isSynced: true),
    );
  }

  /// Полная синхронизация: отправка локальных изменений, миграция старого формата
  /// Firestore при необходимости, скачивание облачных данных и мерж по `lastReviewed`.
  Future<Map<int, WordProgress>> syncAll(String uid) async {
    // 1. Отправляем накопленные локальные изменения.
    await pushUnsyncedChanges(uid);

    // 2. Загружаем данные из новой структуры Firestore и мигрируем старый формат при необходимости.
    final remoteMap = Map<int, WordProgress>.from(
      await _remoteSource.fetchAllProgress(uid),
    );
    final migrated = await _remoteSource.migrateLegacyFormatIfNeeded(
      uid,
      existingRemote: remoteMap,
    );
    remoteMap.addAll(migrated);

    // 3. Мержим облачные и локальные записи.
    final localMap = _localSource.getAllProgress(uid);
    final toSaveLocally = <int, WordProgress>{};
    final toPushRemote = <WordProgress>[];

    for (final entry in remoteMap.entries) {
      final wordId = entry.key;
      final remoteItem = entry.value;
      final localItem = localMap[wordId];

      if (localItem == null) {
        toSaveLocally[wordId] = remoteItem.copyWith(isSynced: true);
        continue;
      }

      final winner = resolveConflict(localItem, remoteItem);
      if (identical(winner, localItem) || winner == localItem) {
        if (_isStrictlyNewer(localItem.lastReviewed, remoteItem.lastReviewed)) {
          toPushRemote.add(localItem);
        } else if (!localItem.isSynced && winner == localItem) {
          toSaveLocally[wordId] = localItem.copyWith(isSynced: true);
        }
      } else {
        toSaveLocally[wordId] = winner;
      }
    }

    if (toSaveLocally.isNotEmpty) {
      await _localSource.putAllProgress(uid, toSaveLocally);
    }

    if (toPushRemote.isNotEmpty) {
      await _remoteSource.setBatchWordProgress(uid, toPushRemote);
      final syncedMap = <int, WordProgress>{
        for (final item in toPushRemote)
          item.wordId: item.copyWith(isSynced: true),
      };
      await _localSource.putAllProgress(uid, syncedMap);
    }

    // 4. Синхронизируем статистику.
    await syncStats(uid);

    return _localSource.getAllProgress(uid);
  }

  /// Синхронизирует статистику пользователя между Hive и Firestore.
  Future<void> syncStats(String uid, [UserStats? localStatsOverride]) async {
    final localStats = localStatsOverride ?? _localSource.getStats(uid);
    final remoteStats = await _remoteSource.fetchStats(uid);

    if (remoteStats == null) {
      if (localStats != UserStats.empty()) {
        await _remoteSource.setStats(uid, localStats);
      }
      return;
    }

    final localDate = localStats.lastStudyDate;
    final remoteDate = remoteStats.lastStudyDate;

    if (remoteDate != null &&
        (localDate == null || remoteDate.isAfter(localDate))) {
      await _localSource.putStats(uid, remoteStats);
    } else if (_isStrictlyNewer(localDate, remoteDate)) {
      await _remoteSource.setStats(uid, localStats);
    }
  }

  /// Отправляет локальную статистику в Firestore.
  Future<void> pushStats(String uid, UserStats stats) async {
    await _remoteSource.setStats(uid, stats);
  }

  static bool _isStrictlyNewer(DateTime? candidate, DateTime? baseline) {
    if (candidate == null) return false;
    if (baseline == null) return true;
    return candidate.isAfter(baseline);
  }
}
