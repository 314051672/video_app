import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:chewie/chewie.dart';
import '../providers/video_provider.dart';
import '../providers/history_provider.dart';
import '../providers/mini_player_provider.dart';
import '../models/video.dart';
import '../models/video_detail.dart';
import '../widgets/video_card.dart';
import '../widgets/category_tabs.dart';
import '../theme/app_theme.dart';
import 'detail_screen.dart';
import 'history_screen.dart';
import 'player_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<VideoProvider>().loadTypes();
      context.read<VideoProvider>().loadVideos(reset: true);
    });
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      final provider = context.read<VideoProvider>();
      if (!provider.isLoading && provider.hasMore) {
        provider.loadVideos();
      }
    }
  }

  void _handleSearch() {
    final query = _searchController.text.trim();
    if (query.isNotEmpty) {
      context.read<VideoProvider>().search(query);
      _searchFocusNode.unfocus();
    }
  }

  void _clearSearch() {
    _searchController.clear();
    context.read<VideoProvider>().search('');
    context.read<VideoProvider>().selectType('all');
  }

  void _openHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const HistoryScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                _buildAppBar(),
                CategoryTabs(
                  selectedType: context.watch<VideoProvider>().selectedType,
                  onTypeSelected: (type) {
                    context.read<VideoProvider>().selectType(type);
                  },
                ),
                Expanded(
                  child: Consumer<VideoProvider>(
                    builder: (context, provider, child) {
                      if (provider.videos.isEmpty && provider.isLoading) {
                        return _buildShimmerGrid();
                      }

                      if (provider.videos.isEmpty) {
                        return _buildEmptyState();
                      }

                      return RefreshIndicator(
                        color: AppTheme.primary,
                        onRefresh: () async {
                          await context.read<VideoProvider>().loadVideos(reset: true);
                        },
                        child: GridView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(16),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.7,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                          ),
                          itemCount: provider.videos.length,
                          itemBuilder: (context, index) {
                            final video = provider.videos[index];
                            return VideoCard(
                              video: video,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => DetailScreen(videoId: video.vodId),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
            _buildMiniPlayer(),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniPlayer() {
    return Consumer<MiniPlayerProvider>(
      builder: (context, miniPlayer, child) {
        if (!miniPlayer.hasMiniPlayer || !miniPlayer.miniPlayerEnabled) {
          return const SizedBox.shrink();
        }

        return Positioned(
          bottom: 20,
          right: 20,
          child: GestureDetector(
            onTap: () {
              if (miniPlayer.video != null) {
                _openFullScreenPlayer(context, miniPlayer);
              } else {
                if (miniPlayer.isPlaying) {
                  miniPlayer.pauseMiniPlayer();
                } else {
                  miniPlayer.resumeMiniPlayer();
                }
              }
            },
            child: Container(
              width: 160,
              height: 90,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.5),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Chewie(controller: miniPlayer.chewieController!),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: GestureDetector(
                        onTap: () {
                          miniPlayer.stopMiniPlayer();
                        },
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.close, color: Colors.white, size: 14),
                        ),
                      ),
                    ),
                    if (miniPlayer.video != null)
                      Positioned(
                        bottom: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () {
                            _openFullScreenPlayer(context, miniPlayer);
                          },
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.fullscreen, color: Colors.white, size: 18),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _openFullScreenPlayer(BuildContext context, MiniPlayerProvider miniPlayer) async {
    final video = miniPlayer.video;
    if (video == null) return;

    final currentEpisodeIndex = miniPlayer.episodeIndex;
    final currentProgress =
        miniPlayer.videoPlayerController?.value.position.inSeconds ?? miniPlayer.progress;

    final videoProvider = context.read<VideoProvider>();
    final detail = await videoProvider.getVideoDetail(video.vodId);

    if (detail != null && context.mounted) {
      miniPlayer.stopMiniPlayer();
      
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PlayerScreen(
            videoDetail: detail,
            initialEpisodeIndex: currentEpisodeIndex,
            initialProgress: currentProgress,
          ),
        ),
      );
    }
  }

  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppTheme.background.withOpacity(0.95),
            AppTheme.background.withOpacity(0.8),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: _clearSearch,
                child: Row(
                  children: [
                    Icon(
                      Icons.movie_filter_rounded,
                      color: AppTheme.primary,
                      size: 28,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '影视搜索',
                      style: AppTheme.headlineMedium.copyWith(
                        color: AppTheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: _openHistory,
                icon: Icon(
                  Icons.history_rounded,
                  color: AppTheme.textSecondary,
                  size: 24,
                ),
                tooltip: '历史记录',
              ),
              if (_searchController.text.isNotEmpty)
                IconButton(
                  onPressed: _clearSearch,
                  icon: Icon(
                    Icons.close,
                    color: AppTheme.textSecondary,
                    size: 20,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              style: AppTheme.bodyLarge.copyWith(color: AppTheme.textPrimary),
              decoration: InputDecoration(
                hintText: '搜索影片、演员、导演...',
                hintStyle: AppTheme.bodyLarge.copyWith(color: AppTheme.textHint),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: AppTheme.textSecondary,
                  size: 24,
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                        },
                        icon: Icon(
                          Icons.close,
                          color: AppTheme.textSecondary,
                          size: 20,
                        ),
                      )
                    : IconButton(
                        onPressed: _handleSearch,
                        icon: Icon(
                          Icons.search_rounded,
                          color: AppTheme.primary,
                          size: 24,
                        ),
                      ),
                filled: true,
                fillColor: AppTheme.cardBackground,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
              ),
              onSubmitted: (_) => _handleSearch(),
              onChanged: (_) => setState(() {}),
              textInputAction: TextInputAction.search,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerGrid() {
    return Shimmer.fromColors(
      baseColor: AppTheme.cardBackground,
      highlightColor: AppTheme.surface,
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.7,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: 6,
        itemBuilder: (context, index) {
          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.movie_filter_rounded,
            size: 80,
            color: AppTheme.textHint,
          ),
          const SizedBox(height: 16),
          Text(
            '暂无内容',
            style: AppTheme.bodyLarge.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: CircularProgressIndicator(
          color: AppTheme.primary,
          strokeWidth: 2,
        ),
      ),
    );
  }
}

