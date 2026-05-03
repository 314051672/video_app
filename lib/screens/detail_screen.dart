import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../models/video.dart';
import '../models/video_detail.dart';
import '../providers/video_provider.dart';
import '../providers/history_provider.dart';
import '../services/video_preload_service.dart';
import '../theme/app_theme.dart';
import 'player_screen.dart';

class DetailScreen extends StatefulWidget {
  final int videoId;

  const DetailScreen({super.key, required this.videoId});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  VideoDetail? _videoDetail;
  bool _isLoading = true;
  int _selectedEpisodeIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  @override
  void dispose() {
    VideoPreloadService().cancelPreload();
    super.dispose();
  }

  Future<void> _loadDetail() async {
    final detail = await context.read<VideoProvider>().getVideoDetail(widget.videoId);
    if (mounted) {
      setState(() {
        _videoDetail = detail;
        _isLoading = false;
      });
      if (detail != null) {
        final video = Video(
          vodId: detail.vodId,
          vodName: detail.vodName,
          vodPic: detail.vodPic,
          vodRemarks: detail.vodRemarks,
          typeId: detail.typeId,
          typeName: detail.typeName,
        );
        context.read<HistoryProvider>().addToHistory(video);

        final episodes = detail.getEpisodes();
        if (episodes.isNotEmpty) {
          final historyItem = context.read<HistoryProvider>().getHistoryItem(detail.vodId);
          final preloadIndex = historyItem?.episodeIndex ?? _selectedEpisodeIndex;
          if (preloadIndex < episodes.length) {
            VideoPreloadService().preloadVideo(episodes[preloadIndex].url);
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: _isLoading
          ? _buildLoading()
          : _videoDetail == null
              ? _buildError()
              : _buildContent(),
    );
  }

  Widget _buildLoading() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppTheme.primary,
              borderRadius: BorderRadius.circular(28),
            ),
            child: const Center(
              child: SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation(Colors.white),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            '正在加载...',
            style: AppTheme.bodyMedium.copyWith(color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline_rounded,
            size: 64,
            color: AppTheme.textHint,
          ),
          const SizedBox(height: 16),
          Text(
            '加载失败',
            style: AppTheme.titleMedium.copyWith(color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _loadDetail,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: const Text('重新加载'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    final detail = _videoDetail!;
    final episodes = detail.getEpisodes();

    return CustomScrollView(
      slivers: [
        // 顶部图片和应用栏
        SliverAppBar(
          expandedHeight: 260,
          pinned: true,
          backgroundColor: AppTheme.background,
          leading: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.5),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          flexibleSpace: FlexibleSpaceBar(
            background: Stack(
              fit: StackFit.expand,
              children: [
                // 封面图
                if (detail.displayPic.isNotEmpty)
                  CachedNetworkImage(
                    imageUrl: detail.displayPic,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: AppTheme.cardBackground,
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: AppTheme.cardBackground,
                      child: const Icon(
                        Icons.movie,
                        color: AppTheme.textSecondary,
                        size: 48,
                      ),
                    ),
                  )
                else
                  Container(
                    color: AppTheme.cardBackground,
                    child: const Icon(
                      Icons.movie,
                      color: AppTheme.textSecondary,
                      size: 48,
                    ),
                  ),
                
                // 渐变遮罩
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.3),
                        Colors.black.withOpacity(0.8),
                        AppTheme.background,
                      ],
                      stops: const [0.0, 0.4, 0.7, 1.0],
                    ),
                  ),
                ),
                
                // 标题
                Positioned(
                  left: 20,
                  right: 20,
                  bottom: 16,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        detail.vodName,
                        style: AppTheme.headlineMedium.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      if (detail.vodRemarks != null && detail.vodRemarks!.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.primary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            detail.vodRemarks!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        
        // 内容区域
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 影片信息
                _buildInfoSection(detail),
                
                const SizedBox(height: 24),
                
                // 简介
                if (detail.vodBlurb != null && detail.vodBlurb!.isNotEmpty) ...[
                  Text(
                    '简介',
                    style: AppTheme.titleMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    detail.vodBlurb!,
                    style: AppTheme.bodyMedium.copyWith(
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
                
                // 播放列表
                if (episodes.isNotEmpty) ...[
                  _buildEpisodeSection(episodes),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoSection(VideoDetail detail) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _buildInfoRow(Icons.category_rounded, '类型', detail.typeName ?? '未知'),
          const Divider(height: 20, color: AppTheme.borderColor),
          _buildInfoRow(Icons.public_rounded, '地区', detail.vodArea ?? '未知'),
          const Divider(height: 20, color: AppTheme.borderColor),
          _buildInfoRow(Icons.calendar_today_rounded, '年份', detail.vodYear ?? '未知'),
          const Divider(height: 20, color: AppTheme.borderColor),
          _buildInfoRow(Icons.person_rounded, '导演', detail.vodDirector ?? '未知'),
          const Divider(height: 20, color: AppTheme.borderColor),
          _buildInfoRow(Icons.group_rounded, '主演', detail.vodActor ?? '未知'),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppTheme.primary),
        const SizedBox(width: 12),
        Text(
          '$label：',
          style: AppTheme.bodyMedium.copyWith(color: AppTheme.textSecondary),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: AppTheme.bodyMedium.copyWith(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEpisodeSection(List<Episode> episodes) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  Icons.playlist_play_rounded,
                  color: AppTheme.primary,
                  size: 22,
                ),
                const SizedBox(width: 8),
                Text(
                  '播放列表',
                  style: AppTheme.titleMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '共${episodes.length}集',
                style: AppTheme.caption.copyWith(
                  color: AppTheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        // 播放按钮
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              final historyItem = context.read<HistoryProvider>().getHistoryItem(_videoDetail!.vodId);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PlayerScreen(
                    videoDetail: _videoDetail!,
                    initialEpisodeIndex: historyItem?.episodeIndex ?? _selectedEpisodeIndex,
                    initialProgress: historyItem?.progress ?? 0,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.play_circle_fill_rounded, size: 24),
            label: Text(
              '开始播放',
              style: AppTheme.titleMedium.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 4,
            ),
          ),
        ),
        
        const SizedBox(height: 20),
        
        // 剧集列表
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: episodes.asMap().entries.map((entry) {
            final index = entry.key;
            final episode = entry.value;
            final isSelected = index == _selectedEpisodeIndex;

            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedEpisodeIndex = index;
                });
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PlayerScreen(
                      videoDetail: _videoDetail!,
                      initialEpisodeIndex: index,
                    ),
                  ),
                );
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.primary : AppTheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? AppTheme.primary : AppTheme.borderColor,
                    width: isSelected ? 2 : 1,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: AppTheme.primary.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.play_arrow_rounded,
                      size: 16,
                      color: isSelected ? Colors.white : AppTheme.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      episode.name,
                      style: TextStyle(
                        color: isSelected ? Colors.white : AppTheme.textPrimary,
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        
        const SizedBox(height: 40),
      ],
    );
  }
}
