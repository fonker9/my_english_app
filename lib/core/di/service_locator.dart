import 'package:get_it/get_it.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/progress_repository.dart';
import '../../data/repositories/settings_repository.dart';
import '../../data/repositories/words_repository.dart';
import '../../data/sources/asset/asset_words_source.dart';
import '../../data/sources/local/hive_progress_source.dart';
import '../../data/sources/local/hive_settings_source.dart';
import '../../data/sources/remote/firebase_auth_source.dart';
import '../../data/sources/remote/firestore_progress_source.dart';
import '../../features/auth/cubit/auth_cubit.dart';
import '../../features/dictionary/cubit/dictionary_cubit.dart';
import '../../features/learning/cubit/learning_cubit.dart';
import '../../features/learning/data/words_repository.dart' as legacy_words;
import '../../features/progress/data/progress_repository.dart'
    as legacy_progress;

/// Глобальный экземпляр Service Locator.
final sl = GetIt.instance;

/// Регистрирует источники данных, репозитории и кубиты приложения.
Future<void> initDependencies() async {
  // --- Data Sources ---
  sl.registerLazySingleton(() => AssetWordsSource());
  sl.registerLazySingleton(() => HiveProgressSource());
  sl.registerLazySingleton(() => HiveSettingsSource());
  sl.registerLazySingleton(() => FirestoreProgressSource());
  sl.registerLazySingleton(() => FirebaseAuthSource());

  // --- Repositories (новая архитектура) ---
  sl.registerLazySingleton<WordsRepository>(
    () => WordsRepositoryImpl(sl<AssetWordsSource>()),
  );
  sl.registerLazySingleton<ProgressRepository>(
    () => ProgressRepositoryImpl(
      sl<HiveProgressSource>(),
      sl<FirestoreProgressSource>(),
    ),
  );
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(sl<FirebaseAuthSource>()),
  );
  sl.registerLazySingleton<SettingsRepository>(
    () => SettingsRepositoryImpl(sl<HiveSettingsSource>()),
  );

  // --- Временные зависимости для существующих Cubit до Фазы 2 ---
  sl.registerLazySingleton<legacy_words.WordsRepository>(
    () => legacy_words.LocalWordsRepository(),
  );
  sl.registerLazySingleton<legacy_progress.ProgressRepository>(
    () => legacy_progress.ProgressRepository(),
  );

  // --- Cubits ---
  sl.registerFactory(() => AuthCubit());
  sl.registerFactory(
    () => LearningCubit(
      sl<legacy_words.WordsRepository>(),
      sl<legacy_progress.ProgressRepository>(),
    ),
  );
  sl.registerFactory(
    () => DictionaryCubit(
      sl<legacy_words.WordsRepository>(),
      sl<legacy_progress.ProgressRepository>(),
    ),
  );
}
