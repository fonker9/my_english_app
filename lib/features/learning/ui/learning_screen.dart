import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:my_english_app/features/learning/cubit/learning_cubit.dart';
import 'package:my_english_app/features/learning/cubit/learning_state.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
      backgroundColor: const Color(0xFFFFFAE9),
      body: SafeArea(
        child: BlocBuilder<LearningCubit, LearningState>(
          builder: (context, state) {
            if (state is LearningLoading) {
              return const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Color(0xFFA43032),
                  ),
                ),
              );
            }

            if (state is LearningError) {
              return const Center(
                child: Text(
                  'Ошибка при загрузке слов',
                  style: TextStyle(
                    color: Color(0xFFA43032),
                    fontSize: 18,
                  ),
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
                      style: const TextStyle(
                        fontSize: 20,
                        fontFamily: 'Prosto One',
                        color: Color(0xFFA43032),
                      ),
                    ),

                    const SizedBox(height: 2),

                    const Text(
                      'Готовы изучать новые слова?',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        fontFamily: 'Prosto One',
                        color: Color(0xFFA43032),
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      'Изучено сегодня: ${state.learnedCount} из 5',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF828700),
                      ),
                    ),


                    Expanded(
                      child: CardSwiper(
                        controller: _swiperController,
                        cardsCount: state.words.length,
                        initialIndex: 0,
                        allowedSwipeDirection:
                            const AllowedSwipeDirection.only(
                          left: true,
                          right: true,
                        ),
                        maxAngle: 30,
                        threshold: 30,
                        duration: const Duration(milliseconds: 400),

                        onSwipe:
                            (previousIndex, currentIndex, direction) {
                          if (direction ==
                              CardSwiperDirection.left) {
                            context
                                .read<LearningCubit>()
                                .knowWord();
                          } else if (direction ==
                              CardSwiperDirection.right) {
                            context
                                .read<LearningCubit>()
                                .notKnowWord();
                          }
                          return true;
                        },

                        onUndo:
                            (previousIndex, currentIndex, direction) =>
                                true,

                        cardBuilder:
                            (context, index, percentX, percentY) {
                          final word = state.words[index];

                          Color cardBgColor =
                              const Color(0xFFD2E5C5);

                          if (percentX > 10) {
                            cardBgColor =
                                const Color(0xFFB4B55D);
                          } else if (percentX < -10) {
                            cardBgColor =
                                const Color(0xFFC8817B);
                          }

                          return GestureDetector(
                            onTap: () {
                              context
                                  .read<LearningCubit>()
                                  .toggleCardSide();
                            },
                            child: Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: cardBgColor,
                                borderRadius:
                                    BorderRadius.circular(24.0),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black
                                        .withValues(alpha: 0.05),
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
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '${word.level.toUpperCase()} Level',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFFA43032),
                                      ),
                                    ),

                                    Text(
                                      !state.isFront
                                          ? word.russian
                                          : word.english,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontSize: 34,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFFA43032),
                                      ),
                                    ),

                                    
                                    Row(
                                      children: [
                                        Expanded(
                                          child: ElevatedButton(
                                            onPressed: () =>
                                                _smoothSwipe(
                                              CardSwiperDirection.left,
                                            ),
                                            style:
                                                ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  const Color(
                                                0xFFA43032,
                                              ),
                                              foregroundColor:
                                                  Colors.white,
                                              shape:
                                                  RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius
                                                        .circular(
                                                  12,
                                                ),
                                              ),
                                              padding:
                                                  const EdgeInsets
                                                      .symmetric(
                                                vertical: 14,
                                              ),
                                            ),
                                            child: const Text(
                                              'Знаю',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight:
                                                    FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: ElevatedButton(
                                            onPressed: () =>
                                                _smoothSwipe(
                                              CardSwiperDirection.right,
                                            ),
                                            style:
                                                ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  const Color(
                                                0xFF828700,
                                              ),
                                              foregroundColor:
                                                  Colors.white,
                                              shape:
                                                  RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius
                                                        .circular(
                                                  12,
                                                ),
                                              ),
                                              padding:
                                                  const EdgeInsets
                                                      .symmetric(
                                                vertical: 14,
                                              ),
                                            ),
                                            child: const Text(
                                              'Учу',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight:
                                                    FontWeight.bold,
                                              ),
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
                  style: TextStyle(
                    color: Color(0xFF828700),
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
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
                    style: TextStyle(
                      color: Color(0xFFA43032),
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
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