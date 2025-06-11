// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'painting.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PaintingAdapter extends TypeAdapter<Painting> {
  @override
  final int typeId = 0;

  @override
  Painting read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Painting(
      id: fields[0] as String,
      imagePath: fields[1] as String,
      title: fields[2] as String,
      details: fields[3] as String,
      gallery: fields[4] as String,
      year: fields[5] as String,
      author: fields[6] as String,
    );
  }

  @override
  void write(BinaryWriter writer, Painting obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.imagePath)
      ..writeByte(2)
      ..write(obj.title)
      ..writeByte(3)
      ..write(obj.details)
      ..writeByte(4)
      ..write(obj.gallery)
      ..writeByte(5)
      ..write(obj.year)
      ..writeByte(6)
      ..write(obj.author);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PaintingAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
