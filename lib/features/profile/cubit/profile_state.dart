import 'package:equatable/equatable.dart';
import 'package:my_english_app/data/models/user_stats.dart';

/// Базовое состояние экрана профиля и дашборда.
abstract class ProfileState extends Equatable {
  const ProfileState();

  @override
  List<Object?> get props => [];
}

/// Загрузка данных профиля.
class ProfileLoading extends ProfileState {
  const ProfileLoading();
}

/// Ошибка загрузки данных профиля.
class ProfileError extends ProfileState {
  final String message;

  const ProfileError([this.message = 'Ошибка загрузки профиля']);

  @override
  List<Object?> get props => [message];
}

/// Загруженные данные профиля, целей и статистики пользователя.
class ProfileLoaded extends ProfileState {
  final String nickname;
  final String email;
  final UserStats stats;
  final int accuracyPercent;
  final int dailyGoal;
  final int dueReviewsCount;

  const ProfileLoaded({
    required this.nickname,
    required this.email,
    required this.stats,
    required this.accuracyPercent,
    this.dailyGoal = 5,
    this.dueReviewsCount = 0,
  });

  @override
  List<Object?> get props => [
        nickname,
        email,
        stats,
        accuracyPercent,
        dailyGoal,
        dueReviewsCount,
      ];
}
