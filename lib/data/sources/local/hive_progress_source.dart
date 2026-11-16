import 'package:hive/hive.dart';
import '../../models/user_stats.dart';
import '../../models/word_progress.dart';

/// Локальный источник данных (Hive) для прогресса слов и статистики пользователя.
class HiveProgressSource {
  static const String wordProgressBoxName = 'word_progress';
  static const String userStatsBoxName = 'user_stats';

  final Box<WordProgress>? _customProgressBox;
  final Box<UserStats>? _customStatsBox;

  HiveProgressSource({
    Box<WordProgress>? progressBox,
    Box<UserStats>? statsBox,
  })  : _customProgressBox = progressBox,
        _customStatsBox = statsBox;

  Box<WordProgress> get _progressBox =>
      _customProgressBox ?? Hive.box<WordProgress>(wordProgressBoxName);

  Box<UserStats> get _statsBox =>
      _customStatsBox ?? Hive.box<UserStats>(userStatsBoxName);

  String _wordKey(String uid, int wordId) => '${uid}_$wordId';

  /// Возвращает весь локальный прогресс по словам для пользователя [uid].
  Map<int, WordProgress> getAllProgress(String uid) {
    final prefix = '${uid}_';
    final result = <int, WordProgress>{};

    for (final key in _progressBox.keys) {
      if (key is String && key.startsWith(prefix)) {
        final item = _progressBox.get(key);
        if (item != null) {
          result[item.wordId] = item;
        }
      }
    }

    return result;
  }

  /// Возвращает прогресс по конкретному слову [wordId] или `null`.
  WordProgress? getWordProgress(String uid, int wordId) {
    return _progressBox.get(_wordKey(uid, wordId));
  }

  /// Сохраняет или обновляет прогресс по одному слову в Hive.
  Future<void> putWordProgress(String uid, WordProgress progress) async {
    await _progressBox.put(_wordKey(uid, progress.wordId), progress);
  }

  /// Массово сохраняет прогресс по словам в Hive.
  Future<void> putAllProgress(
    String uid,
    Map<int, WordProgress> progressMap,
  ) async {
    final entries = <String, WordProgress>{
      for (final entry in progressMap.entries)
        _wordKey(uid, entry.key): entry.value,
    };
    await _progressBox.putAll(entries);
  }

  /// Возвращает список записей прогресса, ещё не синхронизированных с Firestore.
  List<WordProgress> getUnsyncedProgress(String uid) {
    return getAllProgress(uid)
        .values
        .where((progress) => !progress.isSynced)
        .toList();
  }

  /// Загружает статистику пользователя [uid] из Hive.
  UserStats getStats(String uid) {
    return _statsBox.get(uid) ?? UserStats.empty();
  }

  /// Сохраняет статистику пользователя [uid] в Hive.
  Future<void> putStats(String uid, UserStats stats) async {
    await _statsBox.put(uid, stats);
  }
}
