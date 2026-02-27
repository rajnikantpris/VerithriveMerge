import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService extends GetxService {
  static const String keyToken = 'token';

  SharedPreferences? _prefs;

  Future<StorageService> init() async {
    _prefs ??= await SharedPreferences.getInstance();
    return this;
  }

  Future<void> writeInt(String key, int value) async {
    await _prefs?.setInt(key, value);
  }

  int? readInt(String key) => _prefs?.getInt(key);

  Future<void> writeDouble(String key, double value) async {
    await _prefs?.setDouble(key, value);
  }

  double? readDouble(String key) => _prefs?.getDouble(key);

  Future<void> writeString(String key, String value) async {
    await _prefs?.setString(key, value);
  }

  String? readString(String key) => _prefs?.getString(key);

  Future<void> writeStringList(String key, List<String> value) async {
    await _prefs?.setStringList(key, value);
  }

  List<String>? readStringList(String key) => _prefs?.getStringList(key);

  Future<void> writeBool(String key, bool value) async {
    await _prefs?.setBool(key, value);
  }

  bool? readBool(String key) => _prefs?.getBool(key);

  Future<void> remove(String key) async {
    await _prefs?.remove(key);
  }

  Future<void> clear() async {
    await _prefs?.clear();
  }

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
