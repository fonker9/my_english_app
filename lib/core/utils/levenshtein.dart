import 'dart:math';

/// Вычисляет редакционное расстояние Левенштейна между строками [s1] и [s2]
/// без учёта регистра и пробелов по краям.
int levenshteinDistance(String s1, String s2) {
  final a = s1.trim().toLowerCase();
  final b = s2.trim().toLowerCase();

  if (a.isEmpty) return b.length;
  if (b.isEmpty) return a.length;

  var previous = List<int>.generate(b.length + 1, (j) => j);
  var current = List<int>.filled(b.length + 1, 0);

  for (var i = 1; i <= a.length; i++) {
    current[0] = i;
    for (var j = 1; j <= b.length; j++) {
      final cost = a[i - 1] == b[j - 1] ? 0 : 1;
      current[j] = min(
        min(current[j - 1] + 1, previous[j] + 1),
        previous[j - 1] + cost,
      );
    }
    final temp = previous;
    previous = current;
    current = temp;
  }

  return previous[b.length];
}

/// Проверяет, принимается ли ввод [userInput] для целевого слова [targetWord]
/// с допустимым числом опечаток [maxDistance].
/// По умолчанию для коротких слов (<= 2 символов) требуется точное совпадение,
/// а для остальных допускается не более 1 опечатки.
bool isAnswerAccepted(
  String userInput,
  String targetWord, {
  int? maxDistance,
}) {
  final normalizedInput = userInput.trim();
  if (normalizedInput.isEmpty) return false;

  final normalizedTarget = targetWord.trim();
  final effectiveMaxDistance =
      maxDistance ?? (normalizedTarget.length <= 2 ? 0 : 1);

  return levenshteinDistance(normalizedInput, normalizedTarget) <=
      effectiveMaxDistance;
}
