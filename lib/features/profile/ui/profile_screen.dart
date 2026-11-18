import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:my_english_app/app/theme/app_colors.dart';
import 'package:my_english_app/app/theme/app_text_styles.dart';
import 'package:my_english_app/core/utils/russian_plurals.dart';
import 'package:my_english_app/features/auth/cubit/auth_cubit.dart';
import 'package:my_english_app/features/profile/cubit/profile_cubit.dart';
import 'package:my_english_app/features/profile/cubit/profile_state.dart';

/// Экран профиля пользователя со статистикой и навигацией в настройки.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: BlocBuilder<ProfileCubit, ProfileState>(
          builder: (context, state) {
            if (state is ProfileLoading) {
              return const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              );
            }

            if (state is ProfileError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Text(
                    state.message,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.statusMessage,
                  ),
                ),
              );
            }

            if (state is ProfileLoaded) {
              final stats = state.stats;

              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20.0,
                  vertical: 24.0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Center(
                      child: Text(
                        'Профиль',
                        style: AppTextStyles.screenTitle,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Аватар, никнейм и email
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.person_rounded,
                              color: AppColors.background,
                              size: 36,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  state.nickname,
                                  style: AppTextStyles.sectionHeader,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (state.email.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    state.email,
                                    style: AppTextStyles.wordTranslation,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),
                    const Text(
                      'Статистика',
                      style: AppTextStyles.sectionTitle,
                    ),
                    const SizedBox(height: 12),

                    _StatTile(
                      icon: Icons.local_fire_department_rounded,
                      iconColor: AppColors.levelC1,
                      label: 'Серия дней',
                      value:
                          '${stats.currentStreak} (макс: ${stats.longestStreak})',
                    ),
                    const SizedBox(height: 12),

                    _StatTile(
                      icon: Icons.menu_book_rounded,
                      iconColor: AppColors.secondary,
                      label: 'Всего выучено',
                      value:
                          RussianPlurals.wordsWithCount(stats.totalWordsLearned),
                    ),
                    const SizedBox(height: 12),

                    _StatTile(
                      icon: Icons.track_changes_rounded,
                      iconColor: AppColors.primary,
                      label: 'Точность квизов',
                      value: '${state.accuracyPercent}%',
                    ),

                    const SizedBox(height: 32),

                    ElevatedButton.icon(
                      onPressed: () => context.push('/settings'),
                      icon: const Icon(Icons.settings_rounded),
                      label: const Text(
                        'Настройки',
                        style: AppTextStyles.buttonMedium,
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.secondary,
                        foregroundColor: AppColors.background,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    ElevatedButton.icon(
                      onPressed: () {
                        context.read<AuthCubit>().signOut();
                      },
                      icon: const Icon(Icons.logout_rounded),
                      label: const Text(
                        'Выйти',
                        style: AppTextStyles.buttonMedium,
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.background,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
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
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  const _StatTile({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              label,
              style: AppTextStyles.profileStatLabel,
            ),
          ),
          Text(
            value,
            style: AppTextStyles.profileStatValue,
          ),
        ],
      ),
    );
  }
}
