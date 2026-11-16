import 'package:equatable/equatable.dart';

/// Иммутабельная модель английского слова из базы assets/words.json.
/// Не хранит прогресс пользователя — прогресс находится в [WordProgress].
class Word extends Equatable {
  final int id;
  final String en;
  final String ru;
  final String level;
  final String topic;
  final String partOfSpeech;
  final String transcription;
  final String? example;
  final String? exampleRu;

  const Word({
    required this.id,
    required this.en,
    required this.ru,
    required this.level,
    this.topic = 'general',
    this.partOfSpeech = '',
    this.transcription = '',
    this.example,
    this.exampleRu,
  });

  /// Создаёт модель [Word] из JSON-объекта.
  factory Word.fromJson(Map<String, dynamic> json) {
    return Word(
      id: (json['id'] as num).toInt(),
      en: json['en'] as String,
      ru: json['ru'] as String,
      level: json['level'] as String,
      topic: json['topic'] as String? ?? 'general',
      partOfSpeech: json['partOfSpeech'] as String? ?? '',
      transcription: json['transcription'] as String? ?? '',
      example: json['example'] as String?,
      exampleRu: json['exampleRu'] as String?,
    );
  }

  /// Преобразует модель [Word] в JSON-объект.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'en': en,
      'ru': ru,
      'level': level,
      'topic': topic,
      'partOfSpeech': partOfSpeech,
      'transcription': transcription,
      if (example != null) 'example': example,
      if (exampleRu != null) 'exampleRu': exampleRu,
    };
  }

  @override
  List<Object?> get props => [
        id,
        en,
        ru,
        level,
        topic,
        partOfSpeech,
        transcription,
        example,
        exampleRu,
      ];
}
