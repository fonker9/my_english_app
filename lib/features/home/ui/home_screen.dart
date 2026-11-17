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
import 'package:my_english_app/features/profile/cubit/profile_state.dart';

/// Главный экран-дашборд приложения.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Future<void> _openLearningHub(BuildContext context) async {
    await context.push('/learning');
    if (!context.mounted) return;
    context.read<ProfileCubit>().loadProfile();
    context.read<DictionaryCubit>().refreshWords();
    context.read<SwipeCubit>().refreshWords();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: BlocBuilder<ProfileCubit, ProfileState>(
          builder: (context, profileState) {
            if (profileState is ProfileLoading) {
              return const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              );
            }

            if (profileState is ProfileError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Text(
                    profileState.message,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.statusMessage,
                  ),
                ),
              );
            }

            if (profileState is ProfileLoaded) {
              return BlocBuilder<DictionaryCubit, DictionaryState>(
                builder: (context, dictState) {
                  final stats = profileState.stats;
                  final dueCount = dictState is DictionaryLoaded
                      ? dictState.dueForReviewCount
                      : profileState.dueReviewsCount;
                  final dailyGoal = profileState.dailyGoal;
                  final newWordsProgress = dailyGoal > 0
                      ? (stats.todayNewWords / dailyGoal).clamp(0.0, 1.0)
                      : 0.0;

                  final totalReviewsTarget = stats.todayReviews + dueCount;
                  final reviewsProgress = totalReviewsTarget > 0
                      ? (stats.todayReviews / totalReviewsTarget)
                          .clamp(0.0, 1.0)
                      : 0.0;

                  return SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20.0,
                      vertical: 24.0,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 8),
                        Text(
                          'Здравствуйте, ${profileState.nickname}',
                          style: AppTextStyles.homeGreeting,
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Готовы продолжить изучение английского?',
                          style: AppTextStyles.screenSubtitle,
                        ),
                        const SizedBox(height: 24),

                        // Карточка серии дней (streak)
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 52,
                                height: 52,
                                decoration: BoxDecoration(
                                  color: AppColors.background,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const Icon(
                                  Icons.local_fire_department_rounded,
                                  color: AppColors.levelC1,
                                  size: 30,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${RussianPlurals.daysWithCount(stats.currentStreak)} подряд',
                                      style: AppTextStyles.daysOneTitle,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Рекорд: ${RussianPlurals.daysWithCount(stats.longestStreak)}',
                                      style: AppTextStyles.cardMeta,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Карточка ежедневной цели
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Ежедневная цель',
                                style: AppTextStyles.sectionTitle,
                              ),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Новых слов',
                                    style: AppTextStyles.profileStatLabel,
                                  ),
                                  Text(
                                    '${stats.todayNewWords} / $dailyGoal',
                                    style: AppTextStyles.dailyCounter,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: LinearProgressIndicator(
                                  value: newWordsProgress,
                                  minHeight: 10,
                                  backgroundColor: AppColors.background,
                                  valueColor:
                                      const AlwaysStoppedAnimation<Color>(
                                    AppColors.secondary,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Повторений',
                                    style: AppTextStyles.profileStatLabel,
                                  ),
                                  Text(
                                    '${stats.todayReviews} / $totalReviewsTarget',
                                    style: AppTextStyles.dailyCounter,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: LinearProgressIndicator(
                                  value: reviewsProgress,
                                  minHeight: 10,
                                  backgroundColor: AppColors.background,
                                  valueColor:
                                      const AlwaysStoppedAnimation<Color>(
                                    AppColors.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Слова для повторения сегодня
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: AppColors.cardDefault,
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.schedule_rounded,
                                color: AppColors.primary,
                                size: 30,
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Слова для повторения сегодня',
                                      style: AppTextStyles.inputLabel,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      dueCount > 0
                                          ? 'Ждут повторения: ${RussianPlurals.wordsWithCount(dueCount)}'
                                          : 'На сегодня все повторения выполнены',
                                      style: AppTextStyles.wordTranslation,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 28),

                        // Кнопка «Начать обучение»
                        ElevatedButton(
                          onPressed: () => _openLearningHub(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: AppColors.background,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Text(
                            'Начать обучение',
                            style: AppTextStyles.buttonLarge,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            }

            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}
