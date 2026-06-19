import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:nofak/app/routes.dart';
import 'package:nofak/data/cubits/item/manage_item_cubit.dart';
import 'package:nofak/data/model/item/item_model.dart';
import 'package:nofak/data/model/localized_string.dart';
import 'package:nofak/data/model/location/leaf_location.dart';
import 'package:nofak/ui/screens/item/my_item_tab_screen.dart';
import 'package:nofak/ui/screens/widgets/location_map/location_map_controller.dart';
import 'package:nofak/ui/screens/widgets/location_map/location_map_widget.dart';
import 'package:nofak/ui/theme/theme.dart';
import 'package:nofak/utils/app_icon.dart';
import 'package:nofak/utils/cloud_state/cloud_state.dart';
import 'package:nofak/utils/constant.dart';
import 'package:nofak/utils/custom_text.dart';
import 'package:nofak/utils/extensions/extensions.dart';
import 'package:nofak/utils/helper_utils.dart';
import 'package:nofak/utils/hive_utils.dart';
import 'package:nofak/ui/screens/widgets/blurred_dialog_box.dart';
import 'package:nofak/utils/ui_utils.dart';
import 'package:nofak/utils/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:nofak/data/repositories/item/advertisement_repository.dart';
import 'package:shimmer/shimmer.dart';
import 'package:nofak/data/cubits/auth/user_profile_cubit.dart';
import 'package:nofak/data/cubits/system/user_details.dart';
import 'package:nofak/data/cubits/system/fetch_system_settings_cubit.dart';
import 'package:nofak/data/model/user/user_model.dart';


class ConfirmLocationScreen extends StatefulWidget {
  final bool? isEdit;
  final File? mainImage;
  final List<File>? otherImage;
  final File? video;

  const ConfirmLocationScreen({
    Key? key,
    required this.isEdit,
    required this.mainImage,
    required this.otherImage,
    this.video,
  }) : super(key: key);

  @override
  State<ConfirmLocationScreen> createState() => _ConfirmLocationScreenState();

  static MaterialPageRoute route(RouteSettings settings) {
    Map? arguments = settings.arguments as Map?;

    return MaterialPageRoute(
      builder: (context) {
        return BlocProvider(
          create: (context) => ManageItemCubit(),
          child: ConfirmLocationScreen(
            isEdit: arguments?['isEdit'] ?? false,
            mainImage: arguments?['mainImage'],
            otherImage: arguments?['otherImage'],
            video: arguments?['video'],
          ),
        );
      },
    );
  }
}

class _ConfirmLocationScreenState extends CloudState<ConfirmLocationScreen> {
  LeafLocation _location = LeafLocation();

  late final LocationMapController _controller;

