import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_english_app/core/di/service_locator.dart';
import 'package:my_english_app/data/models/user_stats.dart';
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

  Map<int, WordProgress> _progressMap = {};
  UserStats _stats = UserStats.empty();

  SwipeCubit(
    this._wordsRepository,
    this._progressRepository,
    this._settingsRepository, [
    AuthRepository? authRepository,
  ])  : _authRepository = authRepository ?? sl<AuthRepository>(),
        super(const SwipeLoading());

  /// Загружает слова со статусом `unseen`, дневную цель и статистику за сегодня.
  Future<void> loadWords() async {
    try {
      emit(const SwipeLoading());

      final uid = _authRepository.currentUid;
      if (uid == null) {
        emit(const SwipeError('Пользователь не авторизован'));
        return;
      }

      final allWords = await _wordsRepository.getAllWords();
      _progressMap = Map<int, WordProgress>.from(
        await _progressRepository.loadAllProgress(uid),
      );
      _stats = await _progressRepository.loadStats(uid);

      // Сбрасываем дневные счётчики, если последнее занятие было в другой день.
      final now = DateTime.now();
      if (_stats.lastStudyDate != null &&
          !_isSameDay(_stats.lastStudyDate!, now) &&
          (_stats.todayNewWords != 0 || _stats.todayReviews != 0)) {
        _stats = _stats.copyWith(todayNewWords: 0, todayReviews: 0);
        await _progressRepository.updateStats(uid, _stats);
      }

      final settings = await _settingsRepository.loadSettings();
      final dailyGoal = settings.dailyNewWordsGoal;

      if (_stats.todayNewWords >= dailyGoal) {
        emit(
          SwipeFinished(
            learnedCount: _stats.todayNewWords,
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
          learnedCount: _stats.todayNewWords,
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

    final newLearnedCount = currentState.learnedCount + 1;
    _stats = _markStudyActivity(_stats, now).copyWith(
      todayNewWords: newLearnedCount,
    );
    unawaited(_progressRepository.updateStats(uid, _stats));

    final nextIndex = currentState.currentIndex + 1;
    if (newLearnedCount >= currentState.dailyGoal ||
        nextIndex >= currentState.words.length) {
      emit(
        SwipeFinished(
          learnedCount: newLearnedCount,
          dailyGoal: currentState.dailyGoal,
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

    _stats = _markStudyActivity(_stats, now).copyWith(
      totalWordsLearned: _stats.totalWordsLearned + 1,
    );
    unawaited(_progressRepository.updateStats(uid, _stats));

    final nextIndex = currentState.currentIndex + 1;
    if (nextIndex >= currentState.words.length) {
      emit(
        SwipeFinished(
          learnedCount: currentState.learnedCount,
          dailyGoal: currentState.dailyGoal,
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

  static bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  static bool _isYesterday(DateTime date, DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    return today.difference(target).inDays == 1;
  }

  static UserStats _markStudyActivity(UserStats currentStats, DateTime now) {
    final lastDate = currentStats.lastStudyDate;
    int newStreak;

    if (lastDate != null && _isSameDay(lastDate, now)) {
      newStreak =
          currentStats.currentStreak > 0 ? currentStats.currentStreak : 1;
    } else if (lastDate != null && _isYesterday(lastDate, now)) {
      newStreak = currentStats.currentStreak + 1;
    } else {
      newStreak = 1;
    }

    final newLongest = newStreak > currentStats.longestStreak
        ? newStreak
        : currentStats.longestStreak;

    return currentStats.copyWith(
      currentStreak: newStreak,
      longestStreak: newLongest,
      lastStudyDate: now,
    );
  }
}
