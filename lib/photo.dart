// photo.dart
import 'package:hive/hive.dart';

//part "photo.g.dart";

@HiveType(typeId: 0)
class Photo extends HiveObject{
  @HiveField(0)
  String? id;

  @HiveField(1)
  String? smallUrl;

  @HiveField(2)
  String? regularUrl;

  Photo({required this.id, required this.smallUrl, required this.regularUrl});

}

class PhotoAdapter extends TypeAdapter<Photo> {
  @override
  final int typeId = 0;

  @override
  Photo read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Photo(
      id: fields[0] as String?,
      smallUrl: fields[1] as String?,
      regularUrl: fields[2] as String?
    );
  }

  @override
  void write(BinaryWriter writer, Photo obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.smallUrl)
      ..writeByte(2)
      ..write(obj.regularUrl);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is PhotoAdapter &&
              runtimeType == other.runtimeType &&
              typeId == other.typeId;
}