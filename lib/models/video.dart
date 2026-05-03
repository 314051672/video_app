class Video {
  final int vodId;
  final String vodName;
  final String? vodPic;
  final String? vodRemarks;
  final int? typeId;
  final String? typeName;
  final String? vodActor;
  final int episodeIndex;
  final int progress;

  Video({
    required this.vodId,
    required this.vodName,
    this.vodPic,
    this.vodRemarks,
    this.typeId,
    this.typeName,
    this.vodActor,
    this.episodeIndex = 0,
    this.progress = 0,
  });

  String get displayPic {
    if (vodPic == null || vodPic!.isEmpty) return '';
    if (vodPic!.startsWith('http')) return vodPic!;
    if (vodPic!.startsWith('//')) return 'https:$vodPic';
    return 'https://$vodPic';
  }

  factory Video.fromJson(Map<String, dynamic> json) {
    return Video(
      vodId: int.parse(json['vod_id'].toString()),
      vodName: json['vod_name'] ?? '',
      vodPic: json['vod_pic'],
      vodRemarks: json['vod_remarks'],
      typeId: json['type_id'] != null ? int.parse(json['type_id'].toString()) : null,
      typeName: json['type_name'],
      vodActor: json['vod_actor'],
      episodeIndex: json['episode_index'] ?? 0,
      progress: json['progress'] ?? 0,
    );
  }

  Video copyWith({
    int? vodId,
    String? vodName,
    String? vodPic,
    String? vodRemarks,
    int? typeId,
    String? typeName,
    String? vodActor,
    int? episodeIndex,
    int? progress,
  }) {
    return Video(
      vodId: vodId ?? this.vodId,
      vodName: vodName ?? this.vodName,
      vodPic: vodPic ?? this.vodPic,
      vodRemarks: vodRemarks ?? this.vodRemarks,
      typeId: typeId ?? this.typeId,
      typeName: typeName ?? this.typeName,
      vodActor: vodActor ?? this.vodActor,
      episodeIndex: episodeIndex ?? this.episodeIndex,
      progress: progress ?? this.progress,
    );
  }
}
