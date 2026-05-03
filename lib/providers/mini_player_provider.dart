import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import '../models/video.dart';
import '../models/video_detail.dart';

class MiniPlayerProvider with ChangeNotifier {
  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController;
  String? _videoUrl;
  String? _videoTitle;
  Video? _video;
  int _episodeIndex = 0;
  int _progress = 0;
  bool _isPlaying = false;
  bool _miniPlayerEnabled = true;
  bool _initialized = false;

  static const String _keyMiniPlayerEnabled = 'mini_player_enabled';

  VideoPlayerController? get videoPlayerController => _videoPlayerController;
  ChewieController? get chewieController => _chewieController;
  String? get videoUrl => _videoUrl;
  String? get videoTitle => _videoTitle;
  Video? get video => _video;
  int get episodeIndex => _episodeIndex;
  int get progress => _progress;
  bool get isPlaying => _isPlaying;
  bool get miniPlayerEnabled => _miniPlayerEnabled;

  bool get hasMiniPlayer => _videoUrl != null && _chewieController != null;

  Future<void> init() async {
    if (_initialized) return;
    final prefs = await SharedPreferences.getInstance();
    _miniPlayerEnabled = prefs.getBool(_keyMiniPlayerEnabled) ?? true;
    _initialized = true;
    notifyListeners();
  }

  Future<void> setMiniPlayerEnabled(bool enabled) async {
    _miniPlayerEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyMiniPlayerEnabled, enabled);
    notifyListeners();
  }

  Future<void> toggleMiniPlayer() async {
    _miniPlayerEnabled = !_miniPlayerEnabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyMiniPlayerEnabled, _miniPlayerEnabled);
    notifyListeners();
  }

  Future<void> startMiniPlayer({
    required VideoPlayerController controller,
    required ChewieController chewieController,
    required String videoUrl,
    String? videoTitle,
    Video? video,
    int episodeIndex = 0,
    int progress = 0,
  }) async {
    _videoPlayerController = controller;
    _chewieController = chewieController;
    _videoUrl = videoUrl;
    _videoTitle = videoTitle;
    _video = video;
    _episodeIndex = episodeIndex;
    _progress = progress;
    _isPlaying = true;
    notifyListeners();
  }

  void stopMiniPlayer() {
    _videoPlayerController?.dispose();
    _chewieController?.dispose();
    _videoPlayerController = null;
    _chewieController = null;
    _videoUrl = null;
    _videoTitle = null;
    _video = null;
    _episodeIndex = 0;
    _progress = 0;
    _isPlaying = false;
    notifyListeners();
  }

  void pauseMiniPlayer() {
    _videoPlayerController?.pause();
    _isPlaying = false;
    notifyListeners();
  }

  void resumeMiniPlayer() {
    _videoPlayerController?.play();
    _isPlaying = true;
    notifyListeners();
  }

  void updateProgress(int progress) {
    _progress = progress;
    notifyListeners();
  }

  @override
  void dispose() {
    _videoPlayerController?.dispose();
    _chewieController?.dispose();
    super.dispose();
  }
}
