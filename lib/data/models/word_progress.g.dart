// GENERATED CODE - HANDWRITTEN ADAPTER FOR HIVE

part of 'word_progress.dart';

/// Адаптер Hive для [WordProgress] (typeId: 0).
class WordProgressAdapter extends TypeAdapter<WordProgress> {
  @override
  final int typeId = 0;

  @override
  WordProgress read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };

    final rawStatus = fields[1];
    WordStatus status = WordStatus.unseen;
    if (rawStatus is int &&
        rawStatus >= 0 &&
        rawStatus < WordStatus.values.length) {
      status = WordStatus.values[rawStatus];
    } else if (rawStatus is String) {
      status = WordStatus.values.firstWhere(
        (s) => s.name == rawStatus,
        orElse: () => WordStatus.unseen,
      );
    } else if (rawStatus is WordStatus) {
      status = rawStatus;
    }

    return WordProgress(
      wordId: fields[0] as int,
      status: status,
      consecutiveCorrect: (fields[2] as int?) ?? 0,
      totalCorrect: (fields[3] as int?) ?? 0,
      totalWrong: (fields[4] as int?) ?? 0,
      lastReviewed: fields[5] as DateTime?,
      nextReview: fields[6] as DateTime?,
      firstSeen: fields[7] as DateTime?,
      isSynced: (fields[8] as bool?) ?? false,
    );
  }

  @override
  void write(BinaryWriter writer, WordProgress obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.wordId)
      ..writeByte(1)
      ..write(obj.status.index)
      ..writeByte(2)
      ..write(obj.consecutiveCorrect)
      ..writeByte(3)
      ..write(obj.totalCorrect)
      ..writeByte(4)
      ..write(obj.totalWrong)
      ..writeByte(5)
      ..write(obj.lastReviewed)
      ..writeByte(6)
      ..write(obj.nextReview)
      ..writeByte(7)
      ..write(obj.firstSeen)
      ..writeByte(8)
      ..write(obj.isSynced);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WordProgressAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
