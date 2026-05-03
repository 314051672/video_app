import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/history_provider.dart';
import '../providers/video_provider.dart';
import '../widgets/video_card.dart';
import '../theme/app_theme.dart';
import 'detail_screen.dart';
import 'player_screen.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.cardBackground,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: AppTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '历史记录',
          style: AppTheme.titleLarge.copyWith(color: AppTheme.textPrimary),
        ),
        actions: [
          Consumer<HistoryProvider>(
            builder: (context, provider, _) {
              if (provider.history.isEmpty) return const SizedBox();
              return TextButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      backgroundColor: AppTheme.cardBackground,
                      title: Text(
                        '清空历史',
                        style: TextStyle(color: AppTheme.textPrimary),
                      ),
                      content: Text(
                        '确定要清空所有历史记录吗？',
                        style: TextStyle(color: AppTheme.textSecondary),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: Text('取消', style: TextStyle(color: AppTheme.textSecondary)),
                        ),
                        TextButton(
                          onPressed: () {
                            provider.clearHistory();
                            Navigator.pop(ctx);
                          },
                          child: Text('确定', style: TextStyle(color: AppTheme.primary)),
                        ),
                      ],
                    ),
                  );
                },
                child: Text(
                  '清空',
                  style: TextStyle(color: AppTheme.primary),
                ),
              );
            },
          ),
        ],
      ),
      body: Consumer<HistoryProvider>(
        builder: (context, provider, _) {
          if (provider.history.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.history_rounded,
                    size: 80,
                    color: AppTheme.textHint,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '暂无历史记录',
                    style: AppTheme.bodyLarge.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: provider.history.length,
            itemBuilder: (context, index) {
              final video = provider.history[index];
              return Dismissible(
                key: Key('history_${video.vodId}'),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  color: Colors.red,
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                onDismissed: (_) {
                  provider.removeFromHistory(video.vodId);
                },
                child: VideoCard(
                  video: video,
                  onTap: () async {
                    final videoProvider = context.read<VideoProvider>();
                    final detail = await videoProvider.getVideoDetail(video.vodId);
                    if (detail != null && context.mounted) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PlayerScreen(
                            videoDetail: detail,
                            initialEpisodeIndex: video.episodeIndex,
                            initialProgress: video.progress,
                          ),
                        ),
                      );
                    } else if (context.mounted) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DetailScreen(videoId: video.vodId),
                        ),
                      );
                    }
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
