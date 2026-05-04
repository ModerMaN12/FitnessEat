// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'meal.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MealItemAdapter extends TypeAdapter<MealItem> {
  @override
  final int typeId = 2;

  @override
  MealItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MealItem(
      foodItemId: fields[0] as String,
      grams: fields[1] as double,
      foodName: fields[2] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, MealItem obj) {
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
      other is MealItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class MealAdapter extends TypeAdapter<Meal> {
  @override
  final int typeId = 3;

  @override
  Meal read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Meal(
      id: fields[0] as String,
      date: fields[1] as DateTime,
      type: fields[2] as String,
      items: (fields[3] as List).cast<MealItem>(),
      imagePath: fields[4] as String?,
      totalCalories: fields[5] as double,
      totalProteins: fields[6] as double,
      totalFats: fields[7] as double,
      totalCarbs: fields[8] as double,
    );
  }

  @override
  void write(BinaryWriter writer, Meal obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.date)
      ..writeByte(2)
      ..write(obj.type)
      ..writeByte(3)
      ..write(obj.items)
      ..writeByte(4)
      ..write(obj.imagePath)
      ..writeByte(5)
      ..write(obj.totalCalories)
      ..writeByte(6)
      ..write(obj.totalProteins)
      ..writeByte(7)
      ..write(obj.totalFats)
      ..writeByte(8)
      ..write(obj.totalCarbs);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MealAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
