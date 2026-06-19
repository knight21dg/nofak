// ignore_for_file: file_names

import 'package:nofak/utils/extensions/extensions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';

class ErrorFilter {
  final dynamic error;
  ErrorFilter(this.error);

  static final Map<String, String> _errorKeyMap = {
    "network-request-failed": "networkRequestFailed",
    "app-not-authorized": "appNotAuthorized",
    "no-internet": "checkNetwork",
    "email-already-in-use": "emailAlreadyInUse",
    "wrong-password": "wrongPassword",
    "user-not-found": "emailNotRegistered",
    "invalid-email": "invalidEmail",
    "invalid-phone-number": "invalidPhoneNumber",
    "invalid-verification-code": "invalidVerificationCode",
    "session-expired": "sessionExpired",
    "too-many-requests": "tooManyRequests",
    "user-disabled": "userDisabled",
    "operation-not-allowed": "operationNotAllowed",
    "invalid-credential": "invalidCredential",
    "account-exists-with-different-credential": "accountExistsWithDifferentCredential",
    "invalid-user-token": "invalidUserToken",
    "web-context-cancelled": "webContextCancelled",
    "user-mismatch": "userMismatch",
    "credential-already-in-use": "credentialAlreadyInUse",
    "requires-recent-login": "requiresRecentLogin",
    "weak-password": "weakPassword",
    "expired-action-code": "expiredActionCode",
    "invalid-action-code": "invalidActionCode",
    "server-not-available": "serverNotAvailable",
    "user-token-expired": "userTokenExpired",
    "null-value": "fieldMustNotBeEmpty",
    "invalid-verification-id": "invalidVerificationId",
    "captcha-check-failed": "captchaCheckFailed",
    "user-signed-out": "userSignedOut",
    "account-locked": "accountLocked",
    "missing-email": "missingEmail",
    "missing-password": "missingPassword",
    "mismatch-password": "mismatchPassword",
  };

  /// Returns the translated message based on any error type
  static String getTranslatedFirebaseAuthException(
    BuildContext context, {
    required dynamic error,
  }) {
    // If it's a Firebase Auth specific exception
    if (error is FirebaseAuthException) {
      final errorKey = _errorKeyMap[error.code];
      if (errorKey != null) {
        return errorKey.translate(context);
      }
      return error.message ?? error.code.translate(context);
    }

    // Handle common string-based error keys
    if (error is String) {
      if (_errorKeyMap.containsKey(error)) {
        return _errorKeyMap[error]!.translate(context);
      }
      // If it looks like a technical error with a status code
      if (error.contains("Something went wrong with error")) {
        return "somethingWentWrong".translate(context);
      }
      return error.translate(context);
    }

    // Fallback for any other objects
    String errorString = error.toString();
    
    // Strip "Exception: " or "ApiException: " prefixes for cleaner messages
    if (errorString.startsWith("Exception: ")) {
      errorString = errorString.replaceFirst("Exception: ", "");
    } else if (errorString.startsWith("ApiException: ")) {
      errorString = errorString.replaceFirst("ApiException: ", "");
    }

    if (_errorKeyMap.containsKey(errorString)) {
      return _errorKeyMap[errorString]!.translate(context);
    }

    // If it's still a non-empty string that doesn't look like an object description, return it
    if (errorString.isNotEmpty && !errorString.contains("Instance of '")) {
      return errorString.translate(context);
    }

    return "somethingWentWrong".translate(context);
  }

  /// Returns just the error key (e.g., "userNotFound") for internal use or logging
  static String getErrorKeyFromFirebaseAuthException(
    FirebaseAuthException error,
  ) {
    return _errorKeyMap[error.code] ?? error.message ?? error.code;
  }
}
