// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:nofak/data/model/data_output.dart';
import 'package:nofak/data/model/subscription/subscription_package_model.dart';
import 'package:nofak/data/repositories/subscription/subscription_repository.dart';
import 'package:nofak/utils/api.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

abstract class FetchFeaturedSubscriptionPackagesState {}

class FetchFeaturedSubscriptionPackagesInitial
    extends FetchFeaturedSubscriptionPackagesState {}

class FetchFeaturedSubscriptionPackagesInProgress
    extends FetchFeaturedSubscriptionPackagesState {}

class FetchFeaturedSubscriptionPackagesSuccess
    extends FetchFeaturedSubscriptionPackagesState {
  final List<SubscriptionPackageModel> subscriptionPackages;

  FetchFeaturedSubscriptionPackagesSuccess({
    required this.subscriptionPackages,
  });
}

class FetchFeaturedSubscriptionPackagesFailure
    extends FetchFeaturedSubscriptionPackagesState {
  final String errorMessage;

  FetchFeaturedSubscriptionPackagesFailure(this.errorMessage);
}

class FetchFeaturedSubscriptionPackagesCubit
    extends Cubit<FetchFeaturedSubscriptionPackagesState> {
  FetchFeaturedSubscriptionPackagesCubit()
    : super(FetchFeaturedSubscriptionPackagesInitial());
  final SubscriptionRepository _subscriptionRepository =
      SubscriptionRepository();

  Future<void> fetchPackages() async {
    try {
      emit(FetchFeaturedSubscriptionPackagesInProgress());
      DataOutput<SubscriptionPackageModel> result =
          await _subscriptionRepository.getSubscriptionPacakges(
            type: Api.advertisement,
          );
      emit(
        FetchFeaturedSubscriptionPackagesSuccess(
          subscriptionPackages: result.modelList,
        ),
      );
    } catch (e) {
      emit(FetchFeaturedSubscriptionPackagesFailure(e.toString()));
    }
  }
}
