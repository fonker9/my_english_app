import '../data/word_model.dart';

abstract class LearningState {}

class LearningLoading extends LearningState {}

class LearningError extends LearningState {}

class LearningLoaded extends LearningState{

  final List<Word> words;
  final int currentIndex;
  final int learnedCount;
  final bool isFront;

  LearningLoaded({
    required this.words,
    required this.currentIndex,
    required this.learnedCount,
    required this.isFront,
  });

}

class LearningFinished extends LearningState {}