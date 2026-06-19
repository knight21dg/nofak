import 'package:nofak/data/model/data_output.dart';
import 'package:nofak/data/model/user/job_request_model.dart';
import 'package:nofak/data/repositories/technician_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

abstract class FetchJobRequestsState {}

class FetchJobRequestsInitial extends FetchJobRequestsState {}

class FetchJobRequestsInProgress extends FetchJobRequestsState {}

class FetchJobRequestsSuccess extends FetchJobRequestsState {
  final List<JobRequestModel> jobs;
  final bool isLoadingMore;
  final bool loadingMoreError;
  final int page;
  final int total;

  FetchJobRequestsSuccess({
    required this.jobs,
    required this.isLoadingMore,
    required this.loadingMoreError,
    required this.page,
    required this.total,
  });

  FetchJobRequestsSuccess copyWith({
    List<JobRequestModel>? jobs,
    bool? isLoadingMore,
    bool? loadingMoreError,
    int? page,
    int? total,
  }) {
    return FetchJobRequestsSuccess(
      jobs: jobs ?? this.jobs,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      loadingMoreError: loadingMoreError ?? this.loadingMoreError,
      page: page ?? this.page,
      total: total ?? this.total,
    );
  }
}

class FetchJobRequestsFailure extends FetchJobRequestsState {
  final String errorMessage;
  FetchJobRequestsFailure(this.errorMessage);
}

class FetchJobRequestsCubit extends Cubit<FetchJobRequestsState> {
  final TechnicianRepository _repository = TechnicianRepository();

  FetchJobRequestsCubit() : super(FetchJobRequestsInitial());

  Future<void> fetchJobRequests({
    required String role,
    String? status,
  }) async {
    try {
      emit(FetchJobRequestsInProgress());
      final DataOutput<JobRequestModel> result = await _repository.getJobRequests(
        role: role,
        status: status,
        page: 1,
      );

      emit(FetchJobRequestsSuccess(
        jobs: result.modelList,
        isLoadingMore: false,
        loadingMoreError: false,
        page: 1,
        total: result.total,
      ));
    } catch (e) {
      emit(FetchJobRequestsFailure(e.toString()));
    }
  }

  Future<void> fetchMoreJobRequests({
    required String role,
    String? status,
  }) async {
    try {
      if (state is FetchJobRequestsSuccess) {
        final currentState = state as FetchJobRequestsSuccess;
        if (currentState.isLoadingMore || currentState.jobs.length >= currentState.total) {
          return;
        }

        emit(currentState.copyWith(isLoadingMore: true));

        final int nextPage = currentState.page + 1;
        final DataOutput<JobRequestModel> result = await _repository.getJobRequests(
          role: role,
          status: status,
          page: nextPage,
        );

        final List<JobRequestModel> updatedList = List.from(currentState.jobs)..addAll(result.modelList);

        emit(FetchJobRequestsSuccess(
          jobs: updatedList,
          isLoadingMore: false,
          loadingMoreError: false,
          page: nextPage,
          total: result.total,
        ));
      }
    } catch (e) {
      if (state is FetchJobRequestsSuccess) {
        emit((state as FetchJobRequestsSuccess).copyWith(
          isLoadingMore: false,
          loadingMoreError: true,
        ));
      }
    }
  }

  bool hasMoreData() {
    if (state is FetchJobRequestsSuccess) {
      final currentState = state as FetchJobRequestsSuccess;
      return currentState.jobs.length < currentState.total;
    }
    return false;
  }
}
