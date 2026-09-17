import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// TEST ONLY: shared with Android Gradle. No production IDs or override flags.
/// Production rollout requires a separate, reviewed configuration.
class AdConfig {
  AdConfig._(this.bannerId, this.rewardedId);

  final String bannerId;
  final String rewardedId;

  static bool get enabled =>
      !kIsWeb &&
      !kReleaseMode &&
      defaultTargetPlatform == TargetPlatform.android;

  static Future<AdConfig> load() async {
    final json =
        jsonDecode(await rootBundle.loadString('config/admob_test.json'))
            as Map<String, dynamic>;
    const testPublisher = 'ca-app-pub-3940256099942544/';
    final banner = json['androidAdaptiveBannerId'] as String;
    final rewarded = json['androidRewardedId'] as String;
    if (json['mode'] != 'test' ||
        !banner.startsWith(testPublisher) ||
        !rewarded.startsWith(testPublisher)) {
      throw StateError('Only Google demo ad units are supported.');
    }
    return AdConfig._(banner, rewarded);
  }
}
