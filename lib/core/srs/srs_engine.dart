import '../../data/models/user_stats.dart';
import '../../data/models/word_progress.dart';

/// Движок интервального повторения (Spaced Repetition System).
class SrsEngine {
  SrsEngine._();

  /// Вычисляет следующий интервал повторения.
  ///
  /// [consecutiveCorrect] — серия правильных ответов подряд.
  /// Возвращает количество дней до следующего повторения или `-1` для `mastered`.
  static int nextIntervalDays(int consecutiveCorrect) {
    // 1 → 2 → 4 → 8 → 16 → mastered
    const intervals = [1, 2, 4, 8, 16];
    if (consecutiveCorrect >= intervals.length) return -1; // mastered
    return intervals[consecutiveCorrect];
  }

  /// Обрабатывает ответ пользователя и возвращает обновлённый прогресс.
  static WordProgress processAnswer({
    required WordProgress current,
    required bool isCorrect,
  }) {
    final now = DateTime.now();

    if (isCorrect) {
      final newConsecutive = current.consecutiveCorrect + 1;
      final intervalDays = nextIntervalDays(newConsecutive);

      return current.copyWith(
        consecutiveCorrect: newConsecutive,
        totalCorrect: current.totalCorrect + 1,
        lastReviewed: now,
        nextReview: intervalDays == -1
            ? null // mastered — больше не повторять
            : now.add(Duration(days: intervalDays)),
        status:
            intervalDays == -1 ? WordStatus.mastered : WordStatus.review,
        isSynced: false,
      );
    } else {
      return current.copyWith(
        consecutiveCorrect: 0, // сброс серии
        totalWrong: current.totalWrong + 1,
        lastReviewed: now,
        nextReview: now.add(const Duration(days: 1)),
        status: WordStatus.learning,
        isSynced: false,
      );
    }
  }

  /// Сбрасывает дневные счётчики статистики, если [stats.lastStudyDate] относится
  /// к предыдущему дню относительно [now].
  static UserStats resetDailyCountersIfNeeded(UserStats stats, [DateTime? now]) {
    final reference = now ?? DateTime.now();
    if (stats.lastStudyDate != null &&
        !isSameDay(stats.lastStudyDate!, reference) &&
        (stats.todayNewWords != 0 || stats.todayReviews != 0)) {
      return stats.copyWith(todayNewWords: 0, todayReviews: 0);
    }
    return stats;
  }

  /// Обновляет серию дней (streak) и дату последнего занятия в [stats].
  static UserStats markStudyActivity(UserStats stats, [DateTime? now]) {
    final reference = now ?? DateTime.now();
    final lastDate = stats.lastStudyDate;
    int newStreak;

    if (lastDate != null && isSameDay(lastDate, reference)) {
      newStreak = stats.currentStreak > 0 ? stats.currentStreak : 1;
    } else if (lastDate != null && _isYesterday(lastDate, reference)) {
      newStreak = stats.currentStreak + 1;
    } else {
      newStreak = 1;
    }

    final newLongest =
        newStreak > stats.longestStreak ? newStreak : stats.longestStreak;

    return stats.copyWith(
      currentStreak: newStreak,
      longestStreak: newLongest,
      lastStudyDate: reference,
    );
  }

  /// Проверяет, относятся ли две даты к одному календарному дню.
  static bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  static bool _isYesterday(DateTime date, DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    return today.difference(target).inDays == 1;
  }
}
