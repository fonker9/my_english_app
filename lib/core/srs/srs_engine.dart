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
}
