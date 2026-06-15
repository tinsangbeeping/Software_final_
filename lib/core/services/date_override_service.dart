import 'package:shared_preferences/shared_preferences.dart';

class DateOverrideService {
  static const String _overrideKey = 'debug_date_override';
  static const String _enabledKey = 'debug_date_enabled';

  static DateOverrideService? _instance;
  late SharedPreferences _prefs;

  DateOverrideService._();

  static Future<DateOverrideService> getInstance() async {
    if (_instance == null) {
      _instance = DateOverrideService._();
      _instance!._prefs = await SharedPreferences.getInstance();
    }
    return _instance!;
  }

  DateTime now() {
    if (!isEnabled) return DateTime.now();
    final override = _prefs.getString(_overrideKey);
    if (override == null) return DateTime.now();
    try {
      return DateTime.parse(override);
    } catch (_) {
      return DateTime.now();
    }
  }

  bool get isEnabled => _prefs.getBool(_enabledKey) ?? false;

  Future<void> setOverride(DateTime date) async {
    await _prefs.setString(_overrideKey, date.toIso8601String());
    await _prefs.setBool(_enabledKey, true);
  }

  Future<void> clearOverride() async {
    await _prefs.remove(_overrideKey);
    await _prefs.setBool(_enabledKey, false);
  }

  String? get overrideString => _prefs.getString(_overrideKey);
}
