import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:my_english_app/core/srs/srs_engine.dart';
import 'package:my_english_app/core/utils/russian_plurals.dart';
import 'package:my_english_app/data/models/user_settings.dart';
import 'package:my_english_app/data/models/user_stats.dart';
import 'package:my_english_app/data/models/word.dart';
import 'package:my_english_app/data/models/word_progress.dart';
import 'package:my_english_app/data/repositories/auth_repository.dart';
import 'package:my_english_app/data/repositories/progress_repository.dart';
import 'package:my_english_app/data/repositories/settings_repository.dart';
import 'package:my_english_app/data/repositories/words_repository.dart';
import 'package:my_english_app/data/sources/asset/asset_words_source.dart';
import 'package:my_english_app/data/sources/local/hive_progress_source.dart';
import 'package:my_english_app/data/sources/local/hive_settings_source.dart';
import 'package:my_english_app/features/auth/cubit/auth_cubit.dart';
import 'package:my_english_app/features/auth/cubit/auth_state.dart';
import 'package:my_english_app/features/dictionary/cubit/dictionary_cubit.dart';
import 'package:my_english_app/features/dictionary/cubit/dictionary_state.dart';
import 'package:my_english_app/features/learning/cubit/quiz_cubit.dart';
import 'package:my_english_app/features/learning/cubit/quiz_state.dart';
import 'package:my_english_app/features/learning/cubit/swipe_cubit.dart';
import 'package:my_english_app/features/learning/cubit/swipe_state.dart';
import 'package:my_english_app/features/profile/cubit/profile_cubit.dart';
import 'package:my_english_app/features/profile/cubit/profile_state.dart';

class _TestAssetBundle extends CachingAssetBundle {
  final String jsonPayload;

  _TestAssetBundle(this.jsonPayload);

  @override
  Future<ByteData> load(String key) async {
    final bytes = Uint8List.fromList(utf8.encode(jsonPayload));
    return ByteData.view(bytes.buffer);
  }
}

class _FakeAuthRepository implements AuthRepository {
  @override
  final String? currentUid;

  @override
  final String? currentDisplayName;

  @override
  final String? currentEmail;

  _FakeAuthRepository({
    this.currentUid = 'user_1',
    this.currentDisplayName = 'Алексей',
    this.currentEmail = 'alex@example.com',
  });

  @override
  Stream<String?> authStateChanges() => Stream.value(currentUid);

  @override
  Future<String> signIn(String email, String password) async =>
      currentUid ?? 'user_1';

  @override
  Future<void> signOut() async {}

  @override
  Future<String> signUp(String email, String password, String nickname) async =>
      currentUid ?? 'user_1';
}

class _FakeWordsRepository implements WordsRepository {
  final List<Word> words;

  _FakeWordsRepository(this.words);

  @override
  Future<List<Word>> getAllWords() async => words;

  @override
  List<String> getAvailableTopics() =>
      words.map((w) => w.topic).toSet().toList();

  @override
  List<Word> getFilteredWords({String? level, String? topic}) {
    return words.where((w) {
      final matchesLevel =
          level == null || w.level.toLowerCase() == level.toLowerCase();
      final matchesTopic =
          topic == null || w.topic.toLowerCase() == topic.toLowerCase();
      return matchesLevel && matchesTopic;
    }).toList();
  }
}

class _FakeProgressRepository implements ProgressRepository {
  final Map<int, WordProgress> progressMap;
  UserStats stats;

  _FakeProgressRepository({
    Map<int, WordProgress>? progressMap,
    UserStats? stats,
  })  : progressMap = progressMap ?? {},
        stats = stats ?? UserStats.empty();

  @override
  Future<List<int>> getWordsDueForReview(String uid) async => [];

  @override
  Future<Map<int, WordProgress>> loadAllProgress(String uid) async =>
      progressMap;

  @override
  Future<UserStats> loadStats(String uid) async => stats;

  @override
  Future<void> syncWithCloud(String uid) async {}

  @override
  Future<void> updateStats(String uid, UserStats stats) async {
    this.stats = stats;
  }

  @override
  Future<void> updateWordProgress(String uid, WordProgress progress) async {
    progressMap[progress.wordId] = progress;
  }
}

class _FakeSettingsRepository implements SettingsRepository {
  UserSettings settings;

  _FakeSettingsRepository(this.settings);

  @override
  Future<UserSettings> loadSettings() async => settings;

