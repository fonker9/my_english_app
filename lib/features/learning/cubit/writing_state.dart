import 'package:equatable/equatable.dart';
import 'package:my_english_app/data/models/word.dart';

/// Статус проверки ответа в режиме «Написание».
enum WritingAnswerStatus { initial, correct, wrong }

/// Базовое состояние экрана «Написание».
abstract class WritingState extends Equatable {
  const WritingState();

  @override
  List<Object?> get props => [];
}

/// Загрузка слов для повторения.
class WritingLoading extends WritingState {
  const WritingLoading();
}

/// Нет слов для повторения в режиме «Написание».
class WritingEmpty extends WritingState {
  const WritingEmpty();
}

/// Ошибка загрузки или запуска режима «Написание».
class WritingError extends WritingState {
  final String message;

  const WritingError([this.message = 'Ошибка загрузки режима написания']);

  @override
  List<Object?> get props => [message];
}

/// Активная сессия написания слов.
class WritingLoaded extends WritingState {
  final List<Word> words;
  final int currentIndex;
  final WritingAnswerStatus answerStatus;
  final String submittedText;
  final int correctCount;
  final int wrongCount;
  final List<Word> wrongWords;

  const WritingLoaded({
    required this.words,
    this.currentIndex = 0,
    this.answerStatus = WritingAnswerStatus.initial,
    this.submittedText = '',
    this.correctCount = 0,
    this.wrongCount = 0,
    this.wrongWords = const [],
  });

  /// Текущее слово в сессии.
  Word get currentWord => words[currentIndex];

  /// Проверен ли уже ответ на текущее слово.
  bool get isAnswered => answerStatus != WritingAnswerStatus.initial;

  WritingLoaded copyWith({
    List<Word>? words,
    int? currentIndex,
    WritingAnswerStatus? answerStatus,
    String? submittedText,
    int? correctCount,
    int? wrongCount,
    List<Word>? wrongWords,
  }) {
    return WritingLoaded(
      words: words ?? this.words,
      currentIndex: currentIndex ?? this.currentIndex,
      answerStatus: answerStatus ?? this.answerStatus,
      submittedText: submittedText ?? this.submittedText,
      correctCount: correctCount ?? this.correctCount,
      wrongCount: wrongCount ?? this.wrongCount,
      wrongWords: wrongWords ?? this.wrongWords,
    );
  }

  @override
  List<Object?> get props => [
        words,
        currentIndex,
        answerStatus,
        submittedText,
        correctCount,
        wrongCount,
        wrongWords,
      ];
}

/// Сессия режима «Написание» завершена.
class WritingFinished extends WritingState {
  final int correctCount;
  final int wrongCount;
  final List<Word> wrongWords;

  const WritingFinished({
    required this.correctCount,
    required this.wrongCount,
    required this.wrongWords,
  });

  @override
  List<Object?> get props => [correctCount, wrongCount, wrongWords];
}
