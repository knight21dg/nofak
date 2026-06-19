// ignore_for_file: invalid_use_of_protected_member

import 'dart:async';
import 'dart:io';

import 'package:nofak/app/routes.dart';
import 'package:nofak/data/cubits/system/fetch_system_settings_cubit.dart';
import 'package:nofak/data/model/system_settings_model.dart';
import 'package:nofak/ui/screens/chat/chat_list_screen.dart';
import 'package:nofak/ui/screens/home/home_screen.dart';
import 'package:nofak/ui/screens/item/my_items_screen.dart';
import 'package:nofak/ui/screens/user_profile/profile_screen.dart';
import 'package:nofak/ui/screens/widgets/blurred_dialog_box.dart';
import 'package:nofak/ui/screens/home/category_list.dart';
import 'package:nofak/ui/screens/widgets/bottom_navigation_bar/custom_bottom_navigation_bar.dart';
import 'package:nofak/ui/screens/widgets/tutorial_overlay.dart';
import 'package:nofak/utils/tutorial_keys.dart';
import 'package:nofak/ui/screens/widgets/bottom_navigation_bar/diamond_fab.dart';
import 'package:nofak/ui/screens/widgets/maintenance_mode.dart';
import 'package:nofak/ui/theme/theme.dart';
import 'package:nofak/utils/app_icon.dart';
import 'package:nofak/utils/constant.dart';
import 'package:nofak/utils/custom_text.dart';
import 'package:nofak/utils/extensions/extensions.dart';
import 'package:nofak/utils/helper_utils.dart';
import 'package:nofak/utils/hive_utils.dart';
import 'package:nofak/utils/ui_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:nofak/utils/notification/notification_service.dart';
import 'package:url_launcher/url_launcher.dart';

Map<String, dynamic> searchBody = {};
String selectedCategoryId = "0";
String selectedCategoryName = "";
dynamic selectedCategory;

//this will set when i will visit in any category
dynamic currentVisitingCategoryId = "";
dynamic currentVisitingCategory = "";

class MainActivity extends StatefulWidget {
  final String from;
  final String? itemSlug;
  final String? sellerId;
  final String? blogSlug;
  static final GlobalKey<MainActivityState> globalKey =
      GlobalKey<MainActivityState>();

  MainActivity({Key? key, required this.from, this.itemSlug, this.sellerId, this.blogSlug})
    : super(key: key);

  @override
  State<MainActivity> createState() => MainActivityState();

  static Route route(RouteSettings routeSettings) {
    Map arguments = routeSettings.arguments as Map;
    return MaterialPageRoute(
      builder: (_) => MainActivity(
        key: (globalKey.currentContext == null) ? globalKey : GlobalKey<MainActivityState>(),
        from: arguments['from'] as String,
        itemSlug: arguments['slug'] as String?,
        sellerId: arguments['sellerId'] as String?,
        blogSlug: arguments['blogSlug'] as String?,
      ),
    );
  }
}

class MainActivityState extends State<MainActivity> {
  final PageController _pageController = PageController();
  final BottomNavigationController _bottomNavigationController =
      BottomNavigationController();

