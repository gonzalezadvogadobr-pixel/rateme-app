import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/database_service.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import 'post_detail_screen.dart';
import 'create_post_screen.dart';
import 'search_screen.dart';
import 'notifications_screen.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  bool _showFollowingOnly = false;

  @override
  Widget build(BuildContext context) {
    return Consumer<DatabaseService>(builder: (context, db, _) {
      final allPosts      = db.getAllFeedPosts();
      final feedPosts     = _showFollowingOnly ? db.getFeedPosts() : allPosts;
      final unread        = db.unreadNotifCount;
      final hasFollowing  = db.followingIds(db.currentUser?.id ?? '').isNotEmpty;

      return Scaffold(
        backgroundColor: AppTheme.bgPrimary,
        appBar: AppBar(
          title: ShaderMask(
            shaderCallback: (bounds) =>
                AppTheme.gradientPurplePink.createShader(bounds),
            child: Text(
              'RateMe',
              style: GoogleFonts.dmSans(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
                color: Colors.white,
              ),
            ),
          ),
          actions: [
            // Busca
            IconButton(
              icon: const Icon(Icons.search_rounded,
                  color: AppTheme.textSecondary),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SearchScreen()),
              ),
            ),
            // Notificações com badge
            Stack(
              alignment: Alignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.notifications_outlined,
                      color: AppTheme.textSecondary),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const NotificationsScreen()),
                  ),
                ),
                if (unread > 0)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: const BoxDecoration(
                        color: AppTheme.pink,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          unread > 9 ? '9+' : '$unread',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
          bottom: hasFollowing
              ? PreferredSize(
                  preferredSize: const Size.fromHeight(42),
                  child: Container(
                    color: AppTheme.bgSecondary,
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: Row(
                      children: [
                        _TabChip(
                          label: 'Todos',
                          active: !_showFollowingOnly,
                          onTap: () =>
                              setState(() => _showFollowingOnly = false),
                        ),
                        const SizedBox(width: 8),
                        _TabChip(
                          label: 'Seguindo',
                          active: _showFollowingOnly,
                          onTap: () =>
                              setState(() => _showFollowingOnly = true),
                        ),
                      ],
                    ),
                  ),
                )
              : null,
        ),
        body: feedPosts.isEmpty
            ? _buildEmpty(context)
            : RefreshIndicator(
                color: AppTheme.purple,
                backgroundColor: Colors.white,
                onRefresh: () async {},
                child: ListView.builder(
                  padding: const EdgeInsets.only(top: 8, bottom: 80),
                  itemCount: feedPosts.length,
                  itemBuilder: (context, index) =>
                      _PostCard(post: feedPosts[index]),
                ),
              ),
      );
    });
  }

  Widget _buildEmpty(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.photo_library_outlined,
              size: 64, color: AppTheme.textMuted),
          const SizedBox(height: 16),
          Text(
            _showFollowingOnly
                ? 'Nenhum post de quem você segue'
                : 'Nenhum post ainda',
            style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 18,
                fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            _showFollowingOnly
                ? 'Siga mais pessoas para ver o feed deles.'
                : 'Seja o primeiro a compartilhar uma foto!',
            style: const TextStyle(color: AppTheme.textMuted),
          ),
          const SizedBox(height: 24),
          if (!_showFollowingOnly)
            ElevatedButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CreatePostScreen()),
              ),
              icon: const Icon(Icons.add_photo_alternate_rounded),
              label: const Text('Criar post'),
            ),
        ],
      ),
    );
  }
}

class _TabChip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _TabChip(
      {required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          gradient: active ? AppTheme.gradientPurplePink : null,
          color: active ? null : AppTheme.bgSurface,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? Colors.white : AppTheme.textMuted,
            fontWeight: active ? FontWeight.w700 : FontWeight.w500,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

class _PostCard extends StatelessWidget {
  final Post post;
  const _PostCard({required this.post});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => PostDetailScreen(postId: post.id)),
      ),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: AppTheme.bgCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFEEEEF5)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.07),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  UserAvatar(
                    avatarBase64: post.ownerAvatarBase64,
                    name: post.ownerName,
                    size: 38,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          post.ownerName,
                          style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontWeight: FontWeight.w700,
                              fontSize: 14),
                        ),
                        Text(
                          _timeAgo(post.createdAt),
                          style: const TextStyle(
                              color: AppTheme.textMuted, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  ScoreBadge(score: post.notaMedia),
                ],
              ),
            ),
            // Imagem — 50% mais alta que antes (3:4 portrait em vez de 4:3)
            AspectRatio(
              aspectRatio: 4 / 6,
              child: AppImage(imageData: post.imageBase64, fit: BoxFit.cover),
            ),
            // Footer
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (post.caption.isNotEmpty) ...[
                    RichText(
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: '${post.ownerName} ',
                            style: const TextStyle(
                                color: AppTheme.textPrimary,
                                fontWeight: FontWeight.w700,
                                fontSize: 13),
                          ),
                          TextSpan(
                            text: post.caption,
                            style: const TextStyle(
                                color: AppTheme.textSecondary, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  Row(
                    children: [
                      const Icon(Icons.push_pin_rounded,
                          size: 14, color: AppTheme.purpleLight),
                      const SizedBox(width: 4),
                      Text('${post.totalPins} pins',
                          style: const TextStyle(
                              color: AppTheme.textMuted, fontSize: 12)),
                      const SizedBox(width: 12),
                      const Icon(Icons.chat_bubble_outline_rounded,
                          size: 14, color: AppTheme.pink),
                      const SizedBox(width: 4),
                      Text('${post.totalComments}',
                          style: const TextStyle(
                              color: AppTheme.textMuted, fontSize: 12)),
                      const SizedBox(width: 12),
                      const Icon(Icons.people_outline_rounded,
                          size: 14, color: AppTheme.success),
                      const SizedBox(width: 4),
                      Text('${post.totalAvaliadores}',
                          style: const TextStyle(
                              color: AppTheme.textMuted, fontSize: 12)),
                      const Spacer(),
                      const Text('Ver →',
                          style: TextStyle(
                              color: AppTheme.purpleLight,
                              fontSize: 12,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'agora há pouco';
    if (diff.inMinutes < 60) return 'há ${diff.inMinutes}min';
    if (diff.inHours < 24)   return 'há ${diff.inHours}h';
    if (diff.inDays < 7)     return 'há ${diff.inDays}d';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}
