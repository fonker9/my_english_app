import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:my_english_app/app/theme/app_colors.dart';
import 'package:my_english_app/app/theme/app_text_styles.dart';
import 'package:my_english_app/core/utils/russian_plurals.dart';
import 'package:my_english_app/features/dictionary/cubit/dictionary_cubit.dart';
import 'package:my_english_app/features/dictionary/cubit/dictionary_state.dart';
import 'package:my_english_app/features/learning/cubit/swipe_cubit.dart';
import 'package:my_english_app/features/profile/cubit/profile_cubit.dart';

/// Экран выбора режима обучения (Карточки, Квиз, Написание).
class LearningHubScreen extends StatelessWidget {
  const LearningHubScreen({super.key});

  Future<void> _openMode(BuildContext context, String route) async {
    await context.push(route);
    if (!context.mounted) return;
    context.read<DictionaryCubit>().refreshWords();
    context.read<ProfileCubit>().loadProfile();
    context.read<SwipeCubit>().refreshWords();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
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
                    'Обучение',
                    style: AppTextStyles.sectionHeader,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                'Выберите режим тренировки',
                style: AppTextStyles.screenSubtitle,
              ),
              const SizedBox(height: 20),

              Expanded(
                child: BlocBuilder<DictionaryCubit, DictionaryState>(
                  builder: (context, state) {
                    final unseenCount = state is DictionaryLoaded
                        ? state.unseenWordsCount
                        : 0;
                    final dueCount = state is DictionaryLoaded
                        ? state.dueForReviewCount
                        : 0;

                    return ListView(
                      children: [
                        _LearningModeCard(
                          icon: Icons.style_rounded,
                          accentColor: AppColors.secondary,
                          title: 'Карточки',
                          description:
                              'Свайп-карточки для знакомства с новыми словами',
                          availabilityText:
                              'Доступно новых: ${RussianPlurals.wordsWithCount(unseenCount)}',
                          onTap: () => _openMode(context, '/learning/swipe'),
                        ),
                        const SizedBox(height: 16),
                        _LearningModeCard(
                          icon: Icons.quiz_rounded,
                          accentColor: AppColors.primary,
                          title: 'Квиз',
                          description: '4 варианта ответа, en ↔ ru (SRS)',
                          availabilityText:
                              'Для повторения: ${RussianPlurals.wordsWithCount(dueCount)}',
                          onTap: () => _openMode(context, '/learning/quiz'),
                        ),
                        const SizedBox(height: 16),
                        _LearningModeCard(
                          icon: Icons.edit_note_rounded,
                          accentColor: AppColors.levelB2,
                          title: 'Написание',
                          description: 'Ввод английского слова вручную (SRS)',
                          availabilityText:
                              'Для повторения: ${RussianPlurals.wordsWithCount(dueCount)}',
                          onTap: () => _openMode(context, '/learning/writing'),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LearningModeCard extends StatelessWidget {
  final IconData icon;
  final Color accentColor;
  final String title;
  final String description;
  final String availabilityText;
  final VoidCallback onTap;

  const _LearningModeCard({
    required this.icon,
    required this.accentColor,
    required this.title,
    required this.description,
    required this.availabilityText,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: accentColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                icon,
                color: AppColors.background,
                size: 30,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.daysOneTitle,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: AppTextStyles.wordTranslation,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    availabilityText,
                    style: AppTextStyles.dailyCounter,
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.primary,
              size: 28,
            ),
          ],
        ),
      ),
    );
  }
}
