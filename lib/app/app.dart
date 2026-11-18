import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:my_english_app/app/router.dart';
import 'package:my_english_app/app/theme/app_colors.dart';
import 'package:my_english_app/core/di/service_locator.dart';
import 'package:my_english_app/features/auth/cubit/auth_cubit.dart';
import 'package:my_english_app/features/auth/cubit/auth_state.dart';
import 'package:my_english_app/features/dictionary/cubit/dictionary_cubit.dart';
import 'package:my_english_app/features/learning/cubit/swipe_cubit.dart';
import 'package:my_english_app/features/profile/cubit/profile_cubit.dart';

/// Корневой виджет приложения с конфигурацией [GoRouter] и [MultiBlocProvider].
class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final AuthCubit _authCubit;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _authCubit = sl<AuthCubit>()..checkAuth();
    _router = createAppRouter(_authCubit);
  }

  @override
  void dispose() {
    _router.dispose();
    _authCubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthCubit>.value(value: _authCubit),
        BlocProvider<SwipeCubit>(
          create: (_) {
            final cubit = sl<SwipeCubit>();
            if (_authCubit.state is AuthSuccess) {
              cubit.loadWords();
            }
            return cubit;
          },
        ),
        BlocProvider<DictionaryCubit>(
          create: (_) {
            final cubit = sl<DictionaryCubit>();
            if (_authCubit.state is AuthSuccess) {
              cubit.loadWords();
            }
            return cubit;
          },
        ),
        BlocProvider<ProfileCubit>(
          create: (_) {
            final cubit = sl<ProfileCubit>();
            if (_authCubit.state is AuthSuccess) {
              cubit.loadProfile();
            }
            return cubit;
          },
        ),
      ],
      child: BlocListener<AuthCubit, AuthState>(
        listenWhen: (previous, current) {
          if (current is AuthSuccess) {
            return previous is! AuthSuccess || previous.uid != current.uid;
          }
          return previous is AuthSuccess;
        },
        listener: (context, state) {
          if (state is AuthSuccess) {
            context.read<SwipeCubit>().loadWords();
            context.read<DictionaryCubit>().loadWords();
            context.read<ProfileCubit>().loadProfile();
          } else {
            context.read<SwipeCubit>().reset();
            context.read<DictionaryCubit>().reset();
            context.read<ProfileCubit>().reset();
          }
        },
        child: MaterialApp.router(
          title: 'My English App',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            useMaterial3: true,
            scaffoldBackgroundColor: AppColors.background,
            colorScheme: ColorScheme.fromSeed(
              seedColor: AppColors.primary,
            ),
          ),
          routerConfig: _router,
        ),
      ),
    );
  }
}
