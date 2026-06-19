import 'dart:developer';

import 'package:nofak/data/repositories/item/renew_item_repository.dart';
import 'package:nofak/utils/api.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

abstract class RenewItemState {}

class RenewItemInitial extends RenewItemState {}

class RenewItemInProgress extends RenewItemState {}

class RenewItemInSuccess extends RenewItemState {
  final String responseMessage;

  RenewItemInSuccess(this.responseMessage);
}

class RenewItemFailure extends RenewItemState {
  final dynamic error;

  RenewItemFailure(this.error);
}

class RenewItemCubit extends Cubit<RenewItemState> {
  RenewItemCubit() : super(RenewItemInitial());
  RenewItemRepositoryRepository repository = RenewItemRepositoryRepository();

  void renewItem({required int itemId}) async {
    try {
      emit(RenewItemInProgress());

      final response = await repository.renewItem(
        itemId: itemId,
      );

      emit(RenewItemInSuccess(response['message']));
    } on Exception catch (e) {
      emit(RenewItemFailure(e.toString()));
    }
  }

  Future<void> renewMultiItems({
    required Iterable<int> ids,
  }) async {
    try {
      emit(RenewItemInProgress());

      final response = await repository.renewItem(
        itemIds: ids,
      );

      emit(RenewItemInSuccess(response['message']));
    } on Exception catch (e, stack) {
      log(e.toString(), name: 'renewMultiItems');
      log('$stack', name: 'renewMultiItems');
      throw ApiException(e.toString());
    }
  }
}

