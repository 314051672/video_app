import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/video.dart';

class HistoryProvider with ChangeNotifier {
  static const String _historyKey = 'video_history';
  List<Video> _history = [];
  
  List<Video> get history => _history;

  Future<void> loadHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getString(_historyKey);
      if (historyJson != null) {
        final List<dynamic> decoded = json.decode(historyJson);
        _history = decoded.map((item) => Video.fromJson(item)).toList();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading history: $e');
    }
  }

  Future<void> addToHistory(Video video, {int episodeIndex = 0, int progress = 0}) async {
    try {
      _history.removeWhere((v) => v.vodId == video.vodId);
      _history.insert(0, video.copyWith(episodeIndex: episodeIndex, progress: progress));
      if (_history.length > 50) {
        _history = _history.take(50).toList();
      }
      
      final prefs = await SharedPreferences.getInstance();
      final historyJson = json.encode(_history.map((v) => {
        'vod_id': v.vodId,
        'vod_name': v.vodName,
        'vod_pic': v.vodPic,
        'vod_remarks': v.vodRemarks,
        'type_id': v.typeId,
        'type_name': v.typeName,
        'episode_index': v.episodeIndex,
        'progress': v.progress,
      }).toList());
      await prefs.setString(_historyKey, historyJson);
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error adding to history: $e');
    }
  }

  Future<void> updateProgressSilently(int vodId, {int episodeIndex = 0, int progress = 0}) async {
    try {
      final index = _history.indexWhere((v) => v.vodId == vodId);
      if (index == -1) return;

      _history[index] = _history[index].copyWith(
        episodeIndex: episodeIndex,
        progress: progress,
      );

      final prefs = await SharedPreferences.getInstance();
      final historyJson = json.encode(_history.map((v) => {
        'vod_id': v.vodId,
        'vod_name': v.vodName,
        'vod_pic': v.vodPic,
        'vod_remarks': v.vodRemarks,
        'type_id': v.typeId,
        'type_name': v.typeName,
        'episode_index': v.episodeIndex,
        'progress': v.progress,
      }).toList());
      await prefs.setString(_historyKey, historyJson);
    } catch (e) {
      debugPrint('Error updating progress silently: $e');
    }
  }

  Video? getHistoryItem(int vodId) {
    try {
      return _history.firstWhere((v) => v.vodId == vodId);
    } catch (e) {
      return null;
    }
  }

  Future<void> removeFromHistory(int vodId) async {
    try {
      _history.removeWhere((v) => v.vodId == vodId);
      
      final prefs = await SharedPreferences.getInstance();
      final historyJson = json.encode(_history.map((v) => {
        'vod_id': v.vodId,
        'vod_name': v.vodName,
        'vod_pic': v.vodPic,
        'vod_remarks': v.vodRemarks,
        'type_id': v.typeId,
        'type_name': v.typeName,
        'episode_index': v.episodeIndex,
        'progress': v.progress,
      }).toList());
      await prefs.setString(_historyKey, historyJson);
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error removing from history: $e');
    }
  }

  Future<void> clearHistory() async {
    try {
      _history.clear();
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_historyKey);
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error clearing history: $e');
    }
  }
}
