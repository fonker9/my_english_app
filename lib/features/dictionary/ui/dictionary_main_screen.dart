import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_english_app/features/dictionary/cubit/dictionary_cubit.dart';
import 'package:my_english_app/features/dictionary/cubit/dictionary_state.dart';
import 'package:my_english_app/features/dictionary/ui/dictionary_level_screen.dart';

class DictionaryMainScreen extends StatelessWidget {
  const DictionaryMainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: const Color(0xFFFFFAE9),
        body: SafeArea(
          child: BlocBuilder<DictionaryCubit, DictionaryState>(
            builder: (context, state) {
              if (state is DictionaryLoading) {
                return const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFA43032)),
                  ),
                );
              }

              if (state is DictionaryError) {
                return const Center(
                  child: Text(
                    'Ошибка загрузки словаря',
                    style: TextStyle(color: Color(0xFFA43032)),
                  ),
                );
              }

              if (state is DictionaryLoaded) {
                final List<Map<String, dynamic>> levelConfigs = [
                  {'name': 'A1', 'color': const Color(0xFF04826B)},
                  {'name': 'A2', 'color': const Color(0xFF4B7C0C)},
                  {'name': 'B1', 'color': const Color(0xFFA48C0E)},
                  {'name': 'B2', 'color': const Color(0xFFA44D0E)},
                  {'name': 'C1', 'color': const Color(0xFFDC401D)},
                  {'name': 'C2', 'color': const Color(0xFFDC1D62)},
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
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFA43032),
                            fontFamily: 'Prosto One',
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Center(
                        child: Text(
                          'Выберите словарь под уровень английского',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFFA43032),
                            fontFamily: 'Prosto One',
                          ),
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
                                  color: const Color(0xFFF2D9A4),
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
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                            fontFamily: 'SF Pro Display',
                                          ),
                                        ),
                                      ),
                                    ),
                                    
                                    Expanded(
                                      child: Center(
                                        child: Padding(
                                          padding: const EdgeInsets.only(right: 54), 
                                          child: Text(
                                            '$wordsCount слов',
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFFA43032),
                                              fontFamily: 'Days One',
                                            ),
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