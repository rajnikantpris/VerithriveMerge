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

      if (plan != null && plan.isNotEmpty) {
        await _analytics.setUserProperty(
          name: 'user_plan',
          value: plan,
        );
      }

      if (kDebugMode) {
        final planPart = (plan != null && plan.isNotEmpty) ? ', user_plan: $plan' : '';
        print(
          'Analytics: Set user profile { user_login_state: $loginState, user_id: $userId, user_registration_type: $registrationType, user_city: $city, user_persona: $persona$planPart }',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('Analytics Error: Could not set user profile. Error: $e');
      }
    }
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
    if (raw.contains('wellness') || raw.contains('therapy') ||
        raw.contains('therapist') || raw.contains('sport')) {
      return 'professional_wellness';
    }
    if (raw.contains('fitness') || raw.contains('trainer') ||
        raw.contains('personal train')) {
      return 'professional_fitness';
    }
    if (raw.contains('food & nutrition') || raw.contains('nutritionist') ||
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
    if (category == 'fitness' || category.contains('trainer') || category.contains('coach')) {
      finalBrand = 'Fitness';
    } else if (category == 'wellness' || category.contains('therapist') || category.contains('physio')) {
      finalBrand = 'Wellness';
    } else if (category == 'food_nutrition' || category == 'food & nutrition' || category.contains('nutrition') || category.contains('diet')) {
      finalBrand = 'Food & Nutrition';
    }

    // Standardize Name if it matches one of the known sub-types
    final nameLower = itemName.toLowerCase();
    if (finalBrand == 'Fitness') {
      if (nameLower.contains('trainer')) finalName = 'Personal Trainer';
      else if (nameLower.contains('coach')) finalName = 'Fitness Coach';
      else if (nameLower.contains('instructor')) finalName = 'Fitness Instructor';
      else if (finalName == 'unknown' || finalName.isEmpty || finalName == 'fitness') finalName = 'Personal Trainer'; // Default
    } else if (finalBrand == 'Wellness') {
      if (nameLower.contains('physio')) finalName = 'Physiotherapist';
      else if (nameLower.contains('chiro')) finalName = 'Chiropractor';
      else if (nameLower.contains('osteo')) finalName = 'Osteopath';
      else if (nameLower.contains('sport')) finalName = 'Sports Therapist';
      else if (finalName == 'unknown' || finalName.isEmpty || finalName == 'wellness') finalName = 'Sports Therapist'; // Default
    } else if (finalBrand == 'Food & Nutrition') {
      if (nameLower.contains('diet')) finalName = 'Dietitian';
      else if (nameLower.contains('nutrition')) finalName = 'Nutritionist';
      else if (nameLower.contains('chef')) finalName = 'Private Chef';
      else if (finalName == 'unknown' || finalName.isEmpty || finalName == 'food_nutrition') finalName = 'Nutritionist'; // Default
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
    Map<String, Object>? extraParams,
  }) async {
    try {
      await _analytics.logViewItemList(
        items: items,
        itemListId: itemListId,
        itemListName: itemListName,
      );
      if (kDebugMode) {
        final itemDetails = items.map((i) => {
          'item_id': i.itemId,
          'item_name': i.itemName,
          'item_category': i.itemCategory,
          'item_category2': i.itemCategory2,
          'item_variant': i.itemVariant,
          'item_brand': i.itemBrand,
          'price': i.price,
          'quantity': i.quantity,
        }).toList();
        print(
          'Analytics: view_item_list logged '
          '{ item_list_id: $itemListId, item_list_name: $itemListName, '
          'items (${items.length}): $itemDetails }',
        );
      }
    } catch (e) {
      if (kDebugMode) print('Analytics Error: view_item_list. $e');
    }
  }

  Future<void> logViewItemEvent({
    required AnalyticsEventItem item,
    double value = 0.0,
    String currency = 'GBP',
    Map<String, Object>? extraParams,
  }) async {
    try {
      await _analytics.logViewItem(
        currency: currency,
        value: value,
        items: [item],
      );
      if (kDebugMode) {
        print(
          'Analytics: view_item logged { '
          'currency: $currency, value: $value, '
          'item_id: ${item.itemId}, item_name: ${item.itemName}, '
          'item_category: ${item.itemCategory}, item_category2: ${item.itemCategory2}, '
          'item_variant: ${item.itemVariant}, '
          'item_brand: ${item.itemBrand}, price: ${item.price}, quantity: ${item.quantity} }',
        );
      }
    } catch (e) {
      if (kDebugMode) print('Analytics Error: view_item. $e');
    }
  }

  Future<void> logSelectItemEvent({
    required AnalyticsEventItem item,
    String? itemListId,
    String? itemListName,
  }) async {
    try {
      await _analytics.logSelectItem(
        items: [item],
        itemListId: itemListId,
        itemListName: itemListName,
      );
      if (kDebugMode) {
        print(
          'Analytics: select_item logged { '
          'item_list_id: $itemListId, item_list_name: $itemListName, '
          'item_id: ${item.itemId}, item_name: ${item.itemName}, '
          'item_category: ${item.itemCategory}, item_category2: ${item.itemCategory2}, '
          'item_variant: ${item.itemVariant}, '
          'item_brand: ${item.itemBrand}, price: ${item.price}, quantity: ${item.quantity} }',
        );
      }
    } catch (e) {
      if (kDebugMode) print('Analytics Error: select_item. $e');
    }
  }

  Future<void> logViewCartEvent({
    required AnalyticsEventItem item,
    dynamic value = 0.0,
    String currency = 'GBP',
  }) async {
    try {
      final validatedValue = validatePrice(value);
      final validatedCurrency = validateCurrency(currency);
      await _analytics.logViewCart(
        currency: validatedCurrency,
        value: validatedValue,
        items: [item],
      );
      if (kDebugMode) {
        print(
          'Analytics: view_cart logged { '
          'currency: $validatedCurrency, value: $validatedValue, '
          'item_id: ${item.itemId}, item_name: ${item.itemName}, '
          'item_category: ${item.itemCategory}, item_category2: ${item.itemCategory2}, '
          'item_variant: ${item.itemVariant}, '
          'item_brand: ${item.itemBrand}, price: ${item.price}, quantity: ${item.quantity} }',
        );
      }
    } catch (e) {
      if (kDebugMode) print('Analytics Error: view_cart. $e');
    }
  }

  Future<void> logRemoveFromCartEvent({
    required AnalyticsEventItem item,
    dynamic value = 0.0,
    String currency = 'GBP',
  }) async {
    try {
      final validatedValue = validatePrice(value);
      final validatedCurrency = validateCurrency(currency);
      await _analytics.logRemoveFromCart(
        currency: validatedCurrency,
        value: validatedValue,
        items: [item],
      );
      if (kDebugMode) {
        print('Analytics: remove_from_cart logged (${item.itemName}, value: $validatedValue $validatedCurrency)');
      }
    } catch (e) {
      if (kDebugMode) print('Analytics Error: remove_from_cart. $e');
    }
  }

  Future<void> logBeginCheckoutEvent({
    required AnalyticsEventItem item,
    dynamic value = 0.0,
    String currency = 'GBP',
  }) async {
    try {
      final validatedValue = validatePrice(value);
      final validatedCurrency = validateCurrency(currency);
      await _analytics.logBeginCheckout(
        currency: validatedCurrency,
        value: validatedValue,
        items: [item],
      );
      if (kDebugMode) {
        print(
          'Analytics: begin_checkout logged { '
          'currency: $validatedCurrency, value: $validatedValue, '
          'item_id: ${item.itemId}, item_name: ${item.itemName}, '
          'item_category: ${item.itemCategory}, item_category2: ${item.itemCategory2}, '
          'item_variant: ${item.itemVariant}, '
          'item_brand: ${item.itemBrand}, price: ${item.price}, quantity: ${item.quantity} }',
        );
      }
    } catch (e) {
      if (kDebugMode) print('Analytics Error: begin_checkout. $e');
    }
  }

  Future<void> logPurchaseEvent({
    required AnalyticsEventItem item,
    required String transactionId,
    dynamic value = 0.0,
    String currency = 'GBP',
  }) async {
    try {
      final validatedValue = validatePrice(value);
      final validatedCurrency = validateCurrency(currency);
      if (validatedValue <= 0.0) {
        if (kDebugMode) {
          print('Analytics Warning: purchase event value is £0.00 — check price passed to logPurchaseEvent (transactionId: $transactionId)');
        }
      }
      await _analytics.logPurchase(
        currency: validatedCurrency,
        value: validatedValue,
        transactionId: transactionId,
        items: [item],
      );
      if (kDebugMode) {
        print(
          'Analytics: purchase logged { '
          'currency: $validatedCurrency, value: $validatedValue, '
          'transaction_id: $transactionId, '
          'item_id: ${item.itemId}, item_name: ${item.itemName}, '
          'item_category: ${item.itemCategory}, item_category2: ${item.itemCategory2}, '
          'item_variant: ${item.itemVariant}, '
          'item_brand: ${item.itemBrand}, price: ${item.price}, quantity: ${item.quantity} }',
        );
      }
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