  Timer? _timer;

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, () {
      if (mounted) NotificationService.init(context);
    });

    FetchSystemSettingsCubit settings = context
        .read<FetchSystemSettingsCubit>();
    if (!bool.fromEnvironment(
      Constant.forceDisableDemoMode,
      defaultValue: false,
    )) {
      Constant.isDemoModeOn =
          settings.getSetting(SystemSetting.demoMode) ?? false;
    }
    var numberWithSuffix = settings.getSetting(SystemSetting.numberWithSuffix);
    Constant.isNumberWithSuffix = numberWithSuffix == "1" ? true : false;

    ///This will check for update
    versionCheck(settings);

    if (widget.itemSlug != null) {
      Navigator.of(context).pushNamed(
        Routes.adDetailsScreen,
        arguments: {"slug": widget.itemSlug!},
      );
    }
    if (widget.blogSlug != null) {
      // For now, we redirect to the blogs screen or handle slug-to-model fetch
      // If we had a fetchBlogBySlug cubit, we would call it here.
      Navigator.pushNamed(
        context,
        Routes.blogsScreenRoute,
      );
    }
    if (widget.sellerId != null) {
      Navigator.pushNamed(
        context,
        Routes.sellerProfileScreen,
        arguments: {"sellerId": int.parse(widget.sellerId!)},
      );
    }

    _bottomNavigationController.addListener(() {
      _pageController.jumpToPage(_bottomNavigationController.index);
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!HiveUtils.isTutorialShown()) {
        _showTutorial();
      }
    });
  }

  OverlayEntry? _tutorialOverlayEntry;

  void _showTutorial() {
    final steps = [
      TutorialStep(
        targetKey: TutorialKeys.locationKey,
        title: "locationLbl".translate(context),
        description: "tutorialLocationDescription".translate(context),
      ),
      TutorialStep(
        targetKey: TutorialKeys.chatKey,
        title: "chat".translate(context),
        description: "tutorialChatDescription".translate(context),
      ),
      TutorialStep(
        targetKey: TutorialKeys.sellKey,
        title: "sell".translate(context),
        description: "tutorialSellDescription".translate(context),
      ),
      TutorialStep(
        targetKey: TutorialKeys.profileKey,
        title: "profileTab".translate(context),
        description: "tutorialProfileDescription".translate(context),
      ),
    ];

    _tutorialOverlayEntry = OverlayEntry(
      builder: (context) => TutorialOverlay(
        steps: steps,
        onFinished: () {
          _tutorialOverlayEntry?.remove();
          _tutorialOverlayEntry = null;
          HiveUtils.setTutorialShown();
        },
      ),
    );

    Overlay.of(context).insert(_tutorialOverlayEntry!);
  }

  void completeProfileCheck() {
    if (HiveUtils.getUserDetails().name == "" ||
        HiveUtils.getUserDetails().email == "") {
      Future.delayed(const Duration(milliseconds: 100), () {
        Navigator.pushReplacementNamed(
          context,
          Routes.completeProfile,
          arguments: {"from": "login"},
        );
      });
    }
  }

  void versionCheck(settings) async {
    var remoteVersion = settings.getSetting(
      Platform.isIOS ? SystemSetting.iosVersion : SystemSetting.androidVersion,
    );
    var remote = remoteVersion;

    var forceUpdate = settings.getSetting(SystemSetting.forceUpdate);

    PackageInfo packageInfo = await PackageInfo.fromPlatform();

    var current = packageInfo.version;

    int currentVersion = HelperUtils.comparableVersion(packageInfo.version);
    if (remoteVersion == null) {
      return;
    }

    remoteVersion = HelperUtils.comparableVersion(remoteVersion);

    if (remoteVersion > currentVersion) {
      Constant.isUpdateAvailable = true;
      Constant.newVersionNumber = settings.getSetting(
        Platform.isIOS
            ? SystemSetting.iosVersion
            : SystemSetting.androidVersion,
      );

      Future.delayed(Duration.zero, () {
        //This is force update -> forceUpdate == "1"
        UiUtils.showBlurredDialoge(
          context,
          dialoge: BlurredDialogBox(
            onAccept: () async {
              await launchUrl(
                Uri.parse(
                  Platform.isAndroid
                      ? Constant.playStoreUrl
                      : Constant.appStoreUrl,
                ),
                mode: LaunchMode.externalApplication,
              );
            },
            acceptTextColor: Colors.white,
            backAllowedButton: forceUpdate != "1",
            svgImagePath: AppIcons.update,
            isAcceptContainerPush: forceUpdate == "1",
            svgImageColor: context.color.territoryColor,
            showCancelButton: forceUpdate != "1",
            title: "updateAvailable".translate(context),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (forceUpdate == "1") CustomText("$current>$remote"),
                CustomText(
                  (forceUpdate == "1"
                          ? "newVersionAvailableForce"
                          : "newVersionAvailable")
                      .translate(context),
                ),
              ],
            ),
          ),
        );
      });
    }
  }

  @override
  void dispose() {
    _tutorialOverlayEntry?.remove();
    _tutorialOverlayEntry = null;
    _pageController.dispose();
    _bottomNavigationController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion(
      value: UiUtils.getSystemUiOverlayStyle(
        context: context,
        statusBarColor: context.color.primaryColor,
      ),
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          if (_bottomNavigationController.index != 0) {
            _bottomNavigationController.changeIndex(0);
          } else {
            if (_timer == null) {
              _timer = Timer(const Duration(seconds: 2), () {
                _timer?.cancel();
                _timer = null;
              });
              HelperUtils.showSnackBarMessage(
                context,
                "pressAgainToExit".translate(context),
                isFloating: true,
              );
            } else {
              SystemNavigator.pop();
            }
          }
        },
        child: Scaffold(
          backgroundColor: context.color.primaryColor,
          bottomNavigationBar: CustomBottomNavigationBar(
            controller: _bottomNavigationController,
          ),
          floatingActionButton: DiamondFab(),
          floatingActionButtonLocation:
              FloatingActionButtonLocation.centerDocked,
          body: Stack(
            children: <Widget>[
              PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  HomeScreen(from: widget.from),
                  ChatListScreen(),
                  ItemsScreen(),
                  const ProfileScreen(),
                ],
              ),
              if (Constant.maintenanceMode == "1") MaintenanceMode(),
            ],
          ),
        ),
      ),
    );
  }

  void onItemTapped(int index) {
    print(index);
    _bottomNavigationController.changeIndex(index);
  }
}
