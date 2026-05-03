class VideoDetail {
  final int vodId;
  final String vodName;
  final String? vodPic;
  final String? vodArea;
  final String? vodYear;
  final String? vodActor;
  final String? vodDirector;
  final String? vodBlurb;
  final String? vodContent;
  final String? vodPlayUrl;
  final String? typeName;
  final String? vodRemarks;
  final int? typeId;

  VideoDetail({
    required this.vodId,
    required this.vodName,
    this.vodPic,
    this.vodArea,
    this.vodYear,
    this.vodActor,
    this.vodDirector,
    this.vodBlurb,
    this.vodContent,
    this.vodPlayUrl,
    this.typeName,
    this.vodRemarks,
    this.typeId,
  });

  String get displayPic {
    if (vodPic == null || vodPic!.isEmpty) return '';
    if (vodPic!.startsWith('http')) return vodPic!;
    if (vodPic!.startsWith('//')) return 'https:$vodPic';
    return 'https://$vodPic';
  }

  factory VideoDetail.fromJson(Map<String, dynamic> json) {
    return VideoDetail(
      vodId: int.parse(json['vod_id'].toString()),
      vodName: json['vod_name'] ?? '',
      vodPic: json['vod_pic'],
      vodArea: json['vod_area'],
      vodYear: json['vod_year'],
      vodActor: json['vod_actor'],
      vodDirector: json['vod_director'],
      vodBlurb: json['vod_blurb'],
      vodContent: json['vod_content'],
      vodPlayUrl: json['vod_play_url'],
      typeName: json['type_name'],
      vodRemarks: json['vod_remarks'],
      typeId: int.tryParse(json['type_id']?.toString() ?? ''),
    );
  }

  List<Episode> getEpisodes() {
    if (vodPlayUrl == null || vodPlayUrl!.isEmpty) return [];

    List<Episode> allEpisodes = [];
    List<String> sources = vodPlayUrl!.split(r'$$$');

    String? selectedSource;
    
    List<String> m3u8Sources = [];
    List<String> otherSources = [];
    
    for (var source in sources) {
      bool hasM3u8 = false;
      var urls = source.split('#').where((u) => u.trim().isNotEmpty).toList();
      for (var url in urls) {
        var parts = url.split('\$');
        var actualUrl = parts.length > 1 ? parts[1] : url;
        if (_isValidVideoUrl(actualUrl)) {
          if (actualUrl.contains('.m3u8')) {
            hasM3u8 = true;
          }
        }
      }
      
      if (hasM3u8) {
        m3u8Sources.add(source);
      } else {
        otherSources.add(source);
      }
    }

    if (m3u8Sources.isNotEmpty) {
      selectedSource = m3u8Sources.first;
    } else if (otherSources.isNotEmpty) {
      selectedSource = otherSources.first;
    } else if (sources.isNotEmpty) {
      selectedSource = sources.first;
    }

    if (selectedSource != null) {
      var urls = selectedSource.split('#').where((u) => u.trim().isNotEmpty).toList();
      for (int i = 0; i < urls.length; i++) {
        var parts = urls[i].split('\$');
        var name = parts[0].isNotEmpty ? parts[0] : '第${i + 1}集';
        var url = parts.length > 1 ? parts[1] : parts[0];
        
        if (_isValidVideoUrl(url)) {
          allEpisodes.add(Episode(name: name, url: url));
        }
      }
    }

    return allEpisodes;
  }

  bool _isValidVideoUrl(String url) {
    if (url.isEmpty) return false;
    String lowerUrl = url.toLowerCase();
    return lowerUrl.contains('.m3u8') ||
           lowerUrl.contains('.mp4') ||
           lowerUrl.contains('.mkv') ||
           lowerUrl.contains('.avi') ||
           lowerUrl.contains('.flv') ||
           lowerUrl.contains('player') ||
           lowerUrl.contains('play');
  }
}

class Episode {
  final String name;
  final String url;

  Episode({required this.name, required this.url});
}




