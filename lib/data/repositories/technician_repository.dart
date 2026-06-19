import 'package:nofak/utils/api.dart';
import 'package:nofak/data/model/data_output.dart';
import 'package:nofak/data/model/user/user_model.dart';
import 'package:nofak/data/model/user/job_request_model.dart';

class TechnicianRepository {
  /// Fetch list of nearby verified/active technicians
  Future<DataOutput<UserModel>> fetchTechnicians({
    double? lat,
    double? lng,
    String? category,
    String? search,
    String? sortBy,
    required int page,
  }) async {
    try {
      final Map<String, dynamic> parameters = {
        'page': page,
        if (lat != null) 'lat': lat,
        if (lng != null) 'lng': lng,
        if (category != null && category.isNotEmpty) 'category': category,
        if (search != null && search.isNotEmpty) 'search': search,
        if (sortBy != null && sortBy.isNotEmpty) 'sort_by': sortBy,
      };

      final response = await Api.get(
        url: Api.getTechniciansApi,
        queryParameters: parameters,
      );

      final int total = response['data']['total'] ?? 0;
      final List<UserModel> technicians = (response['data']['data'] as List)
          .map((e) => UserModel.fromJson(e))
          .toList();

      return DataOutput(
        total: total,
        modelList: technicians,
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Update availability status and options
  Future<UserModel> updateAvailability({
    required String availabilityStatus,
    double? latitude,
    double? longitude,
    String? address,
    double? serviceRadius,
    String? skills,
  }) async {
    try {
      final Map<String, dynamic> parameters = {
        'availability_status': availabilityStatus,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
        if (address != null) 'address': address,
        if (serviceRadius != null) 'service_radius': serviceRadius,
        if (skills != null) 'skills': skills,
      };

      final response = await Api.post(
        url: Api.updateAvailabilityApi,
        parameter: parameters,
      );

      return UserModel.fromJson(response['data']);
    } catch (e) {
      rethrow;
    }
  }

  /// Send a new job request to a technician
  Future<JobRequestModel> sendJobRequest({
    required int technicianId,
    required String description,
    String? address,
    double? latitude,
    double? longitude,
    double? proposedFee,
  }) async {
    try {
      final Map<String, dynamic> parameters = {
        'technician_id': technicianId,
        'description': description,
        if (address != null) 'address': address,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
        if (proposedFee != null) 'proposed_fee': proposedFee,
      };

      final response = await Api.post(
        url: Api.sendJobRequestApi,
        parameter: parameters,
      );

      return JobRequestModel.fromJson(response['data']);
    } catch (e) {
      rethrow;
    }
  }

  /// Get job requests list (either sent or received)
  Future<DataOutput<JobRequestModel>> getJobRequests({
    required String role,
    String? status,
    required int page,
  }) async {
    try {
      final Map<String, dynamic> parameters = {
        'role': role,
        'page': page,
        if (status != null && status.isNotEmpty) 'status': status,
      };

      final response = await Api.get(
        url: Api.getJobRequestsApi,
        queryParameters: parameters,
      );

      final int total = response['data']['total'] ?? 0;
      final List<JobRequestModel> jobs = (response['data']['data'] as List)
          .map((e) => JobRequestModel.fromJson(e))
          .toList();

      return DataOutput(
        total: total,
        modelList: jobs,
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Update job request status (and optionally submit rating/review)
  Future<JobRequestModel> updateJobRequestStatus({
    required int jobId,
    required String status,
    int? rating,
    String? review,
  }) async {
    try {
      final Map<String, dynamic> parameters = {
        'job_id': jobId,
        'status': status,
        if (rating != null) 'rating': rating,
        if (review != null) 'review': review,
      };

      final response = await Api.post(
        url: Api.updateJobRequestStatusApi,
        parameter: parameters,
      );

      return JobRequestModel.fromJson(response['data']);
    } catch (e) {
      rethrow;
    }
  }
}
