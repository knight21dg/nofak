import 'package:nofak/data/model/custom_field/custom_field_model.dart';
import 'package:nofak/data/repositories/seller/seller_verification_field_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

abstract class FetchSellerVerificationFieldState {}

class FetchSellerVerificationFieldInitial
    extends FetchSellerVerificationFieldState {}

class FetchSellerVerificationFieldInProgress
    extends FetchSellerVerificationFieldState {}

class FetchSellerVerificationFieldSuccess
    extends FetchSellerVerificationFieldState {
  final List<VerificationFieldModel> fields;

  FetchSellerVerificationFieldSuccess(this.fields);
}

class FetchSellerVerificationFieldFail
    extends FetchSellerVerificationFieldState {
  final dynamic error;

  FetchSellerVerificationFieldFail(this.error);
}

class FetchSellerVerificationFieldsCubit
    extends Cubit<FetchSellerVerificationFieldState> {
  FetchSellerVerificationFieldsCubit()
      : super(FetchSellerVerificationFieldInitial());
  final SellerVerificationFieldRepository sellerVerificationFieldRepository =
      SellerVerificationFieldRepository();

  void fetchSellerVerificationFields({String? type}) async {
    try {
      emit(FetchSellerVerificationFieldInProgress());
      List<VerificationFieldModel> result =
          await sellerVerificationFieldRepository.getSellerVerificationFields(type: type);

      emit(FetchSellerVerificationFieldSuccess(result));
    } catch (e) {
      emit(FetchSellerVerificationFieldFail(e.toString()));
    }
  }
}
