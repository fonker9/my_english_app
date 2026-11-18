import '../../data/models/user_stats.dart';
import '../../data/models/word_progress.dart';
import '../../data/sources/local/hive_progress_source.dart';
import '../../data/sources/remote/firestore_progress_source.dart';

/// Результат полной синхронизации между локальной и облачной базами.
class SyncAllResult {
  final Map<int, WordProgress> progress;
  final bool hasRemoteUpdates;

  const SyncAllResult({
    required this.progress,
    required this.hasRemoteUpdates,
  });
}

/// Сервис двусторонней синхронизации прогресса между Hive и Cloud Firestore.
class SyncService {
  final HiveProgressSource _localSource;
  final FirestoreProgressSource _remoteSource;

  final Map<String, Future<SyncAllResult>> _inFlightSyncAll = {};
  final Map<String, Future<bool>> _inFlightSyncStats = {};

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

    // Помечаем как синхронизированные только те записи, которые не изменились в Hive за время запроса.
    final currentLocal = _localSource.getAllProgress(uid);
    final syncedMap = <int, WordProgress>{};
    for (final item in unsynced) {
      if (currentLocal[item.wordId] == item) {
        syncedMap[item.wordId] = item.copyWith(isSynced: true);
      }
    }
    if (syncedMap.isNotEmpty) {
      await _localSource.putAllProgress(uid, syncedMap);
    }
  }

  /// Синхронизирует прогресс одного слова с Firestore и помечает запись в Hive как `isSynced = true`.
  Future<void> syncSingleWord(String uid, WordProgress progress) async {
    await _remoteSource.setWordProgress(uid, progress);
    if (_localSource.getWordProgress(uid, progress.wordId) == progress) {
      await _localSource.putWordProgress(
        uid,
        progress.copyWith(isSynced: true),
      );
    }
  }

  /// Полная синхронизация (возвращает прогресс и флаг, обновились ли локальные данные из облака).
  /// Повторные параллельные вызовы для одного [uid] переиспользуют уже запущенную операцию.
  Future<SyncAllResult> syncAllWithStatus(String uid) async {
    final existing = _inFlightSyncAll[uid];
    if (existing != null) {
      return existing;
    }

    final future = _runSyncAll(uid);
    _inFlightSyncAll[uid] = future;
    try {
      return await future;
    } finally {
      if (identical(_inFlightSyncAll[uid], future)) {
        _inFlightSyncAll.remove(uid);
      }
    }
  }

  /// Полная синхронизация: отправка локальных изменений, миграция старого формата
  /// Firestore при необходимости, скачивание облачных данных и мерж по `lastReviewed`.
  Future<Map<int, WordProgress>> syncAll(String uid) async {
    final result = await syncAllWithStatus(uid);
    return result.progress;
  }

  Future<SyncAllResult> _runSyncAll(String uid) async {
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

    // 3. Мержим облачные и локальные записи с учётом возможных локальных изменений за время запроса.
    final localMap = _localSource.getAllProgress(uid);
    final toSaveLocally = <int, WordProgress>{};
    final toPushRemote = <WordProgress>[];
    var progressChangedFromCloud = false;

    for (final entry in remoteMap.entries) {
      final wordId = entry.key;
      final remoteItem = entry.value;
      final localItem = localMap[wordId];

      if (localItem == null) {
        toSaveLocally[wordId] = remoteItem.copyWith(isSynced: true);
        progressChangedFromCloud = true;
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
        progressChangedFromCloud = true;
      }
    }

    if (toSaveLocally.isNotEmpty) {
      final filteredToSave = <int, WordProgress>{};
      for (final entry in toSaveLocally.entries) {
        final latestLocal = _localSource.getWordProgress(uid, entry.key);
        // Не перезаписываем запись, если пользователь успел изменить её локально во время сетевого запроса.
        if (latestLocal == null ||
            latestLocal == localMap[entry.key] ||
            resolveConflict(latestLocal, entry.value) == entry.value) {
          filteredToSave[entry.key] = entry.value;
        }
      }
      if (filteredToSave.isNotEmpty) {
        await _localSource.putAllProgress(uid, filteredToSave);
      }
    }

    if (toPushRemote.isNotEmpty) {
      await _remoteSource.setBatchWordProgress(uid, toPushRemote);
      final currentLocal = _localSource.getAllProgress(uid);
      final syncedMap = <int, WordProgress>{};
      for (final item in toPushRemote) {
        if (currentLocal[item.wordId] == item) {
          syncedMap[item.wordId] = item.copyWith(isSynced: true);
        }
      }
      if (syncedMap.isNotEmpty) {
        await _localSource.putAllProgress(uid, syncedMap);
      }
    }

    // 4. Синхронизируем статистику.
    final statsChangedFromCloud = await syncStats(uid);

    return SyncAllResult(
      progress: _localSource.getAllProgress(uid),
      hasRemoteUpdates: progressChangedFromCloud || statsChangedFromCloud,
    );
  }

  /// Синхронизирует статистику пользователя между Hive и Firestore.
  /// Возвращает `true`, если локальные данные в Hive были обновлены из облака.
  Future<bool> syncStats(String uid, [UserStats? localStatsOverride]) async {
    if (localStatsOverride == null) {
      final existing = _inFlightSyncStats[uid];
      if (existing != null) {
        return existing;
      }
      final future = _runSyncStats(uid, null);
      _inFlightSyncStats[uid] = future;
      try {
        return await future;
      } finally {
        if (identical(_inFlightSyncStats[uid], future)) {
          _inFlightSyncStats.remove(uid);
        }
      }
    }
    return _runSyncStats(uid, localStatsOverride);
  }

  Future<bool> _runSyncStats(
    String uid,
    UserStats? localStatsOverride,
  ) async {
    final initialLocal = localStatsOverride ?? _localSource.getStats(uid);
    final remoteStats = await _remoteSource.fetchStats(uid);

    final effectiveLocal = localStatsOverride ?? _localSource.getStats(uid);

    if (remoteStats == null) {
      final hasMeaningfulData =
          effectiveLocal.copyWith(isSynced: true) != UserStats.empty();
      if (!effectiveLocal.isSynced || hasMeaningfulData) {
        await _remoteSource.setStats(uid, effectiveLocal);
        if (localStatsOverride == null &&
            _localSource.getStats(uid) == effectiveLocal &&
            !effectiveLocal.isSynced) {
          await _localSource.putStats(
            uid,
            effectiveLocal.copyWith(isSynced: true),
          );
        }
      }
      return false;
    }

    final localDate = effectiveLocal.lastStudyDate;
    final remoteDate = remoteStats.lastStudyDate;

    if (remoteDate != null &&
        (localDate == null || remoteDate.isAfter(localDate))) {
      final latestLocal = _localSource.getStats(uid);
      if (localStatsOverride == null &&
          latestLocal != initialLocal &&
          !latestLocal.isSynced &&
          latestLocal.lastStudyDate != null &&
          !remoteDate.isAfter(latestLocal.lastStudyDate!)) {
        await _remoteSource.setStats(uid, latestLocal);
        if (_localSource.getStats(uid) == latestLocal) {
          await _localSource.putStats(
            uid,
            latestLocal.copyWith(isSynced: true),
          );
        }
        return false;
      }

      final syncedRemote = remoteStats.copyWith(isSynced: true);
      final dataChanged = syncedRemote != effectiveLocal.copyWith(isSynced: true);
      await _localSource.putStats(uid, syncedRemote);
      return dataChanged;
    } else if (!effectiveLocal.isSynced ||
        _isStrictlyNewer(localDate, remoteDate)) {
      await _remoteSource.setStats(uid, effectiveLocal);
      if (localStatsOverride == null &&
          _localSource.getStats(uid) == effectiveLocal &&
          !effectiveLocal.isSynced) {
        await _localSource.putStats(
          uid,
          effectiveLocal.copyWith(isSynced: true),
        );
      }
    }

    return false;
  }

  /// Отправляет локальную статистику в Firestore и при отсутствии гонок помечает `isSynced = true`.
  Future<void> pushStats(String uid, UserStats stats) async {
    await _remoteSource.setStats(uid, stats);
    if (_localSource.getStats(uid) == stats && !stats.isSynced) {
      await _localSource.putStats(uid, stats.copyWith(isSynced: true));
    }
  }

  static bool _isStrictlyNewer(DateTime? candidate, DateTime? baseline) {
    if (candidate == null) return false;
    if (baseline == null) return true;
    return candidate.isAfter(baseline);
  }
}
