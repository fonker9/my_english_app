import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:my_english_app/app/theme/app_colors.dart';
import 'package:my_english_app/app/theme/app_text_styles.dart';
import 'package:my_english_app/core/di/service_locator.dart';
import 'package:my_english_app/core/utils/russian_plurals.dart';
import 'package:my_english_app/features/learning/cubit/quiz_cubit.dart';
import 'package:my_english_app/features/learning/cubit/quiz_state.dart';

/// Экран квиза (4 варианта ответа, смешанное направление en ↔ ru).
class QuizScreen extends StatelessWidget {
  const QuizScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<QuizCubit>(
      create: (_) => sl<QuizCubit>()..startQuiz(),
      child: const _QuizView(),
    );
  }
}

class _QuizView extends StatefulWidget {
  const _QuizView();

  @override
  State<_QuizView> createState() => _QuizViewState();
}

class _QuizViewState extends State<_QuizView> {
  Timer? _autoAdvanceTimer;

  @override
  void dispose() {
    _autoAdvanceTimer?.cancel();
    super.dispose();
  }

  void _onOptionTap(QuizCubit cubit, int optionIndex) {
    final state = cubit.state;
    if (state is! QuizLoaded || state.isAnswered) return;

    cubit.selectAnswer(optionIndex);
    _autoAdvanceTimer?.cancel();
    _autoAdvanceTimer = Timer(const Duration(milliseconds: 1000), () {
      if (!mounted) return;
      cubit.nextQuestion();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: BlocBuilder<QuizCubit, QuizState>(
          builder: (context, state) {
            if (state is QuizLoading) {
              return const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              );
            }

            if (state is QuizError) {
              return _buildCenteredMessage(
                context,
                title: state.message,
                buttonLabel: 'Назад',
                onPressed: () => context.pop(),
              );
            }

            if (state is QuizEmpty) {
              return _buildCenteredMessage(
                context,
                title: 'Нет слов для повторения',
                subtitle:
                    'Сначала отметьте новые слова кнопкой «Учу» в карточках или возвращайтесь по расписанию повторений.',
                buttonLabel: 'Назад',
                onPressed: () => context.pop(),
              );
            }

            if (state is QuizFinished) {
              return _QuizSummaryView(
                state: state,
                onRetry: () => context.read<QuizCubit>().startQuiz(),
                onHome: () => context.go('/home'),
              );
            }

            if (state is QuizLoaded) {
              final question = state.currentQuestion;
              final progress = (state.currentIndex + 1) / state.questions.length;

              return Padding(
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
                            'Вопрос ${state.currentIndex + 1} из ${state.questions.length}',
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

                    // Карточка со словом-вопросом
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
                          Text(
                            question.direction == QuizDirection.enToRu
                                ? 'Выберите перевод на русский'
                                : 'Выберите перевод на английский',
                            style: AppTextStyles.cardMeta,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            question.prompt,
                            textAlign: TextAlign.center,
                            style: AppTextStyles.flashcardWord,
                          ),
                          if (question.direction == QuizDirection.enToRu &&
                              question.word.transcription.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              question.word.transcription,
                              textAlign: TextAlign.center,
                              style: AppTextStyles.wordTranslation,
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // 4 варианта ответа
                    Expanded(
                      child: ListView.separated(
                        itemCount: question.options.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final optionText = question.options[index];
                          final bgColor = _optionColor(state, index);
                          final textStyle = _optionTextStyle(state, index);

                          return GestureDetector(
                            onTap: () => _onOptionTap(
                              context.read<QuizCubit>(),
                              index,
                            ),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 18,
                              ),
                              decoration: BoxDecoration(
                                color: bgColor,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Center(
                                child: Text(
                                  optionText,
                                  textAlign: TextAlign.center,
                                  style: textStyle,
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

            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Color _optionColor(QuizLoaded state, int index) {
    if (!state.isAnswered) {
      return AppColors.surface;
    }

    final correctIndex = state.currentQuestion.correctIndex;
    if (index == correctIndex) {
      return AppColors.success;
    }
    if (index == state.selectedOptionIndex) {
      return AppColors.error;
    }
    return AppColors.surface.withValues(alpha: 0.6);
  }

  TextStyle _optionTextStyle(QuizLoaded state, int index) {
    if (!state.isAnswered) {
      return AppTextStyles.quizOption;
    }

    final correctIndex = state.currentQuestion.correctIndex;
    if (index == correctIndex || index == state.selectedOptionIndex) {
      return AppTextStyles.quizOptionSelected;
    }
    return AppTextStyles.quizOption;
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

class _QuizSummaryView extends StatelessWidget {
  final QuizFinished state;
  final VoidCallback onRetry;
  final VoidCallback onHome;

  const _QuizSummaryView({
    required this.state,
    required this.onRetry,
    required this.onHome,
  });

  @override
  Widget build(BuildContext context) {
    final title = state.accuracyPercent >= 70
        ? 'Отличная работа!'
        : 'Можно лучше!';

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppTextStyles.screenTitle,
          ),
          const SizedBox(height: 20),

          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              children: [
                Text(
                  '${state.accuracyPercent}%',
                  style: AppTextStyles.authTitle,
                ),
                const SizedBox(height: 6),
                Text(
                  'Правильных: ${state.correctCount} из ${state.totalQuestions}',
                  style: AppTextStyles.dailyCounter,
                ),
                const SizedBox(height: 4),
                Text(
                  'Ошибок: ${RussianPlurals.wordsWithCount(state.wrongCount)}',
                  style: AppTextStyles.wordTranslation,
                ),
              ],
            ),
          ),

          if (state.wrongWords.isNotEmpty) ...[
            const SizedBox(height: 24),
            const Text(
              'Слова с ошибками',
              style: AppTextStyles.sectionTitle,
            ),
            const SizedBox(height: 12),
            ...state.wrongWords.map(
              (word) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surface.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          word.en,
                          style: AppTextStyles.daysOneTitle,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          word.ru,
                          textAlign: TextAlign.right,
                          style: AppTextStyles.wordTranslation,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],

          const SizedBox(height: 28),
          ElevatedButton(
            onPressed: onRetry,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.secondary,
              foregroundColor: AppColors.background,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text('Ещё раз', style: AppTextStyles.buttonMedium),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: onHome,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.background,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text('На главную', style: AppTextStyles.buttonMedium),
          ),
        ],
      ),
    );
  }
}
