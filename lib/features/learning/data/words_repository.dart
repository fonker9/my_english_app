import 'word_model.dart';
import 'dart:convert';
import 'package:flutter/services.dart';

abstract class WordsRepository {
  Future<List<Word>> getDailyWords();
  void markAsLearned(int wordId); 
  void markAsLearning(int wordId);
}

class LocalWordsRepository implements WordsRepository {
  List<Word> _cachedWords = [];

  @override
  Future<List<Word>> getDailyWords() async {
    if (_cachedWords.isNotEmpty) {
      return _cachedWords;
    }

    final response = await rootBundle.loadString('assets/words.json');
    final List<dynamic> data = jsonDecode(response);
    
    _cachedWords = data.map((json) => Word.fromJson(json)).toList();
    return _cachedWords;
  }

  @override
  void markAsLearned(int wordId) {
    final index = _cachedWords.indexWhere((w) => w.id == wordId);
    if (index != -1) {
      // Если слово выучено, заодно убираем флаг isLearning
      _cachedWords[index] = _cachedWords[index].copyWith(isLearned: true, isLearning: false);
    }
  }

  @override
  void markAsLearning(int wordId) {
    final index = _cachedWords.indexWhere((w) => w.id == wordId);
    if (index != -1) {
      _cachedWords[index] = _cachedWords[index].copyWith(isLearning: true);
    }
  }
}