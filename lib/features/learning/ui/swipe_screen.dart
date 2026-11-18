import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:go_router/go_router.dart';
import 'package:my_english_app/app/theme/app_colors.dart';
import 'package:my_english_app/app/theme/app_text_styles.dart';
import 'package:my_english_app/features/learning/cubit/swipe_cubit.dart';
import 'package:my_english_app/features/learning/cubit/swipe_state.dart';
import 'package:my_english_app/features/learning/ui/session_result_screen.dart';

/// Экран свайп-карточек для знакомства с новыми словами.
class SwipeScreen extends StatefulWidget {
  const SwipeScreen({super.key});

  @override
  State<SwipeScreen> createState() => _SwipeScreenState();
}

class _SwipeScreenState extends State<SwipeScreen> {
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
    final canPop = context.canPop();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            if (canPop)
              Padding(
                padding: const EdgeInsets.fromLTRB(8.0, 8.0, 20.0, 0.0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.arrow_back_ios,
                        color: AppColors.primary,
                      ),
                      onPressed: () => context.pop(),
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      'Карточки',
                      style: AppTextStyles.sectionHeader,
                    ),
                  ],
                ),
              ),
            Expanded(
              child: BlocConsumer<SwipeCubit, SwipeState>(
                listenWhen: (previous, current) =>
                    previous is SwipeLoaded && current is SwipeFinished,
                listener: (context, state) {
                  if (state is SwipeFinished) {
                    context.pushReplacement(
                      '/learning/result',
                      extra: SessionResult(
                        correctCount:
                            state.sessionKnowCount + state.sessionLearnCount,
                        wrongCount: 0,
                        wrongWords: const [],
                        retryRoute: '/learning/swipe',
                      ),
                    );
                  }
                },
                builder: (context, state) {
            if (state is SwipeLoading) {
              return const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              );
            }

            if (state is SwipeError) {
              return Center(
                child: Text(
                  state.message,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.statusMessage,
                ),
              );
            }

            if (state is SwipeLoaded) {
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
                      'Здравствуйте, ${state.nickname}',
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
                      'Новых сегодня: ${state.learnedCount} из ${state.dailyGoal}',
                      style: AppTextStyles.dailyCounter,
                    ),

                    Expanded(
                      child: CardSwiper(
                        key: ValueKey(
                          state.words.map((w) => w.id).join(','),
                        ),
                        controller: _swiperController,
                        cardsCount: state.words.length,
                        initialIndex: state.currentIndex,
                        numberOfCardsDisplayed:
                            state.words.length < 2 ? 1 : 2,
                        isLoop: false,
                        allowedSwipeDirection: const AllowedSwipeDirection.only(
                          left: true,
                          right: true,
                        ),
                        maxAngle: 30,
                        threshold: 30,
                        duration: const Duration(milliseconds: 400),
                        onSwipe: (previousIndex, currentIndex, direction) {
                          if (direction == CardSwiperDirection.left) {
                            context.read<SwipeCubit>().knowWord();
                          } else if (direction == CardSwiperDirection.right) {
                            context.read<SwipeCubit>().notKnowWord();
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
                              context.read<SwipeCubit>().toggleCardSide();
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

                                    Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          !state.isFront ? word.ru : word.en,
                                          textAlign: TextAlign.center,
                                          style: AppTextStyles.flashcardWord,
                                        ),
                                        if (state.isFront &&
                                            word.transcription.isNotEmpty) ...[
                                          const SizedBox(height: 8),
                                          Text(
                                            word.transcription,
                                            textAlign: TextAlign.center,
                                            style: AppTextStyles.wordTranslation,
                                          ),
                                        ],
                                      ],
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

            if (state is SwipeFinished) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Ура! План на сегодня выполнен!',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.finishedMessage,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Новых сегодня: ${state.learnedCount} из ${state.dailyGoal}',
                        style: AppTextStyles.dailyCounter,
                      ),
                    ],
                  ),
                ),
              );
            }

            if (state is SwipeEmpty) {
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
          ],
        ),
      ),
    );
  }
}
