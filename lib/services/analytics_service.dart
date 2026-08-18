import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import 'storage_service.dart';

/// Service to handle Firebase Analytics logging across the app.
class AnalyticsService {
  AnalyticsService._();

  /// Singleton instance for easy access.
  static final AnalyticsService instance = AnalyticsService._();

  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  static const String _userProfileSetKey = 'analytics_user_profile_set_user_id';

  String? _lastScreenViewName;
  String? _lastScreenViewClass;

  /// Observer to automatically track screen transitions in [GetMaterialApp] or [MaterialApp].
  FirebaseAnalyticsObserver get observer =>
      FirebaseAnalyticsObserver(analytics: _analytics);

  void _printEvent(String eventName, [Map<String, Object?>? parameters]) {
    print('Analytics: [$eventName] parameters: ${parameters ?? {}}');
  }

  Map<String, Object?> _itemLogParams(AnalyticsEventItem item) => {
        'item_id': item.itemId,
        'item_name': item.itemName,
        'item_category': item.itemCategory,
        'item_category2': item.itemCategory2,
        'item_variant': item.itemVariant,
        'item_brand': item.itemBrand,
        'price': item.price,
        'quantity': item.quantity,
      };

  /// Log a button tap / CTA interaction event.
  ///
  /// [eventName] should be one of the defined tap event names (e.g. join_tap, login_tap).
  /// [screenName], [screenClass], [elementText], [elementLocation], [pageCategory]
  /// match the standard analytics parameter schema.
  Future<void> logButtonTap({
    required String eventName,
    required String screenName,
    String? screenClass,
    String? elementText,
    String elementLocation = 'button_tap_cta',
    String pageCategory = 'onboarding',
  }) async {
    await logEvent(
      name: eventName,
      parameters: {
        'screen_name': screenName,
        if (screenClass != null) 'screen_class': screenClass,
        if (elementText != null) 'element_text': elementText,
        'element_location': elementLocation,
        'page_category': pageCategory,
      },
    );
  }

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

