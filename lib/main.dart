import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:my_english_app/app/app.dart';
import 'package:my_english_app/core/di/service_locator.dart';
import 'package:my_english_app/data/models/user_settings.dart';
import 'package:my_english_app/data/models/user_stats.dart';
import 'package:my_english_app/data/models/word_progress.dart';
import 'package:my_english_app/data/sources/local/hive_progress_source.dart';
import 'package:my_english_app/data/sources/local/hive_settings_source.dart';
import 'package:my_english_app/features/notifications/notification_service.dart';
import 'package:my_english_app/firebase_options.dart';

void main() async {
  // Гарантируем готовность связей Flutter до запуска асинхронной инициализации.
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 2. Hive: регистрация адаптеров и открытие боксов
  await Hive.initFlutter();
  Hive.registerAdapter(WordProgressAdapter());
  Hive.registerAdapter(UserStatsAdapter());
  Hive.registerAdapter(UserSettingsAdapter());
  await Hive.openBox<WordProgress>(HiveProgressSource.wordProgressBoxName);
  await Hive.openBox<UserStats>(HiveProgressSource.userStatsBoxName);
  await Hive.openBox<UserSettings>(HiveSettingsSource.userSettingsBoxName);

  // 3. DI (GetIt)
  await initDependencies();

  // 4. Notifications
  await sl<NotificationService>().init();

  runApp(const MyApp());
}
