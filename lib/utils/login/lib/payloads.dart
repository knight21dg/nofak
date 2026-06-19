abstract class LoginPayload {
  final String? referralCode;
  LoginPayload({this.referralCode});
}

class MultiLoginPayload {
  final Map<String, LoginPayload> payloads;

  MultiLoginPayload(this.payloads);
}

enum EmailLoginType { login, signup }

class EmailLoginPayload extends LoginPayload {
  final String email;
  final String password;
  final EmailLoginType type;

  EmailLoginPayload(
      {required this.email,
      required this.password,
      required this.type,
      String? referralCode})
      : super(referralCode: referralCode);
}

class GoogleLoginPayload extends LoginPayload {
  GoogleLoginPayload({String? referralCode})
      : super(referralCode: referralCode);
}

class AppleLoginPayload extends LoginPayload {
  AppleLoginPayload({String? referralCode}) : super(referralCode: referralCode);
}

class PhoneLoginPayload extends LoginPayload {
  final String phoneNumber;
  final String countryCode;
  String? otp;

  PhoneLoginPayload(this.phoneNumber, this.countryCode, {String? referralCode})
      : super(referralCode: referralCode);

  void setOTP(String value) {
    otp = value;
  }

  String? getOTP() {
    return otp;
  }
}
