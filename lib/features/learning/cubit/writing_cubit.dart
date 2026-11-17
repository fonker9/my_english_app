import 'dart:async';
import 'dart:math';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_english_app/core/di/service_locator.dart';
import 'package:my_english_app/core/srs/srs_engine.dart';
import 'package:my_english_app/core/utils/levenshtein.dart';
import 'package:my_english_app/data/models/user_stats.dart';
import 'package:my_english_app/data/models/word_progress.dart';
import 'package:my_english_app/data/repositories/auth_repository.dart';
import 'package:my_english_app/data/repositories/progress_repository.dart';
import 'package:my_english_app/data/repositories/words_repository.dart';
import 'writing_state.dart';

/// Кубит для режима «Написание» (ручной ввод английского слова с проверкой по Левенштейну).
class WritingCubit extends Cubit<WritingState> {
  static const int maxWordsPerSession = 10;

  final WordsRepository _wordsRepository;
  final ProgressRepository _progressRepository;
  final AuthRepository _authRepository;
  final Random _random;

  Map<int, WordProgress> _progressMap = {};
  UserStats _stats = UserStats.empty();

  WritingCubit(
    this._wordsRepository,
    this._progressRepository, [
    AuthRepository? authRepository,
    Random? random,
  ])  : _authRepository = authRepository ?? sl<AuthRepository>(),
        _random = random ?? Random(),
        super(const WritingLoading());

  /// Загружает слова для повторения и формирует сессию написания (до 10 слов).
  Future<void> startSession() async {
    try {
      emit(const WritingLoading());

      final uid = _authRepository.currentUid;
      if (uid == null) {
        emit(const WritingError('Пользователь не авторизован'));
        return;
      }

      final allWords = await _wordsRepository.getAllWords();
      _progressMap = Map<int, WordProgress>.from(
        await _progressRepository.loadAllProgress(uid),
      );
      _stats = await _progressRepository.loadStats(uid);

      final now = DateTime.now();
      final resetStats = SrsEngine.resetDailyCountersIfNeeded(_stats, now);
      if (resetStats != _stats) {
        _stats = resetStats;
        await _progressRepository.updateStats(uid, _stats);
      }

      final dueWords = allWords.where((word) {
        final progress = _progressMap[word.id];
        if (progress == null) return false;
        return ProgressRepositoryImpl.isWordDueForReview(progress, now);
      }).toList();

      if (dueWords.isEmpty) {
        emit(const WritingEmpty());
        return;
      }

      dueWords.shuffle(_random);
      final sessionWords = dueWords.take(maxWordsPerSession).toList();
      emit(WritingLoaded(words: sessionWords));
    } catch (e) {
      emit(WritingError('Ошибка запуска режима написания: $e'));
    }
  }

  /// Проверяет введённое слово [input] (допускается расстояние Левенштейна <= 1).
  void checkAnswer(String input) {
    if (state is! WritingLoaded) return;
    final currentState = state as WritingLoaded;
    if (currentState.isAnswered) return;

    final isCorrect = isAnswerAccepted(
      input,
      currentState.currentWord.en,
      maxDistance: 1,
    );
    _processResult(
      currentState: currentState,
      isCorrect: isCorrect,
      submittedText: input,
    );
  }

  /// Фиксирует нажатие кнопки «Не помню» как неправильный ответ.
  void skipWord() {
    if (state is! WritingLoaded) return;
    final currentState = state as WritingLoaded;
    if (currentState.isAnswered) return;

    _processResult(
      currentState: currentState,
      isCorrect: false,
      submittedText: '',
    );
  }

  void _processResult({
    required WritingLoaded currentState,
    required bool isCorrect,
    required String submittedText,
  }) {
    final uid = _authRepository.currentUid;
    if (uid == null) return;

    final currentWord = currentState.currentWord;
    final now = DateTime.now();

    final currentProgress = _progressMap[currentWord.id] ??
        WordProgress(
          wordId: currentWord.id,
          status: WordStatus.learning,
          firstSeen: now,
        );

    final wasMastered = currentProgress.status == WordStatus.mastered;
    final updatedProgress = SrsEngine.processAnswer(
      current: currentProgress,
      isCorrect: isCorrect,
    );

    _progressMap[currentWord.id] = updatedProgress;
    unawaited(_progressRepository.updateWordProgress(uid, updatedProgress));

    final becameMastered =
        !wasMastered && updatedProgress.status == WordStatus.mastered;
    _stats = SrsEngine.markStudyActivity(_stats, now).copyWith(
      todayReviews: _stats.todayReviews + 1,
      totalQuizCorrect: _stats.totalQuizCorrect + (isCorrect ? 1 : 0),
      totalQuizWrong: _stats.totalQuizWrong + (isCorrect ? 0 : 1),
      totalWordsLearned: _stats.totalWordsLearned + (becameMastered ? 1 : 0),
    );
    unawaited(_progressRepository.updateStats(uid, _stats));

    final updatedWrongWords = isCorrect
        ? currentState.wrongWords
        : [...currentState.wrongWords, currentWord];

    emit(
      currentState.copyWith(
        answerStatus: isCorrect
            ? WritingAnswerStatus.correct
            : WritingAnswerStatus.wrong,
        submittedText: submittedText,
        correctCount: currentState.correctCount + (isCorrect ? 1 : 0),
        wrongCount: currentState.wrongCount + (isCorrect ? 0 : 1),
        wrongWords: updatedWrongWords,
      ),
    );
  }

  /// Переходит к следующему слову или завершает сессию.
  void nextWord() {
    if (state is! WritingLoaded) return;
    final currentState = state as WritingLoaded;

    final nextIndex = currentState.currentIndex + 1;
    if (nextIndex >= currentState.words.length) {
      emit(
        WritingFinished(
          correctCount: currentState.correctCount,
          wrongCount: currentState.wrongCount,
          wrongWords: currentState.wrongWords,
        ),
      );
    } else {
      emit(
        currentState.copyWith(
          currentIndex: nextIndex,
          answerStatus: WritingAnswerStatus.initial,
          submittedText: '',
        ),
      );
    }
  }
}
