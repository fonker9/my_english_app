import 'package:equatable/equatable.dart';
import 'package:my_english_app/data/models/word.dart';

/// Базовое состояние экрана свайп-карточек.
abstract class SwipeState extends Equatable {
  const SwipeState();

  @override
  List<Object?> get props => [];
}

/// Загрузка слов и прогресса.
class SwipeLoading extends SwipeState {
  const SwipeLoading();
}

/// Ошибка загрузки слов.
class SwipeError extends SwipeState {
  final String message;

  const SwipeError([this.message = 'Ошибка при загрузке слов']);

  @override
  List<Object?> get props => [message];
}

/// Активная сессия свайп-карточек.
class SwipeLoaded extends SwipeState {
  final List<Word> words;
  final int currentIndex;
  final int learnedCount;
  final int dailyGoal;
  final bool isFront;
  final String nickname;

  const SwipeLoaded({
    required this.words,
    required this.currentIndex,
    required this.learnedCount,
    required this.dailyGoal,
    required this.isFront,
    required this.nickname,
  });

  SwipeLoaded copyWith({
    List<Word>? words,
    int? currentIndex,
    int? learnedCount,
    int? dailyGoal,
    bool? isFront,
    String? nickname,
  }) {
    return SwipeLoaded(
      words: words ?? this.words,
      currentIndex: currentIndex ?? this.currentIndex,
      learnedCount: learnedCount ?? this.learnedCount,
      dailyGoal: dailyGoal ?? this.dailyGoal,
      isFront: isFront ?? this.isFront,
      nickname: nickname ?? this.nickname,
    );
  }

  @override
  List<Object?> get props => [
        words,
        currentIndex,
        learnedCount,
        dailyGoal,
        isFront,
        nickname,
      ];
}

/// Дневной план по новым словам выполнен или карточки сессии закончились.
class SwipeFinished extends SwipeState {
  final int learnedCount;
  final int dailyGoal;

  const SwipeFinished({
    required this.learnedCount,
    required this.dailyGoal,
  });

  @override
  List<Object?> get props => [learnedCount, dailyGoal];
}

/// В базе больше нет новых (unseen) слов.
class SwipeEmpty extends SwipeState {
  const SwipeEmpty();
}
