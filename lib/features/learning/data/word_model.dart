class Word{
  final int id;
  final String english;
  final String russian;
  final String level;
  final bool isLearned;
  final bool isLearning;
  
  Word({
    required this.id,
    required this.english,
    required this.russian,
    required this.level,
    this.isLearned = false,
    this.isLearning = false,
  });

  factory Word.fromJson(Map<String, dynamic> json) {
    return Word(
      id: json['id'] as int,
      english: json['en'] as String,
      russian: json['ru'] as String,
      level: json['level'] as String,
      isLearned: json['isLearned'] as bool? ?? false,
      isLearning: json['isLearning'] as bool? ?? false,
    );
  }

  Word copyWith({bool? isLearned, bool? isLearning}){
    return Word(
      id: id,
      english: english,
      russian: russian,
      level: level,
      isLearned: isLearned ?? this.isLearned,
      isLearning: isLearning ?? this.isLearning,
    );
  }

}