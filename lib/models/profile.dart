// models/profile.dart
import 'package:goodjob/models/city.dart';

class Profile {
  final String firstname;
  final String lastname;
  final String? patronymic;
  final String? telephone;
  final City city;
  final String activeMode;

  Profile({
    required this.firstname,
    required this.lastname,
    this.patronymic,
    this.telephone,
    required this.city,
    required this.activeMode,
  });

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      firstname: json['firstname'],
      lastname: json['lastname'],
      patronymic: json['patronymic'],
      telephone: json['telephone'],
      city: City.fromJson(json['city']),
      activeMode: json['active_mode'],
    );
  }
}