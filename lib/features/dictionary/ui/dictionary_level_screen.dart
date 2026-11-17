import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:my_english_app/app/theme/app_colors.dart';
import 'package:my_english_app/app/theme/app_text_styles.dart';
import 'package:my_english_app/data/models/word.dart';
import 'package:my_english_app/data/models/word_progress.dart';
import 'package:my_english_app/features/dictionary/cubit/dictionary_cubit.dart';
import 'package:my_english_app/features/dictionary/cubit/dictionary_state.dart';
import 'package:my_english_app/features/dictionary/ui/dictionary_main_screen.dart';

/// Экран списка слов выбранного уровня или темы с тремя секциями статусов.
class DictionaryLevelScreen extends StatefulWidget {
  final String level;

  const DictionaryLevelScreen({
    super.key,
    required this.level,
  });

  @override
  State<DictionaryLevelScreen> createState() => _DictionaryLevelScreenState();
}

class _DictionaryLevelScreenState extends State<DictionaryLevelScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<DictionaryCubit>().selectCategory(widget.level);
    });
  }

  @override
  void didUpdateWidget(covariant DictionaryLevelScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.level != widget.level) {
      context.read<DictionaryCubit>().selectCategory(widget.level);
    }
  }

  String _screenTitle() {
    final normalized = widget.level.trim().toLowerCase();
    if (DictionaryCubit.cefrLevels.contains(normalized)) {
      return 'Уровень ${normalized.toUpperCase()}';
    }
    return DictionaryMainScreen.topicDisplayName(widget.level);
  }

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

            final newWords = state.newWordsFiltered;
            final learningWords = state.learningWordsFiltered;
            final masteredWords = state.masteredWordsFiltered;

            final totalWords = state.totalWordsInSelection;
            final totalMastered = state.masteredWordsInSelection;

            return Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 20.0,
                vertical: 16.0,
              ),
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
                      Expanded(
                        child: Text(
                          _screenTitle(),
                          style: AppTextStyles.sectionHeader,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        '$totalMastered / $totalWords',
                        style: AppTextStyles.daysOneTitle,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  TextField(
                    onChanged: (value) =>
                        context.read<DictionaryCubit>().searchWords(value),
                    style: AppTextStyles.searchInput,
                    decoration: InputDecoration(
                      hintText: 'Найти слово...',
                      hintStyle: AppTextStyles.searchHint,
                      prefixIcon: const Icon(
                        Icons.search,
                        color: AppColors.primary,
                      ),
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
                          _buildSectionTitle('Новые', newWords.length),
                          const SizedBox(height: 12),
                          _buildWordList(newWords, state),

                          const SizedBox(height: 28),

                          _buildSectionTitle(
                            'На изучении',
                            learningWords.length,
                          ),
                          const SizedBox(height: 12),
                          _buildWordList(learningWords, state),

                          const SizedBox(height: 28),

                          _buildSectionTitle('Изучено', masteredWords.length),
                          const SizedBox(height: 12),
                          _buildWordList(masteredWords, state),
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

  Widget _buildWordList(List<Word> words, DictionaryLoaded state) {
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
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final word = words[index];
        final status = state.statusOf(word.id);

        final metaParts = <String>[
          if (word.transcription.isNotEmpty) word.transcription,
          if (word.partOfSpeech.isNotEmpty) word.partOfSpeech,
        ];

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.surface.withValues(alpha: 0.45),
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
                      word.en,
                      style: AppTextStyles.daysOneTitle,
                    ),
                    if (metaParts.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        metaParts.join(' · '),
                        style: AppTextStyles.cardMeta,
                      ),
                    ],
                    const SizedBox(height: 4),
                    Text(
                      word.ru,
                      style: AppTextStyles.wordTranslation,
                    ),
                  ],
                ),
              ),
              Icon(
                _statusIcon(status),
                color: status == WordStatus.mastered
                    ? AppColors.secondary
                    : AppColors.primary,
                size: 22,
              ),
            ],
          ),
        );
      },
    );
  }

  IconData _statusIcon(WordStatus status) {
    switch (status) {
      case WordStatus.unseen:
        return Icons.circle_outlined;
      case WordStatus.learning:
      case WordStatus.review:
        return Icons.menu_book_rounded;
      case WordStatus.mastered:
        return Icons.check_circle_rounded;
    }
  }
}
