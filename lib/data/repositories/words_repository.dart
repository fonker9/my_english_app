import '../models/word.dart';
import '../sources/asset/asset_words_source.dart';

/// Репозиторий для работы со словарной базой из assets.
/// Иммутабельный — не хранит прогресс изучения.
abstract class WordsRepository {
  /// Загружает все слова из assets. Кэширует в памяти.
  Future<List<Word>> getAllWords();

  /// Фильтрует слова по уровню и/или теме.
  List<Word> getFilteredWords({String? level, String? topic});

  /// Возвращает список уникальных тем.
  List<String> getAvailableTopics();
}

/// Реализация [WordsRepository] поверх [AssetWordsSource].
class WordsRepositoryImpl implements WordsRepository {
  final AssetWordsSource _assetWordsSource;

  List<Word> _cachedWords = const [];

  WordsRepositoryImpl(this._assetWordsSource);

  @override
  Future<List<Word>> getAllWords() async {
    if (_cachedWords.isNotEmpty) {
      return _cachedWords;
    }

    final words = await _assetWordsSource.loadWords();
    _cachedWords = List.unmodifiable(words);
    return _cachedWords;
  }

  @override
  List<Word> getFilteredWords({String? level, String? topic}) {
    final normalizedLevel = level?.trim().toLowerCase();
    final normalizedTopic = topic?.trim().toLowerCase();

    return _cachedWords.where((word) {
      final matchesLevel = normalizedLevel == null ||
          normalizedLevel.isEmpty ||
          word.level.toLowerCase() == normalizedLevel;
      final matchesTopic = normalizedTopic == null ||
          normalizedTopic.isEmpty ||
          word.topic.toLowerCase() == normalizedTopic;
      return matchesLevel && matchesTopic;
    }).toList();
  }

  @override
  List<String> getAvailableTopics() {
    final seen = <String>{};
    final topics = <String>[];

    for (final word in _cachedWords) {
      final topic = word.topic.trim();
      if (topic.isNotEmpty && seen.add(topic)) {
        topics.add(topic);
      }
    }

    return topics;
  }
}
