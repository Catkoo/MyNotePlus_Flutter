import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';

Future<bool> isXiaomiOrPoco() async {
  if (!Platform.isAndroid) return false;
  final deviceInfo = await DeviceInfoPlugin().androidInfo;
  final brand = deviceInfo.brand?.toLowerCase() ?? '';
  return brand.contains('xiaomi') ||
      brand.contains('poco') ||
      brand.contains('redmi');
}
