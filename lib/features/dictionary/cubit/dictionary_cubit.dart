import 'package:flutter_bloc/flutter_bloc.dart';
import '../../learning/data/words_repository.dart';
import 'dictionary_state.dart';

class DictionaryCubit extends Cubit<DictionaryState> {
  final WordsRepository _wordsRepository;

  DictionaryCubit(this._wordsRepository) : super(DictionaryLoading());

  Future<void> loadWords() async {
    try {
      emit(DictionaryLoading());
      final words = await _wordsRepository.getDailyWords();
      
      emit(DictionaryLoaded(allWords: words)); 
    } catch (e) {
      emit(DictionaryError());
    }
  }
  
  void refreshWords() async {
    if (state is DictionaryLoaded) {
      final currentState = state as DictionaryLoaded;
      final updatedWords = await _wordsRepository.getDailyWords();
      
      // Создаем полностью новый экземпляр списка,
      // чтобы Bloc гарантированно увидел изменение состояния и обновил ui
      emit(currentState.copyWith(allWords: List.from(updatedWords)));
    }
  }

  void selectLevel(String level) {
    if (state is DictionaryLoaded) {
      final currentState = state as DictionaryLoaded;
      emit(currentState.copyWith(selectedLevel: level, searchQuery: ''));
    }
  }

  void searchWords(String query) {
    if (state is DictionaryLoaded) {
      final currentState = state as DictionaryLoaded;
      emit(currentState.copyWith(searchQuery: query));
    }
  }
}