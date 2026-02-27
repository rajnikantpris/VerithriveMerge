import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService extends GetxService {
  SharedPreferences? _prefs;

  Future<StorageService> init() async {
    _prefs ??= await SharedPreferences.getInstance();
    return this;
  }

  Future<void> writeString(String key, String value) async {
    await _prefs?.setString(key, value);
  }

  String? readString(String key) => _prefs?.getString(key);

  Future<void> writeBool(String key, bool value) async {
    await _prefs?.setBool(key, value);
  }

  bool? readBool(String key) => _prefs?.getBool(key);

  /// Clear all stored data except the specified keys
  Future<void> clearAllExcept(List<String> keysToKeep) async {
    if (_prefs == null) return;

    final allKeys = _prefs!.getKeys();
    for (final key in allKeys) {
      if (!keysToKeep.contains(key)) {
        await _prefs!.remove(key);
      }
    }
  }

  /// Get all stored keys
  Set<String> getAllKeys() {
    return _prefs?.getKeys() ?? <String>{};
  }
}
