import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_english_app/features/auth/cubit/auth_cubit.dart';
import 'package:my_english_app/features/auth/cubit/auth_state.dart';
import 'package:my_english_app/features/auth/ui/register_screen.dart';
import 'package:my_english_app/features/main_tabs_screen.dart';

class LoginScreen extends StatefulWidget{
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>{
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;

  // позже нужно добавить сюда контроллеры для текста
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // Освобождаем память при закрытии экрана
  @override
  void dispose(){
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context){
    const backgroundColor = Color(0xFFFFFAE9);
    const primaryColor = Color(0xFFA43032);
    const inputFieldColor = Color(0xFFF2D9A4);
    const hintTextColor = Color(0xFF7B7A7A);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child:SingleChildScrollView(
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
                  style: TextStyle(
                    fontFamily: 'Prosto One',
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),

                const SizedBox(height: 16),

                // Надпись Рады видеть вас снова
                const Text(
                  'Рады видеть Вас снова!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Prosto One',
                    fontSize: 26,
                    color: primaryColor,
                  ),
                ),

                const SizedBox(height: 16),

                // Надпись Впервые у нас?
                const Text(
                  'Впервые у нас?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Prosto One',
                    fontSize: 18,
                    color: primaryColor,
                  ),
                ),

                const SizedBox(height: 4,),

                // Кликабельная надпись Зарегистрируйтесь
                GestureDetector(
                  onTap: (){
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => RegisterScreen()),
                    );
                  },
                  child: const Text(
                    'Зарегистрируйтесь',
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

                const SizedBox(height: 40,),

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

                const SizedBox(height: 8,),

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
                    hintStyle: const TextStyle(color: hintTextColor),
                    filled: true,
                    fillColor: inputFieldColor,
                    // Скругление углов
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),

                const SizedBox(height: 16,),

                // Надпись пароль
                const Text(
                  'Пароль',
                  textAlign: TextAlign.left,
                  style: TextStyle(
                    fontFamily: 'Prosto One',
                    fontSize: 16,
                    color: primaryColor,
                  ),
                ),

                const SizedBox(height: 8,),

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
                    hintStyle: const TextStyle(color:hintTextColor),
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

                const SizedBox(height: 32,),

                // Кнопка Войти
                Center(
                  child: SizedBox(
                    width: 240,
                    child: BlocConsumer<AuthCubit, AuthState>(
                      listener: (context, state) {
                        if (state is AuthSuccess) {
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(builder: (context) => const MainTabsScreen()),
                            (route) => false,
                          );
                        } else if (state is AuthFailure) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              backgroundColor: primaryColor,
                              content: Text(state.error, style: const TextStyle(color: backgroundColor)),
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
                                  'Войти',
                                  style: TextStyle(fontFamily: 'Days One', fontSize: 24, color: backgroundColor),
                                ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        )
      )
    );
  }
}