import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_english_app/features/progress/data/progress_repository.dart';
import '../data/words_repository.dart';
import 'learning_state.dart';

class LearningCubit extends Cubit<LearningState> {
  final WordsRepository _wordsRepository;
  final ProgressRepository _progressRepository;

  final FirebaseAuth _auth = FirebaseAuth.instance;

  int _learnedTodayCount = 0;

  LearningCubit(
    this._wordsRepository,
    this._progressRepository,
  ) : super(LearningLoading());

  Future<void> loadWords() async {
    try {
      final words = await _wordsRepository.getDailyWords();

      emit(
        LearningLoaded(
          words: words,
          currentIndex: 0,
          learnedCount: _learnedTodayCount,
          isFront: true,
        ),
      );
    } catch (e) {
      emit(LearningError());
    }
  }


  Future<void> _saveProgress({
    required int wordId,
    required bool isLearned,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final currentProgress =
        await _progressRepository.loadProgress(user.uid);

    List<int> learned = List.from(currentProgress.learnedWords);
    List<int> learning = List.from(currentProgress.learningWords);

    if (isLearned) {
      if (!learned.contains(wordId)) {
        learned.add(wordId);
      }
      learning.remove(wordId);
    } else {
      if (!learning.contains(wordId)) {
        learning.add(wordId);
      }
    }

    await _progressRepository.saveProgress(
      user.uid,
      currentProgress.copyWith(
        learnedWords: learned,
        learningWords: learning,
      ),
    );
  }


  void notKnowWord() {
    if (state is LearningLoaded) {
      final currentState = state as LearningLoaded;

      final currentWord =
          currentState.words[currentState.currentIndex];

      _wordsRepository.markAsLearning(currentWord.id);

      _saveProgress(
        wordId: currentWord.id,
        isLearned: false,
      );

      _learnedTodayCount++;

      final nextIndex = currentState.currentIndex + 1;

      if (_learnedTodayCount >= 5 ||
          nextIndex >= currentState.words.length) {
        emit(LearningFinished());
      } else {
        emit(
          LearningLoaded(
            words: currentState.words,
            currentIndex: nextIndex,
            learnedCount: _learnedTodayCount,
            isFront: true,
          ),
        );
      }
    }
  }


  void knowWord() {
    if (state is LearningLoaded) {
      final currentState = state as LearningLoaded;

      final currentWord =
          currentState.words[currentState.currentIndex];

      _wordsRepository.markAsLearned(currentWord.id);

      _saveProgress(
        wordId: currentWord.id,
        isLearned: true,
      );

      final nextIndex = currentState.currentIndex + 1;

      if (nextIndex >= currentState.words.length) {
        emit(LearningFinished());
      } else {
        emit(
          LearningLoaded(
            words: currentState.words,
            currentIndex: nextIndex,
            learnedCount: _learnedTodayCount,
            isFront: true,
          ),
        );
      }
    }
  }

  void toggleCardSide() {
    if (state is LearningLoaded) {
      final currentState = state as LearningLoaded;

      emit(
        LearningLoaded(
          words: currentState.words,
          currentIndex: currentState.currentIndex,
          learnedCount: currentState.learnedCount,
          isFront: !currentState.isFront,
        ),
      );
    }
  }

  void refreshWords() async {
    if (state is LearningLoaded) {
      final currentState = state as LearningLoaded;

      final updatedWords =
          await _wordsRepository.getDailyWords();

      emit(
        LearningLoaded(
          words: List.from(updatedWords),
          currentIndex: currentState.currentIndex,
          learnedCount: currentState.learnedCount,
          isFront: currentState.isFront,
        ),
      );
    }
  }
}