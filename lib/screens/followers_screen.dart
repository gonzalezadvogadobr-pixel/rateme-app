import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/database_service.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import 'user_profile_screen.dart';

/// Tela que lista seguidores OU pessoas que o usuário segue.
/// [showFollowers] = true → "Seguidores"; false → "Seguindo"
class FollowersScreen extends StatelessWidget {
  final String userId;
  final bool showFollowers;

  const FollowersScreen({
    super.key,
    required this.userId,
    required this.showFollowers,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<DatabaseService>(builder: (context, db, _) {
      final List<AppUser> list = showFollowers
          ? db.getFollowersList(userId)
          : db.getFollowingList(userId);

      return Scaffold(
        backgroundColor: AppTheme.bgPrimary,
        appBar: AppBar(
          title: Text(showFollowers ? 'Seguidores' : 'Seguindo'),
        ),
        body: list.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.people_outline_rounded,
                        size: 64, color: AppTheme.textMuted),
                    const SizedBox(height: 16),
                    Text(
                      showFollowers
                          ? 'Nenhum seguidor ainda'
                          : 'Não está seguindo ninguém',
                      style: const TextStyle(
                          color: AppTheme.textSecondary, fontSize: 16),
                    ),
                  ],
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                itemCount: list.length,
                itemBuilder: (context, i) {
                  final user = list[i];
                  final isFollowing = db.isFollowing(user.id);
                  final isSelf = user.id == db.currentUser?.id;
                  return GestureDetector(
                    onTap: () {
                      if (!isSelf) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                UserProfileScreen(userId: user.id),
                          ),
                        );
                      }
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppTheme.bgCard,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isFollowing && !isSelf
                              ? AppTheme.purple.withValues(alpha: 0.35)
                              : AppTheme.bgSurface,
                        ),
                      ),
                      child: Row(
                        children: [
                          UserAvatar(
                            avatarBase64: user.avatarBase64,
                            name: user.name,
                            size: 48,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  user.name,
                                  style: const TextStyle(
                                    color: AppTheme.textPrimary,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                  ),
                                ),
                                if (user.bio.isNotEmpty)
                                  Text(
                                    user.bio,
                                    style: const TextStyle(
                                        color: AppTheme.textMuted,
                                        fontSize: 12),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                              ],
                            ),
                          ),
                          if (!isSelf) ...[
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () => db.toggleFollow(user.id),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 7),
                                decoration: BoxDecoration(
                                  gradient: isFollowing
                                      ? null
                                      : AppTheme.gradientPurplePink,
                                  color: isFollowing
                                      ? AppTheme.bgSurface
                                      : null,
                                  borderRadius: BorderRadius.circular(20),
                                  border: isFollowing
                                      ? Border.all(
                                          color: AppTheme.textMuted)
                                      : null,
                                ),
                                child: Text(
                                  isFollowing ? 'Seguindo' : 'Seguir',
                                  style: TextStyle(
                                    color: isFollowing
                                        ? AppTheme.textMuted
                                        : Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
      );
    });
  }
}
