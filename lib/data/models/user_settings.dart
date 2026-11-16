import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

part 'user_settings.g.dart';

/// Локальные настройки пользователя (хранятся только в Hive).
@HiveType(typeId: 2)
class UserSettings extends Equatable {
  static const Object _unset = Object();

  @HiveField(0)
  final int dailyNewWordsGoal;

  @HiveField(1)
  final TimeOfDay? notificationTime;

  @HiveField(2)
  final bool notificationsEnabled;

  const UserSettings({
    this.dailyNewWordsGoal = 5,
    this.notificationTime,
    this.notificationsEnabled = false,
  });

  /// Настройки по умолчанию.
  factory UserSettings.defaults() => const UserSettings();

  /// Создаёт копию [UserSettings] с обновлёнными полями.
  UserSettings copyWith({
    int? dailyNewWordsGoal,
    Object? notificationTime = _unset,
    bool? notificationsEnabled,
  }) {
    return UserSettings(
      dailyNewWordsGoal: dailyNewWordsGoal ?? this.dailyNewWordsGoal,
      notificationTime: identical(notificationTime, _unset)
          ? this.notificationTime
          : notificationTime as TimeOfDay?,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
    );
  }

  @override
  List<Object?> get props => [
        dailyNewWordsGoal,
        notificationTime,
        notificationsEnabled,
      ];
}
