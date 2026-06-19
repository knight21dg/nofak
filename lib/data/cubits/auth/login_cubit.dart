import 'dart:io';

import 'package:nofak/data/cubits/auth/authentication_cubit.dart';
import 'package:nofak/data/repositories/auth_repository.dart';
import 'package:nofak/utils/api.dart';
import 'package:nofak/utils/hive_utils.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/foundation.dart';

/// States for the login operation
abstract class LoginState {
  const LoginState();
}

/// Initial state when no login operation has been performed
class LoginInitial extends LoginState {
  const LoginInitial();
}

/// State indicating that the login operation is in progress
class LoginInProgress extends LoginState {
  const LoginInProgress();
}

/// State indicating successful login
class LoginSuccess extends LoginState {
  final bool isProfileCompleted;
  final dynamic credential;
  final Map<String, dynamic> apiResponse;

  const LoginSuccess({
    required this.isProfileCompleted,
    required this.credential,
    required this.apiResponse,
  });
}

/// State indicating failure in login
class LoginFailure extends LoginState {
  final dynamic errorMessage;

  const LoginFailure(this.errorMessage);
}

/// Cubit responsible for handling login operations
class LoginCubit extends Cubit<LoginState> {
  final AuthRepository _authRepository;
  final FirebaseAuth _firebaseAuth;
  final FirebaseMessaging _firebaseMessaging;

  /// Creates a new instance of [LoginCubit]
  LoginCubit({
    AuthRepository? authRepository,
    FirebaseAuth? firebaseAuth,
    FirebaseMessaging? firebaseMessaging,
  })  : _authRepository = authRepository ?? AuthRepository(),
        _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
        _firebaseMessaging = firebaseMessaging ?? FirebaseMessaging.instance,
        super(const LoginInitial());

  /// Gets the device token for push notifications
  Future<String?> getDeviceToken() async {
    try {
      if (Platform.isIOS) {
        return await _firebaseMessaging.getAPNSToken();
      }
      return await _firebaseMessaging.getToken();
    } catch (e) {
      return null;
    }
  }

  /// Handles the login process
  Future<void> login({
    String? phoneNumber,
    required String firebaseUserId,
    required String type,
    required UserCredential credential,
    String? countryCode,
    String? referralCode,
  }) async {
    try {
      emit(const LoginInProgress());

      final token = await _getFCMToken();
      final user = await _getUpdatedUser(type, credential);
      final name = _getUserName(type, user, credential);

      final hasProviderData = credential.user?.providerData != null &&
          credential.user!.providerData.isNotEmpty;

      final phoneVal = phoneNumber ??
          (hasProviderData ? credential.user!.providerData[0].phoneNumber : null) ??
          credential.user?.phoneNumber;

      final emailVal = (hasProviderData ? credential.user!.providerData[0].email : null) ??
          credential.user?.email;

      final profileVal = (hasProviderData ? credential.user!.providerData[0].photoURL : null) ??
          credential.user?.photoURL;

      final result = await _authRepository.numberLoginWithApi(
        phone: phoneVal,
        type: type,
        uid: firebaseUserId,
        fcmId: token,
        email: emailVal,
        name: name,
        profile: profileVal,
        countryCode: countryCode,
        referralCode: referralCode,
      );

      await _handleLoginResponse(result, credential);
    } catch (e) {
      emit(LoginFailure(e));
    }
  }

  /// Handles login with Twilio
  Future<void> loginWithTwilio({
    required String phoneNumber,
    required String firebaseUserId,
    required String type,
    required Map<String, dynamic> credential,
    required String countryCode,
    String? referralCode,
  }) async {
    try {
      emit(const LoginInProgress());
      final token = await _getFCMToken();

      if (_isValidTwilioCredential(credential)) {
        await _handleTwilioLoginResponse(credential);

        try {
          HiveUtils.setUserIsAuthenticated(true);
          await Api.post(
            url: Api.updateProfileApi,
            parameter: {
              Api.fcmId: token,
              Api.platformType: Platform.isAndroid ? "android" : "ios",
            },
          );
        } catch (_) {
          // FCM token registration is best-effort; don't block login
        }
        return;
      }

      final result = await _authRepository.numberLoginWithApi(
        phone: phoneNumber,
        type: type,
        uid: firebaseUserId,
        fcmId: token,
        email: null,
        name: null,
        profile: null,
        countryCode: countryCode,
        referralCode: referralCode,
      );

      await _handleLoginResponse(result, credential);
    } catch (e) {
      emit(LoginFailure(e));
    }
  }

  /// Gets FCM token with error handling
  Future<String?> _getFCMToken() async {
    try {
      return await _firebaseMessaging.getToken();
    } catch (_) {
      return '';
    }
  }

  /// Gets updated user information
  Future<User?> _getUpdatedUser(String type, UserCredential credential) async {
    if (type == AuthenticationType.apple.name) {
      final user = _firebaseAuth.currentUser;
      await credential.user!.reload();
      return user;
    }
    return null;
  }

  /// Gets user name based on authentication type
  String? _getUserName(String type, User? updatedUser, UserCredential credential) {
    final user = updatedUser ?? credential.user;
    if (user == null) return null;

    final hasProviderData = user.providerData.isNotEmpty;

    if (type == AuthenticationType.apple.name) {
      return user.displayName ??
          (hasProviderData ? user.providerData[0].displayName : null);
    }
    return (hasProviderData ? user.providerData[0].displayName : null) ??
        user.displayName;
  }

  /// Handles login response
  Future<void> _handleLoginResponse(
    Map<String, dynamic> result,
    dynamic credential,
  ) async {
    // debugPrint("_handleLoginResponse result: $result");
    HiveUtils.setJWT(result['token']);
    final data = result['data'];
    final isProfileCompleted = _isProfileCompleted(data);
    
    // debugPrint("_handleLoginResponse data: $data");
    // debugPrint("_handleLoginResponse isProfileCompleted: $isProfileCompleted");

    if (!isProfileCompleted) {
      HiveUtils.setProfileNotCompleted();
    }

    HiveUtils.setUserData(data);
    emit(LoginSuccess(
      apiResponse: Map<String, dynamic>.from(data),
      isProfileCompleted: isProfileCompleted,
      credential: credential,
    ));
  }

  /// Handles Twilio login response
  Future<void> _handleTwilioLoginResponse(Map<String, dynamic> credential) async {
    HiveUtils.setJWT(credential['token']);
    final data = credential['data'];
    final isProfileCompleted = _isProfileCompleted(data);

    if (!isProfileCompleted) {
      HiveUtils.setProfileNotCompleted();
    }

    HiveUtils.setUserData(data);
    emit(LoginSuccess(
      apiResponse: Map<String, dynamic>.from(data),
      isProfileCompleted: isProfileCompleted,
      credential: credential,
    ));
  }

  /// Checks if the profile is completed
  bool _isProfileCompleted(Map<String, dynamic> data) {
    return !(data['name'] == "" ||
        data['name'] == null);
  }

  /// Validates Twilio credential format
  bool _isValidTwilioCredential(Map<String, dynamic> credential) {
    return credential.containsKey('token') && credential.containsKey('data');
  }
}
