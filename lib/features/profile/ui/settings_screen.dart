import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:my_english_app/app/theme/app_colors.dart';
import 'package:my_english_app/app/theme/app_text_styles.dart';

/// Заглушка экрана настроек до реализации в Фазе 3.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_back_ios,
                      color: AppColors.primary,
                    ),
                    onPressed: () => context.pop(),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Настройки',
                    style: AppTextStyles.sectionHeader,
                  ),
                ],
              ),
              const Expanded(
                child: Center(
                  child: Text(
                    'Настройки цели и уведомлений появятся в следующем обновлении.',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.statusMessage,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
