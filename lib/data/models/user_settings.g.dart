// GENERATED CODE - HANDWRITTEN ADAPTER FOR HIVE

part of 'user_settings.dart';

/// Адаптер Hive для [UserSettings] (typeId: 2).
class UserSettingsAdapter extends TypeAdapter<UserSettings> {
  @override
  final int typeId = 2;

  @override
  UserSettings read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };

    final rawMinutes = fields[1] as int?;
    final TimeOfDay? notificationTime = rawMinutes == null
        ? null
        : TimeOfDay(hour: rawMinutes ~/ 60, minute: rawMinutes % 60);

    return UserSettings(
      dailyNewWordsGoal: (fields[0] as int?) ?? 5,
      notificationTime: notificationTime,
      notificationsEnabled: (fields[2] as bool?) ?? false,
    );
  }

  @override
  void write(BinaryWriter writer, UserSettings obj) {
    final int? minutes = obj.notificationTime == null
        ? null
        : obj.notificationTime!.hour * 60 + obj.notificationTime!.minute;

    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.dailyNewWordsGoal)
      ..writeByte(1)
      ..write(minutes)
      ..writeByte(2)
      ..write(obj.notificationsEnabled);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserSettingsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
