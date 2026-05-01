import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

/// Service to handle Firebase Analytics logging across the app.
class AnalyticsService {
  AnalyticsService._();
  
  /// Singleton instance for easy access.
  static final AnalyticsService instance = AnalyticsService._();

  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  /// Observer to automatically track screen transitions in [GetMaterialApp] or [MaterialApp].
  FirebaseAnalyticsObserver get observer => FirebaseAnalyticsObserver(analytics: _analytics);

  /// Log a custom event.
  /// 
  /// [name] is the event name (use snake_case, max 40 chars).
  /// [parameters] are additional key-value pairs to log (e.g., product_id, category).
  Future<void> logEvent({
    required String name,
    Map<String, Object>? parameters,
  }) async {
    try {
      // Event name validation: max 40 characters, only alphanumeric and underscores.
      final validName = name.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_').take(40);
      
      await _analytics.logEvent(
        name: validName,
        parameters: parameters,
      );
      
      if (kDebugMode) {
        print('Analytics: Logged event [$validName] with parameters $parameters');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Analytics Error: Could not log event [$name]. Error: $e');
      }
    }
  }

  /// Log screen view manually if automatic tracking is not enough.
  Future<void> logScreenView({
    required String screenName,
    String? screenClass,
    String? pageCategory,
    String? elementLocation,
  }) async {
    try {
      final parameters = <String, Object>{};
      if (pageCategory != null) parameters['page_category'] = pageCategory;
      if (elementLocation != null) parameters['element_location'] = elementLocation;
      
      await _analytics.logEvent(
        name: 'screen_view',
        parameters: {
          'screen_name': screenName,
          if (screenClass != null) 'screen_class': screenClass,
          ...parameters,
        },
      );
      
      if (kDebugMode) {
        final allParameters = {
          'screen_name': screenName,
          if (screenClass != null) 'screen_class': screenClass,
          ...parameters,
        };
        print('Analytics: Logged screen view [$screenName] with parameters ${allParameters.isEmpty ? '' : allParameters}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Analytics Error: Could not log screen view [$screenName]. Error: $e');
      }
    }
  }

  /// Set the user ID for the current session.
  /// Useful for tracking user behavior across devices.
  Future<void> setUserId(String? userId) async {
    try {
      await _analytics.setUserId(id: userId);
    } catch (e) {
      if (kDebugMode) {
        print('Analytics Error: Could not set user ID. Error: $e');
      }
    }
  }

  /// Set persistent user properties (e.g., user role, favorite category).
  Future<void> setUserProperty({
    required String name,
    required String? value,
  }) async {
    try {
      await _analytics.setUserProperty(name: name, value: value);
    } catch (e) {
      if (kDebugMode) {
        print('Analytics Error: Could not set user property [$name]. Error: $e');
      }
    }
  }

  /// Set commonly used user profile properties in one call.
  Future<void> setUserProfile({
    String? loginState,
    String? userId,
    String? registrationType,
    String? city,
    String? persona,
    String? plan,
  }) async {
    try {
      await _analytics.setUserProperty(
        name: 'user_login_state',
        value: loginState,
      );

      if (userId != null) {
        await _analytics.setUserId(id: userId);
      }

      if (registrationType != null) {
        await _analytics.setUserProperty(
          name: 'user_registration_type',
          value: registrationType,
        );
      }

      if (city != null) {
        await _analytics.setUserProperty(
          name: 'user_city',
          value: city,
        );
      }

      if (persona != null) {
        await _analytics.setUserProperty(
          name: 'user_persona',
          value: persona,
        );
      }

      if (plan != null) {
        await _analytics.setUserProperty(
          name: 'user_plan',
          value: plan,
        );
      }

      if (kDebugMode) {
        print(
          'Analytics: Set user profile { loginState: $loginState, userId: $userId, registrationType: $registrationType, city: $city, persona: $persona, plan: $plan }',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('Analytics Error: Could not set user profile. Error: $e');
      }
    }
  }

  Future<void> clearUser() async {
    try {
      await _analytics.setUserId(id: null);

      await _analytics.setUserProperty(
        name: 'user_login_state',
        value: 'logged_out',
      );

      if (kDebugMode) {
        print('Analytics: Cleared user (logged out)');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Analytics Error: Could not clear user. Error: $e');
      }
    }
  }
}

extension StringExtension on String {
  String take(int n) => length <= n ? this : substring(0, n);
}
