import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/database_service.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import 'post_detail_screen.dart';
import 'followers_screen.dart';

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

      final posts       = db.getUserPosts(userId);
      final isFollowing = db.isFollowing(userId);
      final isBlocked   = db.isBlocked(userId);
      final followers   = db.followersCount(userId);
      final following   = db.followingCount(userId);
      final isSelf      = userId == db.currentUser?.id;

      return Scaffold(
        backgroundColor: AppTheme.bgPrimary,
        appBar: AppBar(
          title: Text(user.name),
          actions: [
            if (!isSelf) ...[
              // Seguir / Seguindo
              Padding(
                padding: const EdgeInsets.only(right: 8),
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
              // Menu (bloquear/desbloquear)
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert_rounded,
                    color: AppTheme.textSecondary),
                color: AppTheme.bgCard,
                onSelected: (value) async {
                  if (value == 'block') {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (_) => AlertDialog(
                        backgroundColor: AppTheme.bgCard,
                        title: Text(
                          isBlocked
                              ? 'Desbloquear ${user.name}?'
                              : 'Bloquear ${user.name}?',
                          style: const TextStyle(
                              color: AppTheme.textPrimary),
                        ),
                        content: Text(
                          isBlocked
                              ? 'Este usuário poderá ver seus posts e interagir com você novamente.'
                              : 'Este usuário não poderá ver seus posts. Você também deixará de segui-lo.',
                          style: const TextStyle(
                              color: AppTheme.textSecondary),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () =>
                                Navigator.pop(context, false),
                            child: const Text('Cancelar'),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isBlocked
                                  ? AppTheme.success
                                  : AppTheme.error,
                            ),
                            onPressed: () =>
                                Navigator.pop(context, true),
                            child: Text(
                                isBlocked ? 'Desbloquear' : 'Bloquear'),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      await db.toggleBlock(userId);
                      if (context.mounted) Navigator.pop(context);
                    }
                  }
                },
                itemBuilder: (_) => [
                  PopupMenuItem(
                    value: 'block',
                    child: Row(
                      children: [
                        Icon(
                          isBlocked
                              ? Icons.lock_open_rounded
                              : Icons.block_rounded,
                          color: isBlocked
                              ? AppTheme.success
                              : AppTheme.error,
                          size: 18,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          isBlocked
                              ? 'Desbloquear usuário'
                              : 'Bloquear usuário',
                          style: TextStyle(
                            color: isBlocked
                                ? AppTheme.success
                                : AppTheme.error,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 4),
            ],
          ],
        ),
        body: isBlocked
            // Usuário bloqueado — mostra aviso
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.block_rounded,
                        size: 64, color: AppTheme.textMuted),
                    const SizedBox(height: 16),
                    const Text(
                      'Você bloqueou este usuário.',
                      style: TextStyle(
                          color: AppTheme.textSecondary, fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => db.toggleBlock(userId),
                      child: const Text('Desbloquear',
                          style: TextStyle(color: AppTheme.purpleLight)),
                    ),
                  ],
                ),
              )
            : SingleChildScrollView(
                child: Column(
                  children: [
                    // Header
                    _buildHeader(context, db, user, posts.length,
                        followers, following),
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
    BuildContext context,
    DatabaseService db,
    AppUser user,
    int postCount,
    int followers,
    int following,
  ) {
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
              _Stat(
                value: '$postCount',
                label: 'Posts',
                color: AppTheme.purpleLight,
                onTap: null,
              ),
              _Stat(
                value: '$followers',
                label: 'Seguidores',
                color: AppTheme.pink,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => FollowersScreen(
                      userId: userId,
                      showFollowers: true,
                    ),
                  ),
                ),
              ),
              _Stat(
                value: '$following',
                label: 'Seguindo',
                color: AppTheme.success,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => FollowersScreen(
                      userId: userId,
                      showFollowers: false,
                    ),
                  ),
                ),
              ),
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
  final VoidCallback? onTap;

  const _Stat({
    required this.value,
    required this.label,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Text(value,
              style: TextStyle(
                  color: color,
                  fontSize: 22,
                  fontWeight: FontWeight.w800)),
          Text(
            label,
            style: TextStyle(
              color: onTap != null
                  ? color.withValues(alpha: 0.7)
                  : AppTheme.textMuted,
              fontSize: 11,
              decoration:
                  onTap != null ? TextDecoration.underline : null,
            ),
          ),
        ],
      ),
    );
  }
}
