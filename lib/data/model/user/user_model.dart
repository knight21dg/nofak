class UserModel {
  String? address;
  String? createdAt;
  int? customerTotalPost;
  String? email;
  String? fcmId;
  String? firebaseId;
  int? id;
  int? isActive;
  bool? isProfileCompleted;
  String? type;
  String? mobile;
  String? name;
  int? isPersonalDetailShow;
  int? notification;
  String? profile;
  String? token;
  String? updatedAt;
  int? isVerified;
  String? accountType;
  int? credits;
  String? introductionVideo;
  String? fieldOfExpertise;
  int? yearsOfExperience;
  int? isAddressVerified;
  String? referralCode;
  int? signupBonusAvailable;
  double? latitude;
  double? longitude;
  double? serviceRadius;
  String? availabilityStatus;
  String? skills;
  String? status;
  int? jobsCompleted;
  double? averageRating;
  double? distance;

  UserModel({this.address,
    this.createdAt,
    this.customerTotalPost,
    this.email,
    this.fcmId,
    this.firebaseId,
    this.id,
    this.isActive,
    this.isProfileCompleted,
    this.type,
    this.mobile,
    this.name,
    this.notification,
    this.profile,
    this.token,
    this.updatedAt,
    this.isPersonalDetailShow,
    this.isVerified,
    this.accountType,
    this.credits,
    this.introductionVideo,
    this.fieldOfExpertise,
    this.yearsOfExperience,
    this.isAddressVerified,
    this.referralCode,
    this.signupBonusAvailable,
    this.latitude,
    this.longitude,
    this.serviceRadius,
    this.availabilityStatus,
    this.skills,
    this.status,
    this.jobsCompleted,
    this.averageRating,
    this.distance});

  UserModel.fromJson(Map<String, dynamic> json) {
    address = json['address'];
    createdAt = json['created_at'];
    customerTotalPost = json['customertotalpost'] as int?;
    email = json['email'];
    fcmId = json['fcm_id'];
    firebaseId = json['firebase_id'];
    id = json['id'];
    isActive = json['isActive'] as int?;
    isProfileCompleted = json['isProfileCompleted'];
    type = json['type'];
    mobile = json['mobile'];
    name = json['name'];

    notification = (json['notification'] != null
        ? (json['notification'] is int)
        ? json['notification']
        : int.parse(json['notification'])
        : null);
    profile = json['profile'];
    token = json['token'];
    updatedAt = json['updated_at'];
    isVerified = json['is_verified'];
    isPersonalDetailShow = (json['show_personal_details'] != null
        ? (json['show_personal_details'] is int)
        ? json['show_personal_details']
        : int.parse(json['show_personal_details'])
        : null);
    accountType = json['account_type'];
    credits = json['credits'] != null
        ? (json['credits'] is int)
        ? json['credits']
        : int.parse(json['credits'])
        : 0;
    introductionVideo = json['introduction_video'];
    fieldOfExpertise = json['field_of_expertise'];
    yearsOfExperience = json['years_of_experience'] != null
        ? (json['years_of_experience'] is int)
        ? json['years_of_experience']
        : int.parse(json['years_of_experience'])
        : null;
    isAddressVerified = json['is_address_verified'] != null
        ? (json['is_address_verified'] is int)
        ? json['is_address_verified']
        : int.parse(json['is_address_verified'])
        : 0;
    referralCode = json['referral_code'];
    signupBonusAvailable = (json['signup_bonus_available'] != null
        ? (json['signup_bonus_available'] is int)
        ? json['signup_bonus_available']
        : int.parse(json['signup_bonus_available'])
        : 0);
    latitude = json['latitude'] != null ? double.tryParse(json['latitude'].toString()) : null;
    longitude = json['longitude'] != null ? double.tryParse(json['longitude'].toString()) : null;
    serviceRadius = json['service_radius'] != null ? double.tryParse(json['service_radius'].toString()) : null;
    availabilityStatus = json['availability_status'];
    skills = json['skills'];
    status = json['status'];
    jobsCompleted = json['jobs_completed'] != null ? int.tryParse(json['jobs_completed'].toString()) : null;
    averageRating = json['average_rating'] != null ? double.tryParse(json['average_rating'].toString()) : null;
    distance = json['distance'] != null ? double.tryParse(json['distance'].toString()) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['address'] = address;
    data['created_at'] = createdAt;
    data['customertotalpost'] = customerTotalPost;
    data['email'] = email;
    data['fcm_id'] = fcmId;
    data['firebase_id'] = firebaseId;
    data['id'] = id;
    data['isActive'] = isActive;
    data['isProfileCompleted'] = isProfileCompleted;
    data['type'] = type;
    data['mobile'] = mobile;
    data['name'] = name;
    data['notification'] = notification;
    data['profile'] = profile;
    data['token'] = token;
    data['updated_at'] = updatedAt;
    data['show_personal_details'] = isPersonalDetailShow;
    data['is_verified'] = isVerified;
    data['account_type'] = accountType;
    data['credits'] = credits;
    data['introduction_video'] = introductionVideo;
    data['field_of_expertise'] = fieldOfExpertise;
    data['years_of_experience'] = yearsOfExperience;
    data['is_address_verified'] = isAddressVerified;
    data['referral_code'] = referralCode;
    data['signup_bonus_available'] = signupBonusAvailable;
    data['latitude'] = latitude;
    data['longitude'] = longitude;
    data['service_radius'] = serviceRadius;
    data['availability_status'] = availabilityStatus;
    data['skills'] = skills;
    data['status'] = status;
    data['jobs_completed'] = jobsCompleted;
    data['average_rating'] = averageRating;
    data['distance'] = distance;
    return data;
  }

  @override
  String toString() {
    return 'UserModel(address: $address, createdAt: $createdAt, customertotalpost: $customerTotalPost, email: $email, fcmId: $fcmId, firebaseId: $firebaseId, id: $id, isActive: $isActive, isProfileCompleted: $isProfileCompleted, type: $type, mobile: $mobile, name: $name, profile: $profile, token: $token, updatedAt: $updatedAt,notification:$notification,isPersonalDetailShow:$isPersonalDetailShow,isVerified:$isVerified, accountType: $accountType, credits: $credits, referralCode: $referralCode)';
  }
}

class BuyerModel {
  int? id;
  String? name;
  String? profile;

  BuyerModel({this.id, this.name, this.profile});

  BuyerModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    profile = json['profile'];
  }

  BuyerModel. fromJobApplicationJson(Map<String, dynamic> json) {
    id = json['user_id'];
    name = json['full_name'];
    profile = '';
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['name'] = this.name;
    data['profile'] = this.profile;
    return data;
  }
}
