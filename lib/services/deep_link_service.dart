import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:get/get.dart';
import 'package:verithrive_dev/enduser/core/values/sharePrefrenceConst.dart';
import 'package:verithrive_dev/enduser/data/remote/project_remote_data_source.dart';
import 'package:verithrive_dev/enduser/data/remote/project_remote_data_source_impl.dart';
import 'package:verithrive_dev/enduser/data/repository/project_repository.dart';
import 'package:verithrive_dev/enduser/data/repository/project_repository_impl.dart';
import 'package:verithrive_dev/enduser/screens/main/MainScreen.dart';
import 'package:verithrive_dev/enduser/screens/main/MainTabController.dart';
import 'package:verithrive_dev/enduser/screens/therapy_details/TherapistDetailScreen.dart';
import 'package:verithrive_dev/enduser/screens/therapy_details/TherapyDetailBinding.dart';
import 'package:verithrive_dev/routes/app_routes.dart';
import 'package:verithrive_dev/services/storage_service.dart';

/// Handles App Links / Universal Links / custom scheme for profile sharing.
///
/// Stack is always: [MainScreen] → [TherapistDetailScreen]
/// so Back never lands on Splash.
///
/// Only [MainScreen] (or a warm-start when Main is already up) should open
/// the pending profile — never Splash/Login in parallel (that opened Detail twice).
class DeepLinkService {
  DeepLinkService._();

  static final DeepLinkService instance = DeepLinkService._();

  // static const String profileShareBaseUrl =
  //     'https://dev.verithrive.co.uk/profile_view';
  static const String profileShareBaseUrl =
      'https://adminportal.verithrive.co.uk/profile_view';

  static const String profileCustomSchemeBaseUrl = 'verithrive://profile_view';

  static const Duration _openCooldown = Duration(seconds: 4);

  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSubscription;

  String? _pendingProfessionalId;
  String? _coldStartLink;
  String? _lastOpenedProfessionalId;
  DateTime? _lastOpenedAt;
  bool _openScheduled = false;
  bool _isOpeningProfile = false;

  /// Profile was opened via deep link (not listing). Back should go to Main.
  bool _openedFromDeepLink = false;

  String? get pendingProfessionalId => _pendingProfessionalId;

  bool get openedFromDeepLink => _openedFromDeepLink;

  static String buildProfileShareUrl(String professionalId) {
    return '$profileShareBaseUrl/$professionalId';
  }

  Future<void> init() async {
    try {
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        _coldStartLink = initialUri.toString();
        _handleUri(initialUri, fromColdStart: true);
      }
    } catch (e) {
      debugPrint('DeepLinkService: failed to get initial link: $e');
    }

