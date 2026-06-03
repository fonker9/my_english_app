import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_english_app/features/auth/cubit/auth_cubit.dart';
import 'package:my_english_app/features/auth/cubit/auth_state.dart';
import 'package:my_english_app/features/main_tabs_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;

  // Создаем контроллеры для полей ввода
  final _nicknameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // Освобождаем память при закрытии экрана
  @override
  void dispose() {
    _nicknameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const backgroundColor = Color(0xFFFFFAE9);
    const primaryColor = Color(0xFFA43032);
    const inputFieldColor = Color(0xFFF2D9A4);
    const hintTextColor = Color(0xFF7B7A7A);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 150.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                
                // Надпись регистрация
                const Text(
                  'Регистрация',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Prosto One',
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
                
                const SizedBox(height: 16),

                // Надпись Уже есть аккаунт?
                const Text(
                  'Уже есть аккаунт?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Prosto One',
                    fontSize: 18,
                    color: primaryColor,
                  ),
                ),

                const SizedBox(height: 4),

                // Кликабельная надпись Войдите
                GestureDetector(
                  onTap: () {
                    // Возвращаемся назад на экран логина
                    Navigator.of(context).pop();
                  },
                  child: const Text(
                    'Войдите',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Prosto One',
                      fontSize: 18,
                      color: primaryColor,
                      decoration: TextDecoration.underline,
                      decorationColor: primaryColor,
                    ),
                  ),
                ),
                
                const SizedBox(height: 40),

                // Надпись Никнейм
                const Text(
                  'Никнейм',
                  textAlign: TextAlign.left,
                  style: TextStyle(
                    fontFamily: 'Prosto One',
                    fontSize: 16,
                    color: primaryColor,
                  ),
                ),

                const SizedBox(height: 8),
                
                // Форма ввода "Никнейм"
                TextFormField(
                  controller: _nicknameController,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Пожалуйста, придумайте никнейм';
                    }
                    return null;
                  },
                  decoration: InputDecoration(
                    hintText: 'Придумайте никнейм',
                    hintStyle: const TextStyle(color: hintTextColor),
                    filled: true,
                    fillColor: inputFieldColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),

                // Надпись Логин
                const Text(
                  'Логин',
                  textAlign: TextAlign.left,
                  style: TextStyle(
                    fontFamily: 'Prosto One',
                    fontSize: 16,
                    color: primaryColor,
                  ),
                ),

                const SizedBox(height: 8),
                
                // Форма ввода Почта
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Пожалуйста, введите свою почту';
                    }
                    if (!value.contains('@')) {
                      return 'Некорректный формат почты';
                    }
                    return null;
                  },
                  decoration: InputDecoration(
                    hintText: 'Введите свою почту',
                    hintStyle: const TextStyle(color: hintTextColor),
                    filled: true,
                    fillColor: inputFieldColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Надпись Пароль
                const Text(
                  'Пароль',
                  textAlign: TextAlign.left,
                  style: TextStyle(
                    fontFamily: 'Prosto One',
                    fontSize: 16,
                    color: primaryColor,
                  ),
                ),
                const SizedBox(height: 8),
                
                // Форма ввода Пароль
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword, // Скрываем пароль
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Пожалуйста, придумайте пароль';
                    }
                    if (value.length < 6) {
                      return 'Пароль должен быть не менее 6 символов';
                    }
                    return null;
                  },
                  decoration: InputDecoration(
                    hintText: 'Придумайте пароль',
                    hintStyle: const TextStyle(color: hintTextColor),
                    filled: true,
                    fillColor: inputFieldColor,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off : Icons.visibility,
                        color: hintTextColor,
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

                const SizedBox(height: 40),

                // Кнопка Зарегистрироваться
                Center(
                  child: SizedBox(
                    width: 240,
                    child: BlocConsumer<AuthCubit, AuthState>(
                      // listener обрабатывает действия навигации и всплывающие окна (вызывается 1 раз при смене стейта)
                      listener: (context, state) {
                        if (state is AuthSuccess) {
                          // Перенаправляем на главный экран и полностью очищаем историю переходов
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(builder: (context) => const MainTabsScreen()),
                            (route) => false,
                          );
                        } else if (state is AuthFailure) {
                          // Показываем ошибку от Firebase
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              backgroundColor: primaryColor,
                              content: Text(state.error, style: const TextStyle(color: backgroundColor)),
                            ),
                          );
                        }
                      },
                      // builder отвечает только за прорисовку внешнего вида кнопки
                      builder: (context, state) {
                        return ElevatedButton(
                          // Если идет загрузка (state is AuthLoading), передаем в onPressed значение null.
                          // во флатере передача null в onPressed автоматически делает кнопку неактивной
                          onPressed: state is AuthLoading
                              ? null
                              : () {
                                  if (_formKey.currentState!.validate()) {
                                    // Вызываем метод Cubit, передавая данные из контроллеров
                                    context.read<AuthCubit>().signUp(
                                          _emailController.text,
                                          _passwordController.text,
                                          _nicknameController.text,
                                        );
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: state is AuthLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(color: backgroundColor, strokeWidth: 2),
                                )
                              : const Text(
                                  'Зарегистрироваться',
                                  maxLines: 1,
                                  style: TextStyle(fontFamily: 'Days One', fontSize: 16, color: backgroundColor),
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