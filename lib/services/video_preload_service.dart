import 'package:video_player/video_player.dart';
import 'package:flutter/foundation.dart';

class VideoPreloadService {
  static final VideoPreloadService _instance = VideoPreloadService._internal();
  factory VideoPreloadService() => _instance;
  VideoPreloadService._internal();

  VideoPlayerController? _preloadedController;
  String? _preloadedUrl;
  bool _isPreloading = false;

  String? get preloadedUrl => _preloadedUrl;

  Future<void> preloadVideo(String url) async {
    if (url == _preloadedUrl && _preloadedController != null) return;
    if (_isPreloading) return;

    _isPreloading = true;

    _preloadedController?.dispose();
    _preloadedController = null;
    _preloadedUrl = null;

    try {
      final controller = VideoPlayerController.networkUrl(
        Uri.parse(url),
        videoPlayerOptions: VideoPlayerOptions(mixWithOthers: false),
      );

      await controller.initialize();

      if (_preloadedUrl != url) {
        _preloadedController = controller;
        _preloadedUrl = url;
      } else {
        controller.dispose();
      }
    } catch (e) {
      debugPrint('Preload failed for $url: $e');
    } finally {
      _isPreloading = false;
    }
  }

  VideoPlayerController? takePreloadedController(String url) {
    if (url == _preloadedUrl && _preloadedController != null) {
      final controller = _preloadedController;
      _preloadedController = null;
      _preloadedUrl = null;
      return controller;
    }
    return null;
  }

  void cancelPreload() {
    _preloadedController?.dispose();
    _preloadedController = null;
    _preloadedUrl = null;
    _isPreloading = false;
  }

  void dispose() {
    _preloadedController?.dispose();
    _preloadedController = null;
    _preloadedUrl = null;
  }
}