  @override
  void initState() {
    super.initState();
    context.read<FetchSystemSettingsCubit>().fetchSettings(forceRefresh: true);
    if (widget.isEdit ?? false) {
      final item = getCloudData('edit_request') as ItemModel?;
      if (item != null && item.latitude != null && item.longitude != null) {
        final location = LeafLocation(
          latitude: item.latitude,
          longitude: item.longitude,
          country: item.country != null
              ? LocalizedString(canonical: item.country!)
              : null,
          state: item.state != null
              ? LocalizedString(canonical: item.state!)
              : null,
          city: item.city != null
              ? LocalizedString(canonical: item.city!)
              : null,
          area: item.area != null
              ? LocalizedString(canonical: item.area!)
              : null,
        );
        _controller = LocationMapController(
          initialCoordinates: LatLng(item.latitude!, item.longitude!),
          initialLocation: location,
        );
      }
    } else {
      _controller = LocationMapController();
    }

    _controller.addListener(() {
      _location = _controller.data.location;
    });

    // Initialize the controller (sets initial location from Hive or default)
    _controller.init();

    if (!(widget.isEdit ?? false)) {
      // Always fetch live GPS for new ads — never rely on stale Hive cache
      _controller.getLocation(context);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) async {
        return;
      },
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        appBar: UiUtils.buildAppBar(
          context,
          onBackPress: () {
            Navigator.pop(context);
          },
          showBackButton: true,
          title: "confirmLocation".translate(context),
        ),
        bottomNavigationBar: ListenableBuilder(
          listenable: _controller,
          builder: (context, child) {
            return BlocConsumer<ManageItemCubit, ManageItemState>(
              listener: (context, state) {
                if (state is ManageItemInProgress) {
                  LoadingWidgets.showLoader(context);
                } else if (state is ManageItemSuccess) {
                  LoadingWidgets.hideLoader(context);
                  addCloudData('is_submitting', true);
                  HiveUtils.clearAddItemDraft();

                  // Refresh user profile and credit balance after successfully adding/editing an item
                  context.read<UserProfileCubit>().getUserProfile().then((_) {
                    context.read<UserDetailsCubit>().fill(HiveUtils.getUserDetails());
                  });

                  if (widget.isEdit == true) {
                    myAdsCubitReference[getCloudData("edit_from")]?.editAds(
                      state.model,
                    );
                  } else {
                    myAdsCubitReference[getCloudData("edit_from")]?.addItem(
                      state.model,
                    );
                  }

                  Navigator.pushNamed(
                    context,
                    Routes.successItemScreen,
                    arguments: {'model': state.model, 'isEdit': widget.isEdit},
                  );
                } else if (state is ManageItemFail) {
                  LoadingWidgets.hideLoader(context);
                  addCloudData('is_submitting', false);
                  // DEBUG: Show actual server error to diagnose the issue
                  log('ManageItemFail error: ${state.error}', name: 'ConfirmLocation');
                  HelperUtils.showSnackBarMessage(
                    context,
                    'Server error: ${state.error}',
                    type: MessageType.error,
                    messageDuration: 10,
                  );
                }
              },
              builder: (context, state) {
                return UiUtils.buildButton(
                  context,
                  outerPadding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).padding.bottom + 10,
                    left: 18.0,
                    right: 18,
                  ),
                  onTapDisabledButton: () {
                    HelperUtils.showSnackBarMessage(
                      context,
                      'Invalid Location',
                    );
                  },
                  onPressed: () async {
                    if (context.read<ManageItemCubit>().state
                        is ManageItemInProgress) {
                      return; // Prevent multiple API calls
                    }

                    try {
                      Map<String, dynamic> cloudData =
                          getCloudData("with_more_details") ?? {};

                      cloudData['address'] = _location.canonicalPath;
                      if (_location.latitude != null)
                        cloudData['latitude'] = _location.latitude;
                      if (_location.longitude != null)
                        cloudData['longitude'] = _location.longitude;
                      cloudData['country'] = _location.country?.canonical;
                      cloudData['city'] = _location.city?.canonical;
                      cloudData['state'] = _location.state?.canonical;
                      cloudData['area'] = _location.area?.canonical;

                      // Validate files exist before proceeding
                      if (widget.mainImage != null && !await widget.mainImage!.exists()) {
                        UiUtils.showError(context, "Main image file not found. Please go back and re-select.");
                        return;
                      }
                      if (widget.otherImage != null) {
                        for (var img in widget.otherImage!) {
                          if (!await img.exists()) {
                            UiUtils.showError(context, "One or more gallery images are missing. Please go back and re-select.");
                            return;
                          }
                        }
                      }
                      if (widget.video != null && !await widget.video!.exists()) {
                         UiUtils.showError(context, "Video file not found. Please go back and re-select.");
                         return;
                      }
                      if (widget.isEdit ?? false) {
                        addCloudData('is_submitting', true);
                        context.read<ManageItemCubit>().manage(
                          ManageItemType.edit,
                          cloudData,
                          widget.mainImage,
                          widget.otherImage!,
                          widget.video,
                        );
                        return;
                      } else {
                        // Credit-based monetization check (Spec 3.2 & 5.1)
                        UserModel userAuth = HiveUtils.getUserDetails();
                        int postAdDeduction = int.tryParse(context.read<FetchSystemSettingsCubit>().getRawSettings()['post_ad_deduction']?.toString() ?? '20') ?? 20;
                        int credits = userAuth.credits ?? 0;

                        if (credits < postAdDeduction) {
                          UiUtils.insufficientCreditsDialog(context);
                          return;
                        }

                        if (credits < 25) {
                          var acceptWarning = await UiUtils.showBlurredDialoge(
                            context,
                            dialoge: BlurredDialogBox(
                              title: "Low Credit Warning".translate(context),
                              content: CustomText(
                                "Your credit balance is low ($credits credits). Posting this ad will deduct $postAdDeduction credits, leaving you with ${credits - postAdDeduction} credits. Do you want to proceed?"
                                    .translate(context),
                              ),
                              showCancelButton: true,
                              acceptButtonName: "Proceed".translate(context),
                              cancelButtonName: "Cancel".translate(context),
                            ),
                          );
                          if (acceptWarning != true) {
                            return;
                          }
                        }

                        var accept = await UiUtils.showBlurredDialoge(
                          context,
                          dialoge: BlurredDialogBox(
                            title: "postNow".translate(context),
                            content: CustomText("postConfirmMsg".translate(context)),
                            showCancelButton: true,
                          ),
                        );
                        if (accept == true) {
                          addCloudData('is_submitting', true);
                          context.read<ManageItemCubit>().manage(
                            ManageItemType.add,
                            cloudData,
                            widget.mainImage!,
                            widget.otherImage!,
                            widget.video,
                          );
                        }
                        return;
                      }
                    } catch (e, st) {
                      log('$e', name: 'Add Item');
                      log('$st', name: 'Add Item');
                    }
                  },
                  height: 48,
                  fontSize: context.font.large,
                  autoWidth: false,
                  radius: 8,
                  disabledColor: const Color.fromARGB(255, 104, 102, 106),
                  disabled: !_location.isValid || _controller.isGeocoding,
                  width: double.maxFinite,
                  buttonTitle: _controller.isGeocoding
                      ? "locating".translate(context)
                      : "postNow".translate(context),
                );
              },
            );
          },
        ),
        body: bodyData(),
      ),
    );
  }

  Widget bodyData() {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, child) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Expanded(
              child: LocationMapWidget(
                controller: _controller,
                showCircleArea: false,
              ),
            ),
            if (_controller.isReady)
              ColoredBox(
                color: context.color.backgroundColor,
                child: Padding(
                  padding: Constant.appContentPadding.copyWith(
                    top: 16,
                    bottom: 16,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 5,
                    children: [
                      SvgPicture.asset(
                        AppIcons.location,
                        height: 20,
                        width: 20,
                        colorFilter: ColorFilter.mode(
                          context.color.territoryColor,
                          BlendMode.srcIn,
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (_location.primaryText != null)
                              CustomText(
                                _location.primaryText!,
                                color: context.color.textColorDark,
                                fontSize: context.font.normal,
                                fontWeight: FontWeight.w600,
                              ),
                            if (_location.secondaryText != null)
                              CustomText(
                                _location.secondaryText!,
                                softWrap: true,
                                overflow: TextOverflow.ellipsis,
                                fontSize: context.font.small,
                                maxLines: 2,
                              ),
                          ],
                        ),
                      ),
                      if (Constant.mapProvider == 'free_api')
                        FilledButton(
                          onPressed: () async {
                            final location =
                                await Navigator.of(context).pushNamed(
                                      Routes.locationScreen,
                                      arguments: {
                                        'requires_exact_location': true,
                                      },
                                    )
                                    as LeafLocation?;
                            if (location == null) return;
                            _controller.updateLocation(location);
                          },
                          style: FilledButton.styleFrom(
                            backgroundColor: context.color.territoryColor
                                .withValues(alpha: .1),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                            minimumSize: Size(70, 20),
                            fixedSize: Size(70, 25),
                            padding: EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 8,
                            ),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            visualDensity: VisualDensity.compact,
                          ),
                          child: CustomText(
                            'change'.translate(context),
                            color: context.color.territoryColor,
                            fontSize: context.font.small,
                          ),
                        ),
                    ],
                  ),
                ),
              )
            else
              shimmerEffect(),
          ],
        );
      },
    );
  }

  Widget shimmerEffect() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 5,
        children: [
          Padding(
            padding: Constant.appContentPadding,
            child: Shimmer.fromColors(
              baseColor: Theme.of(context).colorScheme.shimmerBaseColor,
              highlightColor: Theme.of(
                context,
              ).colorScheme.shimmerHighlightColor,
              child: Container(
                margin: EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: Colors.grey,
                ),
                height: 20,
                width: MediaQuery.of(context).size.width * .5,
              ),
            ),
          ),
          Padding(
            padding: Constant.appContentPadding,
            child: Shimmer.fromColors(
              baseColor: Theme.of(context).colorScheme.shimmerBaseColor,
              highlightColor: Theme.of(
                context,
              ).colorScheme.shimmerHighlightColor,
              child: Container(
                margin: EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: Colors.grey,
                ),
                height: 20,
                width: MediaQuery.of(context).size.width,
              ),
            ),
          ),
        ],
      ),
    );
  }
}