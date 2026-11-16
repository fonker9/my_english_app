import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:my_english_app/app/theme/app_colors.dart';
import 'package:my_english_app/app/theme/app_text_styles.dart';
import 'package:my_english_app/features/learning/cubit/learning_cubit.dart';
import 'package:my_english_app/features/learning/cubit/learning_state.dart';

class LearningScreen extends StatefulWidget {
  const LearningScreen({super.key});

  @override
  State<LearningScreen> createState() => _LearningScreenState();
}

class _LearningScreenState extends State<LearningScreen> {
  final CardSwiperController _swiperController = CardSwiperController();

  @override
  void dispose() {
    _swiperController.dispose();
    super.dispose();
  }

  void _smoothSwipe(CardSwiperDirection direction) {
    _swiperController.swipe(direction);
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final nickname = user?.displayName ?? 'пользователь';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: BlocBuilder<LearningCubit, LearningState>(
          builder: (context, state) {
            if (state is LearningLoading) {
              return const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              );
            }

            if (state is LearningError) {
              return const Center(
                child: Text(
                  'Ошибка при загрузке слов',
                  style: AppTextStyles.statusMessage,
                ),
              );
            }

            if (state is LearningLoaded) {
              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20.0,
                  vertical: 12.0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 42),

                    Text(
                      'Здравствуйте‚ $nickname',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.greetingTitle,
                    ),

                    const SizedBox(height: 2),

                    const Text(
                      'Готовы изучать новые слова?',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.inputLabel,
                    ),

                    const SizedBox(height: 8),

                    Text(
                      'Изучено сегодня: ${state.learnedCount} из 5',
                      style: AppTextStyles.dailyCounter,
                    ),

                    Expanded(
                      child: CardSwiper(
                        controller: _swiperController,
                        cardsCount: state.words.length,
                        initialIndex: 0,
                        allowedSwipeDirection: const AllowedSwipeDirection.only(
                          left: true,
                          right: true,
                        ),
                        maxAngle: 30,
                        threshold: 30,
                        duration: const Duration(milliseconds: 400),
                        onSwipe: (previousIndex, currentIndex, direction) {
                          if (direction == CardSwiperDirection.left) {
                            context.read<LearningCubit>().knowWord();
                          } else if (direction == CardSwiperDirection.right) {
                            context.read<LearningCubit>().notKnowWord();
                          }
                          return true;
                        },
                        onUndo: (previousIndex, currentIndex, direction) => true,
                        cardBuilder: (context, index, percentX, percentY) {
                          final word = state.words[index];

                          Color cardBgColor = AppColors.cardDefault;

                          if (percentX > 10) {
                            cardBgColor = AppColors.cardSwipeRight;
                          } else if (percentX < -10) {
                            cardBgColor = AppColors.cardSwipeLeft;
                          }

                          return GestureDetector(
                            onTap: () {
                              context.read<LearningCubit>().toggleCardSide();
                            },
                            child: Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: cardBgColor,
                                borderRadius: BorderRadius.circular(24.0),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.shadow.withValues(alpha: 0.05),
                                    blurRadius: 10,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24.0,
                                  vertical: 18.0,
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '${word.level.toUpperCase()} Level',
                                      style: AppTextStyles.flashcardLevel,
                                    ),

                                    Text(
                                      !state.isFront ? word.russian : word.english,
                                      textAlign: TextAlign.center,
                                      style: AppTextStyles.flashcardWord,
                                    ),

                                    Row(
                                      children: [
                                        Expanded(
                                          child: ElevatedButton(
                                            onPressed: () => _smoothSwipe(
                                              CardSwiperDirection.left,
                                            ),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: AppColors.primary,
                                              foregroundColor: AppColors.white,
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              padding: const EdgeInsets.symmetric(
                                                vertical: 14,
                                              ),
                                            ),
                                            child: const Text(
                                              'Знаю',
                                              style: AppTextStyles.cardActionButton,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: ElevatedButton(
                                            onPressed: () => _smoothSwipe(
                                              CardSwiperDirection.right,
                                            ),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: AppColors.secondary,
                                              foregroundColor: AppColors.white,
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              padding: const EdgeInsets.symmetric(
                                                vertical: 14,
                                              ),
                                            ),
                                            child: const Text(
                                              'Учу',
                                              style: AppTextStyles.cardActionButton,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            }

            if (state is LearningFinished) {
              return const Center(
                child: Text(
                  'Ура! План на сегодня выполнен!',
                  style: AppTextStyles.finishedMessage,
                ),
              );
            }

            if (state is LearningEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'Все доступные слова уже распределены.\n\nПродолжайте изучать слова из раздела "На изучении" или добавьте новые слова в базу.',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.emptyLearningMessage,
                  ),
                ),
              );
            }

            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}