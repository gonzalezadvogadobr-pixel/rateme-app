import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/database_service.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import 'post_detail_screen.dart';

/// Perfil público de QUALQUER usuário (não o próprio)
class UserProfileScreen extends StatelessWidget {
  final String userId;
  const UserProfileScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return Consumer<DatabaseService>(builder: (context, db, _) {
      final user = db.getUserById(userId);
      if (user == null) {
        return Scaffold(
            appBar: AppBar(title: const Text('Perfil')),
            body: const Center(child: Text('Usuário não encontrado.')));
      }

      final posts      = db.getUserPosts(userId);
      final isFollowing = db.isFollowing(userId);
      final followers  = db.followersCount(userId);
      final following  = db.followingCount(userId);
      final isSelf     = userId == db.currentUser?.id;

      return Scaffold(
        backgroundColor: AppTheme.bgPrimary,
        appBar: AppBar(
          title: Text(user.name),
          actions: [
            if (!isSelf)
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: GestureDetector(
                  onTap: () => db.toggleFollow(userId),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      gradient:
                          isFollowing ? null : AppTheme.gradientPurplePink,
                      color:
                          isFollowing ? AppTheme.bgSurface : null,
                      borderRadius: BorderRadius.circular(20),
                      border: isFollowing
                          ? Border.all(color: AppTheme.textMuted)
                          : null,
                    ),
                    child: Text(
                      isFollowing ? 'Seguindo' : 'Seguir',
                      style: TextStyle(
                        color: isFollowing
                            ? AppTheme.textMuted
                            : Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
        body: SingleChildScrollView(
          child: Column(
            children: [
              // Header
              _buildHeader(user, posts.length, followers, following),
              const SizedBox(height: 16),
              // Grid de posts
              _buildPostGrid(context, posts),
              const SizedBox(height: 40),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildHeader(
      AppUser user, int postCount, int followers, int following) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(20),
        border:
            Border.all(color: AppTheme.purple.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          UserAvatar(
              avatarBase64: user.avatarBase64, name: user.name, size: 80),
          const SizedBox(height: 12),
          Text(
            user.name,
            style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.w800),
          ),
          if (user.bio.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              user.bio,
              style: const TextStyle(
                  color: AppTheme.textSecondary, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _Stat(value: '$postCount', label: 'Posts',
                  color: AppTheme.purpleLight),
              _Stat(value: '$followers', label: 'Seguidores',
                  color: AppTheme.pink),
              _Stat(value: '$following', label: 'Seguindo',
                  color: AppTheme.success),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPostGrid(BuildContext context, List<Post> posts) {
    if (posts.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Center(
          child: Text(
            'Nenhuma foto publicada ainda.',
            style: TextStyle(color: AppTheme.textMuted),
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 3,
          mainAxisSpacing: 3,
        ),
        itemCount: posts.length,
        itemBuilder: (context, i) {
          final post = posts[i];
          return GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => PostDetailScreen(postId: post.id)),
            ),
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: SizedBox.expand(
                    child: AppImage(
                        imageData: post.imageBase64, fit: BoxFit.cover),
                  ),
                ),
                // Score overlay
                Positioned(
                  bottom: 4,
                  right: 4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.65),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star_rounded,
                            color: AppTheme.warning, size: 10),
                        const SizedBox(width: 2),
                        Text(
                          post.notaMedia.toStringAsFixed(1),
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String value;
  final String label;
  final Color color;

  const _Stat(
      {required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
                color: color, fontSize: 22, fontWeight: FontWeight.w800)),
        Text(label,
            style: const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
      ],
    );
  }
}
