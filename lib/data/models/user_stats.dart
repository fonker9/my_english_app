import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';

part 'user_stats.g.dart';

/// Статистика обучения пользователя (Hive + Firestore).
@HiveType(typeId: 1)
class UserStats extends Equatable {
  static const Object _unset = Object();

  @HiveField(0)
  final int currentStreak;

  @HiveField(1)
  final int longestStreak;

  @HiveField(2)
  final DateTime? lastStudyDate;

  @HiveField(3)
  final int todayNewWords;

  @HiveField(4)
  final int todayReviews;

  @HiveField(5)
  final int totalWordsLearned;

  @HiveField(6)
  final int totalQuizCorrect;

  @HiveField(7)
  final int totalQuizWrong;

  const UserStats({
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.lastStudyDate,
    this.todayNewWords = 0,
    this.todayReviews = 0,
    this.totalWordsLearned = 0,
    this.totalQuizCorrect = 0,
    this.totalQuizWrong = 0,
  });

  /// Пустая начальная статистика нового пользователя.
  factory UserStats.empty() => const UserStats();

  /// Создаёт копию [UserStats] с обновлёнными полями.
  UserStats copyWith({
    int? currentStreak,
    int? longestStreak,
    Object? lastStudyDate = _unset,
    int? todayNewWords,
    int? todayReviews,
    int? totalWordsLearned,
    int? totalQuizCorrect,
    int? totalQuizWrong,
  }) {
    return UserStats(
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      lastStudyDate: identical(lastStudyDate, _unset)
          ? this.lastStudyDate
          : lastStudyDate as DateTime?,
      todayNewWords: todayNewWords ?? this.todayNewWords,
      todayReviews: todayReviews ?? this.todayReviews,
      totalWordsLearned: totalWordsLearned ?? this.totalWordsLearned,
      totalQuizCorrect: totalQuizCorrect ?? this.totalQuizCorrect,
      totalQuizWrong: totalQuizWrong ?? this.totalQuizWrong,
    );
  }

  /// Создаёт [UserStats] из поля `stats` документа Firestore `users_progress/{uid}`.
  factory UserStats.fromFirestore(Map<String, dynamic>? data) {
    if (data == null) {
      return UserStats.empty();
    }

    return UserStats(
      currentStreak: (data['currentStreak'] as num?)?.toInt() ?? 0,
      longestStreak: (data['longestStreak'] as num?)?.toInt() ?? 0,
      lastStudyDate: _parseDate(data['lastStudyDate']),
      todayNewWords: (data['todayNewWords'] as num?)?.toInt() ?? 0,
      todayReviews: (data['todayReviews'] as num?)?.toInt() ?? 0,
      totalWordsLearned: (data['totalWordsLearned'] as num?)?.toInt() ?? 0,
      totalQuizCorrect: (data['totalQuizCorrect'] as num?)?.toInt() ?? 0,
      totalQuizWrong: (data['totalQuizWrong'] as num?)?.toInt() ?? 0,
    );
  }

  /// Преобразует [UserStats] в формат для сохранения в Firestore.
  Map<String, dynamic> toFirestore() {
    return {
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
      'lastStudyDate':
          lastStudyDate != null ? Timestamp.fromDate(lastStudyDate!) : null,
      'todayNewWords': todayNewWords,
      'todayReviews': todayReviews,
      'totalWordsLearned': totalWordsLearned,
      'totalQuizCorrect': totalQuizCorrect,
      'totalQuizWrong': totalQuizWrong,
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
        currentStreak,
        longestStreak,
        lastStudyDate,
        todayNewWords,
        todayReviews,
        totalWordsLearned,
        totalQuizCorrect,
        totalQuizWrong,
      ];
}
