import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:my_english_app/app/theme/app_colors.dart';
import 'package:my_english_app/app/theme/app_text_styles.dart';
import 'package:my_english_app/core/di/service_locator.dart';
import 'package:my_english_app/features/learning/cubit/writing_cubit.dart';
import 'package:my_english_app/features/learning/cubit/writing_state.dart';
import 'package:my_english_app/features/learning/ui/session_result_screen.dart';

/// Экран режима «Написание» (пользователь вводит английское слово по русскому переводу).
class WritingScreen extends StatelessWidget {
  const WritingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<WritingCubit>(
      create: (_) => sl<WritingCubit>()..startSession(),
      child: const _WritingView(),
    );
  }
}

class _WritingView extends StatefulWidget {
  const _WritingView();

  @override
  State<_WritingView> createState() => _WritingViewState();
}

class _WritingViewState extends State<_WritingView> {
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  Timer? _autoAdvanceTimer;

  @override
  void dispose() {
    _autoAdvanceTimer?.cancel();
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _scheduleAdvance(WritingCubit cubit, {required bool isCorrect}) {
    _autoAdvanceTimer?.cancel();
    _autoAdvanceTimer = Timer(
      Duration(milliseconds: isCorrect ? 1000 : 2000),
      () {
        if (!mounted) return;
        cubit.nextWord();
      },
    );
  }

  void _submitAnswer(WritingCubit cubit) {
    final state = cubit.state;
    if (state is! WritingLoaded || state.isAnswered) return;

    cubit.checkAnswer(_textController.text);
    final updatedState = cubit.state;
    if (updatedState is WritingLoaded && updatedState.isAnswered) {
      _scheduleAdvance(
        cubit,
        isCorrect: updatedState.answerStatus == WritingAnswerStatus.correct,
      );
    }
  }

  void _skipWord(WritingCubit cubit) {
    final state = cubit.state;
    if (state is! WritingLoaded || state.isAnswered) return;

    cubit.skipWord();
    _scheduleAdvance(cubit, isCorrect: false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: BlocConsumer<WritingCubit, WritingState>(
          listener: (context, state) {
            if (state is WritingFinished) {
              context.pushReplacement(
                '/learning/result',
                extra: SessionResult(
                  correctCount: state.correctCount,
                  wrongCount: state.wrongCount,
                  wrongWords: state.wrongWords,
                  retryRoute: '/learning/writing',
                ),
              );
            } else if (state is WritingLoaded && !state.isAnswered) {
              _textController.clear();
              _focusNode.requestFocus();
            }
          },
          builder: (context, state) {
            if (state is WritingLoading) {
              return const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              );
            }

            if (state is WritingError) {
              return _buildCenteredMessage(
                context,
                title: state.message,
                buttonLabel: 'Назад',
                onPressed: () => context.pop(),
              );
            }

            if (state is WritingEmpty) {
              return _buildCenteredMessage(
                context,
                title: 'Нет слов для написания',
                subtitle:
                    'Сначала отметьте новые слова кнопкой «Учу» в карточках или дождитесь времени повторения по SRS.',
                buttonLabel: 'Назад',
                onPressed: () => context.pop(),
              );
            }

            if (state is WritingLoaded) {
              final word = state.currentWord;
              final progress = (state.currentIndex + 1) / state.words.length;
              final borderSide = _borderSideForStatus(state.answerStatus);

              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20.0,
                  vertical: 16.0,
                ),
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
                        Expanded(
                          child: Text(
                            'Слово ${state.currentIndex + 1} из ${state.words.length}',
                            textAlign: TextAlign.center,
                            style: AppTextStyles.sectionTitle,
                          ),
                        ),
                        const SizedBox(width: 48),
                      ],
                    ),
                    const SizedBox(height: 12),

                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 8,
                        backgroundColor: AppColors.surface,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          AppColors.secondary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Карточка с русским словом и транскрипцией-подсказкой
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 32,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.cardDefault,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Column(
                        children: [
                          const Text(
                            'Напишите слово на английском',
                            style: AppTextStyles.cardMeta,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            word.ru,
                            textAlign: TextAlign.center,
                            style: AppTextStyles.flashcardWord,
                          ),
                          if (word.transcription.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            Text(
                              word.transcription,
                              textAlign: TextAlign.center,
                              style: AppTextStyles.wordTranslation,
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Поле ввода английского слова
                    TextField(
                      controller: _textController,
                      focusNode: _focusNode,
                      readOnly: state.isAnswered,
                      textInputAction: TextInputAction.done,
                      autocorrect: false,
                      enableSuggestions: false,
                      onSubmitted: (_) =>
                          _submitAnswer(context.read<WritingCubit>()),
                      style: AppTextStyles.quizOption,
                      decoration: InputDecoration(
                        hintText: 'Введите слово...',
                        hintStyle: AppTextStyles.inputHint,
                        filled: true,
                        fillColor: AppColors.surface,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: borderSide,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: borderSide,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: borderSide,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 18,
                        ),
                      ),
                    ),

                    if (state.answerStatus == WritingAnswerStatus.wrong) ...[
                      const SizedBox(height: 12),
                      Text(
                        'Правильный ответ: ${word.en}',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.daysOneTitle,
                      ),
                    ],

                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: state.isAnswered
                          ? null
                          : () => _submitAnswer(context.read<WritingCubit>()),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.background,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'Проверить',
                        style: AppTextStyles.buttonMedium,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: state.isAnswered
                          ? null
                          : () => _skipWord(context.read<WritingCubit>()),
                      child: const Text(
                        'Не помню',
                        style: AppTextStyles.inputLabel,
                      ),
                    ),
                  ],
                ),
              );
            }

            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  BorderSide _borderSideForStatus(WritingAnswerStatus status) {
    switch (status) {
      case WritingAnswerStatus.initial:
        return BorderSide.none;
      case WritingAnswerStatus.correct:
        return const BorderSide(color: AppColors.success, width: 2.5);
      case WritingAnswerStatus.wrong:
        return const BorderSide(color: AppColors.error, width: 2.5);
    }
  }

  Widget _buildCenteredMessage(
    BuildContext context, {
    required String title,
    String? subtitle,
    required String buttonLabel,
    required VoidCallback onPressed,
  }) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTextStyles.sectionHeader,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 12),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: AppTextStyles.wordTranslation,
              ),
            ],
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.background,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(buttonLabel, style: AppTextStyles.buttonMedium),
            ),
          ],
        ),
      ),
    );
  }
}
