/// Утилита для склонения русских существительных после числительных.
class RussianPlurals {
  RussianPlurals._();

  /// Выбирает форму слова в зависимости от числа [count] («1 слово / 2 слова / 5 слов»).
  static String pluralize(int count, String one, String few, String many) {
    final absCount = count.abs();
    final mod100 = absCount % 100;
    final mod10 = absCount % 10;

    if (mod100 >= 11 && mod100 <= 19) {
      return many;
    }
    if (mod10 == 1) {
      return one;
    }
    if (mod10 >= 2 && mod10 <= 4) {
      return few;
    }
    return many;
  }

  /// Возвращает строку вида «5 слов».
  static String wordsWithCount(int count) {
    return '$count ${pluralize(count, 'слово', 'слова', 'слов')}';
  }

  /// Возвращает строку вида «3 дня».
  static String daysWithCount(int count) {
    return '$count ${pluralize(count, 'день', 'дня', 'дней')}';
  }
}
