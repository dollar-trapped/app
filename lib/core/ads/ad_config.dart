import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Debug/profile use Google demo IDs; release uses validated production IDs.
class AdConfig {
  AdConfig._(this.bannerId, this.rewardedId);
  final String bannerId;
  final String? rewardedId;

  static bool get enabled =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
  static bool get isTest => !kReleaseMode;
  static bool get rewardedEnabled => enabled;

  static Future<AdConfig> load() async {
    final path = kReleaseMode
        ? 'config/admob_production.json'
        : 'config/admob_test.json';
    final json =
        jsonDecode(await rootBundle.loadString(path)) as Map<String, dynamic>;
    return AdConfig.fromJson(json, production: kReleaseMode);
  }

  @visibleForTesting
  factory AdConfig.fromJson(
    Map<String, dynamic> json, {
    required bool production,
  }) {
    const testPublisher = 'ca-app-pub-3940256099942544';
    final app = json['androidAppId'] as String;
    final banner = json['androidAdaptiveBannerId'] as String;
    final rewarded = json['androidRewardedId'] as String?;
    final ids = [app, banner, ?rewarded];
    if (rewarded == null ||
        json['mode'] != (production ? 'production' : 'test') ||
        !RegExp(r'^ca-app-pub-\d{16}~\d{10}$').hasMatch(app) ||
        !RegExp(r'^ca-app-pub-\d{16}/\d{10}$').hasMatch(banner) ||
        !RegExp(r'^ca-app-pub-\d{16}/\d{10}$').hasMatch(rewarded) ||
        (production
            ? ids.any((id) => id.startsWith(testPublisher))
            : ids.any((id) => !id.startsWith(testPublisher)))) {
      throw StateError('AdMob IDs do not match the build environment.');
    }
    return AdConfig._(banner, rewarded);
  }
}
