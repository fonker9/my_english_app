import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:my_english_app/app/theme/app_colors.dart';
import 'package:my_english_app/features/dictionary/cubit/dictionary_cubit.dart';
import 'package:my_english_app/features/learning/cubit/swipe_cubit.dart';
import 'package:my_english_app/features/learning/cubit/swipe_state.dart';
import 'package:my_english_app/features/profile/cubit/profile_cubit.dart';

/// Оболочка с нижней панелью навигации для основных вкладок приложения.
class MainTabsScreen extends StatelessWidget {
  final Widget child;

  const MainTabsScreen({
    super.key,
    required this.child,
  });

  int _currentIndexFromLocation(String location) {
    if (location.startsWith('/dictionary')) return 0;
    if (location.startsWith('/profile')) return 2;
    return 1;
  }

  void _onTap(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.read<DictionaryCubit>().refreshWords();
        context.go('/dictionary');
      case 1:
        final swipeCubit = context.read<SwipeCubit>();
        if (swipeCubit.state is! SwipeLoaded) {
          swipeCubit.refreshWords();
        }
        context.go('/home');
      case 2:
        context.read<ProfileCubit>().loadProfile();
        context.go('/profile');
    }
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final currentIndex = _currentIndexFromLocation(location);

    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: AppColors.surface,
        currentIndex: currentIndex,
        onTap: (index) => _onTap(context, index),
        selectedItemColor: AppColors.secondary,
        unselectedItemColor: AppColors.primary,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        items: [
          BottomNavigationBarItem(
            icon: SvgPicture.asset(
              'assets/icons/book.svg',
              height: 40,
              colorFilter: ColorFilter.mode(
                currentIndex == 0 ? AppColors.secondary : AppColors.primary,
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
                currentIndex == 1 ? AppColors.secondary : AppColors.primary,
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
                currentIndex == 2 ? AppColors.secondary : AppColors.primary,
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
