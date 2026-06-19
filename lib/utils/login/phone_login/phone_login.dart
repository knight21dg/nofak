import 'package:nofak/utils/api.dart';
import 'package:nofak/utils/constant.dart';
import 'package:nofak/utils/login/lib/login_status.dart';
import 'package:nofak/utils/login/lib/login_system.dart';
import 'package:nofak/utils/login/lib/payloads.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PhoneLogin extends LoginSystem {
  String? verificationId;
  String? phoneNumber;

  @override
  Future<UserCredential?> login() async {
    try {
      emit(MProgress());
      // (state);

      PhoneAuthCredential credential = PhoneAuthProvider.credential(
          verificationId: verificationId ?? "",
          smsCode: (payload as PhoneLoginPayload).getOTP()!);

      UserCredential userCredential =
          await firebaseAuth.signInWithCredential(credential);

      emit(MSuccess());

      return userCredential;
    } catch (e) {
      emit(MFail(e));
    }
    return null;
  }

  @override
  Future<void> requestVerification() async {
    emit(MOtpSendInProgress());

    try {
      await getTwilioOtp();
      super.requestVerification();
    } on ApiException catch (e) {
      emit(MFail(e.errorMessage));
    } catch (e) {
      emit(MFail(e.toString()));
    }
  }

  Future<Map<String, dynamic>> getTwilioOtp() async {
    phoneNumber = (payload as PhoneLoginPayload).countryCode +
        (payload as PhoneLoginPayload).phoneNumber;
    final parameters = {
      'number':
          "${(payload as PhoneLoginPayload).countryCode}${(payload as PhoneLoginPayload).phoneNumber}",
    };
    final response =
        await Api.get(url: Api.getTwilioOtp, queryParameters: parameters);

    return response;
  }

  @override
  void onEvent(MLoginState state) {}
}
