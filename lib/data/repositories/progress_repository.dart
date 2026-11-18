import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../core/sync/sync_service.dart';
import '../models/user_stats.dart';
import '../models/word_progress.dart';
import '../sources/local/hive_progress_source.dart';
import '../sources/remote/firestore_progress_source.dart';

/// Репозиторий прогресса обучения и статистики пользователя (Local-first).
abstract class ProgressRepository {
  /// Поток `uid` пользователей, для которых фоновая синхронизация обновила локальные данные из облака.
  Stream<String> get cloudUpdates;

  /// Синхронно возвращает закэшированный прогресс из Hive без запуска синхронизации.
  Map<int, WordProgress> getLocalProgress(String uid);

  /// Синхронно возвращает локальную статистику из Hive без запуска синхронизации.
  UserStats getLocalStats(String uid);

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
  final SyncService _syncService;
  final StreamController<String> _cloudUpdatesController =
      StreamController<String>.broadcast();

  ProgressRepositoryImpl(
    this._localSource,
    FirestoreProgressSource remoteSource, [
    SyncService? syncService,
  ]) : _syncService = syncService ?? SyncService(_localSource, remoteSource);

  @override
  Stream<String> get cloudUpdates => _cloudUpdatesController.stream;

  @override
  Map<int, WordProgress> getLocalProgress(String uid) =>
      _localSource.getAllProgress(uid);

  @override
  UserStats getLocalStats(String uid) => _localSource.getStats(uid);

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
    unawaited(_safeSyncStatsFromCloud(uid));

    return localStats;
  }

  @override
  Future<void> updateStats(String uid, UserStats stats) async {
    final localStats = stats.copyWith(isSynced: false);
    await _localSource.putStats(uid, localStats);

    // Запись в Firestore — fire-and-forget с обработкой ошибок.
    unawaited(_syncStatsToCloud(uid, localStats));
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
    final result = await _syncService.syncAllWithStatus(uid);
    if (result.hasRemoteUpdates && !_cloudUpdatesController.isClosed) {
      _cloudUpdatesController.add(uid);
    }
  }

  Future<void> _syncSingleWordToCloud(String uid, WordProgress progress) async {
    try {
      await _syncService.syncSingleWord(uid, progress);
    } catch (e) {
      debugPrint('Ошибка синхронизации слова ${progress.wordId}: $e');
    }
  }

  Future<void> _syncStatsToCloud(String uid, UserStats stats) async {
    try {
      await _syncService.pushStats(uid, stats);
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

  Future<void> _safeSyncStatsFromCloud(String uid) async {
    try {
      final hasUpdates = await _syncService.syncStats(uid);
      if (hasUpdates && !_cloudUpdatesController.isClosed) {
        _cloudUpdatesController.add(uid);
      }
    } catch (e) {
      debugPrint('Фоновая синхронизация статистики не удалась: $e');
    }
  }
}
