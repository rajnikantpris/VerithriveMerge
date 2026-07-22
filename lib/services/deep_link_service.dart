import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:verithrive_dev/enduser/data/repository/project_repository.dart';
import 'package:verithrive_dev/enduser/screens/therapy_details/TherapistDetailScreen.dart';
import 'package:verithrive_dev/enduser/screens/therapy_details/TherapyDetailBinding.dart';

/// Handles App Links / Universal Links / custom scheme for profile sharing.
///
/// Preferred share URL (opens app directly, avoids admin panel browser):
/// `verithrive://profile_view/{professionalId}`
///
/// HTTPS App Link (needs public assetlinks.json on the server):
/// `https://dev.verithrive.co.uk/profile_view/{professionalId}`
class DeepLinkService {
  DeepLinkService._();


  static final DeepLinkService instance = DeepLinkService._();

  /// HTTPS App Link — opens app only after assetlinks.json verifies on device.
  static const String profileShareBaseUrl =
      'https://dev.verithrive.co.uk/profile_view';

  /// Custom scheme fallback (always opens app if installed).
  static const String profileCustomSchemeBaseUrl = 'verithrive://profile_view';

  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSubscription;

  /// Pending professional profile id when app opened from a cold start /
  /// before MainScreen is ready.
  String? _pendingProfessionalId;

  String? get pendingProfessionalId => _pendingProfessionalId;

  /// Share URL for clients: HTTPS App Link.
  /// Format: https://dev.verithrive.co.uk/profile_view/{professionalId}
  static String buildProfileShareUrl(String professionalId) {
    return '$profileShareBaseUrl/$professionalId';
  }

  Future<void> init() async {
    try {
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        _handleUri(initialUri, fromColdStart: true);
      }
    } catch (e) {
      debugPrint('DeepLinkService: failed to get initial link: $e');
    }

    _linkSubscription?.cancel();
    _linkSubscription = _appLinks.uriLinkStream.listen(
      (uri) => _handleUri(uri, fromColdStart: false),
      onError: (Object e) {
        debugPrint('DeepLinkService: uri stream error: $e');
      },
    );
  }

  void dispose() {
    _linkSubscription?.cancel();
    _linkSubscription = null;
  }

  void _handleUri(Uri uri, {required bool fromColdStart}) {
    debugPrint('DeepLinkService: received uri=$uri coldStart=$fromColdStart');

    final professionalId = extractProfessionalId(uri);
    if (professionalId == null || professionalId.isEmpty) {
      debugPrint('DeepLinkService: no professional id in uri');
      return;
    }

    if (fromColdStart) {
      _pendingProfessionalId = professionalId;
      return;
    }

    // Warm start: navigate immediately if navigator is ready, otherwise queue.
    if (Get.key.currentState != null) {
      openProfessionalProfile(professionalId);
    } else {
      _pendingProfessionalId = professionalId;
    }
  }

  /// Parse:
  /// - `verithrive://profile_view/{id}`
  /// - `https://dev.verithrive.co.uk/profile_view/{id}`
  /// - `.../profile_view?id={id}`
  static String? extractProfessionalId(Uri uri) {
    // Custom scheme: verithrive://profile_view/{id}
    if (uri.scheme == 'verithrive' && uri.host == 'profile_view') {
      final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
      if (segments.isNotEmpty) return segments.first;
      final queryId = uri.queryParameters['id'];
      if (queryId != null && queryId.isNotEmpty) return queryId;
      return null;
    }

    // HTTPS / path style: .../profile_view/{id}
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

  /// Called from MainScreen (end-user) once the app is ready to navigate.
  void handlePendingProfileIfAny() {
    final id = _pendingProfessionalId;
    if (id == null || id.isEmpty) return;
    _pendingProfessionalId = null;
    openProfessionalProfile(id);
  }

  void openProfessionalProfile(String professionalId) {
    if (professionalId.isEmpty) return;

    // End-user API deps are registered on MainScreen; queue until then.
    final repoTag = (ProjectRepository).toString();
    if (!Get.isRegistered<ProjectRepository>(tag: repoTag)) {
      _pendingProfessionalId = professionalId;
      debugPrint(
        'DeepLinkService: queued profile $professionalId until MainScreen ready',
      );
      return;
    }

    Get.to(
      () => const TherapistDetailScreen(),
      binding: TherapyDetailBinding(),
      arguments: <String, dynamic>{
        'professionalId': professionalId,
        'category': 'wellness',
      },
    );
  }
}
