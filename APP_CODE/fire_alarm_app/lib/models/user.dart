import 'dart:convert';
import 'package:crypto/crypto.dart';

/// User model representing a registered user in the fire alarm system
/// 
/// This model handles user data serialization and password hashing for secure storage.
/// Requirements: 2.2, 3.1
class User {
  final String username;
  final String passwordHash;

  User({
    required this.username,
    required this.passwordHash,
  });

  /// Creates a User instance with a hashed password from plain text
  /// 
  /// Use this factory when registering a new user with a plain text password.
  factory User.create({
    required String username,
    required String password,
  }) {
    return User(
      username: username,
      passwordHash: _hashPassword(password),
    );
  }

  /// Creates a User instance from JSON map (for loading from storage)
  /// 
  /// Expected JSON format:
  /// {
  ///   "username": "user123",
  ///   "password_hash": "hashed_password_string"
  /// }
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      username: json['username'] as String,
      passwordHash: json['password_hash'] as String,
    );
  }

  /// Converts User to JSON map for serialization
  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'password_hash': passwordHash,
    };
  }

  /// Verifies if the provided password matches the stored hash
  bool verifyPassword(String password) {
    return _hashPassword(password) == passwordHash;
  }

  /// Hashes a password using SHA-256
  static String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is User &&
        other.username == username &&
        other.passwordHash == passwordHash;
  }

  @override
  int get hashCode {
    return Object.hash(username, passwordHash);
  }

  @override
  String toString() {
    return 'User(username: $username)';
  }
}
