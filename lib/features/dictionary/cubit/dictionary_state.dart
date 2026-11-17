import 'package:equatable/equatable.dart';
import 'package:my_english_app/data/models/word.dart';
import 'package:my_english_app/data/models/word_progress.dart';

/// Режим группировки словаря на главном экране.
enum DictionaryFilterMode { byLevel, byTopic }

/// Базовое состояние экрана словаря.
abstract class DictionaryState extends Equatable {
  const DictionaryState();

  @override
  List<Object?> get props => [];
}

/// Загрузка словаря.
class DictionaryLoading extends DictionaryState {
  const DictionaryLoading();
}

/// Загруженное состояние словаря с прогрессом, режимом и фильтрами.
class DictionaryLoaded extends DictionaryState {
  static const Object _unset = Object();

  final List<Word> allWords;
  final Map<int, WordProgress> progressMap;
  final List<String> availableTopics;
  final DictionaryFilterMode filterMode;
  final String? selectedLevel;
  final String? selectedTopic;
  final String searchQuery;

  const DictionaryLoaded({
    required this.allWords,
    required this.progressMap,
    required this.availableTopics,
    this.filterMode = DictionaryFilterMode.byLevel,
    this.selectedLevel,
    this.selectedTopic,
    this.searchQuery = '',
  });

  /// Возвращает текущий статус изучения слова [wordId].
  WordStatus statusOf(int wordId) =>
      progressMap[wordId]?.status ?? WordStatus.unseen;

  /// Новые слова (`unseen`) в выбранном уровне/теме и с учётом поиска.
  List<Word> get newWordsFiltered =>
      _filterWords((status) => status == WordStatus.unseen);

  /// Слова на изучении (`learning` + `review`) с учётом фильтра и поиска.
  List<Word> get learningWordsFiltered => _filterWords(
        (status) =>
            status == WordStatus.learning || status == WordStatus.review,
      );

  /// Полностью изученные слова (`mastered`) с учётом фильтра и поиска.
  List<Word> get masteredWordsFiltered =>
      _filterWords((status) => status == WordStatus.mastered);

  /// Количество всех слов для уровня [level].
  int totalWordsForLevel(String level) {
    final normalized = level.toLowerCase();
    return allWords.where((w) => w.level.toLowerCase() == normalized).length;
  }

  /// Количество изученных (`mastered`) слов для уровня [level].
  int masteredWordsForLevel(String level) {
    final normalized = level.toLowerCase();
    return allWords
        .where(
          (w) =>
              w.level.toLowerCase() == normalized &&
              statusOf(w.id) == WordStatus.mastered,
        )
        .length;
  }

  /// Количество всех слов для темы [topic].
  int totalWordsForTopic(String topic) {
    final normalized = topic.toLowerCase();
    return allWords.where((w) => w.topic.toLowerCase() == normalized).length;
  }

  /// Количество изученных (`mastered`) слов для темы [topic].
  int masteredWordsForTopic(String topic) {
    final normalized = topic.toLowerCase();
    return allWords
        .where(
          (w) =>
              w.topic.toLowerCase() == normalized &&
              statusOf(w.id) == WordStatus.mastered,
        )
        .length;
  }

  /// Общее число слов в текущем выбранном уровне или теме (без поискового фильтра).
  int get totalWordsInSelection {
    return allWords.where(_matchesCategory).length;
  }

  /// Число изученных (`mastered`) слов в текущем выбранном уровне или теме.
  int get masteredWordsInSelection {
    return allWords
        .where(
          (w) => _matchesCategory(w) && statusOf(w.id) == WordStatus.mastered,
        )
        .length;
  }

  List<Word> _filterWords(bool Function(WordStatus status) statusPredicate) {
    final query = searchQuery.trim().toLowerCase();
    return allWords.where((word) {
      if (!_matchesCategory(word)) return false;
      if (!statusPredicate(statusOf(word.id))) return false;
      if (query.isEmpty) return true;
      return word.en.toLowerCase().contains(query) ||
          word.ru.toLowerCase().contains(query);
    }).toList();
  }

  bool _matchesCategory(Word word) {
    final matchesLevel = selectedLevel == null ||
        word.level.toLowerCase() == selectedLevel!.toLowerCase();
    final matchesTopic = selectedTopic == null ||
        word.topic.toLowerCase() == selectedTopic!.toLowerCase();
    return matchesLevel && matchesTopic;
  }

  DictionaryLoaded copyWith({
    List<Word>? allWords,
    Map<int, WordProgress>? progressMap,
    List<String>? availableTopics,
    DictionaryFilterMode? filterMode,
    Object? selectedLevel = _unset,
    Object? selectedTopic = _unset,
    String? searchQuery,
  }) {
    return DictionaryLoaded(
      allWords: allWords ?? this.allWords,
      progressMap: progressMap ?? this.progressMap,
      availableTopics: availableTopics ?? this.availableTopics,
      filterMode: filterMode ?? this.filterMode,
      selectedLevel: identical(selectedLevel, _unset)
          ? this.selectedLevel
          : selectedLevel as String?,
      selectedTopic: identical(selectedTopic, _unset)
          ? this.selectedTopic
          : selectedTopic as String?,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  @override
  List<Object?> get props => [
        allWords,
        progressMap,
        availableTopics,
        filterMode,
        selectedLevel,
        selectedTopic,
        searchQuery,
      ];
}

/// Ошибка загрузки словаря.
class DictionaryError extends DictionaryState {
  final String message;

  const DictionaryError([this.message = 'Ошибка загрузки словаря']);

  @override
  List<Object?> get props => [message];
}
