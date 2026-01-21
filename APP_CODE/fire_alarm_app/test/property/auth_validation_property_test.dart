import 'dart:math';
import 'package:glados/glados.dart';
import 'package:fire_alarm_app/services/auth_service.dart';
import 'package:fire_alarm_app/utils/constants.dart';

/// Custom generators for authentication validation testing

extension AuthGenerators on Any {
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

  /// Generates an invalid username (too short: 0-3 characters)
  Generator<String> get tooShortUsername {
    final random = Random();
    return any.nonEmptyLetters.map((s) {
      final maxLen = AuthConfig.usernameMinLength - 1;
      if (maxLen <= 0) return '';
      final len = random.nextInt(maxLen) + 1;
      return s.length >= len ? s.substring(0, len) : s;
    });
  }

  /// Generates an invalid username (too long: >20 characters)
  Generator<String> get tooLongUsername {
    return any.nonEmptyLetters.map((s) {
      final minLen = AuthConfig.usernameMaxLength + 1;
      if (s.length >= minLen) return s;
      return s.padRight(minLen, 'x');
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

  /// Generates an invalid password (too short: 0-5 characters)
  Generator<String> get tooShortPassword {
    final random = Random();
    return any.nonEmptyLetters.map((s) {
      final maxLen = AuthConfig.passwordMinLength - 1;
      if (maxLen <= 0) return '';
      final len = random.nextInt(maxLen) + 1;
      return s.length >= len ? s.substring(0, len) : s;
    });
  }

  /// Generates an invalid password (too long: >20 characters)
  Generator<String> get tooLongPassword {
    return any.nonEmptyLetters.map((s) {
      final minLen = AuthConfig.passwordMaxLength + 1;
      if (s.length >= minLen) return s;
      return s.padRight(minLen, '9');
    });
  }
}

void main() {
  // **Feature: mqtt-mobile-app, Property 2: Username Validation**
  // **Validates: Requirements 2.2, 2.3**
  //
  // *For any* string, if the string length is between 4 and 20 characters 
  // (inclusive), the username validation SHALL return valid; otherwise, 
  // it SHALL return invalid with an appropriate error message.

  Glados(any.validUsername).test(
    'Property 2: Valid usernames (4-20 chars) should pass validation',
    (username) {
      final result = AuthService.validateUsername(username);
      
      if (!result.isValid) {
        throw Exception(
          'Valid username "$username" (length: ${username.length}) was rejected: ${result.errorMessage}'
        );
      }
    },
  );

  Glados(any.tooShortUsername).test(
    'Property 2: Too short usernames (<4 chars) should fail validation',
    (username) {
      if (username.isEmpty) return;
      
      final result = AuthService.validateUsername(username);
      
      if (result.isValid) {
        throw Exception(
          'Too short username "$username" (length: ${username.length}) should have been rejected'
        );
      }
      if (result.errorMessage == null) {
        throw Exception('Error message should not be null for invalid username');
      }
    },
  );

  Glados(any.tooLongUsername).test(
    'Property 2: Too long usernames (>20 chars) should fail validation',
    (username) {
      final result = AuthService.validateUsername(username);
      
      if (result.isValid) {
        throw Exception(
          'Too long username "$username" (length: ${username.length}) should have been rejected'
        );
      }
      if (result.errorMessage == null) {
        throw Exception('Error message should not be null for invalid username');
      }
    },
  );

  // **Feature: mqtt-mobile-app, Property 3: Password Validation**
  // **Validates: Requirements 2.2, 2.3**
  //
  // *For any* string, if the string length is between 6 and 20 characters 
  // (inclusive), the password validation SHALL return valid; otherwise, 
  // it SHALL return invalid with an appropriate error message.

  Glados(any.validPassword).test(
    'Property 3: Valid passwords (6-20 chars) should pass validation',
    (password) {
      final result = AuthService.validatePassword(password);
      
      if (!result.isValid) {
        throw Exception(
          'Valid password (length: ${password.length}) was rejected: ${result.errorMessage}'
        );
      }
    },
  );

  Glados(any.tooShortPassword).test(
    'Property 3: Too short passwords (<6 chars) should fail validation',
    (password) {
      if (password.isEmpty) return;
      
      final result = AuthService.validatePassword(password);
      
      if (result.isValid) {
        throw Exception(
          'Too short password (length: ${password.length}) should have been rejected'
        );
      }
      if (result.errorMessage == null) {
        throw Exception('Error message should not be null for invalid password');
      }
    },
  );

  Glados(any.tooLongPassword).test(
    'Property 3: Too long passwords (>20 chars) should fail validation',
    (password) {
      final result = AuthService.validatePassword(password);
      
      if (result.isValid) {
        throw Exception(
          'Too long password (length: ${password.length}) should have been rejected'
        );
      }
      if (result.errorMessage == null) {
        throw Exception('Error message should not be null for invalid password');
      }
    },
  );
}
