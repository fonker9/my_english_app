import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_english_app/core/di/service_locator.dart';
import 'package:my_english_app/core/srs/srs_engine.dart';
import 'package:my_english_app/data/models/word_progress.dart';
import 'package:my_english_app/data/repositories/auth_repository.dart';
import 'package:my_english_app/data/repositories/progress_repository.dart';
import 'package:my_english_app/data/repositories/settings_repository.dart';
import 'package:my_english_app/data/repositories/words_repository.dart';
import 'swipe_state.dart';

/// Кубит для режима свайп-карточек (знакомство с новыми словами).
class SwipeCubit extends Cubit<SwipeState> {
  final WordsRepository _wordsRepository;
  final ProgressRepository _progressRepository;
  final SettingsRepository _settingsRepository;
  final AuthRepository _authRepository;

  StreamSubscription<String>? _cloudUpdatesSub;
  Map<int, WordProgress> _progressMap = {};
  int _sessionKnowCount = 0;
  int _sessionLearnCount = 0;

  SwipeCubit(
    this._wordsRepository,
    this._progressRepository,
    this._settingsRepository, [
    AuthRepository? authRepository,
  ])  : _authRepository = authRepository ?? sl<AuthRepository>(),
        super(const SwipeLoading()) {
    _cloudUpdatesSub = _progressRepository.cloudUpdates.listen((updatedUid) {
      if (isClosed || updatedUid != _authRepository.currentUid) return;
      final hasStartedSession = _sessionKnowCount > 0 ||
          _sessionLearnCount > 0 ||
          (state is SwipeLoaded && (state as SwipeLoaded).currentIndex > 0);
      if (!hasStartedSession) {
        unawaited(_loadWordsInternal(triggerSync: false, showLoading: false));
      }
    });
  }

  /// Загружает слова со статусом `unseen`, дневную цель и статистику за сегодня.
  Future<void> loadWords() =>
      _loadWordsInternal(triggerSync: true, showLoading: true);

  Future<void> _loadWordsInternal({
    required bool triggerSync,
    required bool showLoading,
  }) async {
    try {
      if (showLoading) {
        emit(const SwipeLoading());
      }
      _sessionKnowCount = 0;
      _sessionLearnCount = 0;

      final uid = _authRepository.currentUid;
      if (uid == null) {
        emit(const SwipeError('Пользователь не авторизован'));
        return;
      }

      final allWords = await _wordsRepository.getAllWords();
      _progressMap = Map<int, WordProgress>.from(
        triggerSync
            ? await _progressRepository.loadAllProgress(uid)
            : _progressRepository.getLocalProgress(uid),
      );
      var stats = triggerSync
          ? await _progressRepository.loadStats(uid)
          : _progressRepository.getLocalStats(uid);

      // Сбрасываем дневные счётчики, если последнее занятие было в другой день.
      final now = DateTime.now();
      final resetStats = SrsEngine.resetDailyCountersIfNeeded(stats, now);
      if (resetStats != stats) {
        stats = resetStats;
        await _progressRepository.updateStats(uid, stats);
      }

      final settings = await _settingsRepository.loadSettings();
      final dailyGoal = settings.dailyNewWordsGoal;

      if (stats.todayNewWords >= dailyGoal) {
        emit(
          SwipeFinished(
            learnedCount: stats.todayNewWords,
            dailyGoal: dailyGoal,
          ),
        );
        return;
      }

      final availableWords = allWords.where((word) {
        final status = _progressMap[word.id]?.status ?? WordStatus.unseen;
        return status == WordStatus.unseen;
      }).toList();

      if (availableWords.isEmpty) {
        emit(const SwipeEmpty());
        return;
      }

      final displayName = _authRepository.currentDisplayName;
      final nickname = (displayName != null && displayName.trim().isNotEmpty)
          ? displayName.trim()
          : 'пользователь';

      emit(
        SwipeLoaded(
          words: availableWords,
          currentIndex: 0,
          learnedCount: stats.todayNewWords,
          dailyGoal: dailyGoal,
          isFront: true,
          nickname: nickname,
        ),
      );
    } catch (e) {
      emit(SwipeError('Ошибка при загрузке слов: $e'));
    }
  }

