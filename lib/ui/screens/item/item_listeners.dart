import 'package:nofak/data/cubits/item/delete_item_cubit.dart';
import 'package:nofak/data/cubits/renew_item_cubit.dart';
import 'package:nofak/utils/extensions/extensions.dart';
import 'package:nofak/utils/helper_utils.dart';
import 'package:nofak/utils/ui_utils.dart';
import 'package:nofak/utils/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ItemListeners extends StatelessWidget {
  const ItemListeners({
    required this.child,
    required this.onComplete,
    super.key,
  });

  final Widget child;
  final ValueChanged<bool> onComplete;

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<RenewItemCubit, RenewItemState>(
          listener: (context, state) {
            if (state is RenewItemInProgress) {
              LoadingWidgets.showLoader(context);
            }
            if (state is RenewItemInSuccess) {
              LoadingWidgets.hideLoader(context);
              HelperUtils.showSnackBarMessage(
                context,
                state.responseMessage,
                type: MessageType.success,
              );
              onComplete(true);
            }
            if (state is RenewItemFailure) {
              LoadingWidgets.hideLoader(context);
              if (state.error.toString().toLowerCase().contains("credit") || 
                  state.error.toString().toLowerCase().contains("package")) {
                UiUtils.insufficientCreditsDialog(context);
              } else {
                HelperUtils.showSnackBarMessage(
                  context,
                  state.error,
                  type: MessageType.error,
                );
              }
              onComplete(false);
            }
          },
        ),
        BlocListener<DeleteItemCubit, DeleteItemState>(
          listener: (context, state) {
            if (state is DeleteItemInProgress) {
              LoadingWidgets.showLoader(context);
            }
            if (state is DeleteItemSuccess) {
              LoadingWidgets.hideLoader(context);
              HelperUtils.showSnackBarMessage(
                context,
                "deletedSuccessfully".translate(context),
                type: MessageType.success,
              );
              onComplete(true);
            }
            if (state is DeleteItemFailure) {
              LoadingWidgets.hideLoader(context);
              HelperUtils.showSnackBarMessage(
                context,
                state.errorMessage,
                type: MessageType.error,
              );
              onComplete(false);
            }
          },
        ),
      ],
      child: child,
    );
  }
}
