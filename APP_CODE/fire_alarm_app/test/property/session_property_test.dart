import 'package:flutter_test/flutter_test.dart';
import 'package:glados/glados.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fire_alarm_app/services/auth_service.dart';
import 'package:fire_alarm_app/utils/constants.dart';

/// Custom generators for session and registration testing
extension SessionGenerators on Any {
  /// Generates a valid username (4-20 characters)
  Generator<String> get validUsername {
    return any.nonEmptyLetters.map((s) {
      final minLen = AuthConfig.usernameMinLength;
      final maxLen = AuthConfig.usernameMaxLength;
      if (s.length < minLen) {
        return s.padRight(minLen, 'a');
      } else if (s.length > maxLen) {
        return s.substring(0, maxLen);
      }
      return s;
    });
  }

  /// Generates a valid password (6-20 characters)
  Generator<String> get validPassword {
    return any.nonEmptyLetters.map((s) {
      final minLen = AuthConfig.passwordMinLength;
      final maxLen = AuthConfig.passwordMaxLength;
      if (s.length < minLen) {
        return s.padRight(minLen, '1');
      } else if (s.length > maxLen) {
        return s.substring(0, maxLen);
      }
      return s;
    });
  }

  /// Generates a different password (for testing wrong password scenarios)
  Generator<String> get differentPassword {
    return any.validPassword.map((p) => '${p}different');
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // **Feature: mqtt-mobile-app, Property 4: Duplicate Username Prevention**
  // **Validates: Requirements 2.4**
  //
  // *For any* username that has been successfully registered, attempting 
  // to register the same username again SHALL fail with a duplicate username error.

  Glados2(any.validUsername, any.validPassword).test(
    'Property 4: Duplicate username registration should fail',
    (username, password) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final authService = AuthService(prefs);

      // First registration should succeed
      final firstResult = await authService.register(username, password);
      if (!firstResult.success) {
        throw Exception('First registration should succeed: ${firstResult.errorMessage}');
      }

      // Second registration with same username should fail
      final secondResult = await authService.register(username, password);
      if (secondResult.success) {
        throw Exception('Duplicate username registration should fail');
      }
      if (secondResult.errorMessage == null) {
        throw Exception('Error message should not be null for duplicate username');
      }
    },
  );

  // **Feature: mqtt-mobile-app, Property 5: Login Credential Verification**
  // **Validates: Requirements 3.1, 3.2**
  //
  // *For any* registered user with username U and password P, logging in 
  // with credentials (U, P) SHALL succeed, and logging in with credentials 
  // (U, P') where P' ≠ P SHALL fail.

  Glados2(any.validUsername, any.validPassword).test(
    'Property 5: Login with correct credentials should succeed',
    (username, password) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final authService = AuthService(prefs);

      // Register user
      await authService.register(username, password);

      // Login with correct credentials should succeed
      final loginResult = await authService.login(username, password);
      if (!loginResult.success) {
        throw Exception('Login with correct credentials should succeed');
      }
    },
  );

  Glados3(any.validUsername, any.validPassword, any.differentPassword).test(
    'Property 5: Login with wrong password should fail',
    (username, correctPassword, wrongPassword) async {
      // Ensure passwords are actually different
      if (correctPassword == wrongPassword) return;

      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final authService = AuthService(prefs);

      // Register user
      await authService.register(username, correctPassword);

      // Login with wrong password should fail
      final loginResult = await authService.login(username, wrongPassword);
      if (loginResult.success) {
        throw Exception('Login with wrong password should fail');
      }
    },
  );

  // **Feature: mqtt-mobile-app, Property 6: Session Persistence Round-Trip**
  // **Validates: Requirements 3.3, 3.4**
  //
  // *For any* successful login, the session token stored after login SHALL 
  // allow session restoration without requiring re-authentication.

  Glados2(any.validUsername, any.validPassword).test(
    'Property 6: Session should persist after login',
    (username, password) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final authService = AuthService(prefs);

      // Register and login
      await authService.register(username, password);
      await authService.login(username, password);

      // Session should be active
      final isLoggedIn = await authService.isLoggedIn();
      if (!isLoggedIn) {
        throw Exception('Session should be active after login');
      }

      // Current user should match
      final currentUser = await authService.getCurrentUser();
      if (currentUser != username) {
        throw Exception('Current user should match logged in user');
      }
    },
  );

  // **Feature: mqtt-mobile-app, Property 7: Logout Clears Session**
  // **Validates: Requirements 3.5**
  //
  // *For any* logged-in user, after logout, the session state SHALL indicate 
  // not logged in and require re-authentication.

  Glados2(any.validUsername, any.validPassword).test(
    'Property 7: Logout should clear session',
    (username, password) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final authService = AuthService(prefs);

      // Register, login, then logout
      await authService.register(username, password);
      await authService.login(username, password);
      await authService.logout();

      // Session should be cleared
      final isLoggedIn = await authService.isLoggedIn();
      if (isLoggedIn) {
        throw Exception('Session should be cleared after logout');
      }

      // Current user should be null
      final currentUser = await authService.getCurrentUser();
      if (currentUser != null) {
        throw Exception('Current user should be null after logout');
      }
    },
  );
}