    _linkSubscription?.cancel();
    _linkSubscription = _appLinks.uriLinkStream.listen(
      (uri) {
        if (_coldStartLink != null && uri.toString() == _coldStartLink) {
          debugPrint('DeepLinkService: ignoring duplicate cold-start uri=$uri');
          _coldStartLink = null;
          return;
        }
        // Also ignore if we already opened / are opening this professional.
        final id = extractProfessionalId(uri);
        if (id != null && _shouldSkipOpen(id)) {
          debugPrint('DeepLinkService: ignoring stream uri (cooldown) $uri');
          return;
        }
        _handleUri(uri, fromColdStart: false);
      },
      onError: (Object e) {
        debugPrint('DeepLinkService: uri stream error: $e');
      },
    );
  }

  void dispose() {
    _linkSubscription?.cancel();
    _linkSubscription = null;
  }

  void markProfileRouteClosed() {
    _openedFromDeepLink = false;
  }

  /// Back from deep-link Detail → always Main/Home, never Splash.
  void navigateBackFromProfile() {
    _openedFromDeepLink = false;
    Get.offAll(() => MainScreen());
  }

  /// Splash detected Detail on top of Splash — rebuild as Main → Detail.
  void reanchorProfileOnMain() {
    final id = _pendingProfessionalId ?? _lastOpenedProfessionalId;
    if (id == null || id.isEmpty) {
      if (!_isMainShellLive() || _isOnSplashRoute()) {
        Get.offAll(() => MainScreen());
      }
      return;
    }
    if (_shouldSkipOpen(id)) {
      // Already opened; just ensure Main is under Detail.
      if (_isOnTherapistDetailRoute()) return;
      Get.offAll(() => MainScreen());
      return;
    }
    _pendingProfessionalId = id;
    // Let MainScreen open Detail once after offAll.
    _isOpeningProfile = false;
    Get.offAll(() => MainScreen());
  }

  void _handleUri(Uri uri, {required bool fromColdStart}) {
    debugPrint('DeepLinkService: received uri=$uri coldStart=$fromColdStart');

    final professionalId = extractProfessionalId(uri);
    if (professionalId == null || professionalId.isEmpty) {
      debugPrint('DeepLinkService: no professional id in uri');
      return;
    }

    if (_shouldSkipOpen(professionalId)) {
      debugPrint('DeepLinkService: skip handle uri (cooldown) $professionalId');
      return;
    }

    _pendingProfessionalId = professionalId;

    // Cold start: wait for Splash → MainScreen → handlePendingProfileIfAny.
    if (!fromColdStart) {
      _scheduleOpenPending(delayMs: 350);
    }
  }

  static String? extractProfessionalId(Uri uri) {
    if (uri.scheme == 'verithrive' && uri.host == 'profile_view') {
      final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
      if (segments.isNotEmpty) return segments.first;
      final queryId = uri.queryParameters['id'];
      if (queryId != null && queryId.isNotEmpty) return queryId;
      return null;
    }

    final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
    final profileIndex = segments.indexOf('profile_view');
    if (profileIndex >= 0 && profileIndex + 1 < segments.length) {
      return segments[profileIndex + 1];
    }

    final queryId = uri.queryParameters['id'];
    if (queryId != null && queryId.isNotEmpty) {
      return queryId;
    }

    return null;
  }

  bool _shouldSkipOpen(String professionalId) {
    if (_isOpeningProfile && _lastOpenedProfessionalId == professionalId) {
      return true;
    }
    if (_isOnTherapistDetailRoute() &&
        _lastOpenedProfessionalId == professionalId) {
      return true;
    }
    if (_lastOpenedProfessionalId == professionalId &&
        _lastOpenedAt != null &&
        DateTime.now().difference(_lastOpenedAt!) < _openCooldown) {
      return true;
    }
    return false;
  }

  /// Called from MainScreen once the client shell is ready.
  void handlePendingProfileIfAny() {
    final id = _pendingProfessionalId;
    if (id == null || id.isEmpty) return;

    if (_shouldSkipOpen(id)) {
      debugPrint('DeepLinkService: skip pending (cooldown/in-progress) $id');
      _pendingProfessionalId = null;
      return;
    }

    if (!_isEndUserSessionReady()) {
      debugPrint(
        'DeepLinkService: session not ready, keeping pending $id '
        '(route=${Get.currentRoute})',
      );
      return;
    }

    // Main must be live — Splash/Login should only Get.offAll(MainScreen).
    if (!_isMainShellLive() || _isOnSplashRoute()) {
      debugPrint(
        'DeepLinkService: Main not ready for pending $id, keep queued',
      );
      return;
    }

    _pendingProfessionalId = null;
    _coldStartLink = null;
    _pushDetailOnce(id);
  }

  void _scheduleOpenPending({int delayMs = 0}) {
    if (_openScheduled) return;
    _openScheduled = true;

    void run() {
      _openScheduled = false;
      handlePendingProfileIfAny();
    }

    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (delayMs <= 0) {
        run();
      } else {
        Future<void>.delayed(Duration(milliseconds: delayMs), run);
      }
    });
  }

  bool _isEndUserSessionReady() {
    if (Get.key.currentState == null) return false;
    if (!Get.isRegistered<StorageService>()) return false;

    final storage = Get.find<StorageService>();
    final userType = storage.readString('userType') ??
        storage.readString(SharePreferenceConst.userType) ??
        '';
    if (userType == 'professional') return false;

    final isGuest =
        storage.readBool(SharePreferenceConst.isGuest) ?? false;
    final token = storage.readString(SharePreferenceConst.access_token) ??
        storage.readString('access_token') ??
        '';
    return isGuest || token.isNotEmpty;
  }

  bool _isMainShellLive() => Get.isRegistered<MainTabController>();

  bool _isOnSplashRoute() {
    final route = Get.currentRoute.toLowerCase();
    if (route.contains('splash')) return true;
    if (route == Routes.splash || route == '/') {
      return !_isMainShellLive();
    }
    return false;
  }

  bool _isOnTherapistDetailRoute() {
    return Get.currentRoute.toLowerCase().contains('therapistdetail');
  }

  void _ensureEndUserDependencies() {
    final remoteTag = (ProjectRemoteDataSource).toString();
    final repoTag = (ProjectRepository).toString();

    if (!Get.isRegistered<ProjectRemoteDataSource>(tag: remoteTag)) {
      Get.put<ProjectRemoteDataSource>(
        ProjectRemoteDataSourceImpl(),
        tag: remoteTag,
        permanent: true,
      );
    }
    if (!Get.isRegistered<ProjectRepository>(tag: repoTag)) {
      Get.put<ProjectRepository>(
        ProjectRepositoryImpl(),
        tag: repoTag,
        permanent: true,
      );
    }
  }

  /// Single entry that actually pushes Detail (at most once per cooldown).
  void _pushDetailOnce(String professionalId) {
    if (professionalId.isEmpty) return;
    if (_shouldSkipOpen(professionalId)) {
      debugPrint('DeepLinkService: skip push (cooldown) $professionalId');
      return;
    }

    _isOpeningProfile = true;
    _openedFromDeepLink = true;
    _lastOpenedProfessionalId = professionalId;
    _lastOpenedAt = DateTime.now();
    _pendingProfessionalId = null;

    _ensureEndUserDependencies();

    final args = <String, dynamic>{
      'professionalId': professionalId,
      'category': 'wellness',
    };

    debugPrint(
      'DeepLinkService: push TherapistDetailScreen ONCE id=$professionalId '
      'route=${Get.currentRoute}',
    );

    if (_isOnTherapistDetailRoute()) {
      Get.off(
        () => const TherapistDetailScreen(),
        binding: TherapyDetailBinding(),
        arguments: args,
        preventDuplicates: false,
      );
    } else {
      Get.to(
        () => const TherapistDetailScreen(),
        binding: TherapyDetailBinding(),
        arguments: args,
        preventDuplicates: false,
      );
    }

    // Keep skip window active; clear in-progress after the route has settled.
    Future<void>.delayed(const Duration(milliseconds: 800), () {
      _isOpeningProfile = false;
    });
  }

  void openProfessionalProfile(String professionalId) {
    if (professionalId.isEmpty) return;
    if (_shouldSkipOpen(professionalId)) return;
    _pendingProfessionalId = professionalId;
    handlePendingProfileIfAny();
  }
}
