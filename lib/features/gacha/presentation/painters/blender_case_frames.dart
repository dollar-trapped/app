import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../grade_config.dart';

/// Original, locally modelled Blender case. Decode once per route, never in paint.
class BlenderCaseFrames {
  BlenderCaseFrames(this.quality);
  final GachaQuality quality;
  static const frameCount = 24;
  static const assetDirectory = 'assets/gacha/case';
  final List<ui.Image> _frames = [];
  Future<void>? _loading;
  bool _disposed = false;
  bool get ready => _frames.length == frameCount;
  int get decodedCount => _frames.length;

  Future<void> prepare() => _loading ??= _decode();

  Future<void> _decode() async {
    final pending = <ui.Image>[];
    try {
      for (var i = 0; i < frameCount; i++) {
        if (_disposed) return;
        final data = await rootBundle.load(
          '$assetDirectory/case_${i.toString().padLeft(2, '0')}.png',
        );
        if (_disposed) return;
        final codec = await ui.instantiateImageCodec(
          data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
          targetWidth: quality == GachaQuality.high ? 640 : 384,
        );
        try {
          pending.add((await codec.getNextFrame()).image);
        } finally {
          codec.dispose();
        }
      }
      if (!_disposed) {
        _frames.addAll(pending);
        pending.clear();
      }
    } catch (error) {
      debugPrint('Gacha case frames unavailable: $error');
    } finally {
      for (final frame in pending) {
        frame.dispose();
      }
    }
  }

  ui.Image? frameAt(double opening) =>
      ready ? _frames[(opening.clamp(0, 1) * (frameCount - 1)).round()] : null;

  void dispose() {
    _disposed = true;
    for (final frame in _frames) {
      frame.dispose();
    }
    _frames.clear();
  }
}
