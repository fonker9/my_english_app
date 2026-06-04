import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_english_app/features/auth/cubit/auth_cubit.dart';
import 'package:my_english_app/features/auth/cubit/auth_state.dart';
import 'package:my_english_app/features/auth/ui/login_screen.dart';
import 'package:my_english_app/features/main_tabs_screen.dart';
import 'package:my_english_app/firebase_options.dart';
import 'features/learning/data/words_repository.dart';
import 'features/learning/cubit/learning_cubit.dart';
import 'features/dictionary/cubit/dictionary_cubit.dart';
import 'features/progress/data/progress_repository.dart';

void main() async {
  // Гарантируем, что внутренние связи Flutter с нативной платформой (Android/iOS)
  // готовы к выполнению асинхронных команд до запуска runApp.
  WidgetsFlutterBinding.ensureInitialized();

  // Инициализируем firebase, передавая сгенерированные FlutterFire CLI настройки
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final wordsRepository = LocalWordsRepository();
    final progressRepository = ProgressRepository();

    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthCubit>(
          create: (context) => AuthCubit()..checkAuth(),
        ),
        BlocProvider<LearningCubit>(
          create: (context) =>
            LearningCubit(
              wordsRepository,
              progressRepository,
            )..loadWords(),
        ),
        BlocProvider<DictionaryCubit>(
          create: (context) => DictionaryCubit(
            wordsRepository,
            ProgressRepository(),
          )..loadWords(),
        ),
      ],
      child: MaterialApp(
        title: 'My English App',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
        ),
        // home: const LoginScreen(),
        home: BlocBuilder<AuthCubit, AuthState>(
          builder: (context, state) {
            if (state is AuthSuccess) {
              // Если Firebase вернул активного пользователя — пускаем в приложение
              return const MainTabsScreen();
            }
            
            if (state is AuthLoading) {
              // Пока Firebase проверяет токен, показываем спиннер
              return const Scaffold(
                body: Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFFA43032),
                  ),
                ),
              );
            }

            // Если пользователь не авторизован (AuthInitial или AuthFailure) — показываем вход
            return const LoginScreen();
          },
        ),
      ),
    );
  }
}