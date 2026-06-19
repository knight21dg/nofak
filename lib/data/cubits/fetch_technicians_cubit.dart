import 'package:nofak/data/model/data_output.dart';
import 'package:nofak/data/model/user/user_model.dart';
import 'package:nofak/data/repositories/technician_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

abstract class FetchTechniciansState {}

class FetchTechniciansInitial extends FetchTechniciansState {}

class FetchTechniciansInProgress extends FetchTechniciansState {}

class FetchTechniciansSuccess extends FetchTechniciansState {
  final List<UserModel> technicians;
  final bool isLoadingMore;
  final bool loadingMoreError;
  final int page;
  final int total;

  FetchTechniciansSuccess({
    required this.technicians,
    required this.isLoadingMore,
    required this.loadingMoreError,
    required this.page,
    required this.total,
  });

  FetchTechniciansSuccess copyWith({
    List<UserModel>? technicians,
    bool? isLoadingMore,
    bool? loadingMoreError,
    int? page,
    int? total,
  }) {
    return FetchTechniciansSuccess(
      technicians: technicians ?? this.technicians,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      loadingMoreError: loadingMoreError ?? this.loadingMoreError,
      page: page ?? this.page,
      total: total ?? this.total,
    );
  }
}

class FetchTechniciansFailure extends FetchTechniciansState {
  final String errorMessage;
  FetchTechniciansFailure(this.errorMessage);
}

class FetchTechniciansCubit extends Cubit<FetchTechniciansState> {
  final TechnicianRepository _repository = TechnicianRepository();

  FetchTechniciansCubit() : super(FetchTechniciansInitial());

  Future<void> fetchTechnicians({
    double? lat,
    double? lng,
    String? category,
    String? search,
    String? sortBy,
  }) async {
    try {
      emit(FetchTechniciansInProgress());
      final DataOutput<UserModel> result = await _repository.fetchTechnicians(
        lat: lat,
        lng: lng,
        category: category,
        search: search,
        sortBy: sortBy,
        page: 1,
      );

      emit(FetchTechniciansSuccess(
        technicians: result.modelList,
        isLoadingMore: false,
        loadingMoreError: false,
        page: 1,
        total: result.total,
      ));
    } catch (e) {
      emit(FetchTechniciansFailure(e.toString()));
    }
  }

  Future<void> fetchMoreTechnicians({
    double? lat,
    double? lng,
    String? category,
    String? search,
    String? sortBy,
  }) async {
    try {
      if (state is FetchTechniciansSuccess) {
        final currentState = state as FetchTechniciansSuccess;
        if (currentState.isLoadingMore || currentState.technicians.length >= currentState.total) {
          return;
        }

        emit(currentState.copyWith(isLoadingMore: true));

        final int nextPage = currentState.page + 1;
        final DataOutput<UserModel> result = await _repository.fetchTechnicians(
          lat: lat,
          lng: lng,
          category: category,
          search: search,
          sortBy: sortBy,
          page: nextPage,
        );

        final List<UserModel> updatedList = List.from(currentState.technicians)..addAll(result.modelList);

        emit(FetchTechniciansSuccess(
          technicians: updatedList,
          isLoadingMore: false,
          loadingMoreError: false,
          page: nextPage,
          total: result.total,
        ));
      }
    } catch (e) {
      if (state is FetchTechniciansSuccess) {
        emit((state as FetchTechniciansSuccess).copyWith(
          isLoadingMore: false,
          loadingMoreError: true,
        ));
      }
    }
  }

  bool hasMoreData() {
    if (state is FetchTechniciansSuccess) {
      final currentState = state as FetchTechniciansSuccess;
      return currentState.technicians.length < currentState.total;
    }
    return false;
  }
}
