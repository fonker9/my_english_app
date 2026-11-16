import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_english_app/app/theme/app_colors.dart';
import 'package:my_english_app/core/di/service_locator.dart';
import 'package:my_english_app/features/auth/cubit/auth_cubit.dart';
import 'package:my_english_app/features/auth/cubit/auth_state.dart';
import 'package:my_english_app/features/auth/ui/login_screen.dart';
import 'package:my_english_app/features/dictionary/cubit/dictionary_cubit.dart';
import 'package:my_english_app/features/learning/cubit/learning_cubit.dart';
import 'package:my_english_app/features/main_tabs_screen.dart';

/// Корневой виджет приложения.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthCubit>(
          create: (_) => sl<AuthCubit>()..checkAuth(),
        ),
        BlocProvider<LearningCubit>(
          create: (_) => sl<LearningCubit>()..loadWords(),
        ),
        BlocProvider<DictionaryCubit>(
          create: (_) => sl<DictionaryCubit>()..loadWords(),
        ),
      ],
      child: MaterialApp(
        title: 'My English App',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          scaffoldBackgroundColor: AppColors.background,
          colorScheme: ColorScheme.fromSeed(
            seedColor: AppColors.primary,
          ),
        ),
        home: BlocBuilder<AuthCubit, AuthState>(
          builder: (context, state) {
            if (state is AuthSuccess) {
              // Если Firebase вернул активного пользователя — пускаем в приложение
              return const MainTabsScreen();
            }

            if (state is AuthLoading) {
              // Пока Firebase проверяет токен, показываем спиннер
              return const Scaffold(
                backgroundColor: AppColors.background,
                body: Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primary,
                  ),
                ),
              );
            }

            // Если пользователь не авторизован — показываем экран входа
            return const LoginScreen();
          },
        ),
      ),
    );
  }
}
