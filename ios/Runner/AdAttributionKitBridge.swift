import Foundation
import Flutter
import AdAttributionKit

/// Native side of the Flutter MethodChannel that talks to AdAttributionKit.
///
/// Apple only starts a postback conversion window after the advertised app
/// updates the conversion value at least once. This bridge does that on first
/// launch and forwards later updates from Dart.
enum AdAttributionReporter {
  static let channelName = "com.verithrive/adattribution"
  private static let storedValueKey = "ad_attribution_last_fine_value"

  static func startConversionWindow() {
    Task {
      await update(fine: 0, coarse: nil, lockPostback: false)
    }
  }

  static func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard call.method == "updateConversionValue" else {
      result(FlutterMethodNotImplemented)
      return
    }

    let args = call.arguments as? [String: Any]
    let fine = args?["conversionValue"] as? Int ?? 0
    let coarse = args?["coarseValue"] as? String
    let lock = args?["lockPostback"] as? Bool ?? false

    Task {
      let errorMessage = await update(fine: fine, coarse: coarse, lockPostback: lock)
      await MainActor.run {
        if let errorMessage {
          result(FlutterError(code: "ad_attribution", message: errorMessage, details: nil))
        } else {
          result(nil)
        }
      }
    }
  }

  /// Sends a fine conversion value (0...63) to AdAttributionKit.
  ///
  /// A later call with a lower value is ignored so a routine app open cannot
  /// wipe a higher conversion already reported in this install.
  @discardableResult
  static func update(fine: Int, coarse: String?, lockPostback: Bool) async -> String? {
    guard #available(iOS 17.4, *) else {
      return nil
    }

    let value = min(max(fine, 0), 63)
    let defaults = UserDefaults.standard
    if defaults.object(forKey: storedValueKey) != nil {
      let last = defaults.integer(forKey: storedValueKey)
      if value < last && !lockPostback {
        return nil
      }
    }

    do {
      if let coarse, !coarse.isEmpty {
        try await Postback.updateConversionValue(
          value,
          coarseConversionValue: coarseConversion(coarse),
          lockPostback: lockPostback
        )
      } else {
        try await Postback.updateConversionValue(value, lockPostback: lockPostback)
      }
      defaults.set(value, forKey: storedValueKey)
      return nil
    } catch {
      NSLog("AdAttributionKit update failed: \(error.localizedDescription)")
      return error.localizedDescription
    }
  }

  @available(iOS 17.4, *)
  private static func coarseConversion(_ raw: String) -> CoarseConversionValue {
    switch raw.lowercased() {
    case "medium":
      return .medium
    case "high":
      return .high
    default:
      return .low
    }
  }
}
