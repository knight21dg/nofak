import 'user_model.dart';

class JobRequestModel {
  int? id;
  int? userId;
  int? technicianId;
  String? status;
  String? address;
  double? latitude;
  double? longitude;
  String? description;
  double? proposedFee;
  int? rating;
  String? review;
  String? createdAt;
  String? updatedAt;
  UserModel? user;
  UserModel? technician;

  JobRequestModel({
    this.id,
    this.userId,
    this.technicianId,
    this.status,
    this.address,
    this.latitude,
    this.longitude,
    this.description,
    this.proposedFee,
    this.rating,
    this.review,
    this.createdAt,
    this.updatedAt,
    this.user,
    this.technician,
  });

  factory JobRequestModel.fromJson(Map<String, dynamic> json) {
    return JobRequestModel(
      id: json['id'],
      userId: json['user_id'] != null ? int.tryParse(json['user_id'].toString()) : null,
      technicianId: json['technician_id'] != null ? int.tryParse(json['technician_id'].toString()) : null,
      status: json['status'],
      address: json['address'],
      latitude: json['latitude'] != null ? double.tryParse(json['latitude'].toString()) : null,
      longitude: json['longitude'] != null ? double.tryParse(json['longitude'].toString()) : null,
      description: json['description'],
      proposedFee: json['proposed_fee'] != null ? double.tryParse(json['proposed_fee'].toString()) : null,
      rating: json['rating'] != null ? int.tryParse(json['rating'].toString()) : null,
      review: json['review'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
      user: json['user'] != null ? UserModel.fromJson(json['user']) : null,
      technician: json['technician'] != null ? UserModel.fromJson(json['technician']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'technician_id': technicianId,
      'status': status,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'description': description,
      'proposed_fee': proposedFee,
      'rating': rating,
      'review': review,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'user': user?.toJson(),
      'technician': technician?.toJson(),
    };
  }
}
