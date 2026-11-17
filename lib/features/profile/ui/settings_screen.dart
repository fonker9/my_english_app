import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:my_english_app/app/theme/app_colors.dart';
import 'package:my_english_app/app/theme/app_text_styles.dart';
import 'package:my_english_app/core/di/service_locator.dart';
import 'package:my_english_app/data/models/user_settings.dart';
import 'package:my_english_app/data/repositories/settings_repository.dart';
import 'package:my_english_app/features/learning/cubit/swipe_cubit.dart';
import 'package:my_english_app/features/profile/cubit/profile_cubit.dart';

/// Экран настроек цели на день, уведомлений и информации о приложении.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const List<int> _goalOptions = [5, 10, 15, 20];
  static const TimeOfDay _defaultTime = TimeOfDay(hour: 20, minute: 0);

  late final SettingsRepository _settingsRepository;
  UserSettings _settings = UserSettings.defaults();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _settingsRepository = sl<SettingsRepository>();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final loaded = await _settingsRepository.loadSettings();
    if (!mounted) return;
    setState(() {
      _settings = loaded;
      _isLoading = false;
    });
  }

  Future<void> _saveSettings(UserSettings updated) async {
    setState(() {
      _settings = updated;
    });
    await _settingsRepository.saveSettings(updated);
    if (!mounted) return;
    context.read<ProfileCubit>().loadProfile();
    context.read<SwipeCubit>().refreshWords();
  }

  Future<void> _pickNotificationTime() async {
    final initial = _settings.notificationTime ?? _defaultTime;
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
    );
    if (picked == null || !mounted) return;

    await _saveSettings(
      _settings.copyWith(
        notificationTime: picked,
        notificationsEnabled: true,
      ),
    );
  }

  String _formatTime(TimeOfDay? time) {
    final effective = time ?? _defaultTime;
    final hour = effective.hour.toString().padLeft(2, '0');
    final minute = effective.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              )
            : SingleChildScrollView(
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
                        const SizedBox(width: 8),
                        const Text(
                          'Настройки',
                          style: AppTextStyles.sectionHeader,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Ежедневная цель
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Ежедневная цель',
                            style: AppTextStyles.sectionTitle,
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Сколько новых слов изучать в день',
                            style: AppTextStyles.wordTranslation,
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: _goalOptions.map((goal) {
                              final isSelected =
                                  _settings.dailyNewWordsGoal == goal;
                              return Expanded(
                                child: Padding(
                                  padding: EdgeInsets.only(
                                    right: goal == _goalOptions.last ? 0 : 8,
                                  ),
                                  child: GestureDetector(
                                    onTap: () => _saveSettings(
                                      _settings.copyWith(
                                        dailyNewWordsGoal: goal,
                                      ),
                                    ),
                                    child: AnimatedContainer(
                                      duration:
                                          const Duration(milliseconds: 200),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? AppColors.primary
                                            : AppColors.background,
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      child: Center(
                                        child: Text(
                                          '$goal',
                                          style: isSelected
                                              ? AppTextStyles.segmentSelected
                                              : AppTextStyles.segmentUnselected,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Уведомления
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Уведомления',
                            style: AppTextStyles.sectionTitle,
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Expanded(
                                child: Text(
                                  'Ежедневное напоминание',
                                  style: AppTextStyles.inputLabel,
                                ),
                              ),
                              Switch(
                                value: _settings.notificationsEnabled,
                                activeThumbColor: AppColors.background,
                                activeTrackColor: AppColors.secondary,
                                onChanged: (enabled) {
                                  _saveSettings(
                                    _settings.copyWith(
                                      notificationsEnabled: enabled,
                                      notificationTime:
                                          _settings.notificationTime ??
                                              _defaultTime,
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          InkWell(
                            borderRadius: BorderRadius.circular(14),
                            onTap: _pickNotificationTime,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.background,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Время уведомления',
                                    style: AppTextStyles.profileStatLabel,
                                  ),
                                  Text(
                                    _formatTime(_settings.notificationTime),
                                    style: AppTextStyles.daysOneTitle,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // О приложении
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'О приложении',
                            style: AppTextStyles.sectionTitle,
                          ),
                          SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'My English App',
                                style: AppTextStyles.inputLabel,
                              ),
                              Text(
                                'Версия 1.0.0',
                                style: AppTextStyles.wordTranslation,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
