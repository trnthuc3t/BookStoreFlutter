import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

class User {
  int? id;
  String? email;
  String? password;
  String? firstName;
  String? lastName;
  bool isAdmin;

  User({
    this.id,
    this.email,
    this.password,
    this.firstName,
    this.lastName,
    this.isAdmin = false,
  });

  User.withCredentials(this.email, this.password) : isAdmin = false;

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      email: json['email'],
      password: json['password'],
      firstName: json['firstName'] ?? json['first_name'],
      lastName: json['lastName'] ?? json['last_name'],
      isAdmin: json['isAdmin'] ?? json['is_admin'] ?? false,
    );
  }

  factory User.fromFirebaseUser(firebase_auth.User firebaseUser) {
    return User(
      id: null,
      email: firebaseUser.email,
      password: null,
      isAdmin: false, // Default to false, can be updated from database
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'password': password,
      'firstName': firstName,
      'lastName': lastName,
      'isAdmin': isAdmin,
    };
  }

  String toJsonString() {
    return jsonEncode(toJson());
  }

  User copyWith({
    int? id,
    String? email,
    String? password,
    String? firstName,
    String? lastName,
    bool? isAdmin,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      password: password ?? this.password,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      isAdmin: isAdmin ?? this.isAdmin,
    );
  }
}
