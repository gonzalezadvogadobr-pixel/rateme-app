import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/database_service.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import 'post_detail_screen.dart';

class RankingScreen extends StatelessWidget {
  const RankingScreen({super.key});

  static const int _minPins = 5;

  @override
  Widget build(BuildContext context) {
    return Consumer<DatabaseService>(builder: (context, db, _) {
      final top3 = db.getRankingPosts(minPins: _minPins);
      final allPosts = db.getFeedPosts();
      final filtered = allPosts.where((p) => p.totalPins < _minPins).length;

      return Scaffold(
        backgroundColor: AppTheme.bgPrimary,
        appBar: AppBar(
          title: const Text('Ranking'),
          actions: [
            Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.bgSurface,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Min. $_minPins pins',
                style: const TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: AppTheme.gradientPurplePink,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.emoji_events_rounded,
                        color: Colors.white, size: 48),
                    const SizedBox(height: 8),
                    const Text(
                      'Top 3 Fotos',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      'As fotos mais bem avaliadas',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Requer no mínimo $_minPins pins para entrar no ranking',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              if (top3.isEmpty) ...[
                _buildEmptyRanking(filtered),
              ] else ...[
                ...top3.asMap().entries.map((entry) {
                  return _RankingCard(
                    post: entry.value,
                    position: entry.key + 1,
                  );
                }),
              ],

              if (allPosts.length > 3) ...[
                const SizedBox(height: 24),
                const Divider(color: AppTheme.bgSurface),
                const SizedBox(height: 16),
                const Text(
                  'Outros posts',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                ...allPosts
                    .where((p) =>
                        !top3.any((t) => t.id == p.id) &&
                        p.totalPins < _minPins)
                    .map((p) => _OtherPostRow(post: p, minPins: _minPins)),
              ],
            ],
          ),
        ),
      );
    });
  }

  Widget _buildEmptyRanking(int filtered) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.purple.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          const Icon(Icons.hourglass_empty_rounded,
              size: 48, color: AppTheme.textMuted),
          const SizedBox(height: 16),
          const Text(
            'Nenhuma foto no ranking ainda',
            style: TextStyle(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            filtered > 0
                ? 'Há $filtered foto(s) aguardando mais avaliações.\nAvalie fotos adicionando pins para elas subirem no ranking!'
                : 'Publique fotos e avalie usando pins para preencher o ranking!',
            style:
                const TextStyle(color: AppTheme.textMuted, fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _RankingCard extends StatelessWidget {
  final Post post;
  final int position;

  const _RankingCard({required this.post, required this.position});

  Color get _medalColor {
    switch (position) {
      case 1:
        return AppTheme.goldColor;
      case 2:
        return AppTheme.silverColor;
      case 3:
        return AppTheme.bronzeColor;
      default:
        return AppTheme.textMuted;
    }
  }

  String get _medalEmoji {
    switch (position) {
      case 1:
        return '🥇';
      case 2:
        return '🥈';
      case 3:
        return '🥉';
      default:
        return '#$position';
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => PostDetailScreen(postId: post.id)),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: AppTheme.bgCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _medalColor.withValues(alpha: 0.4),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: _medalColor.withValues(alpha: 0.1),
              blurRadius: 12,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Column(
          children: [
            // Header com medalha
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: _medalColor.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: _medalColor.withValues(alpha: 0.5)),
                    ),
                    child: Center(
                      child: Text(
                        _medalEmoji,
                        style: const TextStyle(fontSize: 22),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          post.ownerName,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary),
                        ),
                        if (post.caption.isNotEmpty)
                          Text(
                            post.caption,
                            style: const TextStyle(
                                color: AppTheme.textSecondary, fontSize: 12),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  ScoreBadge(score: post.notaMedia, large: true),
                ],
              ),
            ),
            // Imagem
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(bottom: Radius.circular(14)),
              child: AspectRatio(
                aspectRatio: position == 1 ? 1 : 16 / 9,
                child: Stack(
                  children: [
                    SizedBox.expand(
                      child: AppImage(
                        imageData: post.imageBase64,
                        fit: BoxFit.cover,
                      ),
                    ),
                    // Overlay stats
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0.7),
                              Colors.transparent,
                            ],
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.push_pin_rounded,
                                color: Colors.white, size: 14),
                            const SizedBox(width: 4),
                            Text(
                              '${post.totalPins} pins',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(width: 12),
                            const Icon(Icons.people_rounded,
                                color: Colors.white, size: 14),
                            const SizedBox(width: 4),
                            Text(
                              '${post.totalAvaliadores} avaliadores',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OtherPostRow extends StatelessWidget {
  final Post post;
  final int minPins;

  const _OtherPostRow({required this.post, required this.minPins});

  @override
  Widget build(BuildContext context) {
    final pinsNeeded = minPins - post.totalPins;
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => PostDetailScreen(postId: post.id)),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.bgCard,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 56,
                height: 56,
                child: AppImage(
                    imageData: post.imageBase64, fit: BoxFit.cover),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    post.ownerName,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary),
                  ),
                  Text(
                    post.notaMedia > 0
                        ? 'Nota: ${post.notaMedia.toStringAsFixed(1)}/10'
                        : 'Sem avaliações',
                    style: const TextStyle(
                        color: AppTheme.textMuted, fontSize: 12),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${post.totalPins}/$minPins pins',
                  style: const TextStyle(
                      color: AppTheme.textMuted, fontSize: 11),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.warning.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Faltam $pinsNeeded',
                    style: const TextStyle(
                        color: AppTheme.warning,
                        fontSize: 10,
                        fontWeight: FontWeight.w600),
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
