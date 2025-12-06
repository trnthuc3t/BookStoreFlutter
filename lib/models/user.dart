import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

class User {
  int? id;
  String? email;
  String? password;
  String? firstName;
  String? lastName;
  bool isAdmin;
  bool isStaff;
  String? role;

  User({
    this.id,
    this.email,
    this.password,
    this.firstName,
    this.lastName,
    this.isAdmin = false,
    this.isStaff = false,
    this.role,
  });

  User.withCredentials(this.email, this.password) : isAdmin = false, isStaff = false;

  factory User.fromJson(Map<String, dynamic> json) {
    final role = json['role'] as String?;
    return User(
      id: json['id'],
      email: json['email'],
      password: json['password'],
      firstName: json['firstName'] ?? json['first_name'],
      lastName: json['lastName'] ?? json['last_name'],
      role: role,
      isAdmin: role == 'admin' || json['isAdmin'] == true || json['is_admin'] == true,
      isStaff: role == 'staff',
    );
  }

  factory User.fromFirebaseUser(firebase_auth.User firebaseUser) {
    return User(
      id: null,
      email: firebaseUser.email,
      password: null,
      isAdmin: false,
      isStaff: false,
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
      'isStaff': isStaff,
      'role': role,
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
    bool? isStaff,
    String? role,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      password: password ?? this.password,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      isAdmin: isAdmin ?? this.isAdmin,
      isStaff: isStaff ?? this.isStaff,
      role: role ?? this.role,
    );
  }
}
