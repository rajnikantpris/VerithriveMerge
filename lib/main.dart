import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'dart:io';
import 'package:verithrive_dev/enduser/flavors/build_config.dart'
    as enduser_build;
import 'package:verithrive_dev/enduser/flavors/env_config.dart' as enduser_env;
import 'package:verithrive_dev/enduser/flavors/environment.dart'
    as enduser_environment;
import 'enduser/FirebaseTokenService.dart';
import 'enduser/screens/DevHttpOverrides.dart';
import 'routes/app_pages.dart';
import 'theme/app_theme.dart';
import 'theme/colors.dart';
import 'common/firebase_config.dart';
import 'services/foreground_notification_service.dart';
import 'services/deep_link_service.dart';
import 'services/analytics_service.dart';

// lib/main.dart file

/// Top-level background message handler required by firebase_messaging.
/// Must be a top-level (non-class) function annotated with @pragma.
@pragma('vm:entry-point')
Future<void> _firebaseBackgroundMessageHandler(RemoteMessage message) async {
  // Re-initialise Firebase for the background isolate
  if (Platform.isIOS) {
    await Firebase.initializeApp();
  } else {
    await Firebase.initializeApp(options: FirebaseConfig.getFirebaseOptions());
  }

  await ForegroundNotificationService.backgroundMessageHandler(message);
}

Future<void> main() async {
  HttpOverrides.global = DevHttpOverrides();
  final enduser_env.EnvConfig enduserConfig = enduser_env.EnvConfig(
    appName: "VeriThrive",
    baseUrl: "",
    shouldCollectCrashLog: true,
  );

  enduser_build.BuildConfig.instantiate(
    envType: enduser_environment.Environment.DEVELOPMENT,
    envConfig: enduserConfig,
  );

  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase with platform-specific options
  if (Platform.isIOS) {
    await Firebase.initializeApp();
    // 🔥 ADD THIS (VERY IMPORTANT)
    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
  } else {
    await Firebase.initializeApp(options: FirebaseConfig.getFirebaseOptions());
  }

  // Android only: prefetch FCM token at startup (does not show a permission dialog).
  if (Platform.isAndroid) {
    FirebaseTokenService.getFCMToken();
  }

  // Register the background message handler
  FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundMessageHandler);

  // Initialize foreground notification service (channels, local notifications)
  await ForegroundNotificationService.initialize();

  // Setup foreground + background-tap message handlers
  ForegroundNotificationService.setupForegroundMessageHandler();

  // App Links / Universal Links (professional profile share)
  await DeepLinkService.instance.init();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  const SystemUiOverlayStyle(
    statusBarColor: AppColor.white,
    statusBarIconBrightness: Brightness.dark,
    statusBarBrightness: Brightness.light,
  );

  runApp(const VerithriveApp());
}

class VerithriveApp extends StatefulWidget {
  const VerithriveApp({super.key});

  @override
  State<VerithriveApp> createState() => _VerithriveAppState();
}

class _VerithriveAppState extends State<VerithriveApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Check if the app was launched from a terminated state via a notification.
    // We defer this until after the first frame so Get's navigator is ready,
    // then store the message as a pending notification.  The Home screen calls
    // ForegroundNotificationService.handlePendingNotificationIfAny() once it
    // has fully loaded, which navigates to the correct destination.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ForegroundNotificationService.checkInitialMessage();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    // When the app resumes from background refresh all relevant data.
    // This covers notifications received while the app was backgrounded.
    if (state == AppLifecycleState.resumed) {
      ForegroundNotificationService.refreshAllDataOnAppResume();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      builder: (_, __) => GetMaterialApp(
        title: 'Verithrive',
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: ThemeMode.system,
        initialRoute: AppPages.initial,
        initialBinding: AppPages.initialBinding,
        getPages: AppPages.routes,
        defaultTransition: Transition.fadeIn,
        debugShowCheckedModeBanner: false,
        navigatorObservers: [
          AnalyticsService.instance.observer,
        ],
      ),
    );
  }
}
