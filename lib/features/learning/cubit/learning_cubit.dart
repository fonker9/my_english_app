import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/words_repository.dart';
import 'learning_state.dart';

class LearningCubit extends Cubit<LearningState> {
  final WordsRepository _wordsRepository;

  int _learnedTodayCount = 0;
  LearningCubit(this._wordsRepository) : super(LearningLoading());
  Future<void> loadWords() async {

    try {
      final words = await _wordsRepository.getDailyWords();
      
      emit(LearningLoaded(words: words, currentIndex: 0, learnedCount: _learnedTodayCount, isFront: true));
      
    } catch (e) {
      emit(LearningError());
    }
  }

  void notKnowWord() {
    if (state is LearningLoaded) {
      final currentState = state as LearningLoaded;
      
      // Берем текущее слово и помечаем его как "В процессе изучения"
      final currentWord = currentState.words[currentState.currentIndex];
      _wordsRepository.markAsLearning(currentWord.id);
      
      _learnedTodayCount++;
      final nextIndex = currentState.currentIndex + 1;

      if (_learnedTodayCount >= 5 || nextIndex >= currentState.words.length) {
        emit(LearningFinished());
      } else {
        emit(LearningLoaded(
          words: currentState.words,
          currentIndex: nextIndex, 
          learnedCount: _learnedTodayCount,
          isFront: true,
        ));
      }
    }
  }

  void knowWord() {
    if (state is LearningLoaded) {
      final currentState = state as LearningLoaded;
      
      // Получаем текущее слово, которое пользователь знает
      final currentWord = currentState.words[currentState.currentIndex];
      
      // Обновляем статус слова в репозитории
      _wordsRepository.markAsLearned(currentWord.id);

      final nextIndex = currentState.currentIndex + 1;
      if (nextIndex >= currentState.words.length) {
        emit(LearningFinished());
      } else {
        emit(LearningLoaded(
          words: currentState.words,
          currentIndex: nextIndex,
          learnedCount: _learnedTodayCount,
          isFront: true,
        ));
      }
    }
  }

  void toggleCardSide() {
    if (state is LearningLoaded) {
      final currentState = state as LearningLoaded;
      emit(LearningLoaded(
        words: currentState.words,
        currentIndex: currentState.currentIndex,
        learnedCount: currentState.learnedCount,
        isFront: !currentState.isFront,
      ));
    }
  }

  void refreshWords() async {
  if (state is LearningLoaded) {
    final currentState = state as LearningLoaded;
    final updatedWords = await _wordsRepository.getDailyWords();
    
    emit(LearningLoaded(
      words: List.from(updatedWords), // Клонируем список
      currentIndex: currentState.currentIndex, // Сохраняем индекс
      learnedCount: currentState.learnedCount,
      isFront: currentState.isFront,
    ));
  }
}

}