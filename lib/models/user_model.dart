import 'package:hive/hive.dart';

@HiveType(typeId: 1)
class UserModel extends HiveObject {
  @HiveField(0)
  final String username;

  @HiveField(1)
  final String email;

  @HiveField(2)
  final String password;

  @HiveField(3)
  final String? profileImagePath;

  UserModel({
    required this.username,
    required this.email,
    required this.password,
    this.profileImagePath,
  });
}
