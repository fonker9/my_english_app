class ProgressModel {
  final List<int> learnedWords;
  final List<int> learningWords;

  const ProgressModel({
    required this.learnedWords,
    required this.learningWords,
  });

  factory ProgressModel.empty() {
    return const ProgressModel(
      learnedWords: [],
      learningWords: [],
    );
  }

  factory ProgressModel.fromFirestore(
    Map<String, dynamic>? data,
  ) {
    if (data == null) {
      return ProgressModel.empty();
    }

    return ProgressModel(
      learnedWords: List<int>.from(data['learnedWords'] ?? []),
      learningWords: List<int>.from(data['learningWords'] ?? []),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'learnedWords': learnedWords,
      'learningWords': learningWords,
      'updatedAt': DateTime.now(),
    };
  }

  ProgressModel copyWith({
    List<int>? learnedWords,
    List<int>? learningWords,
  }) {
    return ProgressModel(
      learnedWords: learnedWords ?? this.learnedWords,
      learningWords: learningWords ?? this.learningWords,
    );
  }
}