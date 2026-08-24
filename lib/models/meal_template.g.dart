// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'meal_template.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MealTemplateAdapter extends TypeAdapter<MealTemplate> {
  @override
  final int typeId = 10;

  @override
  MealTemplate read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MealTemplate(
      id: fields[0] as String,
      name: fields[1] as String,
      type: fields[2] as String,
      items: (fields[3] as List).cast<TemplateItem>(),
      userId: fields[4] as String,
      createdAt: fields[5] as DateTime?,
      updatedAt: fields[6] as DateTime?,
      isSynced: fields[7] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, MealTemplate obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.type)
      ..writeByte(3)
      ..write(obj.items)
      ..writeByte(4)
      ..write(obj.userId)
      ..writeByte(5)
      ..write(obj.createdAt)
      ..writeByte(6)
      ..write(obj.updatedAt)
      ..writeByte(7)
      ..write(obj.isSynced);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MealTemplateAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class TemplateItemAdapter extends TypeAdapter<TemplateItem> {
  @override
  final int typeId = 11;

  @override
  TemplateItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TemplateItem(
      foodItemId: fields[0] as String,
      grams: fields[1] as double,
      foodName: fields[2] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, TemplateItem obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.foodItemId)
      ..writeByte(1)
      ..write(obj.grams)
      ..writeByte(2)
      ..write(obj.foodName);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TemplateItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
