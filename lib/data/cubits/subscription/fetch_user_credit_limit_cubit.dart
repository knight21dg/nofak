import 'package:nofak/data/repositories/item/advertisement_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

abstract class FetchUserCreditLimitState {}

class FetchUserCreditLimitInitial extends FetchUserCreditLimitState {}

class FetchUserCreditLimitInProgress extends FetchUserCreditLimitState {}

class FetchUserCreditLimitInSuccess extends FetchUserCreditLimitState {
  final String responseMessage;

  FetchUserCreditLimitInSuccess(this.responseMessage);
}

class FetchUserCreditLimitFailure extends FetchUserCreditLimitState {
  final dynamic error;

  FetchUserCreditLimitFailure(this.error);
}

class FetchUserCreditLimitCubit extends Cubit<FetchUserCreditLimitState> {
  FetchUserCreditLimitCubit() : super(FetchUserCreditLimitInitial());
  AdvertisementRepository repository = AdvertisementRepository();

  void fetchUserCreditLimit({required String type}) async {
    emit(FetchUserCreditLimitInProgress());

    repository.fetchUserCreditLimit(type: type).then((value) {
      print("CREDIT LIMIT RESPONSE: $value");
      emit(FetchUserCreditLimitInSuccess(value['message']));
    }).catchError((e) {
      print("CREDIT LIMIT ERROR: $e");
      emit(FetchUserCreditLimitFailure(e.toString()));
    });
  }
}

