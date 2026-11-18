import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:my_english_app/app/theme/app_colors.dart';
import 'package:my_english_app/app/theme/app_text_styles.dart';
import 'package:my_english_app/core/utils/russian_plurals.dart';
import 'package:my_english_app/data/models/word.dart';
import 'package:my_english_app/features/dictionary/cubit/dictionary_cubit.dart';
import 'package:my_english_app/features/learning/cubit/swipe_cubit.dart';
import 'package:my_english_app/features/profile/cubit/profile_cubit.dart';

/// Итоговые данные завершённой учебной сессии для передачи на [SessionResultScreen].
class SessionResult extends Equatable {
  final int correctCount;
  final int wrongCount;
  final List<Word> wrongWords;
  final String retryRoute;

  const SessionResult({
    required this.correctCount,
    required this.wrongCount,
    required this.wrongWords,
    required this.retryRoute,
  });

  /// Общее количество обработанных слов в сессии.
  int get totalCount => correctCount + wrongCount;

  /// Процент правильных ответов в сессии.
  int get accuracyPercent =>
      totalCount > 0 ? ((correctCount * 100) / totalCount).round() : 100;

  @override
  List<Object?> get props => [correctCount, wrongCount, wrongWords, retryRoute];
}

/// Общий экран результатов учебной сессии (Карточки, Квиз, Написание).
class SessionResultScreen extends StatelessWidget {
  final SessionResult extra;

  const SessionResultScreen({
    super.key,
    required this.extra,
  });

  @override
  Widget build(BuildContext context) {
    final accuracy = extra.accuracyPercent;
    final ratio = extra.totalCount > 0
        ? (extra.correctCount / extra.totalCount).clamp(0.0, 1.0)
        : 1.0;
    final title = accuracy >= 70 ? 'Отличная работа!' : 'Можно лучше!';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
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
              const SizedBox(height: 24),

              // Круговая диаграмма и статистика сессии
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  children: [
                    SizedBox(
                      width: 150,
                      height: 150,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: 150,
                            height: 150,
                            child: CircularProgressIndicator(
                              value: ratio,
                              strokeWidth: 14,
                              strokeCap: StrokeCap.round,
                              backgroundColor: extra.wrongCount > 0
                                  ? AppColors.error
                                  : AppColors.background,
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                AppColors.success,
                              ),
                            ),
                          ),
                          Text(
                            '$accuracy%',
                            style: AppTextStyles.authTitle,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _ResultBadge(
                          color: AppColors.success,
                          label: 'Правильно',
                          value: '${extra.correctCount}',
                        ),
                        _ResultBadge(
                          color: AppColors.error,
                          label: 'Ошибок',
                          value: '${extra.wrongCount}',
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              if (extra.wrongWords.isNotEmpty) ...[
                const SizedBox(height: 24),
                Text(
                  'Слова с ошибками (${RussianPlurals.wordsWithCount(extra.wrongWords.length)})',
                  style: AppTextStyles.sectionTitle,
                ),
                const SizedBox(height: 12),
                ...extra.wrongWords.map(
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
                onPressed: () {
                  if (extra.retryRoute == '/learning/swipe') {
                    context.read<SwipeCubit>().refreshWords();
                  }
                  context.pushReplacement(extra.retryRoute);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  foregroundColor: AppColors.background,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'Ещё раз',
                  style: AppTextStyles.buttonMedium,
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () {
                  context.read<ProfileCubit>().loadProfile();
                  context.read<DictionaryCubit>().refreshWords();
                  context.read<SwipeCubit>().refreshWords();
                  context.go('/home');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.background,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'На главную',
                  style: AppTextStyles.buttonMedium,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResultBadge extends StatelessWidget {
  final Color color;
  final String label;
  final String value;

  const _ResultBadge({
    required this.color,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '$label: $value',
          style: AppTextStyles.inputLabel,
        ),
      ],
    );
  }
}
