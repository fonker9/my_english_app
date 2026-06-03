import 'package:my_english_app/features/learning/data/word_model.dart';

abstract class DictionaryState {}


class DictionaryLoading extends DictionaryState {}

class DictionaryLoaded extends DictionaryState {
  final List<Word> allWords;

  final String? selectedLevel;

  final String searchQuery;

  DictionaryLoaded({
    required this.allWords,
    this.selectedLevel,
    this.searchQuery = '',
  });

  List<Word> get learningWordsFiltered {
    return allWords.where((word) {
      final matchesLevel = selectedLevel == null || 
          word.level.toLowerCase() == selectedLevel!.toLowerCase();
          
      // слово должно быть явно помечено как "Учу" (isLearning == true) 
      // и при этом еще не быть полностью выученным (!word.isLearned)
      final isLearning = word.isLearning && !word.isLearned; 
      
      final matchesSearch = searchQuery.isEmpty ||
          word.english.toLowerCase().contains(searchQuery.toLowerCase()) ||
          word.russian.toLowerCase().contains(searchQuery.toLowerCase());

      return matchesLevel && isLearning && matchesSearch;
    }).toList();
  }

  List<Word> get learnedWordsFiltered {
    return allWords.where((word) {
      final matchesLevel = selectedLevel == null || 
          word.level.toLowerCase() == selectedLevel!.toLowerCase();
          
      final isLearned = word.isLearned; 
      
      final matchesSearch = searchQuery.isEmpty ||
          word.english.toLowerCase().contains(searchQuery.toLowerCase()) ||
          word.russian.toLowerCase().contains(searchQuery.toLowerCase());

      return matchesLevel && isLearned && matchesSearch;
    }).toList();
  }

  DictionaryLoaded copyWith({
    List<Word>? allWords,
    String? selectedLevel,
    String? searchQuery,
  }) {
    return DictionaryLoaded(
      allWords: allWords ?? this.allWords,
      selectedLevel: selectedLevel ?? this.selectedLevel,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

class DictionaryError extends DictionaryState {}