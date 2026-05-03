import 'package:flutter/foundation.dart';
import '../models/video.dart';
import '../models/video_detail.dart';
import '../services/api_service.dart';

class VideoProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<Video> _allVideos = [];
  List<Video> _searchResults = [];
  bool _isLoading = false;
  bool _hasMore = true;
  int _currentPage = 1;
  String _selectedType = 'all';
  String _keyword = '';
  bool _isSearching = false;
  List<Map<String, dynamic>> _types = [];

  static const Map<String, String> typeNames = {
    'all': '全部',
    '1': '电影',
    '2': '连续剧',
    '3': '综艺',
    '4': '动漫',
  };

  List<Video> get videos => _isSearching ? _searchResults : _allVideos;
  bool get isLoading => _isLoading;
  bool get hasMore => _hasMore;
  String get selectedType => _selectedType;
  String get keyword => _keyword;
  List<Map<String, dynamic>> get types => _types;

  Future<void> loadTypes() async {
    try {
      _types = await _apiService.getVideoTypes();
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading types: $e');
    }
  }

  Future<void> loadVideos({bool reset = false}) async {
    if (_isLoading) return;

    if (reset) {
      _currentPage = 1;
      _allVideos = [];
      _hasMore = true;
    }

    _isLoading = true;
    _isSearching = false;
    notifyListeners();

    try {
      int? typeId;
      if (_selectedType == 'all') {
        typeId = null;
      } else {
        typeId = int.tryParse(_selectedType);
      }
      
      final newVideos = await _apiService.getVideoList(page: _currentPage, typeId: typeId);

      if (newVideos.isNotEmpty) {
        _allVideos = [..._allVideos, ...newVideos];
        _currentPage++;
        _hasMore = newVideos.length >= 20;
      } else {
        _hasMore = false;
      }
    } catch (e) {
      debugPrint('Error loading videos: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> search(String keyword) async {
    _keyword = keyword.trim();
    
    if (_keyword.isEmpty) {
      _isSearching = false;
      _searchResults = [];
      notifyListeners();
      return;
    }

    _isLoading = true;
    _isSearching = true;
    _currentPage = 1;
    notifyListeners();

    try {
      final results = await _apiService.searchVideo(_keyword, page: _currentPage);
      _searchResults = results;
      _hasMore = results.length >= 20;
    } catch (e) {
      debugPrint('Error searching videos: $e');
      _searchResults = [];
    }

    _isLoading = false;
    notifyListeners();
  }

  void selectType(String type) {
    if (_selectedType == type) return;
    _selectedType = type;
    _keyword = '';
    
    loadVideos(reset: true);
  }

  Future<VideoDetail?> getVideoDetail(int id) async {
    return await _apiService.getVideoDetail(id);
  }
}
