import 'dart:convert';
import 'package:http/http.dart' as http;

class UserDataModel {
  final String? id;
  final String username;
  final String gmailid;
  final String phoneNo;
  final String location;
  final String password;
  final Map<String, dynamic>? photo;
  final int? dob;

  UserDataModel({
    this.id,
    required this.username,
    required this.gmailid,
    required this.phoneNo,
    required this.location,
    required this.password,
    this.photo,
    this.dob,
  });

  factory UserDataModel.fromJson(Map<String, dynamic> json) {
    return UserDataModel(
      id: json['id'],
      username: json['username'] ?? '',
      gmailid: json['gmailid'] ?? '',
      phoneNo: json['phoneNo'] ?? '',
      location: json['Location'] ?? '', // Note: API uses capital L for Location
      password: json['password'] ?? '',
      photo: json['photo'],
      dob: json['dob'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'gmailid': gmailid,
      'phoneNo': phoneNo,
      'Location': location, // Note: API uses capital L for Location
      'password': password,
      'photo': photo ?? {},
      'dob': dob ?? DateTime.now().millisecondsSinceEpoch ~/ 1000,
    };
  }

  UserDataModel copyWith({
    String? id,
    String? username,
    String? gmailid,
    String? phoneNo,
    String? location,
    String? password,
    Map<String, dynamic>? photo,
    int? dob,
  }) {
    return UserDataModel(
      id: id ?? this.id,
      username: username ?? this.username,
      gmailid: gmailid ?? this.gmailid,
      phoneNo: phoneNo ?? this.phoneNo,
      location: location ?? this.location,
      password: password ?? this.password,
      photo: photo ?? this.photo,
      dob: dob ?? this.dob,
    );
  }
}