import 'package:nofak/firebase_options.dart';
import 'package:nofak/main.dart';
import 'package:nofak/utils/notification/notification_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:nofak/ui/screens/widgets/errors/something_went_wrong.dart';
import 'package:nofak/utils/constant.dart';
import 'package:nofak/utils/hive_keys.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter_android/google_maps_flutter_android.dart';
import 'package:google_maps_flutter_platform_interface/google_maps_flutter_platform_interface.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_displaymode/flutter_displaymode.dart';

/// List of Hive box names that need to be initialized
final List<String> _hiveBoxes = [
  HiveKeys.userDetailsBox,
  HiveKeys.translationsBox,
  HiveKeys.authBox,
  HiveKeys.languageBox,
  HiveKeys.themeBox,
  HiveKeys.svgBox,
  HiveKeys.jwtToken,
  HiveKeys.historyBox,
  HiveKeys.draftBox,
];

/// Initializes the application with all necessary configurations
Future<void> initApp() async {
  try {
    // Ensure Flutter bindings are initialized
    WidgetsFlutterBinding.ensureInitialized();

    // Optimize refresh rates for flagship Android devices (120Hz+)
    if (defaultTargetPlatform == TargetPlatform.android) {
      try {
        await FlutterDisplayMode.setHighRefreshRate();
      } catch (e) {
        debugPrint("Error configuring high refresh rate: $e");
      }
    }

    // Optimize image cache memory bounds to prevent OOM (Out Of Memory) crashes on low-end devices
    PaintingBinding.instance.imageCache.maximumSize = 150; // Limit total cached image items (default: 1000)
    PaintingBinding.instance.imageCache.maximumSizeBytes = 50 * 1024 * 1024; // Limit to 50MB (default: 100MB+)

    // Configure Google Maps for Android
    _configureGoogleMaps();

    // Set up error handling for release mode
    if (kReleaseMode) {
      _setupErrorHandling();
    }

    // Initialize Firebase
    await _initializeFirebase();

    // Initialize Mobile Ads asynchronously in the background
    MobileAds.instance.initialize();

    // Initialize Hive and open boxes
    await _initializeHive();

    // Configure system UI and launch app
    await _configureSystemUI();

    Constant.savePath = await getApplicationDocumentsDirectory().then(
      (dir) => dir.path,
    );

    runApp(const EntryPoint());
  } catch (e, stackTrace) {
    debugPrint('FATAL ERROR DURING APP INITIALIZATION');
    debugPrint('Error: $e');
    debugPrint('Stack Trace: $stackTrace');
    rethrow;
  }
}

/// Configures Google Maps for Android platform
void _configureGoogleMaps() {
  final GoogleMapsFlutterPlatform mapsImplementation =
      GoogleMapsFlutterPlatform.instance;
  if (mapsImplementation is GoogleMapsFlutterAndroid) {
    mapsImplementation.useAndroidViewSurface = false;
  }
}

/// Sets up error handling for release mode
void _setupErrorHandling() {
  ErrorWidget.builder = (FlutterErrorDetails flutterErrorDetails) {
    return SomethingWentWrong();
  };
}

/// Initializes Firebase with appropriate options
Future<void> _initializeFirebase() async {
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  //try {
  //  await FirebaseAppCheck.instance.activate(
  //    appleProvider: kDebugMode ? AppleProvider.debug : AppleProvider.appAttestWithDeviceCheckFallback,
  //    androidProvider: kDebugMode ? AndroidProvider.debug : AndroidProvider.playIntegrity,
  //  );
  //} catch (e) {
  //  debugPrint("Firebase App Check error: $e");
  //}

  FirebaseMessaging.onBackgroundMessage(
    NotificationService.onBackgroundMessageHandler,
  );
}

/// Initializes Hive and opens all required boxes in parallel
Future<void> _initializeHive() async {
  await Hive.initFlutter();
  await Future.wait(_hiveBoxes.map((boxName) => Hive.openBox(boxName)));
}

/// Configures system UI and launches the app
Future<void> _configureSystemUI() async {
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(statusBarColor: Colors.transparent),
  );
}
