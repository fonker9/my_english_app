import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';

part 'word_progress.g.dart';

/// Статус изучения слова в системе интервального повторения (SRS).
enum WordStatus { unseen, learning, review, mastered }

/// Прогресс изучения конкретного слова пользователем (Hive + Firestore).
@HiveType(typeId: 0)
class WordProgress extends Equatable {
  static const Object _unset = Object();

  @HiveField(0)
  final int wordId;

  @HiveField(1)
  final WordStatus status;

  @HiveField(2)
  final int consecutiveCorrect;

  @HiveField(3)
  final int totalCorrect;

  @HiveField(4)
  final int totalWrong;

  @HiveField(5)
  final DateTime? lastReviewed;

  @HiveField(6)
  final DateTime? nextReview;

  @HiveField(7)
  final DateTime? firstSeen;

  @HiveField(8)
  final bool isSynced;

  const WordProgress({
    required this.wordId,
    this.status = WordStatus.unseen,
    this.consecutiveCorrect = 0,
    this.totalCorrect = 0,
    this.totalWrong = 0,
    this.lastReviewed,
    this.nextReview,
    this.firstSeen,
    this.isSynced = false,
  });

  /// Создаёт копию [WordProgress] с обновлёнными полями.
  /// Явная передача `null` для [lastReviewed], [nextReview] или [firstSeen]
  /// сбрасывает соответствующее поле в `null`.
  WordProgress copyWith({
    int? wordId,
    WordStatus? status,
    int? consecutiveCorrect,
    int? totalCorrect,
    int? totalWrong,
    Object? lastReviewed = _unset,
    Object? nextReview = _unset,
    Object? firstSeen = _unset,
    bool? isSynced,
  }) {
    return WordProgress(
      wordId: wordId ?? this.wordId,
      status: status ?? this.status,
      consecutiveCorrect: consecutiveCorrect ?? this.consecutiveCorrect,
      totalCorrect: totalCorrect ?? this.totalCorrect,
      totalWrong: totalWrong ?? this.totalWrong,
      lastReviewed: identical(lastReviewed, _unset)
          ? this.lastReviewed
          : lastReviewed as DateTime?,
      nextReview: identical(nextReview, _unset)
          ? this.nextReview
          : nextReview as DateTime?,
      firstSeen: identical(firstSeen, _unset)
          ? this.firstSeen
          : firstSeen as DateTime?,
      isSynced: isSynced ?? this.isSynced,
    );
  }

  /// Создаёт [WordProgress] из документа подколлекции Firestore `words/{wordId}`.
  factory WordProgress.fromFirestore(
    int wordId,
    Map<String, dynamic> data,
  ) {
    final statusName = data['status'] as String?;
    final parsedStatus = WordStatus.values.firstWhere(
      (s) => s.name == statusName,
      orElse: () => WordStatus.unseen,
    );

    return WordProgress(
      wordId: wordId,
      status: parsedStatus,
      consecutiveCorrect: (data['consecutiveCorrect'] as num?)?.toInt() ?? 0,
      totalCorrect: (data['totalCorrect'] as num?)?.toInt() ?? 0,
      totalWrong: (data['totalWrong'] as num?)?.toInt() ?? 0,
      lastReviewed: _parseDate(data['lastReviewed']),
      nextReview: _parseDate(data['nextReview']),
      firstSeen: _parseDate(data['firstSeen']),
      isSynced: true,
    );
  }

  /// Преобразует [WordProgress] в формат документа Firestore.
  Map<String, dynamic> toFirestore() {
    return {
      'status': status.name,
      'consecutiveCorrect': consecutiveCorrect,
      'totalCorrect': totalCorrect,
      'totalWrong': totalWrong,
      'lastReviewed':
          lastReviewed != null ? Timestamp.fromDate(lastReviewed!) : null,
      'nextReview': nextReview != null ? Timestamp.fromDate(nextReview!) : null,
      'firstSeen': firstSeen != null ? Timestamp.fromDate(firstSeen!) : null,
    };
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    return null;
  }

  @override
  List<Object?> get props => [
        wordId,
        status,
        consecutiveCorrect,
        totalCorrect,
        totalWrong,
        lastReviewed,
        nextReview,
        firstSeen,
        isSynced,
      ];
}
