import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_english_app/features/auth/cubit/auth_cubit.dart';
import 'package:my_english_app/features/auth/ui/login_screen.dart';
import 'package:my_english_app/firebase_options.dart';
import 'features/main_tabs_screen.dart';
import 'features/learning/data/words_repository.dart';
import 'features/learning/cubit/learning_cubit.dart';
import 'features/dictionary/cubit/dictionary_cubit.dart';
import 'features/auth/ui/login_screen.dart';

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

    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthCubit>(
          create: (context) => AuthCubit()..checkAuth(),
        ),
        BlocProvider<LearningCubit>(
          create: (context) => LearningCubit(wordsRepository)..loadWords(),
        ),
        BlocProvider<DictionaryCubit>(
          create: (context) => DictionaryCubit(wordsRepository)..loadWords(),
        ),
      ],
      child: MaterialApp(
        title: 'My English App',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
        ),
        home: const LoginScreen(),
      ),
    );
  }
}