// GENERATED CODE - HANDWRITTEN ADAPTER FOR HIVE

part of 'user_stats.dart';

/// Адаптер Hive для [UserStats] (typeId: 1).
class UserStatsAdapter extends TypeAdapter<UserStats> {
  @override
  final int typeId = 1;

  @override
  UserStats read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };

    return UserStats(
      currentStreak: (fields[0] as int?) ?? 0,
      longestStreak: (fields[1] as int?) ?? 0,
      lastStudyDate: fields[2] as DateTime?,
      todayNewWords: (fields[3] as int?) ?? 0,
      todayReviews: (fields[4] as int?) ?? 0,
      totalWordsLearned: (fields[5] as int?) ?? 0,
      totalQuizCorrect: (fields[6] as int?) ?? 0,
      totalQuizWrong: (fields[7] as int?) ?? 0,
      isSynced: (fields[8] as bool?) ?? true,
    );
  }

  @override
  void write(BinaryWriter writer, UserStats obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.currentStreak)
      ..writeByte(1)
      ..write(obj.longestStreak)
      ..writeByte(2)
      ..write(obj.lastStudyDate)
      ..writeByte(3)
      ..write(obj.todayNewWords)
      ..writeByte(4)
      ..write(obj.todayReviews)
      ..writeByte(5)
      ..write(obj.totalWordsLearned)
      ..writeByte(6)
      ..write(obj.totalQuizCorrect)
      ..writeByte(7)
      ..write(obj.totalQuizWrong)
      ..writeByte(8)
      ..write(obj.isSynced);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserStatsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
