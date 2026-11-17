import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/user_stats.dart';
import '../models/word_progress.dart';
import '../sources/local/hive_progress_source.dart';
import '../sources/remote/firestore_progress_source.dart';

/// Репозиторий прогресса обучения и статистики пользователя (Local-first).
abstract class ProgressRepository {
  /// Загружает прогресс по всем словам для текущего пользователя.
  Future<Map<int, WordProgress>> loadAllProgress(String uid);

  /// Обновляет прогресс по одному слову.
  Future<void> updateWordProgress(String uid, WordProgress progress);

  /// Загружает статистику пользователя.
  Future<UserStats> loadStats(String uid);

  /// Обновляет статистику.
  Future<void> updateStats(String uid, UserStats stats);

  /// Возвращает ID слов, которые нужно повторить сегодня (`nextReview <= now`).
  Future<List<int>> getWordsDueForReview(String uid);

  /// Принудительная синхронизация с Firestore.
  Future<void> syncWithCloud(String uid);
}

/// Local-first реализация [ProgressRepository] поверх Hive и Cloud Firestore.
class ProgressRepositoryImpl implements ProgressRepository {
  final HiveProgressSource _localSource;
  final FirestoreProgressSource _remoteSource;

  ProgressRepositoryImpl(this._localSource, this._remoteSource);

  @override
  Future<Map<int, WordProgress>> loadAllProgress(String uid) async {
    // 1. Мгновенно возвращаем данные из Hive.
    final localProgress = _localSource.getAllProgress(uid);

    // 2. Запускаем фоновую синхронизацию с Firestore, не блокируя UI.
    unawaited(_safeSyncWithCloud(uid));

    return localProgress;
  }

  @override
  Future<void> updateWordProgress(String uid, WordProgress progress) async {
    // Сначала синхронно/мгновенно записываем в Hive с флагом isSynced = false.
    final localEntry = progress.copyWith(isSynced: false);
    await _localSource.putWordProgress(uid, localEntry);

    // Запись в Firestore — fire-and-forget с обработкой ошибок.
    unawaited(_syncSingleWordToCloud(uid, localEntry));
  }

  @override
  Future<UserStats> loadStats(String uid) async {
    final localStats = _localSource.getStats(uid);

    // Фоново подтягиваем облачную статистику.
    unawaited(_safeSyncStatsFromCloud(uid, localStats));

    return localStats;
  }

  @override
  Future<void> updateStats(String uid, UserStats stats) async {
    await _localSource.putStats(uid, stats);

    // Запись в Firestore — fire-and-forget с обработкой ошибок.
    unawaited(_syncStatsToCloud(uid, stats));
  }

  @override
  Future<List<int>> getWordsDueForReview(String uid) async {
    final now = DateTime.now();
    final allProgress = _localSource.getAllProgress(uid);

    return allProgress.values
        .where((progress) => isWordDueForReview(progress, now))
        .map((progress) => progress.wordId)
        .toList();
  }

  /// Проверяет, доступно ли слово для повторения в Квизе или Написании на момент [now].
  static bool isWordDueForReview(WordProgress progress, [DateTime? now]) {
    final referenceTime = now ?? DateTime.now();
    final isActive = progress.status == WordStatus.learning ||
        progress.status == WordStatus.review;
    if (!isActive) return false;

    final isFirstQuizAttempt = progress.status == WordStatus.learning &&
        progress.totalCorrect == 0 &&
        progress.totalWrong == 0;
    if (isFirstQuizAttempt) return true;

    final nextReview = progress.nextReview;
    return nextReview != null && !nextReview.isAfter(referenceTime);
  }

  @override
  Future<void> syncWithCloud(String uid) async {
    // 1. Отправляем несинхронизированные локальные изменения в Firestore.
    final unsynced = _localSource.getUnsyncedProgress(uid);
    if (unsynced.isNotEmpty) {
      await _remoteSource.setBatchWordProgress(uid, unsynced);
      final syncedMap = <int, WordProgress>{
        for (final item in unsynced) item.wordId: item.copyWith(isSynced: true),
      };
      await _localSource.putAllProgress(uid, syncedMap);
    }

    // 2. Загружаем облачное состояние и мержим с локальным по lastReviewed.
    final remoteMap = await _remoteSource.fetchAllProgress(uid);
    final localMap = _localSource.getAllProgress(uid);
    final toSaveLocally = <int, WordProgress>{};

    for (final entry in remoteMap.entries) {
      final wordId = entry.key;
      final remoteItem = entry.value;
      final localItem = localMap[wordId];

      if (_shouldPreferRemote(localItem, remoteItem)) {
        toSaveLocally[wordId] = remoteItem.copyWith(isSynced: true);
      }
    }

    if (toSaveLocally.isNotEmpty) {
      await _localSource.putAllProgress(uid, toSaveLocally);
    }

    // 3. Синхронизируем статистику.
    final localStats = _localSource.getStats(uid);
    await _syncStats(uid, localStats);
  }

  bool _shouldPreferRemote(WordProgress? local, WordProgress remote) {
    if (local == null) return true;

    final localDate = local.lastReviewed;
    final remoteDate = remote.lastReviewed;

    if (remoteDate == null) return false;
    if (localDate == null) return true;

    return remoteDate.isAfter(localDate);
  }

  Future<void> _syncSingleWordToCloud(String uid, WordProgress progress) async {
    try {
      await _remoteSource.setWordProgress(uid, progress);
      await _localSource.putWordProgress(
        uid,
        progress.copyWith(isSynced: true),
      );
    } catch (e) {
      debugPrint('Ошибка синхронизации слова ${progress.wordId}: $e');
    }
  }

  Future<void> _syncStatsToCloud(String uid, UserStats stats) async {
    try {
      await _remoteSource.setStats(uid, stats);
    } catch (e) {
      debugPrint('Ошибка синхронизации статистики: $e');
    }
  }

  Future<void> _safeSyncWithCloud(String uid) async {
    try {
      await syncWithCloud(uid);
    } catch (e) {
      debugPrint('Фоновая синхронизация прогресса не удалась: $e');
    }
  }

  Future<void> _safeSyncStatsFromCloud(String uid, UserStats localStats) async {
    try {
      await _syncStats(uid, localStats);
    } catch (e) {
      debugPrint('Фоновая синхронизация статистики не удалась: $e');
    }
  }

  Future<void> _syncStats(String uid, UserStats localStats) async {
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
    }
  }
}
