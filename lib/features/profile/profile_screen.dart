import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_english_app/features/auth/cubit/auth_cubit.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const backgroundColor = Color(0xFFFFFAE9);
    const primaryColor = Color(0xFFA43032);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Center(
          child: SizedBox(
            width: 240,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: backgroundColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                // Вызываем метод signOut из AuthCubit для очистки сессии в Firebase
                context.read<AuthCubit>().signOut();
              },
              child: const Text(
                'Выйти из аккаунта',
                style: TextStyle(
                  fontFamily: 'Days One',
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}