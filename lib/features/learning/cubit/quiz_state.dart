import 'package:equatable/equatable.dart';
import 'package:my_english_app/data/models/word.dart';

/// Направление перевода вопроса в квизе.
enum QuizDirection { enToRu, ruToEn }

/// Один вопрос квиза с 4 вариантами ответа.
class QuizQuestion extends Equatable {
  final Word word;
  final QuizDirection direction;
  final List<String> options;
  final int correctIndex;

  const QuizQuestion({
    required this.word,
    required this.direction,
    required this.options,
    required this.correctIndex,
  });

  /// Слово-подсказка, которое отображается пользователю.
  String get prompt =>
      direction == QuizDirection.enToRu ? word.en : word.ru;

  /// Правильный вариант ответа.
  String get correctAnswer =>
      direction == QuizDirection.enToRu ? word.ru : word.en;

  @override
  List<Object?> get props => [word, direction, options, correctIndex];
}

/// Базовое состояние экрана квиза.
abstract class QuizState extends Equatable {
  const QuizState();

  @override
  List<Object?> get props => [];
}

/// Загрузка слов для квиза.
class QuizLoading extends QuizState {
  const QuizLoading();
}

/// Нет слов, готовых к повторению в квизе.
class QuizEmpty extends QuizState {
  const QuizEmpty();
}

/// Ошибка загрузки квиза.
class QuizError extends QuizState {
  final String message;

  const QuizError([this.message = 'Ошибка загрузки квиза']);

  @override
  List<Object?> get props => [message];
}

/// Активная сессия квиза.
class QuizLoaded extends QuizState {
  static const Object _unset = Object();

  final List<QuizQuestion> questions;
  final int currentIndex;
  final int? selectedOptionIndex;
  final int correctCount;
  final int wrongCount;
  final List<Word> wrongWords;

  const QuizLoaded({
    required this.questions,
    this.currentIndex = 0,
    this.selectedOptionIndex,
    this.correctCount = 0,
    this.wrongCount = 0,
    this.wrongWords = const [],
  });

  /// Текущий вопрос квиза.
  QuizQuestion get currentQuestion => questions[currentIndex];

  /// Выбран ли уже вариант ответа на текущий вопрос.
  bool get isAnswered => selectedOptionIndex != null;

  QuizLoaded copyWith({
    List<QuizQuestion>? questions,
    int? currentIndex,
    Object? selectedOptionIndex = _unset,
    int? correctCount,
    int? wrongCount,
    List<Word>? wrongWords,
  }) {
    return QuizLoaded(
      questions: questions ?? this.questions,
      currentIndex: currentIndex ?? this.currentIndex,
      selectedOptionIndex: identical(selectedOptionIndex, _unset)
          ? this.selectedOptionIndex
          : selectedOptionIndex as int?,
      correctCount: correctCount ?? this.correctCount,
      wrongCount: wrongCount ?? this.wrongCount,
      wrongWords: wrongWords ?? this.wrongWords,
    );
  }

  @override
  List<Object?> get props => [
        questions,
        currentIndex,
        selectedOptionIndex,
        correctCount,
        wrongCount,
        wrongWords,
      ];
}

/// Сессия квиза завершена.
class QuizFinished extends QuizState {
  final int correctCount;
  final int wrongCount;
  final int totalQuestions;
  final List<Word> wrongWords;

  const QuizFinished({
    required this.correctCount,
    required this.wrongCount,
    required this.totalQuestions,
    required this.wrongWords,
  });

  /// Процент правильных ответов за сессию.
  int get accuracyPercent =>
      totalQuestions > 0 ? ((correctCount * 100) / totalQuestions).round() : 0;

  @override
  List<Object?> get props => [
        correctCount,
        wrongCount,
        totalQuestions,
        wrongWords,
      ];
}
