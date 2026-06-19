import 'dart:async';
import 'dart:developer';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:nofak/app/routes.dart';
import 'package:nofak/data/cubits/system/fetch_language_cubit.dart';
import 'package:nofak/data/cubits/system/fetch_system_settings_cubit.dart';
import 'package:nofak/data/cubits/system/language_cubit.dart';
import 'package:nofak/data/model/system_settings_model.dart';
import 'package:nofak/settings.dart';
import 'package:nofak/ui/screens/widgets/errors/no_internet.dart';
import 'package:nofak/ui/theme/theme.dart';
import 'package:nofak/utils/constant.dart';
import 'package:nofak/utils/custom_text.dart';
import 'package:nofak/utils/extensions/extensions.dart';
import 'package:nofak/utils/helper_utils.dart';
import 'package:nofak/utils/hive_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:permission_handler/permission_handler.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({this.itemSlug, super.key, this.sellerId, this.blogSlug});

  //Used when the app is terminated and then is opened using deep link, in which case
  //the main route needs to be added to navigation stack, previously it directly used to
  //push adDetails route.
  final String? itemSlug;
  final String? sellerId;
  final String? blogSlug;

  @override
  SplashScreenState createState() => SplashScreenState();
}

class SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  bool isTimerCompleted = false;
  bool isSettingsLoaded = false;
  bool isLanguageLoaded = false;
  late StreamSubscription<List<ConnectivityResult>> subscription;
  bool hasInternet = true;
  bool hasError = false;
  bool isNavigating = false;

  late AnimationController _logoAnimationController;
  late Animation<double> _logoScaleAnimation;
  late Animation<double> _logoFadeAnimation;

  @override
  void initState() {
    super.initState();
    _logoAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _logoScaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoAnimationController,
        curve: Curves.easeOutBack,
      ),
    );

    _logoFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoAnimationController,
        curve: Curves.easeIn,
      ),
    );

    _logoAnimationController.forward();

    Connectivity().checkConnectivity().then((result) {
      _handleConnectivityChange(result);
    });
    subscription = Connectivity().onConnectivityChanged.listen((result) {
      _handleConnectivityChange(result);
    });
  }

  void _handleConnectivityChange(List<ConnectivityResult> result) {
    setState(() {
      hasInternet = (!result.contains(ConnectivityResult.none));
    });
    if (hasInternet) {
      setState(() {
        hasError = false;
      });

      final settingsCubit = context.read<FetchSystemSettingsCubit>();
      final cachedSettings = HiveUtils.getSystemSettings();
      final cachedLanguage = HiveUtils.getLanguage();

      if (cachedSettings != null && cachedLanguage != null) {
        // Pre-populate settings and language immediately from Hive cache
        Constant.isDemoModeOn = settingsCubit.getSetting(SystemSetting.demoMode) ?? false;
        
        final defaultLanguageCode = cachedSettings['data']?['default_language'] ?? 'en';
        final currentLanguageCode = cachedSettings['data']?['current_language'];
        
        _getDefaultLanguage(
          defaultCode: defaultLanguageCode,
          currentCode: currentLanguageCode,
        );
        
        // Fetch fresh settings from the server
        settingsCubit.fetchSettings(forceRefresh: true);
      } else {
        // No cache available, perform a blocking fetch
        settingsCubit.fetchSettings(forceRefresh: true);
      }

      startTimer();
    }
  }

  @override
  void dispose() {
    _logoAnimationController.dispose();
    subscription.cancel();
    super.dispose();
  }

  Future _getDefaultLanguage({
    required String defaultCode,
    required String? currentCode,
  }) async {
    try {
      final languageData = Map<String, dynamic>.from(
        HiveUtils.getLanguage() ?? {},
      );
      // Check the language code that settings api returned the response in
      // if the language code is equal to the locally stored language then we directly
      // use the local language.
      // If the currentCode is not equal then it likely means that the language cached
      // locally is no longer available on the admin panel, hence in that case we will
      // fetch the default language data and use that for rest of the app
      if (languageData.isNotEmpty && languageData['code'] == currentCode) {
        context.read<FetchLanguageCubit>().setLanguage(languageData);
        isLanguageLoaded = true;
        setState(() {});
      } else {
        context.read<FetchLanguageCubit>().getLanguage(defaultCode);
      }
    } catch (e, st) {
      context.read<FetchLanguageCubit>().getLanguage(defaultCode);
      log("Error while load default language $e");
      log('$st');
    }
  }

  Future<void> startTimer() async {
    Timer(const Duration(milliseconds: 1500), () {
      isTimerCompleted = true;
      if (mounted) setState(() {});
    });
  }

  void navigateCheck() {
    if (isTimerCompleted && isSettingsLoaded && isLanguageLoaded && !isNavigating) {
      isNavigating = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          navigateToScreen();
        }
      });
    }
  }

  void navigateToScreen() async {
    if (context.read<FetchSystemSettingsCubit>().getSetting(
          SystemSetting.maintenanceMode,
        ) ==
        "1") {
      if (mounted) {
        Navigator.of(context).pushReplacementNamed(Routes.maintenanceMode);
      }
    } else if (HiveUtils.isUserFirstTime()) {
      await requestAllAppPermissions();
      if (mounted) {
        Navigator.of(context).pushReplacementNamed(Routes.onboarding);
      }
    } else if (HiveUtils.isUserAuthenticated()) {
      if (mounted) {
        //We pass slug only when the user is authenticated otherwise drop the slug
        Navigator.of(context).pushReplacementNamed(
          Routes.main,
          arguments: {
            'from': "main",
            "slug": widget.itemSlug,
            "sellerId": widget.sellerId,
          },
        );
      }
    } else {
      if (mounted) {
        // If deep link parameters are present, navigate to content regardless of login status
        if (widget.itemSlug != null || widget.sellerId != null || widget.blogSlug != null) {
          Navigator.of(context).pushReplacementNamed(
            Routes.main,
            arguments: {
              'from': "main",
              "slug": widget.itemSlug,
              "sellerId": widget.sellerId,
              "blogSlug": widget.blogSlug,
            },
          );
        } else if (HiveUtils.isUserSkip()) {
          Navigator.of(context).pushReplacementNamed(
            Routes.main,
            arguments: {
              'from': "main",
            },
          );
        } else {
          Navigator.of(context).pushReplacementNamed(Routes.login);
        }
      }
    }
  }

  Future<void> requestAllAppPermissions() async {
    try {
      await [
        Permission.notification,
        Permission.locationWhenInUse,
        Permission.camera,
        Permission.microphone,
      ].request();
    } catch (e) {
      log("Error requesting permissions on launch: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    navigateCheck();

    return hasInternet
        ? BlocListener<FetchLanguageCubit, FetchLanguageState>(
            listener: (context, state) {
              if (state is FetchLanguageSuccess) {
                Map<String, dynamic> map = state.toMap();

                var data = map['file_name'];
                map['data'] = data;
                map.remove("file_name");

                HiveUtils.storeLanguage(map);
                context.read<LanguageCubit>().changeLanguages(map);
                isLanguageLoaded = true;
                if (mounted) {
                  setState(() {});
                }
              }
              if (state is FetchLanguageFailure) {
                HelperUtils.showSnackBarMessage(context, state.errorMessage);
                final cachedLanguage = HiveUtils.getLanguage();
                if (cachedLanguage != null) {
                  isSettingsLoaded = true;
                  isLanguageLoaded = true;
                  setState(() {});
                } else {
                  if (mounted) {
                    setState(() {
                      hasError = true;
                    });
                  }
                }
              }
            },
            child:
                BlocListener<
                  FetchSystemSettingsCubit,
                  FetchSystemSettingsState
                >(
                  listener: (context, state) {
                    if (state is FetchSystemSettingsSuccess) {
                      Constant.isDemoModeOn = context
                          .read<FetchSystemSettingsCubit>()
                          .getSetting(SystemSetting.demoMode);
                      _getDefaultLanguage(
                        defaultCode: state.settings['data']['default_language'],
                        currentCode:
                            state.settings['data']?['current_language'],
                      );
                      isSettingsLoaded = true;
                      setState(() {});
                    }
                    if (state is FetchSystemSettingsFailure) {
                      log('${state.errorMessage}');
                      final cachedSettings = HiveUtils.getSystemSettings();
                      if (cachedSettings != null) {
                        isSettingsLoaded = true;
                        isLanguageLoaded = true;
                        setState(() {});
                      } else {
                        if (mounted) {
                          setState(() {
                            hasError = true;
                          });
                        }
                      }
                    }
                  },
                  child: SafeArea(
                    top: false,
                    child: AnnotatedRegion(
                      value: SystemUiOverlayStyle(
                        statusBarColor: Colors.transparent,
                        statusBarIconBrightness: Theme.of(context).brightness == Brightness.dark
                            ? Brightness.light
                            : Brightness.dark,
                        systemNavigationBarIconBrightness: Theme.of(context).brightness == Brightness.dark
                            ? Brightness.light
                            : Brightness.dark,
                        systemNavigationBarColor: context.color.backgroundColor,
                      ),
                      child: Scaffold(
                        body: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: Theme.of(context).brightness == Brightness.dark
                                  ? [
                                      const Color(0xff0d0d0d),
                                      const Color(0xff161616),
                                      const Color(0xff0a0a0a),
                                    ]
                                  : [
                                      const Color(0xfffdfdfd),
                                      const Color(0xfff5f5fa),
                                      const Color(0xffeaeaf0),
                                    ],
                            ),
                          ),
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final screenHeight = constraints.maxHeight;
                              final screenWidth = constraints.maxWidth;
                              final isDark = Theme.of(context).brightness == Brightness.dark;
                              
                              // Calculate responsive sizes dynamically
                              final logoSize = (screenWidth * 0.35).clamp(100.0, 160.0);
                              final titleFontSize = (screenWidth * 0.07).clamp(22.0, 32.0);
                              final subtitleFontSize = (screenWidth * 0.028).clamp(10.0, 13.0);
                              
                              return Stack(
                                children: [
                                  Center(
                                    child: SingleChildScrollView(
                                      physics: const NeverScrollableScrollPhysics(),
                                      child: AnimatedBuilder(
                                        animation: _logoAnimationController,
                                        builder: (context, child) {
                                          return Opacity(
                                            opacity: _logoFadeAnimation.value,
                                            child: Transform.scale(
                                              scale: _logoScaleAnimation.value,
                                              child: child,
                                            ),
                                          );
                                        },
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 24.0),
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Container(
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: context.color.territoryColor.withValues(
                                                        alpha: isDark ? 0.15 : 0.08,
                                                      ),
                                                      blurRadius: 40,
                                                      spreadRadius: 10,
                                                    )
                                                  ],
                                                ),
                                                child: ClipRRect(
                                                  borderRadius: BorderRadius.circular(logoSize * 0.22),
                                                  child: Image.asset(
                                                    'assets/nofak_logo.png',
                                                    width: logoSize,
                                                    height: logoSize,
                                                    fit: BoxFit.contain,
                                                  ),
                                                ),
                                              ),
                                              SizedBox(height: screenHeight * 0.04),
                                              CustomText(
                                                AppSettings.applicationName.toUpperCase(),
                                                fontSize: titleFontSize,
                                                color: context.color.textColorDark,
                                                letterSpacing: 4,
                                                fontWeight: FontWeight.w800,
                                                textAlign: TextAlign.center,
                                              ),
                                              SizedBox(height: screenHeight * 0.012),
                                              CustomText(
                                                "VERIFIED & TRUSTED CLASSIFIEDS",
                                                fontSize: subtitleFontSize,
                                                color: context.color.textLightColor,
                                                letterSpacing: 2,
                                                fontWeight: FontWeight.w600,
                                                textAlign: TextAlign.center,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    bottom: (screenHeight * 0.08).clamp(40.0, 80.0),
                                    left: 0,
                                    right: 0,
                                    child: Center(
                                      child: hasError
                                          ? TextButton.icon(
                                              onPressed: () {
                                                setState(() {
                                                  hasError = false;
                                                });
                                                context.read<FetchSystemSettingsCubit>().fetchSettings(
                                                      forceRefresh: true,
                                                    );
                                              },
                                              icon: Icon(
                                                Icons.refresh,
                                                color: context.color.territoryColor,
                                                size: 18,
                                              ),
                                              label: CustomText(
                                                "Tap to retry".toUpperCase(),
                                                color: context.color.territoryColor,
                                                fontSize: subtitleFontSize,
                                                fontWeight: FontWeight.bold,
                                                letterSpacing: 1.5,
                                              ),
                                            )
                                          : SizedBox(
                                              width: 24,
                                              height: 24,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2.5,
                                                valueColor: AlwaysStoppedAnimation<Color>(
                                                  context.color.territoryColor,
                                                ),
                                              ),
                                            ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
          )
        : Material(
            child: Center(
              child: NoInternet(
                onRetry: () {
                  setState(() {});
                },
              ),
            ),
          );
  }
}
