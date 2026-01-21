import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../utils/constants.dart';

/// Authentication service result class
class AuthResult {
  final bool success;
  final String? errorMessage;

  AuthResult.success() : success = true, errorMessage = null;
  AuthResult.failure(this.errorMessage) : success = false;
}

/// Validation result class
class ValidationResult {
  final bool isValid;
  final String? errorMessage;

  ValidationResult.valid() : isValid = true, errorMessage = null;
  ValidationResult.invalid(this.errorMessage) : isValid = false;
}

/// Authentication service for user registration, login, and session management
/// 
/// Uses SharedPreferences for local storage of user data and session tokens.
/// Requirements: 2.2, 2.3, 3.1, 3.2, 3.3, 3.4, 3.5
class AuthService {
  final SharedPreferences _prefs;

  AuthService(this._prefs);

  /// Validates username format
  /// 
  /// Username must be 4-20 characters long.
  /// **Property 2: Username Validation**
  /// **Validates: Requirements 2.2, 2.3**
  static ValidationResult validateUsername(String username) {
    if (username.length < AuthConfig.usernameMinLength) {
      return ValidationResult.invalid(
        '用户名长度不能少于${AuthConfig.usernameMinLength}个字符'
      );
    }
    if (username.length > AuthConfig.usernameMaxLength) {
      return ValidationResult.invalid(
        '用户名长度不能超过${AuthConfig.usernameMaxLength}个字符'
      );
    }
    return ValidationResult.valid();
  }

  /// Validates password format
  /// 
  /// Password must be 6-20 characters long.
  /// **Property 3: Password Validation**
  /// **Validates: Requirements 2.2, 2.3**
  static ValidationResult validatePassword(String password) {
    if (password.length < AuthConfig.passwordMinLength) {
      return ValidationResult.invalid(
        '密码长度不能少于${AuthConfig.passwordMinLength}个字符'
      );
    }
    if (password.length > AuthConfig.passwordMaxLength) {
      return ValidationResult.invalid(
        '密码长度不能超过${AuthConfig.passwordMaxLength}个字符'
      );
    }
    return ValidationResult.valid();
  }


  /// Registers a new user
  /// 
  /// Returns failure if username already exists or validation fails.
  /// **Property 4: Duplicate Username Prevention**
  /// **Validates: Requirements 2.2, 2.4**
  Future<AuthResult> register(String username, String password) async {
    // Validate username
    final usernameValidation = validateUsername(username);
    if (!usernameValidation.isValid) {
      return AuthResult.failure(usernameValidation.errorMessage);
    }

    // Validate password
    final passwordValidation = validatePassword(password);
    if (!passwordValidation.isValid) {
      return AuthResult.failure(passwordValidation.errorMessage);
    }

    // Check for duplicate username
    final users = await _getUsers();
    if (users.any((u) => u.username == username)) {
      return AuthResult.failure('用户名已存在');
    }

    // Create and save new user
    final newUser = User.create(username: username, password: password);
    users.add(newUser);
    await _saveUsers(users);

    return AuthResult.success();
  }

  /// Logs in a user with credentials
  /// 
  /// Returns failure with generic message if credentials are invalid.
  /// **Property 5: Login Credential Verification**
  /// **Validates: Requirements 3.1, 3.2**
  Future<AuthResult> login(String username, String password) async {
    final users = await _getUsers();
    
    // Find user by username
    final user = users.where((u) => u.username == username).firstOrNull;
    
    if (user == null || !user.verifyPassword(password)) {
      // Generic error message to not reveal which credential is wrong
      return AuthResult.failure('用户名或密码错误');
    }

    // Store session
    await _prefs.setString(StorageKeys.currentUser, username);
    await _prefs.setString(
      StorageKeys.sessionToken, 
      _generateSessionToken(username)
    );

    return AuthResult.success();
  }

  /// Logs out the current user
  /// 
  /// Clears session data from storage.
  /// **Property 7: Logout Clears Session**
  /// **Validates: Requirements 3.5**
  Future<void> logout() async {
    await _prefs.remove(StorageKeys.currentUser);
    await _prefs.remove(StorageKeys.sessionToken);
  }

  /// Checks if a user is currently logged in
  /// 
  /// **Property 6: Session Persistence Round-Trip**
  /// **Validates: Requirements 3.4**
  Future<bool> isLoggedIn() async {
    final currentUser = _prefs.getString(StorageKeys.currentUser);
    final sessionToken = _prefs.getString(StorageKeys.sessionToken);
    
    if (currentUser == null || sessionToken == null) {
      return false;
    }

    // Verify session token is valid
    final expectedToken = _generateSessionToken(currentUser);
    return sessionToken == expectedToken;
  }

  /// Gets the current logged-in username
  Future<String?> getCurrentUser() async {
    if (await isLoggedIn()) {
      return _prefs.getString(StorageKeys.currentUser);
    }
    return null;
  }

  /// Gets all registered users from storage
  Future<List<User>> _getUsers() async {
    final usersJson = _prefs.getString(StorageKeys.users);
    if (usersJson == null) {
      return [];
    }

    try {
      final List<dynamic> usersList = jsonDecode(usersJson);
      return usersList
          .map((json) => User.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Saves users list to storage
  Future<void> _saveUsers(List<User> users) async {
    final usersJson = jsonEncode(users.map((u) => u.toJson()).toList());
    await _prefs.setString(StorageKeys.users, usersJson);
  }

  /// Generates a session token for a user
  String _generateSessionToken(String username) {
    // Simple token generation - in production, use more secure method
    final data = '$username:fire_alarm_session';
    final bytes = utf8.encode(data);
    return base64Encode(bytes);
  }
}
