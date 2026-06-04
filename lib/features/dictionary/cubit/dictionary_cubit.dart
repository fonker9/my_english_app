import 'package:flutter_bloc/flutter_bloc.dart';
import '../../learning/data/words_repository.dart';
import '../../progress/data/progress_repository.dart';
import '../../progress/data/progress_model.dart';
import 'dictionary_state.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DictionaryCubit extends Cubit<DictionaryState> {
  final WordsRepository _wordsRepository;
  final ProgressRepository _progressRepository;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  DictionaryCubit(
    this._wordsRepository,
    this._progressRepository,
  ) : super(DictionaryLoading());

  Future<void> loadWords() async {
    try {
      emit(DictionaryLoading());

      final uid = _auth.currentUser?.uid;
      if (uid == null) {
        emit(DictionaryError());
        return;
      }

      // 1. загружаем базовые слова
      final words = await _wordsRepository.getDailyWords();

      // 2. загружаем прогресс пользователя
      final progress = await _progressRepository.loadProgress(uid);

      // 3. накладываем прогресс на слова
      final updatedWords =
          await _wordsRepository.applyProgress(progress);

      emit(DictionaryLoaded(allWords: updatedWords));
    } catch (e) {
      emit(DictionaryError());
    }
  }

  void refreshWords() async {
    if (state is DictionaryLoaded) {
      try {
        final uid = _auth.currentUser?.uid;
        if (uid == null) return;

        final progress = await _progressRepository.loadProgress(uid);
        final updatedWords =
            await _wordsRepository.applyProgress(progress);

        emit(DictionaryLoaded(allWords: updatedWords));
      } catch (e) {
        emit(DictionaryError());
      }
    }
  }

  void selectLevel(String level) {
    if (state is DictionaryLoaded) {
      final currentState = state as DictionaryLoaded;
      emit(currentState.copyWith(
        selectedLevel: level,
        searchQuery: '',
      ));
    }
  }

  void searchWords(String query) {
    if (state is DictionaryLoaded) {
      final currentState = state as DictionaryLoaded;
      emit(currentState.copyWith(searchQuery: query));
    }
  }
}