  /// Свайп вправо («Учу»): слово переходит в статус `learning`, `nextReview = now + 1 день`.
  void notKnowWord() {
    if (state is! SwipeLoaded) return;
    final currentState = state as SwipeLoaded;
    final uid = _authRepository.currentUid;
    if (uid == null) return;

    final currentWord = currentState.words[currentState.currentIndex];
    final now = DateTime.now();
    final existing = _progressMap[currentWord.id];

    final updatedProgress = (existing ??
            WordProgress(
              wordId: currentWord.id,
              firstSeen: now,
            ))
        .copyWith(
      status: WordStatus.learning,
      lastReviewed: now,
      nextReview: now.add(const Duration(days: 1)),
      firstSeen: existing?.firstSeen ?? now,
      isSynced: false,
    );

    _progressMap[currentWord.id] = updatedProgress;
    unawaited(_progressRepository.updateWordProgress(uid, updatedProgress));

    final currentStats = SrsEngine.resetDailyCountersIfNeeded(
      _progressRepository.getLocalStats(uid),
      now,
    );
    final newLearnedCount = currentStats.todayNewWords + 1;
    _sessionLearnCount++;
    final updatedStats = SrsEngine.markStudyActivity(currentStats, now).copyWith(
      todayNewWords: newLearnedCount,
    );
    unawaited(_progressRepository.updateStats(uid, updatedStats));

    final nextIndex = currentState.currentIndex + 1;
    if (newLearnedCount >= currentState.dailyGoal ||
        nextIndex >= currentState.words.length) {
      emit(
        SwipeFinished(
          learnedCount: newLearnedCount,
          dailyGoal: currentState.dailyGoal,
          sessionKnowCount: _sessionKnowCount,
          sessionLearnCount: _sessionLearnCount,
        ),
      );
    } else {
      emit(
        currentState.copyWith(
          currentIndex: nextIndex,
          learnedCount: newLearnedCount,
          isFront: true,
        ),
      );
    }
  }

  /// Свайп влево («Знаю»): слово сразу переходит в статус `mastered`.
  void knowWord() {
    if (state is! SwipeLoaded) return;
    final currentState = state as SwipeLoaded;
    final uid = _authRepository.currentUid;
    if (uid == null) return;

    final currentWord = currentState.words[currentState.currentIndex];
    final now = DateTime.now();
    final existing = _progressMap[currentWord.id];

    final updatedProgress = (existing ??
            WordProgress(
              wordId: currentWord.id,
              firstSeen: now,
            ))
        .copyWith(
      status: WordStatus.mastered,
      lastReviewed: now,
      nextReview: null,
      firstSeen: existing?.firstSeen ?? now,
      isSynced: false,
    );

    _progressMap[currentWord.id] = updatedProgress;
    unawaited(_progressRepository.updateWordProgress(uid, updatedProgress));

    final currentStats = SrsEngine.resetDailyCountersIfNeeded(
      _progressRepository.getLocalStats(uid),
      now,
    );
    _sessionKnowCount++;
    final updatedStats = SrsEngine.markStudyActivity(currentStats, now).copyWith(
      totalWordsLearned: currentStats.totalWordsLearned + 1,
    );
    unawaited(_progressRepository.updateStats(uid, updatedStats));

    final nextIndex = currentState.currentIndex + 1;
    if (nextIndex >= currentState.words.length) {
      emit(
        SwipeFinished(
          learnedCount: currentState.learnedCount,
          dailyGoal: currentState.dailyGoal,
          sessionKnowCount: _sessionKnowCount,
          sessionLearnCount: _sessionLearnCount,
        ),
      );
    } else {
      emit(
        currentState.copyWith(
          currentIndex: nextIndex,
          isFront: true,
        ),
      );
    }
  }

  /// Переворачивает карточку (английский ↔ русский).
  void toggleCardSide() {
    if (state is SwipeLoaded) {
      final currentState = state as SwipeLoaded;
      emit(currentState.copyWith(isFront: !currentState.isFront));
    }
  }

  /// Обновляет список доступных слов и актуальные настройки/статистику.
  Future<void> refreshWords() async {
    await loadWords();
  }

  /// Сбрасывает локальное состояние кубита при выходе из аккаунта.
  void reset() {
    _progressMap = {};
    _sessionKnowCount = 0;
    _sessionLearnCount = 0;
    emit(const SwipeLoading());
  }

  @override
  Future<void> close() async {
    await _cloudUpdatesSub?.cancel();
    return super.close();
  }
}
