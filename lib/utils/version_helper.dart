import 'package:shared_preferences/shared_preferences.dart';
import 'package:package_info_plus/package_info_plus.dart';

const _shownWarningKey = 'shown_warning_version';

Future<String> getAppVersion() async {
  final info = await PackageInfo.fromPlatform();
  return info.version;
}

Future<bool> hasShownXiaomiWarning(String version) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString(_shownWarningKey) == version;
}

Future<void> markXiaomiWarningShown(String version) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(_shownWarningKey, version);
}
