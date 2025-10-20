import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

class User {
  String? email;
  String? password;
  bool isAdmin;

  User({
    this.email,
    this.password,
    this.isAdmin = false,
  });

  User.withCredentials(this.email, this.password) : isAdmin = false;

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      email: json['email'],
      password: json['password'],
      isAdmin: json['isAdmin'] ?? false,
    );
  }

  factory User.fromFirebaseUser(firebase_auth.User firebaseUser) {
    return User(
      email: firebaseUser.email,
      password: null,
      isAdmin: false, // Default to false, can be updated from database
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'password': password,
      'isAdmin': isAdmin,
    };
  }

  String toJsonString() {
    return jsonEncode(toJson());
  }

  User copyWith({
    String? email,
    String? password,
    bool? isAdmin,
  }) {
    return User(
      email: email ?? this.email,
      password: password ?? this.password,
      isAdmin: isAdmin ?? this.isAdmin,
    );
  }
}
