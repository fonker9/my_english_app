import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:my_english_app/app/theme/app_colors.dart';
import 'package:my_english_app/app/theme/app_text_styles.dart';
import 'package:my_english_app/features/dictionary/cubit/dictionary_cubit.dart';
import 'package:my_english_app/features/dictionary/cubit/dictionary_state.dart';

/// Главный экран словаря с переключением «По уровням» и «По темам».
class DictionaryMainScreen extends StatelessWidget {
  const DictionaryMainScreen({super.key});

  static const List<String> _levels = ['A1', 'A2', 'B1', 'B2', 'C1', 'C2'];

  @override
  Widget build(BuildContext context) {
    return Scaffold( 
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: BlocBuilder<DictionaryCubit, DictionaryState>(
          builder: (context, state) {
            if (state is DictionaryLoading) {
              return const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              );
            }

            if (state is DictionaryError) {
              return Center(
                child: Text(
                  state.message,
                  style: AppTextStyles.statusMessage,
                ),
              );
            }

            if (state is DictionaryLoaded) {
              final isByLevel = state.filterMode == DictionaryFilterMode.byLevel;

              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20.0,
                  vertical: 16.0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 16),
                    const Center(
                      child: Text(
                        'Словарь',
                        style: AppTextStyles.screenTitle,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Переключатель «По уровням» / «По темам»
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: _ModeTabButton(
                              label: 'По уровням',
                              isSelected: isByLevel,
                              onTap: () => context
                                  .read<DictionaryCubit>()
                                  .setFilterMode(DictionaryFilterMode.byLevel),
                            ),
                          ),
                          Expanded(
                            child: _ModeTabButton(
                              label: 'По темам',
                              isSelected: !isByLevel,
                              onTap: () => context
                                  .read<DictionaryCubit>()
                                  .setFilterMode(DictionaryFilterMode.byTopic),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),
                    Center(
                      child: Text(
                        isByLevel
                            ? 'Выберите словарь под уровень английского'
                            : 'Выберите словарь по интересующей теме',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.screenSubtitle,
                      ),
                    ),
                    const SizedBox(height: 20),

                    Expanded(
                      child: isByLevel
                          ? _buildLevelsList(context, state)
                          : _buildTopicsList(context, state),
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

  Widget _buildLevelsList(BuildContext context, DictionaryLoaded state) {
    return ListView.separated(
      itemCount: _levels.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final levelName = _levels[index];
        final badgeColor = AppColors.levelColor(levelName);
        final totalCount = state.totalWordsForLevel(levelName);
        final masteredCount = state.masteredWordsForLevel(levelName);
        final progress = totalCount > 0 ? masteredCount / totalCount : 0.0;

        return GestureDetector(
          onTap: () {
            context.read<DictionaryCubit>().selectLevel(levelName);
            context.push('/dictionary/$levelName');
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              children: [
                Container(
                  width: 54,
                  height: 38,
                  decoration: BoxDecoration(
                    color: badgeColor,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text(
                      levelName,
                      style: AppTextStyles.levelBadge,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '$totalCount слов',
                            style: AppTextStyles.daysOneTitle,
                          ),
                          Text(
                            '$masteredCount / $totalCount',
                            style: AppTextStyles.cardMeta,
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 6,
                          backgroundColor: AppColors.background,
                          valueColor: AlwaysStoppedAnimation<Color>(badgeColor),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTopicsList(BuildContext context, DictionaryLoaded state) {
    final topics = state.availableTopics;
    if (topics.isEmpty) {
      return const Center(
        child: Text(
          'Темы пока не загружены',
          style: AppTextStyles.emptyList,
        ),
      );
    }

    return ListView.separated(
      itemCount: topics.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final topic = topics[index];
        final totalCount = state.totalWordsForTopic(topic);
        final masteredCount = state.masteredWordsForTopic(topic);
        final progress = totalCount > 0 ? masteredCount / totalCount : 0.0;

        return GestureDetector(
          onTap: () {
            context.read<DictionaryCubit>().selectTopic(topic);
            context.push('/dictionary/${Uri.encodeComponent(topic)}');
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    _topicIcon(topic),
                    color: AppColors.background,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            topicDisplayName(topic),
                            style: AppTextStyles.daysOneTitle,
                          ),
                          Text(
                            '$masteredCount / $totalCount',
                            style: AppTextStyles.cardMeta,
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$totalCount слов',
                        style: AppTextStyles.cardMeta,
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 6,
                          backgroundColor: AppColors.background,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            AppColors.secondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Возвращает русское название темы для интерфейса.
  static String topicDisplayName(String topic) {
    const names = {
      'general': 'Общие слова',
      'food': 'Еда',
      'travel': 'Путешествия',
      'family': 'Семья',
      'work': 'Работа',
      'nature': 'Природа',
      'health': 'Здоровье',
      'technology': 'Технологии',
      'education': 'Образование',
      'shopping': 'Покупки',
      'emotions': 'Эмоции',
      'home': 'Дом',
      'sport': 'Спорт',
      'transport': 'Транспорт',
      'weather': 'Погода',
      'clothes': 'Одежда',
      'body': 'Тело',
      'time': 'Время',
      'city': 'Город',
      'animals': 'Животные',
      'hobbies': 'Хобби',
    };
    return names[topic.toLowerCase()] ?? topic;
  }

  static IconData _topicIcon(String topic) {
    const icons = {
      'general': Icons.menu_book_rounded,
      'food': Icons.restaurant_rounded,
      'travel': Icons.flight_takeoff_rounded,
      'family': Icons.family_restroom_rounded,
      'work': Icons.work_outline_rounded,
      'nature': Icons.park_rounded,
      'health': Icons.favorite_outline_rounded,
      'technology': Icons.computer_rounded,
      'education': Icons.school_rounded,
      'shopping': Icons.shopping_bag_outlined,
      'emotions': Icons.emoji_emotions_outlined,
      'home': Icons.home_outlined,
      'sport': Icons.sports_soccer_rounded,
      'transport': Icons.directions_bus_rounded,
      'weather': Icons.wb_sunny_outlined,
      'clothes': Icons.checkroom_rounded,
      'body': Icons.accessibility_new_rounded,
      'time': Icons.schedule_rounded,
      'city': Icons.location_city_rounded,
      'animals': Icons.pets_rounded,
      'hobbies': Icons.palette_outlined,
    };
    return icons[topic.toLowerCase()] ?? Icons.category_outlined;
  }
}

class _ModeTabButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ModeTabButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            label,
            style: isSelected
                ? AppTextStyles.segmentSelected
                : AppTextStyles.segmentUnselected,
          ),
        ),
      ),
    );
  }
}