  @override
  Future<void> saveSettings(UserSettings settings) async {
    this.settings = settings;
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

  group('Кубиты Фазы 2 (SwipeCubit, DictionaryCubit, ProfileCubit)', () {
    const sampleWords = [
      Word(id: 1, en: 'apple', ru: 'яблоко', level: 'a1', topic: 'food'),
      Word(id: 2, en: 'book', ru: 'книга', level: 'a1', topic: 'education'),
      Word(id: 3, en: 'journey', ru: 'путешествие', level: 'b1', topic: 'travel'),
    ];

    test('SwipeCubit загружает unseen слова, обновляет прогресс и достигает цели', () async {
      final progressRepo = _FakeProgressRepository(
        progressMap: {
          3: const WordProgress(wordId: 3, status: WordStatus.learning),
        },
        stats: UserStats(
          todayNewWords: 0,
          lastStudyDate: DateTime.now(),
        ),
      );
      final cubit = SwipeCubit(
        _FakeWordsRepository(sampleWords),
        progressRepo,
        _FakeSettingsRepository(const UserSettings(dailyNewWordsGoal: 1)),
        _FakeAuthRepository(),
      );

      await cubit.loadWords();

      expect(cubit.state, isA<SwipeLoaded>());
      final loaded = cubit.state as SwipeLoaded;
      expect(loaded.words.map((w) => w.id).toList(), [1, 2]);
      expect(loaded.dailyGoal, 1);

      // Свайп влево («Знаю») переводит слово 1 в mastered
      cubit.knowWord();
      expect(progressRepo.progressMap[1]?.status, WordStatus.mastered);
      expect(progressRepo.stats.totalWordsLearned, 1);

      // Свайп вправо («Учу») переводит слово 2 в learning и завершает цель на сегодня
      cubit.notKnowWord();
      expect(progressRepo.progressMap[2]?.status, WordStatus.learning);
      expect(progressRepo.progressMap[2]?.nextReview, isNotNull);
      expect(cubit.state, const SwipeFinished(learnedCount: 1, dailyGoal: 1));

      await cubit.close();
    });

    test('DictionaryCubit фильтрует слова по 3 секциям, уровню, теме и поиску', () async {
      final progressRepo = _FakeProgressRepository(
        progressMap: {
          2: const WordProgress(wordId: 2, status: WordStatus.review),
          3: const WordProgress(wordId: 3, status: WordStatus.mastered),
        },
      );
      final cubit = DictionaryCubit(
        _FakeWordsRepository(sampleWords),
        progressRepo,
        _FakeAuthRepository(),
      );

      await cubit.loadWords();
      expect(cubit.state, isA<DictionaryLoaded>());

      cubit.selectLevel('A1');
      var loaded = cubit.state as DictionaryLoaded;
      expect(loaded.newWordsFiltered.map((w) => w.id), [1]);
      expect(loaded.learningWordsFiltered.map((w) => w.id), [2]);
      expect(loaded.masteredWordsFiltered, isEmpty);

      cubit.setFilterMode(DictionaryFilterMode.byTopic);
      cubit.selectTopic('travel');
      loaded = cubit.state as DictionaryLoaded;
      expect(loaded.filterMode, DictionaryFilterMode.byTopic);
      expect(loaded.masteredWordsFiltered.map((w) => w.id), [3]);

      cubit.searchWords('путеш');
      loaded = cubit.state as DictionaryLoaded;
      expect(loaded.masteredWordsFiltered.length, 1);

      await cubit.close();
    });

    test('ProfileCubit загружает данные профиля и рассчитывает точность квизов', () async {
      final progressRepo = _FakeProgressRepository(
        progressMap: {
          1: const WordProgress(wordId: 1, status: WordStatus.mastered),
          2: const WordProgress(wordId: 2, status: WordStatus.mastered),
        },
        stats: const UserStats(
          currentStreak: 4,
          longestStreak: 10,
          totalWordsLearned: 1,
          totalQuizCorrect: 15,
          totalQuizWrong: 5,
        ),
      );

      final cubit = ProfileCubit(
        progressRepo,
        _FakeAuthRepository(),
      );

      await cubit.loadProfile();
      expect(cubit.state, isA<ProfileLoaded>());

      final loaded = cubit.state as ProfileLoaded;
      expect(loaded.nickname, 'Алексей');
      expect(loaded.email, 'alex@example.com');
      expect(loaded.stats.totalWordsLearned, 2);
      expect(loaded.accuracyPercent, 75);

      await cubit.close();
    });

    test('AuthCubit проверяет сессию, выполняет вход, регистрацию и выход', () async {
      final guestAuth = AuthCubit(
        _FakeAuthRepository(
          currentUid: null,
          currentDisplayName: null,
          currentEmail: null,
        ),
      );
      guestAuth.checkAuth();
      expect(guestAuth.state, const AuthInitial());

      await guestAuth.signIn('test@mail.ru', '123456');
      expect(guestAuth.state, const AuthSuccess('user_1'));

      await guestAuth.signOut();
      expect(guestAuth.state, const AuthInitial());
      await guestAuth.close();

      final signedInAuth = AuthCubit(
        _FakeAuthRepository(
          currentUid: 'user_42',
          currentDisplayName: 'Мария',
          currentEmail: 'maria@mail.ru',
        ),
      );
      signedInAuth.checkAuth();
      expect(signedInAuth.state, const AuthSuccess('user_42'));
      await signedInAuth.close();
    });
  });

  group('Фаза 3 (RussianPlurals и QuizCubit)', () {
    test('RussianPlurals корректно склоняет слова и дни', () {
      expect(RussianPlurals.wordsWithCount(0), '0 слов');
      expect(RussianPlurals.wordsWithCount(1), '1 слово');
      expect(RussianPlurals.wordsWithCount(2), '2 слова');
      expect(RussianPlurals.wordsWithCount(5), '5 слов');
      expect(RussianPlurals.wordsWithCount(11), '11 слов');
      expect(RussianPlurals.wordsWithCount(21), '21 слово');
      expect(RussianPlurals.daysWithCount(1), '1 день');
      expect(RussianPlurals.daysWithCount(3), '3 дня');
      expect(RussianPlurals.daysWithCount(5), '5 дней');
    });

    test('QuizCubit эмитит QuizEmpty если нет слов для повторения', () async {
      final cubit = QuizCubit(
        _FakeWordsRepository(const [
          Word(id: 1, en: 'apple', ru: 'яблоко', level: 'a1'),
        ]),
        _FakeProgressRepository(),
        _FakeAuthRepository(),
      );

      await cubit.startQuiz();
      expect(cubit.state, const QuizEmpty());
      await cubit.close();
    });

    test('QuizCubit генерирует 4 уникальных варианта с добором и обновляет SRS', () async {
      const words = [
        Word(id: 1, en: 'apple', ru: 'яблоко', level: 'a1'),
        Word(id: 2, en: 'book', ru: 'книга', level: 'a1'),
        Word(id: 3, en: 'journey', ru: 'путешествие', level: 'b1'),
        Word(id: 4, en: 'knowledge', ru: 'знание', level: 'b2'),
        Word(id: 5, en: 'freedom', ru: 'свобода', level: 'b1'),
      ];

      final pastDate = DateTime.now().subtract(const Duration(hours: 2));
      final progressRepo = _FakeProgressRepository(
        progressMap: {
          1: const WordProgress(wordId: 1, status: WordStatus.learning),
          2: WordProgress(
            wordId: 2,
            status: WordStatus.review,
            consecutiveCorrect: 1,
            totalCorrect: 1,
            nextReview: pastDate,
          ),
        },
        stats: UserStats(lastStudyDate: DateTime.now()),
      );

      final cubit = QuizCubit(
        _FakeWordsRepository(words),
        progressRepo,
        _FakeAuthRepository(),
        Random(42),
      );

      await cubit.startQuiz();
      expect(cubit.state, isA<QuizLoaded>());

      var loaded = cubit.state as QuizLoaded;
      expect(loaded.questions.length, 2);
      for (final q in loaded.questions) {
        expect(q.options.length, 4);
        expect(q.options.toSet().length, 4);
        expect(q.options[q.correctIndex], q.correctAnswer);
      }

      // Первый вопрос: отвечаем правильно
      final firstQuestion = loaded.currentQuestion;
      cubit.selectAnswer(firstQuestion.correctIndex);
      loaded = cubit.state as QuizLoaded;
      expect(loaded.isAnswered, isTrue);
      expect(loaded.correctCount, 1);
      expect(
        progressRepo.progressMap[firstQuestion.word.id]?.status,
        WordStatus.review,
      );

      cubit.nextQuestion();
      loaded = cubit.state as QuizLoaded;
      expect(loaded.currentIndex, 1);
      expect(loaded.isAnswered, isFalse);

      // Второй вопрос: отвечаем неправильно
      final secondQuestion = loaded.currentQuestion;
      final wrongIndex = (secondQuestion.correctIndex + 1) % 4;
      cubit.selectAnswer(wrongIndex);
      loaded = cubit.state as QuizLoaded;
      expect(loaded.wrongCount, 1);
      expect(
        progressRepo.progressMap[secondQuestion.word.id]?.status,
        WordStatus.learning,
      );
      expect(
        progressRepo.progressMap[secondQuestion.word.id]?.consecutiveCorrect,
        0,
      );

      cubit.nextQuestion();
      expect(cubit.state, isA<QuizFinished>());
      final finished = cubit.state as QuizFinished;
      expect(finished.correctCount, 1);
      expect(finished.wrongCount, 1);
      expect(finished.accuracyPercent, 50);
      expect(finished.wrongWords, [secondQuestion.word]);
      expect(progressRepo.stats.todayReviews, 2);
      expect(progressRepo.stats.totalQuizCorrect, 1);
      expect(progressRepo.stats.totalQuizWrong, 1);

      await cubit.close();
    });
  });
}
