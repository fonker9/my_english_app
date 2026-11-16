import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:my_english_app/core/srs/srs_engine.dart';
import 'package:my_english_app/data/models/user_settings.dart';
import 'package:my_english_app/data/models/user_stats.dart';
import 'package:my_english_app/data/models/word.dart';
import 'package:my_english_app/data/models/word_progress.dart';
import 'package:my_english_app/data/repositories/settings_repository.dart';
import 'package:my_english_app/data/repositories/words_repository.dart';
import 'package:my_english_app/data/sources/asset/asset_words_source.dart';
import 'package:my_english_app/data/sources/local/hive_progress_source.dart';
import 'package:my_english_app/data/sources/local/hive_settings_source.dart';

class _TestAssetBundle extends CachingAssetBundle {
  final String jsonPayload;

  _TestAssetBundle(this.jsonPayload);

  @override
  Future<ByteData> load(String key) async {
    final bytes = Uint8List.fromList(utf8.encode(jsonPayload));
    return ByteData.view(bytes.buffer);
  }
}

void main() {
  group('SrsEngine', () {
    test('вычисляет интервалы 1 -> 2 -> 4 -> 8 -> 16 -> mastered (-1)', () {
      expect(SrsEngine.nextIntervalDays(0), 1);
      expect(SrsEngine.nextIntervalDays(1), 2);
      expect(SrsEngine.nextIntervalDays(2), 4);
      expect(SrsEngine.nextIntervalDays(3), 8);
      expect(SrsEngine.nextIntervalDays(4), 16);
      expect(SrsEngine.nextIntervalDays(5), -1);
      expect(SrsEngine.nextIntervalDays(10), -1);
    });

    test('processAnswer обновляет прогресс при серии верных ответов и ошибке', () {
      var progress = const WordProgress(wordId: 1, status: WordStatus.learning);

      // 1-й..4-й правильные ответы -> статус review, nextReview != null
      for (var step = 1; step <= 4; step++) {
        progress = SrsEngine.processAnswer(current: progress, isCorrect: true);
        expect(progress.consecutiveCorrect, step);
        expect(progress.totalCorrect, step);
        expect(progress.status, WordStatus.review);
        expect(progress.nextReview, isNotNull);
        expect(progress.isSynced, isFalse);
      }

      // 5-й правильный ответ -> mastered, nextReview сброшен в null
      progress = SrsEngine.processAnswer(current: progress, isCorrect: true);
      expect(progress.consecutiveCorrect, 5);
      expect(progress.totalCorrect, 5);
      expect(progress.status, WordStatus.mastered);
      expect(progress.nextReview, isNull);

      // Ошибка -> сброс серии и возврат в learning
      progress = SrsEngine.processAnswer(current: progress, isCorrect: false);
      expect(progress.consecutiveCorrect, 0);
      expect(progress.totalWrong, 1);
      expect(progress.status, WordStatus.learning);
      expect(progress.nextReview, isNotNull);
    });
  });

  group('Word.fromJson и WordsRepositoryImpl', () {
    test('Word.fromJson корректно парсит минимальный и полный JSON', () {
      final minimal = Word.fromJson(const {
        'id': 1,
        'en': 'apple',
        'ru': 'яблоко',
        'level': 'a1',
      });
      expect(minimal.id, 1);
      expect(minimal.en, 'apple');
      expect(minimal.ru, 'яблоко');
      expect(minimal.level, 'a1');
      expect(minimal.topic, 'general');
      expect(minimal.partOfSpeech, '');
      expect(minimal.transcription, '');
      expect(minimal.example, isNull);

      final full = Word.fromJson(const {
        'id': 2,
        'en': 'journey',
        'ru': 'путешествие',
        'level': 'b1',
        'topic': 'travel',
        'partOfSpeech': 'noun',
        'transcription': '/ˈdʒɜː.ni/',
        'example': 'Have a safe journey.',
        'exampleRu': 'Счастливого пути.',
      });
      expect(full.topic, 'travel');
      expect(full.partOfSpeech, 'noun');
      expect(full.transcription, '/ˈdʒɜː.ni/');
      expect(full.example, 'Have a safe journey.');
      expect(full.exampleRu, 'Счастливого пути.');
    });

    test('WordsRepositoryImpl кэширует слова и фильтрует по уровню и теме', () async {
      final bundle = _TestAssetBundle(
        jsonEncode([
          {'id': 1, 'en': 'apple', 'ru': 'яблоко', 'level': 'a1', 'topic': 'food'},
          {'id': 2, 'en': 'book', 'ru': 'книга', 'level': 'a1', 'topic': 'education'},
          {'id': 3, 'en': 'challenge', 'ru': 'вызов', 'level': 'b2', 'topic': 'work'},
        ]),
      );

      final repo = WordsRepositoryImpl(AssetWordsSource(bundle: bundle));
      final allWords = await repo.getAllWords();

      expect(allWords.length, 3);
      expect(repo.getFilteredWords(level: 'A1').length, 2);
      expect(repo.getFilteredWords(level: 'a1', topic: 'food').single.en, 'apple');
      expect(repo.getAvailableTopics(), ['food', 'education', 'work']);
    });
  });

  group('Hive адаптеры и локальные репозитории', () {
    late Directory tempDir;

    setUpAll(() async {
      tempDir = await Directory.systemTemp.createTemp('my_english_app_hive_');
      Hive.init(tempDir.path);
      if (!Hive.isAdapterRegistered(0)) {
        Hive.registerAdapter(WordProgressAdapter());
      }
      if (!Hive.isAdapterRegistered(1)) {
        Hive.registerAdapter(UserStatsAdapter());
      }
      if (!Hive.isAdapterRegistered(2)) {
        Hive.registerAdapter(UserSettingsAdapter());
      }
    });

    tearDownAll(() async {
      await Hive.close();
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('WordProgressAdapter, UserStatsAdapter и UserSettingsAdapter сохраняют и читают данные', () async {
      final progressBox = await Hive.openBox<WordProgress>('test_progress');
      final statsBox = await Hive.openBox<UserStats>('test_stats');
      final settingsBox = await Hive.openBox<UserSettings>('test_settings');

      final now = DateTime(2026, 11, 16, 12, 30);
      final progressSource = HiveProgressSource(
        progressBox: progressBox,
        statsBox: statsBox,
      );
      final settingsRepo = SettingsRepositoryImpl(
        HiveSettingsSource(box: settingsBox),
      );

      final originalProgress = WordProgress(
        wordId: 42,
        status: WordStatus.review,
        consecutiveCorrect: 3,
        totalCorrect: 4,
        totalWrong: 1,
        lastReviewed: now,
        nextReview: now.add(const Duration(days: 8)),
        firstSeen: now.subtract(const Duration(days: 5)),
        isSynced: true,
      );
      final originalStats = UserStats(
        currentStreak: 5,
        longestStreak: 12,
        lastStudyDate: now,
        todayNewWords: 4,
        todayReviews: 9,
        totalWordsLearned: 31,
        totalQuizCorrect: 80,
        totalQuizWrong: 7,
      );
      const originalSettings = UserSettings(
        dailyNewWordsGoal: 15,
        notificationTime: TimeOfDay(hour: 20, minute: 45),
        notificationsEnabled: true,
      );

      await progressSource.putWordProgress('user_1', originalProgress);
      await progressSource.putStats('user_1', originalStats);
      await settingsRepo.saveSettings(originalSettings);

      // Закрываем и переоткрываем боксы для проверки реальной сериализации на диск
      await progressBox.close();
      await statsBox.close();
      await settingsBox.close();

      final reopenedProgressBox = await Hive.openBox<WordProgress>('test_progress');
      final reopenedStatsBox = await Hive.openBox<UserStats>('test_stats');
      final reopenedSettingsBox = await Hive.openBox<UserSettings>('test_settings');

      final reopenedProgressSource = HiveProgressSource(
        progressBox: reopenedProgressBox,
        statsBox: reopenedStatsBox,
      );
      final reopenedSettingsRepo = SettingsRepositoryImpl(
        HiveSettingsSource(box: reopenedSettingsBox),
      );

      expect(reopenedProgressSource.getWordProgress('user_1', 42), originalProgress);
      expect(reopenedProgressSource.getStats('user_1'), originalStats);
      expect(await reopenedSettingsRepo.loadSettings(), originalSettings);
    });
  });
}
