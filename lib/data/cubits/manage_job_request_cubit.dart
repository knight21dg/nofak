import 'package:nofak/data/model/user/job_request_model.dart';
import 'package:nofak/data/repositories/technician_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

abstract class ManageJobRequestState {}

class ManageJobRequestInitial extends ManageJobRequestState {}

class ManageJobRequestInProgress extends ManageJobRequestState {}

class ManageJobRequestSubmitSuccess extends ManageJobRequestState {
  final JobRequestModel jobRequest;
  ManageJobRequestSubmitSuccess(this.jobRequest);
}

class ManageJobRequestUpdateSuccess extends ManageJobRequestState {
  final JobRequestModel jobRequest;
  ManageJobRequestUpdateSuccess(this.jobRequest);
}

class ManageJobRequestFailure extends ManageJobRequestState {
  final String errorMessage;
  ManageJobRequestFailure(this.errorMessage);
}

class ManageJobRequestCubit extends Cubit<ManageJobRequestState> {
  final TechnicianRepository _repository = TechnicianRepository();

  ManageJobRequestCubit() : super(ManageJobRequestInitial());

  Future<void> submitJobRequest({
    required int technicianId,
    required String description,
    String? address,
    double? latitude,
    double? longitude,
    double? proposedFee,
  }) async {
    try {
      emit(ManageJobRequestInProgress());
      final JobRequestModel result = await _repository.sendJobRequest(
        technicianId: technicianId,
        description: description,
        address: address,
        latitude: latitude,
        longitude: longitude,
        proposedFee: proposedFee,
      );
      emit(ManageJobRequestSubmitSuccess(result));
    } catch (e) {
      emit(ManageJobRequestFailure(e.toString()));
    }
  }

  Future<void> updateJobRequestStatus({
    required int jobId,
    required String status,
    int? rating,
    String? review,
  }) async {
    try {
      emit(ManageJobRequestInProgress());
      final JobRequestModel result = await _repository.updateJobRequestStatus(
        jobId: jobId,
        status: status,
        rating: rating,
        review: review,
      );
      emit(ManageJobRequestUpdateSuccess(result));
    } catch (e) {
      emit(ManageJobRequestFailure(e.toString()));
    }
  }
}
