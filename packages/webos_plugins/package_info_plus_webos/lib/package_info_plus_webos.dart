import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

import 'package:package_info_plus_platform_interface/package_info_data.dart';
import 'package:package_info_plus_platform_interface/package_info_platform_interface.dart';

/// The webOS implementation of [PackageInfoPlatform].
class PackageInfoPlusWebOSPlugin extends PackageInfoPlatform {
  /// Register this dart class as the platform implementation for webOS
  static void registerWith() {
    PackageInfoPlatform.instance = PackageInfoPlusWebOSPlugin();
  }

  /// Returns a map with the following keys:
  /// appName, packageName, version, buildNumber
  @override
  Future<PackageInfoData> getAll({String? baseUrl}) async {
    final versionJson = await _getVersionJson();
    return PackageInfoData(
      appName: versionJson['app_name'] ?? '',
      version: versionJson['version'] ?? '',
      buildNumber: versionJson['build_number'] ?? '',
      packageName: versionJson['package_name'] ?? '',
      buildSignature: '',
    );
  }

  Future<Map<String, dynamic>> _getVersionJson() async {
    try {
      String data = await rootBundle.loadString("version.json");
      return jsonDecode(data);
    } catch (_) {
      return <String, dynamic>{};
    }
  }
}
