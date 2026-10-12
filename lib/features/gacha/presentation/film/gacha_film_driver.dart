import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:video_player/video_player.dart';
import '../gacha_controller.dart';
import 'gacha_film_track.dart';

/// A local movie supplies the intro clock. The existing controller owns rewards.
/// Only after the final film frame does its free-running card timeline resume.
class GachaFilmDriver extends ChangeNotifier {
  GachaFilmDriver(this.scene, {required this.onFallback}) {
    video = VideoPlayerController.asset(
      'assets/gacha/film/${scene.result.highest.name}.mp4',
      videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
    );
    video.addListener(_observe);
    scene.addListener(_guardClock);
  }
  final GachaController scene;
  final VoidCallback onFallback;
  late final VideoPlayerController video;
  GachaFilmTrack? track;
  bool ready = false, failed = false, finished = false;
  bool _disposed = false, _suspended = false, _started = false;
  Timer? _watchdog, _initialDeadline;
  Duration _position = Duration.zero;
  DateTime _lastProgress = DateTime.now();
  double get introEnd => scene.timeline.bounds[6].toDouble();

  Future<void> start() async {
    if (_started || scene.complete) return;
    _started = true;
    _initialDeadline = Timer(const Duration(seconds: 8), _fallback);
    try {
      await video.initialize();
      if (_disposed || failed || scene.complete) return;
      track = await GachaFilmTrack.load();
      await video.setVolume(0);
      if (_disposed || failed || scene.complete) return;
      _initialDeadline?.cancel();
      ready = true;
      scene.start(held: true);
      notifyListeners();
      _lastProgress = DateTime.now();
      _watchdog = Timer.periodic(const Duration(seconds: 2), (_) {
        if (!_suspended &&
            !finished &&
            !scene.complete &&
            DateTime.now().difference(_lastProgress).inSeconds >= 6) {
          _fallback();
        }
      });
      if (!_suspended) await video.play();
    } catch (_) {
      _fallback();
    }
  }

  void _observe() {
    if (_disposed || failed || finished || scene.complete) return;
    if (video.value.hasError) {
      _fallback();
      return;
    }
    if (!ready || _suspended) return;
    final value = video.value;
    if (value.position != _position) {
      _position = value.position;
      _lastProgress = DateTime.now();
    }
    final position = value.position.inMicroseconds / 1000.0;
    if (value.isCompleted || position >= introEnd) {
      finished = true;
      _watchdog?.cancel();
      scene.clock.value = introEnd / scene.timeline.totalMs;
      scene.clock.forward();
      notifyListeners();
    } else if (value.isBuffering || !value.isPlaying) {
      scene.clock.stop();
    } else {
      // Interpolate on Flutter's vsync between native position reports; correct
      // drift rather than running two independent clocks for the whole clip.
      if ((scene.ms - position).abs() > 75) {
        scene.clock.value =
            position.clamp(0, introEnd) / scene.timeline.totalMs;
      }
      if (!scene.clock.isAnimating) scene.clock.forward();
    }
  }

  void _guardClock() {
    if (_disposed || failed) return;
    if (scene.complete) {
      _watchdog?.cancel();
      _initialDeadline?.cancel();
      unawaited(video.pause().catchError((Object _) {}));
    } else if (ready && !finished && scene.ms >= introEnd) {
      scene.clock.stop();
      scene.clock.value = (introEnd - .01) / scene.timeline.totalMs;
    }
  }

  void _fallback() {
    if (_disposed || failed || scene.complete) return;
    failed = true;
    ready = false;
    _watchdog?.cancel();
    _initialDeadline?.cancel();
    unawaited(video.pause().catchError((Object _) {}));
    onFallback();
    scene.start(held: _suspended);
    if (!_suspended) scene.clock.forward();
    notifyListeners();
  }

  void pause() {
    _suspended = true;
    scene.pause();
    unawaited(video.pause().catchError((Object _) {}));
  }

  void resume() {
    _suspended = false;
    _lastProgress = DateTime.now();
    if (scene.complete) return;
    if (failed || finished) {
      scene.clock.forward();
    } else if (ready) {
      unawaited(video.play().catchError((Object _) => _fallback()));
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _watchdog?.cancel();
    _initialDeadline?.cancel();
    scene.removeListener(_guardClock);
    video.removeListener(_observe);
    unawaited(video.dispose().catchError((Object _) {}));
    super.dispose();
  }
}
