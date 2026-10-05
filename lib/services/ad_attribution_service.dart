import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Reports iOS ad conversion values through AdAttributionKit.
///
/// Flutter talks to native Swift over [MethodChannel]. The Swift side calls
/// AdAttributionKit, and Apple later POSTs a winning-postback copy to the
/// domain configured as AttributionCopyEndpoint. This does not identify the
/// user; Apple only returns campaign-level attribution.
class AdAttributionService {
  AdAttributionService._();

  static final AdAttributionService instance = AdAttributionService._();

  static const MethodChannel _channel =
      MethodChannel('com.verithrive/adattribution');

  /// Opens the conversion window. Call once at startup.
  static const int appOpen = 0;

  bool _started = false;

  Future<void> start() async {
    if (_started || !Platform.isIOS) return;
    _started = true;
    await updateConversionValue(appOpen);
  }

  /// Fine values are 0...63. [coarseValue] is `low`, `medium`, or `high`.
  ///
  /// [lockPostback] ends the current conversion window early.
  Future<void> updateConversionValue(
    int conversionValue, {
    String? coarseValue,
    bool lockPostback = false,
  }) async {
    if (!Platform.isIOS) return;

    final value = conversionValue.clamp(0, 63);
    try {
      await _channel.invokeMethod<void>('updateConversionValue', {
        'conversionValue': value,
        'coarseValue': coarseValue,
        'lockPostback': lockPostback,
      });
    } on PlatformException catch (e) {
      debugPrint('AdAttributionService: ${e.message}');
    } catch (e) {
      debugPrint('AdAttributionService: $e');
    }
  }
}
