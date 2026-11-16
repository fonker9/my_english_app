import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_english_app/app/theme/app_colors.dart';
import 'package:my_english_app/app/theme/app_text_styles.dart';
import 'package:my_english_app/features/dictionary/cubit/dictionary_cubit.dart';
import 'package:my_english_app/features/dictionary/cubit/dictionary_state.dart';

class DictionaryLevelScreen extends StatelessWidget {
  const DictionaryLevelScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: BlocBuilder<DictionaryCubit, DictionaryState>(
          builder: (context, state) {
            if (state is! DictionaryLoaded) {
              return const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              );
            }

            final currentLevel = state.selectedLevel ?? '';
            final learningWords = state.learningWordsFiltered;
            final learnedWords = state.learnedWordsFiltered;

            final int totalWordsInLevel = state.allWords
                .where((w) => w.level.toLowerCase() == currentLevel.toLowerCase())
                .length;
            final int totalLearnedInLevel = state.allWords
                .where((w) => w.level.toLowerCase() == currentLevel.toLowerCase() && w.isLearned)
                .length;

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios, color: AppColors.primary),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Уровень $currentLevel',
                        style: AppTextStyles.sectionHeader,
                      ),
                      const Spacer(),
                      Text(
                        '$totalLearnedInLevel / $totalWordsInLevel',
                        style: AppTextStyles.daysOneTitle,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  TextField(
                    onChanged: (value) => context.read<DictionaryCubit>().searchWords(value),
                    style: AppTextStyles.searchInput,
                    decoration: InputDecoration(
                      hintText: 'Найти слово...',
                      hintStyle: AppTextStyles.searchHint,
                      prefixIcon: const Icon(Icons.search, color: AppColors.primary),
                      filled: true,
                      fillColor: AppColors.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                  const SizedBox(height: 24),

                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionTitle('На изучении', learningWords.length),
                          const SizedBox(height: 12),
                          _buildWordList(learningWords, isLearningSection: true),

                          const SizedBox(height: 28),

                          _buildSectionTitle('Изучено', learnedWords.length),
                          const SizedBox(height: 12),
                          _buildWordList(learnedWords, isLearningSection: false),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, int count) {
    return Text(
      '$title ($count)',
      style: AppTextStyles.sectionTitle,
    );
  }

  Widget _buildWordList(List<dynamic> words, {required bool isLearningSection}) {
    if (words.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8.0),
        child: Text(
          'Список пуст',
          style: AppTextStyles.emptyList,
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: words.length,
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final word = words[index];

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      word.english,
                      style: AppTextStyles.daysOneTitle,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      word.russian,
                      style: AppTextStyles.wordTranslation,
                    ),
                  ],
                ),
              ),
              Icon(
                isLearningSection ? Icons.menu_book_rounded : Icons.check_circle_rounded,
                color: AppColors.primary,
                size: 20,
              ),
            ],
          ),
        );
      },
    );
  }
}