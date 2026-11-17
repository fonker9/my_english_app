import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:my_english_app/app/theme/app_colors.dart';
import 'package:my_english_app/app/theme/app_text_styles.dart';
import 'package:my_english_app/features/auth/cubit/auth_cubit.dart';
import 'package:my_english_app/features/auth/cubit/auth_state.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // Освобождаем память при закрытии экрана
  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 150.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Надпись Вход
                const Text(
                  'Вход',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.authTitle,
                ),

                const SizedBox(height: 16),

                // Надпись Рады видеть вас снова
                const Text(
                  'Рады видеть Вас снова!',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.authSubtitle,
                ),

                const SizedBox(height: 16),

                // Надпись Впервые у нас?
                const Text(
                  'Впервые у нас?',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.prostoBodyLarge,
                ),

                const SizedBox(height: 4),

                // Кликабельная надпись Зарегистрируйтесь
                GestureDetector(
                  onTap: () {
                    context.push('/register');
                  },
                  child: const Text(
                    'Зарегистрируйтесь',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.authLink,
                  ),
                ),

                const SizedBox(height: 40),

                // Надпись Логин
                const Text(
                  'Логин',
                  textAlign: TextAlign.left,
                  style: AppTextStyles.inputLabel,
                ),

                const SizedBox(height: 8),

                // Форма ввода Почта
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Пожалуйста, введите почту';
                    }
                    if (!value.contains('@')) {
                      return 'Некорректный формат почты';
                    }
                    return null;
                  },
                  decoration: InputDecoration(
                    hintText: 'Почта',
                    hintStyle: AppTextStyles.inputHint,
                    filled: true,
                    fillColor: AppColors.surface,
                    // Скругление углов
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Надпись пароль
                const Text(
                  'Пароль',
                  textAlign: TextAlign.left,
                  style: AppTextStyles.inputLabel,
                ),

                const SizedBox(height: 8),

                // Форма ввода Пароль
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Пожалуйста, введите пароль';
                    }
                    if (value.length < 6) {
                      return 'Пароль должен быть не менее 6 символов';
                    }
                    return null;
                  },
                  decoration: InputDecoration(
                    hintText: 'Пароль',
                    hintStyle: AppTextStyles.inputHint,
                    filled: true,
                    fillColor: AppColors.surface,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off : Icons.visibility,
                        color: AppColors.hintText,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // Кнопка Войти
                Center(
                  child: SizedBox(
                    width: 240,
                    child: BlocConsumer<AuthCubit, AuthState>(
                      listener: (context, state) {
                        if (state is AuthSuccess) {
                          context.go('/home');
                        } else if (state is AuthFailure) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              backgroundColor: AppColors.primary,
                              content: Text(
                                state.error,
                                style: const TextStyle(color: AppColors.background),
                              ),
                            ),
                          );
                        }
                      },
                      builder: (context, state) {
                        return ElevatedButton(
                          onPressed: state is AuthLoading
                              ? null
                              : () {
                                  if (_formKey.currentState!.validate()) {
                                    // Вызываем метод signIn
                                    context.read<AuthCubit>().signIn(
                                          _emailController.text,
                                          _passwordController.text,
                                        );
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: state is AuthLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    color: AppColors.background,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  'Войти',
                                  style: AppTextStyles.buttonLarge,
                                ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}