      _printEvent(validName, parameters);
    } catch (e) {
      if (kDebugMode) {
        print('Analytics Error: Could not log event [$name]. Error: $e');
      }
    }
  }

  /// Log screen view manually if automatic tracking is not enough.
  /// Consecutive calls for the same screen are ignored so rebuilds
  /// (e.g. social-login loaders) do not send duplicate events.
  Future<void> logScreenView({
    required String screenName,
    String? screenClass,
    String? pageCategory,
    String? elementLocation,
  }) async {
    if (_lastScreenViewName == screenName &&
        _lastScreenViewClass == screenClass) {
      return;
    }

    try {
      final eventParams = <String, Object>{
        'screen_name': screenName,
        if (screenClass != null) 'screen_class': screenClass,
        if (pageCategory != null && pageCategory.isNotEmpty)
          'page_category': pageCategory,
        if (elementLocation != null) 'element_location': elementLocation,
      };

      await _analytics.logEvent(
        name: 'screen_view',
        parameters: eventParams,
      );

      _lastScreenViewName = screenName;
      _lastScreenViewClass = screenClass;
      _printEvent('screen_view', eventParams);
    } catch (e) {
      if (kDebugMode) {
        print(
            'Analytics Error: Could not log screen view [$screenName]. Error: $e');
      }
    }
  }

  /// Set the user ID for the current session.
  /// Useful for tracking user behavior across devices.
  Future<void> setUserId(String? userId) async {
    try {
      await _analytics.setUserId(id: userId);
      _printEvent('set_user_id', {'user_id': userId});
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
      _printEvent('set_user_property', {'name': name, 'value': value});
    } catch (e) {
      if (kDebugMode) {
        print(
            'Analytics Error: Could not set user property [$name]. Error: $e');
      }
    }
  }

  /// Set commonly used user profile properties in one call.
  ///
  /// When [oncePerLogin] is true, this runs once per user until logout.
  Future<void> setUserProfile({
    String? loginState,
    String? userId,
    String? registrationType,
    String? city,
    String? persona,
    String? plan,
    bool oncePerLogin = false,
  }) async {
    try {
      if (oncePerLogin && !_shouldSetUserProfile(userId)) {
        return;
      }

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

      if (plan != null && plan.isNotEmpty) {
        await _analytics.setUserProperty(
          name: 'user_plan',
          value: plan,
        );
      }

      if (oncePerLogin) {
        await _markUserProfileSet(userId);
      }

      _printEvent('set_user_profile', {
        'user_login_state': loginState,
        'user_id': userId,
        'user_registration_type': registrationType,
        'user_city': city,
        'user_persona': persona,
        'user_plan': plan,
      });
    } catch (e) {
      if (kDebugMode) {
        print('Analytics Error: Could not set user profile. Error: $e');
      }
    }
  }

  bool _shouldSetUserProfile(String? userId) {
    if (userId == null || userId.isEmpty) return true;
    if (!Get.isRegistered<StorageService>()) return true;
    final lastSetFor = Get.find<StorageService>().readString(_userProfileSetKey);
    return lastSetFor != userId;
  }

  Future<void> _markUserProfileSet(String? userId) async {
    if (userId == null || userId.isEmpty) return;
    if (!Get.isRegistered<StorageService>()) return;
    await Get.find<StorageService>().writeString(_userProfileSetKey, userId);
  }

  /// Resolves analytics [page_category], never returning an empty value.
  ///
  /// Uses [raw] when it is a known journey (wellness / fitness /
  /// food & nutrition). Otherwise maps from [raw], [itemBrand], or
  /// [itemVariant], falling back to [fallback].
  static String resolvePageCategory(
    String? raw, {
    String? itemBrand,
    String? itemVariant,
    String fallback = 'wellness',
  }) {
    final value = raw?.trim() ?? '';
    if (value.isNotEmpty) {
      final lower = value.toLowerCase();
      if (lower == 'wellness' || lower == 'fitness') return lower;
      if (lower == 'food & nutrition' || lower == 'food_nutrition') {
        return 'food & nutrition';
      }
      return pageCategoryFromProfession(value);
    }
    if (itemBrand != null && itemBrand.trim().isNotEmpty) {
      return pageCategoryFromProfession(itemBrand);
    }
    if (itemVariant != null && itemVariant.trim().isNotEmpty) {
      return pageCategoryFromProfession(itemVariant);
    }
    return fallback;
  }

  /// Maps profession/journey name to sheet page_category:
  /// wellness | fitness | food & nutrition.
  static String pageCategoryFromProfession(String? professionName) {
    final raw = professionName?.trim().toLowerCase() ?? '';
    if (raw.contains('fitness') ||
        raw.contains('trainer') ||
        raw.contains('coach')) {
      return 'fitness';
    }
    if (raw.contains('food') ||
        raw.contains('nutrition') ||
        raw.contains('diet')) {
      return 'food & nutrition';
    }
    return 'wellness';
  }

  /// Maps a raw profession_name/type value to a canonical persona string.
  /// Returns one of: professional_wellness, professional_fitness,
  /// professional_nutrition, end_user, or 'professional' as fallback.
  /// Never includes PII (names).
  static String resolvePersona({
    String? professionName,
    bool isProfessional = true,
  }) {
    if (!isProfessional) return 'end_user';
    final raw = professionName?.trim().toLowerCase() ?? '';
    if (raw.isEmpty) return 'professional';
    if (raw.contains('wellness') ||
        raw.contains('therapy') ||
        raw.contains('therapist') ||
        raw.contains('sport')) {
      return 'professional_wellness';
    }
    if (raw.contains('fitness') ||
        raw.contains('trainer') ||
        raw.contains('personal train')) {
      return 'professional_fitness';
    }
    if (raw.contains('food & nutrition') ||
        raw.contains('nutritionist') ||
        raw.contains('food')) {
      return 'professional_nutrition';
    }
    return 'professional';
  }

  /// Validate and coerce a numeric value to [double]. Returns 0.0 for nulls/invalid.
  static double validatePrice(dynamic raw) {
    if (raw == null) return 0.0;
    if (raw is num) return raw.toDouble();
    return double.tryParse(raw.toString()) ?? 0.0;
  }

  /// Validate a quantity value. Returns 1 for nulls/invalid, minimum 1.
  static int validateQuantity(dynamic raw) {
    if (raw == null) return 1;
    if (raw is int) return raw < 1 ? 1 : raw;
    final parsed = int.tryParse(raw.toString());
    return (parsed == null || parsed < 1) ? 1 : parsed;
  }

  /// Validate a currency string. Always returns a non-empty string, defaults to 'GBP'.
  static String validateCurrency(String? raw) {
    if (raw == null || raw.trim().isEmpty) return 'GBP';
    return raw.trim().toUpperCase();
  }

  /// Build a validated [AnalyticsEventItem] enforcing numeric types.
  AnalyticsEventItem buildItem({
    required String itemId,
    required String itemName,
    String? itemCategory,
    String? itemCategory2,
    String? itemVariant,
    String? itemBrand,
    dynamic price = 0.0,
    dynamic quantity = 1,
  }) {
    // Standardize Brand and Name based on user requirements
    String finalBrand = itemBrand ?? '';
    String finalName = itemName;

    final category = itemCategory?.toLowerCase() ?? '';
    if (category == 'fitness' ||
        category.contains('trainer') ||
        category.contains('coach')) {
      finalBrand = 'Fitness';
    } else if (category == 'wellness' ||
        category.contains('therapist') ||
        category.contains('physio')) {
      finalBrand = 'Wellness';
    } else if (category == 'food_nutrition' ||
        category == 'food & nutrition' ||
        category.contains('nutrition') ||
        category.contains('diet')) {
      finalBrand = 'Food & Nutrition';
    }

    // Standardize Name if it matches one of the known sub-types
    final nameLower = itemName.toLowerCase();
    if (finalBrand == 'Fitness') {
      if (nameLower.contains('trainer'))
        finalName = 'Personal Trainer';
      else if (nameLower.contains('coach'))
        finalName = 'Fitness Coach';
      else if (nameLower.contains('instructor'))
        finalName = 'Fitness Instructor';
      else if (finalName == 'unknown' ||
          finalName.isEmpty ||
          finalName == 'fitness') finalName = 'Personal Trainer'; // Default
    } else if (finalBrand == 'Wellness') {
      if (nameLower.contains('physio'))
        finalName = 'Physiotherapist';
      else if (nameLower.contains('chiro'))
        finalName = 'Chiropractor';
      else if (nameLower.contains('osteo'))
        finalName = 'Osteopath';
      else if (nameLower.contains('sport'))
        finalName = 'Sports Therapist';
      else if (finalName == 'unknown' ||
          finalName.isEmpty ||
          finalName == 'wellness') finalName = 'Sports Therapist'; // Default
    } else if (finalBrand == 'Food & Nutrition') {
      if (nameLower.contains('diet'))
        finalName = 'Dietitian';
      else if (nameLower.contains('nutrition'))
        finalName = 'Nutritionist';
      else if (nameLower.contains('chef'))
        finalName = 'Private Chef';
      else if (finalName == 'unknown' ||
          finalName.isEmpty ||
          finalName == 'food_nutrition') finalName = 'Nutritionist'; // Default
    }

    return AnalyticsEventItem(
      itemId: itemId.isNotEmpty ? itemId : '',
      itemName: finalName.isNotEmpty ? finalName : '',
      itemCategory: finalBrand,
      itemCategory2: itemCategory2,
      itemVariant: itemVariant,
      itemBrand: finalBrand.isNotEmpty ? finalBrand : null,
      price: validatePrice(price),
      quantity: validateQuantity(quantity),
    );
  }

  Future<void> logViewItemListEvent({
    required List<AnalyticsEventItem> items,
    String? itemListId,
    String? itemListName,
    String currency = 'GBP',
    String? screenName,
    String? screenClass,
    String? pageCategory,
    Map<String, Object>? extraParams,
  }) async {
    try {
      final validatedCurrency = validateCurrency(currency);
      final parameters = <String, Object>{
        'currency': validatedCurrency,
        if (screenName != null) 'screen_name': screenName,
        if (screenClass != null) 'screen_class': screenClass,
        if (pageCategory != null) 'page_category': pageCategory,
        if (extraParams != null) ...extraParams,
      };

      await _analytics.logViewItemList(
        items: items,
        itemListId: itemListId,
        itemListName: itemListName,
        parameters: parameters,
      );
      _printEvent('view_item_list', {
        'item_list_id': itemListId,
        'item_list_name': itemListName,
        ...parameters,
        'items': items.map(_itemLogParams).toList(),
      });
    } catch (e) {
      if (kDebugMode) print('Analytics Error: view_item_list. $e');
    }
  }

  Future<void> logViewItemEvent({
    AnalyticsEventItem? item,
    List<AnalyticsEventItem>? items,
    double? value,
    String? currency,
    String? screenName,
    String? screenClass,
    String? pageCategory,
    Map<String, Object>? extraParams,
  }) async {
    try {
      final eventItems = (items != null && items.isNotEmpty)
          ? items
          : (item != null ? [item] : <AnalyticsEventItem>[]);
      if (eventItems.isEmpty) return;

      final validatedCurrency =
          currency != null ? validateCurrency(currency) : null;
      final parameters = <String, Object>{
        if (screenName != null) 'screen_name': screenName,
        if (screenClass != null) 'screen_class': screenClass,
        if (pageCategory != null) 'page_category': pageCategory,
        if (extraParams != null) ...extraParams,
      };

      await _analytics.logViewItem(
        currency: validatedCurrency,
        value: value,
        items: eventItems,
        parameters: parameters.isEmpty ? null : parameters,
      );
      _printEvent('view_item', {
        if (validatedCurrency != null) 'currency': validatedCurrency,
        if (value != null) 'value': value,
        ...parameters,
        'items': eventItems.map(_itemLogParams).toList(),
      });
    } catch (e) {
      if (kDebugMode) print('Analytics Error: view_item. $e');
    }
  }

  Future<void> logSelectItemEvent({
    required AnalyticsEventItem item,
    String? itemListId,
    String? itemListName,
    String currency = 'GBP',
    String? screenName,
    String? screenClass,
    String? pageCategory,
    Map<String, Object>? extraParams,
  }) async {
    try {
      final validatedCurrency = validateCurrency(currency);
      final parameters = <String, Object>{
        'currency': validatedCurrency,
        if (screenName != null) 'screen_name': screenName,
        if (screenClass != null) 'screen_class': screenClass,
        if (pageCategory != null && pageCategory.isNotEmpty)
          'page_category': pageCategory,
        if (extraParams != null) ...extraParams,
      };

      await _analytics.logSelectItem(
        items: [item],
        itemListId: (itemListId != null && itemListId.isNotEmpty)
            ? itemListId
            : null,
        itemListName: (itemListName != null && itemListName.isNotEmpty)
            ? itemListName
            : null,
        parameters: parameters,
      );
      _printEvent('select_item', {
        if (itemListId != null && itemListId.isNotEmpty)
          'item_list_id': itemListId,
        if (itemListName != null && itemListName.isNotEmpty)
          'item_list_name': itemListName,
        ...parameters,
        ..._itemLogParams(item),
      });
    } catch (e) {
      if (kDebugMode) print('Analytics Error: select_item. $e');
    }
  }

  Future<void> logAddToCartEvent({
    required AnalyticsEventItem item,
    dynamic value = 0.0,
    String currency = 'GBP',
    String? screenName,
    String? screenClass,
    String? pageCategory,
    String? bookingStartTime,
    String? bookingEndTime,
    int? bookingDurationMinutes,
    Map<String, Object>? extraParams,
  }) async {
    try {
      final validatedValue = validatePrice(value);
      final validatedCurrency = validateCurrency(currency);
      final parameters = <String, Object>{
        if (screenName != null) 'screen_name': screenName,
        if (screenClass != null) 'screen_class': screenClass,
        if (pageCategory != null) 'page_category': pageCategory,
        if (bookingStartTime != null) 'booking_start_time': bookingStartTime,
        if (bookingEndTime != null) 'booking_end_time': bookingEndTime,
        if (bookingDurationMinutes != null)
          'booking_duration_minutes': bookingDurationMinutes,
        if (extraParams != null) ...extraParams,
      };

      await _analytics.logAddToCart(
        currency: validatedCurrency,
        value: validatedValue,
        items: [item],
        parameters: parameters.isEmpty ? null : parameters,
      );
      _printEvent('add_to_cart', {
        'currency': validatedCurrency,
        'value': validatedValue,
        ...parameters,
        ..._itemLogParams(item),
      });
    } catch (e) {
      if (kDebugMode) print('Analytics Error: add_to_cart. $e');
    }
  }

  Future<void> logViewCartEvent({
    required AnalyticsEventItem item,
    dynamic value = 0.0,
    String currency = 'GBP',
    String? screenName,
    String? screenClass,
    String? pageCategory,
    Map<String, Object>? extraParams,
  }) async {
    try {
      final validatedValue = validatePrice(value);
      final validatedCurrency = validateCurrency(currency);
      final parameters = <String, Object>{
        if (screenName != null) 'screen_name': screenName,
        if (screenClass != null) 'screen_class': screenClass,
        if (pageCategory != null && pageCategory.isNotEmpty)
          'page_category': pageCategory,
        if (extraParams != null) ...extraParams,
      };

      await _analytics.logViewCart(
        currency: validatedCurrency,
        value: validatedValue,
        items: [item],
        parameters: parameters.isEmpty ? null : parameters,
      );
      _printEvent('view_cart', {
        'currency': validatedCurrency,
        'value': validatedValue,
        ...parameters,
        ..._itemLogParams(item),
      });
    } catch (e) {
      if (kDebugMode) print('Analytics Error: view_cart. $e');
    }
  }

  Future<void> logRemoveFromCartEvent({
    required AnalyticsEventItem item,
    dynamic value = 0.0,
    String currency = 'GBP',
    String? screenName,
    String? screenClass,
    String? pageCategory,
    Map<String, Object>? extraParams,
  }) async {
    try {
      final validatedValue = validatePrice(value);
      final validatedCurrency = validateCurrency(currency);
      final parameters = <String, Object>{
        if (screenName != null) 'screen_name': screenName,
        if (screenClass != null) 'screen_class': screenClass,
        if (pageCategory != null && pageCategory.isNotEmpty)
          'page_category': pageCategory,
        if (extraParams != null) ...extraParams,
      };

      await _analytics.logRemoveFromCart(
        currency: validatedCurrency,
        value: validatedValue,
        items: [item],
        parameters: parameters.isEmpty ? null : parameters,
      );
      _printEvent('remove_from_cart', {
        'currency': validatedCurrency,
        'value': validatedValue,
        ...parameters,
        ..._itemLogParams(item),
      });
    } catch (e) {
      if (kDebugMode) print('Analytics Error: remove_from_cart. $e');
    }
  }

  Future<void> logBeginCheckoutEvent({
    required AnalyticsEventItem item,
    dynamic value = 0.0,
    String currency = 'GBP',
    String? screenName,
    String? screenClass,
    String? pageCategory,
    Map<String, Object>? extraParams,
  }) async {
    try {
      final validatedValue = validatePrice(value);
      final validatedCurrency = validateCurrency(currency);
      final parameters = <String, Object>{
        if (screenName != null) 'screen_name': screenName,
        if (screenClass != null) 'screen_class': screenClass,
        if (pageCategory != null) 'page_category': pageCategory,
        if (extraParams != null) ...extraParams,
      };

      await _analytics.logBeginCheckout(
        currency: validatedCurrency,
        value: validatedValue,
        items: [item],
        parameters: parameters.isEmpty ? null : parameters,
      );
      _printEvent('begin_checkout', {
        'currency': validatedCurrency,
        'value': validatedValue,
        ...parameters,
        ..._itemLogParams(item),
      });
    } catch (e) {
      if (kDebugMode) print('Analytics Error: begin_checkout. $e');
    }
  }

  Future<void> logPurchaseEvent({
    required AnalyticsEventItem item,
    required String transactionId,
    dynamic value = 0.0,
    String currency = 'GBP',
    String? screenName,
    String? screenClass,
    String? pageCategory,
    Map<String, Object>? extraParams,
  }) async {
    try {
      final validatedValue = validatePrice(value);
      final validatedCurrency = validateCurrency(currency);
      if (validatedValue <= 0.0) {
        if (kDebugMode) {
          print(
              'Analytics Warning: purchase event value is £0.00 — check price passed to logPurchaseEvent (transactionId: $transactionId)');
        }
      }
      final parameters = <String, Object>{
        if (screenName != null) 'screen_name': screenName,
        if (screenClass != null) 'screen_class': screenClass,
        if (pageCategory != null) 'page_category': pageCategory,
        if (extraParams != null) ...extraParams,
      };

      await _analytics.logPurchase(
        currency: validatedCurrency,
        value: validatedValue,
        transactionId: transactionId,
        items: [item],
        parameters: parameters.isEmpty ? null : parameters,
      );
      _printEvent('purchase', {
        'currency': validatedCurrency,
        'value': validatedValue,
        'transaction_id': transactionId,
        ...parameters,
        ..._itemLogParams(item),
      });
    } catch (e) {
      if (kDebugMode) print('Analytics Error: purchase. $e');
    }
  }

  Future<void> clearUser() async {
    try {
      await _analytics.setUserId(id: null);

      await _analytics.setUserProperty(
        name: 'user_login_state',
        value: 'logged_out',
      );

      if (Get.isRegistered<StorageService>()) {
        await Get.find<StorageService>().remove(_userProfileSetKey);
      }

      _printEvent('clear_user', {'user_id': null, 'user_login_state': 'logged_out'});
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
