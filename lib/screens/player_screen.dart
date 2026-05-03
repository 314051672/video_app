﻿import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/video_detail.dart';
import '../models/video.dart';
import '../providers/history_provider.dart';
import '../providers/mini_player_provider.dart';
import '../services/video_preload_service.dart';
import '../theme/app_theme.dart';
import 'web_fallback_player_screen.dart';

class PlayerScreen extends StatefulWidget {
  final VideoDetail videoDetail;
  final int initialEpisodeIndex;
  final int initialProgress;

  const PlayerScreen({
    super.key,
    required this.videoDetail,
    this.initialEpisodeIndex = 0,
    this.initialProgress = 0,
  });

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController;
  int _currentEpisodeIndex = 0;
  bool _isLoading = true;
  String? _errorMessage;
  double _videoAspectRatio = 16 / 9;
  bool _isDoubleSpeed = false;
  double _originalSpeed = 1.0;

  @override
  void initState() {
    super.initState();
    _currentEpisodeIndex = widget.initialEpisodeIndex;
    _initializePlayer();
  }

  @override
  void dispose() {
    _saveCurrentProgress();
    _videoPlayerController?.removeListener(_onVideoProgressChanged);
    _videoPlayerController?.pause();
    _videoPlayerController?.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  void _onVideoProgressChanged() {
    if (_videoPlayerController != null && _videoPlayerController!.value.isPlaying) {
      final position = _videoPlayerController!.value.position.inSeconds;
      final duration = _videoPlayerController!.value.duration.inSeconds;
      if (duration > 0 && position > 0 && position % 10 == 0 && position < duration - 5) {
        _saveProgress(position);
      }
    }
  }

  void _saveCurrentProgress() {
    if (_videoPlayerController != null) {
      final position = _videoPlayerController!.value.position.inSeconds;
      if (position > 0) {
        _saveProgress(position);
      }
    }
  }

  Future<void> _initializePlayer() async {
    final episodes = widget.videoDetail.getEpisodes();
    
    if (episodes.isEmpty) {
      setState(() {
        _isLoading = false;
        _errorMessage = '没有可播放的视频';
      });
      return;
    }

    if (_currentEpisodeIndex >= episodes.length) {
      _currentEpisodeIndex = 0;
    }

    final episode = episodes[_currentEpisodeIndex];
    await _loadVideo(episode.url);
  }

  Future<void> _loadVideo(String videoUrl, {bool isRetry = false}) async {
    if (!mounted) return;

    if (!isRetry) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    final oldController = _videoPlayerController;
    final oldChewie = _chewieController;
    _videoPlayerController = null;
    _chewieController = null;

    oldController?.removeListener(_onVideoProgressChanged);
    oldController?.pause();
    oldChewie?.dispose();
    oldController?.dispose();

    try {
      final preloadedController = VideoPreloadService().takePreloadedController(videoUrl);
      
      if (preloadedController != null) {
        _videoPlayerController = preloadedController;
      } else {
        _videoPlayerController = VideoPlayerController.networkUrl(
          Uri.parse(videoUrl),
          videoPlayerOptions: VideoPlayerOptions(
            mixWithOthers: false,
          ),
        );

        await _videoPlayerController!.initialize();
      }

      if (!mounted) {
        _videoPlayerController?.dispose();
        return;
      }
      
      double rawAspectRatio = _videoPlayerController!.value.aspectRatio;
      
      if (rawAspectRatio < 0.4 || rawAspectRatio > 2.5) {
        rawAspectRatio = 16 / 9;
      }
      _videoAspectRatio = rawAspectRatio;

      if (widget.initialProgress > 0 && _currentEpisodeIndex == widget.initialEpisodeIndex) {
        await _videoPlayerController!.seekTo(Duration(seconds: widget.initialProgress));
      }

      _videoPlayerController!.addListener(_onVideoProgressChanged);

      _chewieController = ChewieController(
        videoPlayerController: _videoPlayerController!,
        autoPlay: true,
        looping: false,
        aspectRatio: _videoAspectRatio,
        allowFullScreen: true,
        allowMuting: true,
        showControls: true,
        placeholder: Container(
          color: Colors.black,
          child: const Center(
            child: CircularProgressIndicator(color: AppTheme.primary),
          ),
        ),
        errorBuilder: (context, errorMessage) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, color: Colors.red, size: 42),
                const SizedBox(height: 8),
                Text(
                  '播放出错',
                  style: TextStyle(color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _retryWithNextSource,
                  child: const Text('尝试其他播放源'),
                ),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: _openInWebFallback,
                  child: const Text('网页兜底播放'),
                ),
              ],
            ),
          );
        },
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = '视频加载失败: $e';
        });
      }
    }
  }

  void _retryWithNextSource() {
    final episodes = widget.videoDetail.getEpisodes();
    if (episodes.isEmpty) return;

    final nextIndex = (_currentEpisodeIndex + 1) % episodes.length;
    if (nextIndex != _currentEpisodeIndex) {
      _currentEpisodeIndex = nextIndex;
      _loadVideo(episodes[nextIndex].url, isRetry: true);
    }
  }

  void _onDoubleSpeedStart() {
    if (_videoPlayerController != null && _videoPlayerController!.value.isPlaying) {
      _originalSpeed = _videoPlayerController!.value.playbackSpeed;
      _videoPlayerController!.setPlaybackSpeed(2.0);
      setState(() {
        _isDoubleSpeed = true;
      });
    }
  }

  void _onDoubleSpeedEnd() {
    if (_videoPlayerController != null) {
      _videoPlayerController!.setPlaybackSpeed(_originalSpeed > 0 ? _originalSpeed : 1.0);
      setState(() {
        _isDoubleSpeed = false;
      });
    }
  }

  void _saveProgress(int position) {
    if (!mounted) return;

    final historyProvider = context.read<HistoryProvider>();
    final existingItem = historyProvider.getHistoryItem(widget.videoDetail.vodId);

    if (existingItem != null) {
      historyProvider.updateProgressSilently(
        widget.videoDetail.vodId,
        episodeIndex: _currentEpisodeIndex,
        progress: position,
      );
    } else {
      final video = Video(
        vodId: widget.videoDetail.vodId,
        vodName: widget.videoDetail.vodName,
        vodPic: widget.videoDetail.vodPic,
        vodRemarks: widget.videoDetail.vodRemarks,
        typeId: widget.videoDetail.typeId,
        typeName: widget.videoDetail.typeName,
      );
      historyProvider.addToHistory(
        video,
        episodeIndex: _currentEpisodeIndex,
        progress: position,
      );
    }
  }

  void _copyVideoUrl() {
    final episodes = widget.videoDetail.getEpisodes();
    if (episodes.isEmpty || _currentEpisodeIndex >= episodes.length) return;
    
    final url = episodes[_currentEpisodeIndex].url;
    Clipboard.setData(ClipboardData(text: url));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('视频地址已复制'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  
  Future<void> _openInExternalPlayer() async {
    final episodes = widget.videoDetail.getEpisodes();
    if (episodes.isEmpty || _currentEpisodeIndex >= episodes.length) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('没有可用的播放地址')),
      );
      return;
    }

    final rawUrl = episodes[_currentEpisodeIndex].url.trim();
    final uri = Uri.tryParse(rawUrl);
    if (uri == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('播放地址无效')),
      );
      return;
    }

    try {
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('无法调用外部播放器')),
        );
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('打开外部播放器失败')),
      );
    }
  }
  
  Future<void> _openInWebFallback() async {
    final episodes = widget.videoDetail.getEpisodes();
    if (episodes.isEmpty || _currentEpisodeIndex >= episodes.length) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('没有可用的播放地址')),
      );
      return;
    }

    final url = episodes[_currentEpisodeIndex].url.trim();
    if (url.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('播放地址为空')),
      );
      return;
    }

    final title = '${widget.videoDetail.vodName} - ${episodes[_currentEpisodeIndex].name}';
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => WebFallbackPlayerScreen(
          url: url,
          title: title,
        ),
      ),
    );
  }
  void _showEpisodeSelector() {
    final episodes = widget.videoDetail.getEpisodes();

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.6,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '选集',
                      style: AppTheme.titleMedium.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: episodes.length,
                  itemBuilder: (context, index) {
                    final isSelected = index == _currentEpisodeIndex;
                    return ListTile(
                      title: Text(
                        episodes[index].name,
                        style: TextStyle(
                          color: isSelected ? AppTheme.primary : null,
                          fontWeight: isSelected ? FontWeight.bold : null,
                        ),
                      ),
                      trailing: isSelected
                          ? const Icon(Icons.play_arrow, color: AppTheme.primary)
                          : null,
                      onTap: () {
                        Navigator.pop(context);
                        _currentEpisodeIndex = index;
                        _loadVideo(episodes[index].url);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _transferToMiniPlayer() {
    if (_videoPlayerController == null || _chewieController == null) return;

    final episodes = widget.videoDetail.getEpisodes();
    final videoTitle = episodes.isNotEmpty && _currentEpisodeIndex < episodes.length
        ? '${widget.videoDetail.vodName} - ${episodes[_currentEpisodeIndex].name}'
        : widget.videoDetail.vodName;

    final currentPosition = _videoPlayerController?.value.position.inSeconds ?? 0;

    final video = Video(
      vodId: widget.videoDetail.vodId,
      vodName: widget.videoDetail.vodName,
      vodPic: widget.videoDetail.vodPic,
      vodRemarks: widget.videoDetail.vodRemarks,
      typeId: widget.videoDetail.typeId,
      typeName: widget.videoDetail.typeName,
    );

    context.read<MiniPlayerProvider>().startMiniPlayer(
      controller: _videoPlayerController!,
      chewieController: _chewieController!,
      videoUrl: episodes.isNotEmpty ? episodes[_currentEpisodeIndex].url : '',
      videoTitle: videoTitle,
      video: video,
      episodeIndex: _currentEpisodeIndex,
      progress: currentPosition,
    );

    _videoPlayerController = null;
    _chewieController = null;
  }

  @override
  Widget build(BuildContext context) {
    final miniPlayerEnabled = context.select<MiniPlayerProvider, bool>((p) => p.miniPlayerEnabled);
    
    return WillPopScope(
      onWillPop: () async {
        if (miniPlayerEnabled && _videoPlayerController != null) {
          _transferToMiniPlayer();
          return true;
        }
        _videoPlayerController?.pause();
        _videoPlayerController?.dispose();
        _chewieController?.dispose();
        _videoPlayerController = null;
        _chewieController = null;
        return true;
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          title: Text(
            widget.videoDetail.vodName,
            style: const TextStyle(fontSize: 16),
          ),
          actions: [
            IconButton(
              icon: Icon(
                miniPlayerEnabled ? Icons.picture_in_picture_alt : Icons.picture_in_picture_alt_outlined,
                color: miniPlayerEnabled ? AppTheme.primary : null,
              ),
              onPressed: () {
                context.read<MiniPlayerProvider>().toggleMiniPlayer();
              },
              tooltip: '小窗预览',
            ),
            IconButton(
              onPressed: _copyVideoUrl,
              icon: const Icon(Icons.share),
              tooltip: '复制视频地址',
            ),
            IconButton(
              onPressed: _openInWebFallback,
              icon: const Icon(Icons.public),
              tooltip: '网页兜底',
            ),
            IconButton(
              onPressed: _showEpisodeSelector,
              icon: const Icon(Icons.list),
            ),
          ],
        ),
        body: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppTheme.primary),
              )
            : _errorMessage != null
                ? _buildErrorWidget()
                : _chewieController != null
                    ? Stack(
                        children: [
                          Center(
                            child: AspectRatio(
                              aspectRatio: _videoAspectRatio,
                              child: Chewie(controller: _chewieController!),
                            ),
                          ),
                          Positioned.fill(
                            child: GestureDetector(
                              onLongPressStart: (_) => _onDoubleSpeedStart(),
                              onLongPressEnd: (_) => _onDoubleSpeedEnd(),
                              behavior: HitTestBehavior.translucent,
                            ),
                          ),
                          if (_isDoubleSpeed)
                            Positioned(
                              top: 60,
                              left: 0,
                              right: 0,
                              child: Center(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.black54,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Text(
                                    '2X 倍速',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      )
                    : const Center(
                        child: Text(
                          '无法加载播放器',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 64),
            const SizedBox(height: 16),
            Text(
              _errorMessage ?? '播放失败',
              style: const TextStyle(color: Colors.white, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 12,
              runSpacing: 12,
              children: [
                ElevatedButton.icon(
                  onPressed: _initializePlayer,
                  icon: const Icon(Icons.refresh),
                  label: const Text('重试'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: _retryWithNextSource,
                  icon: const Icon(Icons.skip_next),
                  label: const Text('换一集'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: _openInWebFallback,
                  icon: const Icon(Icons.public),
                  label: const Text('网页兜底'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}


