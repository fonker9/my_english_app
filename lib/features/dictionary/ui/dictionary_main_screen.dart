import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_english_app/app/theme/app_colors.dart';
import 'package:my_english_app/app/theme/app_text_styles.dart';
import 'package:my_english_app/features/dictionary/cubit/dictionary_cubit.dart';
import 'package:my_english_app/features/dictionary/cubit/dictionary_state.dart';
import 'package:my_english_app/features/dictionary/ui/dictionary_level_screen.dart';

class DictionaryMainScreen extends StatelessWidget {
  const DictionaryMainScreen({super.key});

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
              return const Center(
                child: Text(
                  'Ошибка загрузки словаря',
                  style: TextStyle(color: AppColors.primary),
                ),
              );
            }

            if (state is DictionaryLoaded) {
              final List<Map<String, dynamic>> levelConfigs = [
                {'name': 'A1', 'color': AppColors.levelA1},
                {'name': 'A2', 'color': AppColors.levelA2},
                {'name': 'B1', 'color': AppColors.levelB1},
                {'name': 'B2', 'color': AppColors.levelB2},
                {'name': 'C1', 'color': AppColors.levelC1},
                {'name': 'C2', 'color': AppColors.levelC2},
              ];

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 30),
                    const Center(
                      child: Text(
                        'Словарь',
                        style: AppTextStyles.screenTitle,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Center(
                      child: Text(
                        'Выберите словарь под уровень английского',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.screenSubtitle,
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      height: 460,
                      child: ListView.separated(
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: levelConfigs.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final config = levelConfigs[index];
                          final String levelName = config['name'];
                          final Color badgeColor = config['color'];

                          final int wordsCount = state.allWords
                              .where((word) => word.level.toLowerCase() == levelName.toLowerCase())
                              .length;

                          return GestureDetector(
                            onTap: () {
                              context.read<DictionaryCubit>().selectLevel(levelName);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (newContext) => BlocProvider.value(
                                    value: context.read<DictionaryCubit>(),
                                    child: const DictionaryLevelScreen(),
                                  ),
                                ),
                              );
                            },
                            child: Container(
                              height: 64,
                              padding: const EdgeInsets.symmetric(horizontal: 16),
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
                                  Expanded(
                                    child: Center(
                                      child: Padding(
                                        padding: const EdgeInsets.only(right: 54),
                                        child: Text(
                                          '$wordsCount слов',
                                          style: AppTextStyles.daysOneTitle,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const Spacer(),
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
}