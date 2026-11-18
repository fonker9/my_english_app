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
import '../../features/learning/cubit/quiz_cubit.dart';
import '../../features/learning/cubit/swipe_cubit.dart';
import '../../features/learning/cubit/writing_cubit.dart';
import '../../features/notifications/notification_service.dart';
import '../../features/profile/cubit/profile_cubit.dart';
import '../sync/sync_service.dart';

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

  // --- Repositories ---
  sl.registerLazySingleton<WordsRepository>(
    () => WordsRepositoryImpl(sl<AssetWordsSource>()),
  );
  sl.registerLazySingleton<ProgressRepository>(
    () => ProgressRepositoryImpl(
      sl<HiveProgressSource>(),
      sl<FirestoreProgressSource>(),
      sl<SyncService>(),
    ),
  );
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(sl<FirebaseAuthSource>()),
  );
  sl.registerLazySingleton<SettingsRepository>(
    () => SettingsRepositoryImpl(sl<HiveSettingsSource>()),
  );

  // --- Services ---
  sl.registerLazySingleton(
    () => SyncService(
      sl<HiveProgressSource>(),
      sl<FirestoreProgressSource>(),
    ),
  );
  sl.registerLazySingleton(() => NotificationService());

  // --- Cubits ---
  sl.registerFactory(() => AuthCubit(sl<AuthRepository>()));
  sl.registerFactory(
    () => SwipeCubit(
      sl<WordsRepository>(),
      sl<ProgressRepository>(),
      sl<SettingsRepository>(),
    ),
  );
  sl.registerFactory(
    () => QuizCubit(
      sl<WordsRepository>(),
      sl<ProgressRepository>(),
    ),
  );
  sl.registerFactory(
    () => WritingCubit(
      sl<WordsRepository>(),
      sl<ProgressRepository>(),
    ),
  );
  sl.registerFactory(
    () => DictionaryCubit(
      sl<WordsRepository>(),
      sl<ProgressRepository>(),
    ),
  );
  sl.registerFactory(
    () => ProfileCubit(
      sl<ProgressRepository>(),
      sl<AuthRepository>(),
    ),
  );
}
