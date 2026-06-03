import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:my_english_app/features/dictionary/cubit/dictionary_cubit.dart';
import 'package:my_english_app/features/learning/cubit/learning_cubit.dart';
import 'dictionary/ui/dictionary_main_screen.dart';
import 'learning/ui/learning_screen.dart';

class MainTabsScreen extends StatefulWidget {
  const MainTabsScreen({super.key});

  @override
  State<MainTabsScreen> createState() => _MainTabsScreenState();
}

class _MainTabsScreenState extends State<MainTabsScreen> {
  int _currentIndex = 1; 

  final List<Widget> _screens = [
    const DictionaryMainScreen(), 
    const LearningScreen(),       
    const Center(child: Text('Тут будет профиль.. надеюсь')), 
  ];

  @override
  Widget build(BuildContext context) {
      return Scaffold(
        body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFFF2D9A4),
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });

          // Синхронизируем кубиты при переключении вкладок
          if (index == 0) {
            // Перешли в Словарь — принудительно обновляем списки уровней
            context.read<DictionaryCubit>().refreshWords();
          } else if (index == 1) {
            // Вернулись в Обучение — обновляем слова, сохраняя текущий индекс свайпа
            context.read<LearningCubit>().refreshWords();
          }
        },
        selectedItemColor: const Color(0xFF828700),
        unselectedItemColor: const Color(0xFFA43032),
        showSelectedLabels: false,
        showUnselectedLabels: false,
        items: [
          BottomNavigationBarItem(
            icon: SvgPicture.asset(
              'assets/icons/book.svg',
              height: 40,
              colorFilter: ColorFilter.mode(
                _currentIndex == 0 ? const Color(0xFF828700) : const Color(0xFFA43032), 
                BlendMode.srcIn,
              ),
            ),
            label: 'Словарь',
          ),
          BottomNavigationBarItem(
            icon: SvgPicture.asset(
              'assets/icons/home.svg',
              height: 40,
              colorFilter: ColorFilter.mode(
                _currentIndex == 1 ? const Color(0xFF828700) : const Color(0xFFA43032), 
                BlendMode.srcIn,
              ),
            ),
            label: 'Изучение',
          ),
          BottomNavigationBarItem(
            icon: SvgPicture.asset(
              'assets/icons/person.svg',
              height: 40,
              colorFilter: ColorFilter.mode(
                _currentIndex == 2 ? const Color(0xFF828700) : const Color(0xFFA43032), 
                BlendMode.srcIn,
              ),
            ),
            label: 'Профиль',
          ),
        ],
      ),
    );
  }
}