import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/video.dart';
import '../models/video_detail.dart';

class ApiService {
  static const String apiBase = 'http://api.ffzyapi.com/api.php/provide/vod/';

  static final Map<String, String> _headers = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
    'Accept': 'application/json, text/plain, */*',
    'Accept-Language': 'zh-CN,zh;q=0.9,en;q=0.8',
    'Referer': 'http://api.ffzyapi.com/',
  };

  static Map<String, String> get videoHeaders => _headers;

  Future<List<Video>> getVideoList({int page = 1, int? typeId}) async {
    try {
      String url = '$apiBase?ac=list&pg=$page';
      if (typeId != null) {
        url += '&t=$typeId';
      }
      
      final response = await http
          .get(Uri.parse(url), headers: _headers)
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['list'] != null) {
          List<Video> videos = (data['list'] as List)
              .map((item) => Video.fromJson(item))
              .toList();
          
          if (videos.isNotEmpty) {
            final ids = videos.take(20).map((v) => v.vodId).join(',');
            final detailResponse = await http
                .get(Uri.parse('$apiBase?ac=detail&ids=$ids'), headers: _headers)
                .timeout(const Duration(seconds: 15));
            
            if (detailResponse.statusCode == 200) {
              final detailData = json.decode(detailResponse.body);
              if (detailData['list'] != null) {
                final details = (detailData['list'] as List)
                    .map((item) => VideoDetail.fromJson(item))
                    .toList();
                
                final Map<int, String> picMap = {};
                for (var detail in details) {
                  picMap[detail.vodId] = detail.vodPic ?? '';
                }
                
                videos = videos.map((video) {
                  final pic = picMap[video.vodId];
                  if (pic != null && pic.isNotEmpty) {
                    return Video(
                      vodId: video.vodId,
                      vodName: video.vodName,
                      vodPic: pic,
                      vodRemarks: video.vodRemarks,
                      typeId: video.typeId,
                      typeName: video.typeName,
                      vodActor: video.vodActor,
                    );
                  }
                  return video;
                }).toList();
              }
            }
          }
          
          return videos;
        }
      }
      return [];
    } catch (e) {
      print('Error fetching video list: $e');
      return [];
    }
  }

  Future<List<Video>> searchVideo(String keyword, {int page = 1}) async {
    if (keyword.isEmpty) return [];
    
    try {
      final response = await http
          .get(Uri.parse('$apiBase?ac=detail&wd=$keyword&pg=$page'), headers: _headers)
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['list'] != null) {
          return (data['list'] as List)
              .map((item) => Video.fromJson(item))
              .toList();
        }
      }
      return [];
    } catch (e) {
      print('Error searching videos: $e');
      return [];
    }
  }

  Future<VideoDetail?> getVideoDetail(int id) async {
    try {
      final response = await http
          .get(Uri.parse('$apiBase?ac=detail&ids=$id'), headers: _headers)
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['list'] != null && (data['list'] as List).isNotEmpty) {
          return VideoDetail.fromJson(data['list'][0]);
        }
      }
      return null;
    } catch (e) {
      print('Error fetching video detail: $e');
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> getVideoTypes() async {
    try {
      final response = await http
          .get(Uri.parse('$apiBase?ac=type'), headers: _headers)
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['class'] != null) {
          return (data['class'] as List).cast<Map<String, dynamic>>();
        }
      }
      return [];
    } catch (e) {
      print('Error fetching video types: $e');
      return [];
    }
  }

  static String getProxyUrl(String url) {
    return url;
  }
}
