import 'dart:async';
import 'dart:math';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_english_app/core/di/service_locator.dart';
import 'package:my_english_app/core/srs/srs_engine.dart';
import 'package:my_english_app/data/models/word.dart';
import 'package:my_english_app/data/models/word_progress.dart';
import 'package:my_english_app/data/repositories/auth_repository.dart';
import 'package:my_english_app/data/repositories/progress_repository.dart';
import 'package:my_english_app/data/repositories/words_repository.dart';
import 'quiz_state.dart';

/// Кубит для режима «Квиз» (4 варианта ответа, SRS).
class QuizCubit extends Cubit<QuizState> {
  static const int maxQuestionsPerSession = 10;
  static const int optionsCount = 4;

  final WordsRepository _wordsRepository;
  final ProgressRepository _progressRepository;
  final AuthRepository _authRepository;
  final Random _random;

  Map<int, WordProgress> _progressMap = {};

  QuizCubit(
    this._wordsRepository,
    this._progressRepository, [
    AuthRepository? authRepository,
    Random? random,
  ])  : _authRepository = authRepository ?? sl<AuthRepository>(),
        _random = random ?? Random(),
        super(const QuizLoading());

  /// Загружает слова для повторения и формирует сессию квиза (до 10 вопросов).
  Future<void> startQuiz() async {
    try {
      emit(const QuizLoading());

      final uid = _authRepository.currentUid;
      if (uid == null) {
        emit(const QuizError('Пользователь не авторизован'));
        return;
      }

      final allWords = await _wordsRepository.getAllWords();
      _progressMap = Map<int, WordProgress>.from(
        await _progressRepository.loadAllProgress(uid),
      );
      final stats = await _progressRepository.loadStats(uid);

      final now = DateTime.now();
      final resetStats = SrsEngine.resetDailyCountersIfNeeded(stats, now);
      if (resetStats != stats) {
        await _progressRepository.updateStats(uid, resetStats);
      }

      final dueWords = allWords.where((word) {
        final progress = _progressMap[word.id];
        if (progress == null) return false;
        return ProgressRepositoryImpl.isWordDueForReview(progress, now);
      }).toList();

      if (dueWords.isEmpty) {
        emit(const QuizEmpty());
        return;
      }

      dueWords.shuffle(_random);
      final sessionWords = dueWords.take(maxQuestionsPerSession).toList();
      final questions = sessionWords
          .map((word) => _buildQuestion(word, allWords))
          .toList();

      emit(QuizLoaded(questions: questions));
    } catch (e) {
      emit(QuizError('Ошибка запуска квиза: $e'));
    }
  }

  /// Обрабатывает выбор варианта ответа пользователем и обновляет SRS-прогресс.
  void selectAnswer(int optionIndex) {
    if (state is! QuizLoaded) return;
    final currentState = state as QuizLoaded;
    if (currentState.isAnswered) return;

    final uid = _authRepository.currentUid;
    if (uid == null) return;

    final question = currentState.currentQuestion;
    final isCorrect = optionIndex == question.correctIndex;
    final now = DateTime.now();

    final currentProgress = _progressMap[question.word.id] ??
        WordProgress(
          wordId: question.word.id,
          status: WordStatus.learning,
          firstSeen: now,
        );

    final wasMastered = currentProgress.status == WordStatus.mastered;
    final updatedProgress = SrsEngine.processAnswer(
      current: currentProgress,
      isCorrect: isCorrect,
    );

    _progressMap[question.word.id] = updatedProgress;
    unawaited(_progressRepository.updateWordProgress(uid, updatedProgress));

    final becameMastered =
        !wasMastered && updatedProgress.status == WordStatus.mastered;
    final currentStats = SrsEngine.resetDailyCountersIfNeeded(
      _progressRepository.getLocalStats(uid),
      now,
    );
    final updatedStats = SrsEngine.markStudyActivity(currentStats, now).copyWith(
      todayReviews: currentStats.todayReviews + 1,
      totalQuizCorrect: currentStats.totalQuizCorrect + (isCorrect ? 1 : 0),
      totalQuizWrong: currentStats.totalQuizWrong + (isCorrect ? 0 : 1),
      totalWordsLearned:
          currentStats.totalWordsLearned + (becameMastered ? 1 : 0),
    );
    unawaited(_progressRepository.updateStats(uid, updatedStats));

    final updatedWrongWords = isCorrect
        ? currentState.wrongWords
        : [...currentState.wrongWords, question.word];

    emit(
      currentState.copyWith(
        selectedOptionIndex: optionIndex,
        correctCount: currentState.correctCount + (isCorrect ? 1 : 0),
        wrongCount: currentState.wrongCount + (isCorrect ? 0 : 1),
        wrongWords: updatedWrongWords,
      ),
    );
  }

  /// Переходит к следующему вопросу или завершает сессию.
  void nextQuestion() {
    if (state is! QuizLoaded) return;
    final currentState = state as QuizLoaded;

    final nextIndex = currentState.currentIndex + 1;
    if (nextIndex >= currentState.questions.length) {
      emit(
        QuizFinished(
          correctCount: currentState.correctCount,
          wrongCount: currentState.wrongCount,
          totalQuestions: currentState.questions.length,
          wrongWords: currentState.wrongWords,
        ),
      );
    } else {
      emit(
        currentState.copyWith(
          currentIndex: nextIndex,
          selectedOptionIndex: null,
        ),
      );
    }
  }

  QuizQuestion _buildQuestion(Word target, List<Word> allWords) {
    final direction =
        _random.nextBool() ? QuizDirection.enToRu : QuizDirection.ruToEn;
    final correctText =
        direction == QuizDirection.enToRu ? target.ru : target.en;

    final usedTexts = <String>{correctText.trim().toLowerCase()};
    final distractors = <String>[];

    // Сначала подбираем варианты из того же уровня.
    final sameLevel = allWords
        .where(
          (w) =>
              w.id != target.id &&
              w.level.toLowerCase() == target.level.toLowerCase(),
        )
        .toList()
      ..shuffle(_random);

    _collectDistractors(
      candidates: sameLevel,
      direction: direction,
      usedTexts: usedTexts,
      distractors: distractors,
    );

    // Если вариантов не хватает (< 3), добираем из остальных уровней.
    if (distractors.length < optionsCount - 1) {
      final otherLevels = allWords
          .where(
            (w) =>
                w.id != target.id &&
                w.level.toLowerCase() != target.level.toLowerCase(),
          )
          .toList()
        ..shuffle(_random);

      _collectDistractors(
        candidates: otherLevels,
        direction: direction,
        usedTexts: usedTexts,
        distractors: distractors,
      );
    }

    final options = <String>[correctText, ...distractors]..shuffle(_random);
    final correctIndex = options.indexOf(correctText);

    return QuizQuestion(
      word: target,
      direction: direction,
      options: options,
      correctIndex: correctIndex,
    );
  }

  void _collectDistractors({
    required List<Word> candidates,
    required QuizDirection direction,
    required Set<String> usedTexts,
    required List<String> distractors,
  }) {
    for (final candidate in candidates) {
      if (distractors.length >= optionsCount - 1) break;
      final text =
          direction == QuizDirection.enToRu ? candidate.ru : candidate.en;
      if (usedTexts.add(text.trim().toLowerCase())) {
        distractors.add(text);
      }
    }
  }
}
