import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/database_service.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import 'user_profile_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _searchCtrl = TextEditingController();
  List<AppUser> _results = [];
  bool _searched = false;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _search(DatabaseService db) {
    setState(() {
      _results = db.searchUsers(_searchCtrl.text);
      _searched = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DatabaseService>(builder: (context, db, _) {
      // Sugestões: usuários que o current NÃO segue ainda
      final followedIds = db.followingIds(db.currentUser?.id ?? '').toSet();
      final suggestions = db.users
          .where((u) =>
              u.id != db.currentUser?.id && !followedIds.contains(u.id))
          .toList();

      return Scaffold(
        backgroundColor: AppTheme.bgPrimary,
        appBar: AppBar(
          title: const Text('Buscar Pessoas'),
        ),
        body: Column(
          children: [
            // Campo de busca
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: TextField(
                controller: _searchCtrl,
                style: const TextStyle(color: AppTheme.textPrimary),
                onChanged: (v) {
                  if (v.trim().isEmpty) {
                    setState(() {
                      _results = [];
                      _searched = false;
                    });
                  } else {
                    _search(db);
                  }
                },
                decoration: InputDecoration(
                  hintText: 'Nome ou e-mail…',
                  prefixIcon: const Icon(Icons.search_rounded,
                      color: AppTheme.textMuted),
                  suffixIcon: _searchCtrl.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close,
                              color: AppTheme.textMuted, size: 18),
                          onPressed: () {
                            _searchCtrl.clear();
                            setState(() {
                              _results = [];
                              _searched = false;
                            });
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: AppTheme.bgCard,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  // Resultados de busca
                  if (_searched && _results.isEmpty) ...[
                    const SizedBox(height: 40),
                    const Center(
                      child: Text(
                        'Nenhum usuário encontrado.',
                        style: TextStyle(color: AppTheme.textMuted),
                      ),
                    ),
                  ] else if (_results.isNotEmpty) ...[
                    const _SectionLabel('Resultados'),
                    ..._results.map((u) => _UserTile(user: u, db: db)),
                  ],

                  // Sugestões (só mostra se não está pesquisando)
                  if (!_searched && suggestions.isNotEmpty) ...[
                    const _SectionLabel('Sugestões para você'),
                    ...suggestions.map((u) => _UserTile(user: u, db: db)),
                  ],

                  // Seguindo
                  if (!_searched && followedIds.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    const _SectionLabel('Quem você segue'),
                    ...db.users
                        .where((u) => followedIds.contains(u.id))
                        .map((u) => _UserTile(user: u, db: db)),
                  ],
                ],
              ),
            ),
          ],
        ),
      );
    });
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 12, 0, 8),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          color: AppTheme.textMuted,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1,
        ),
      ),
    );
  }
}

class _UserTile extends StatelessWidget {
  final AppUser user;
  final DatabaseService db;

  const _UserTile({required this.user, required this.db});

  @override
  Widget build(BuildContext context) {
    final isFollowing = db.isFollowing(user.id);
    final posts       = db.getUserPosts(user.id).length;
    final followers   = db.followersCount(user.id);

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => UserProfileScreen(userId: user.id)),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.bgCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isFollowing
                ? AppTheme.purple.withValues(alpha: 0.35)
                : AppTheme.bgSurface,
          ),
        ),
        child: Row(
          children: [
            UserAvatar(
                avatarBase64: user.avatarBase64, name: user.name, size: 48),
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
                        fontSize: 15),
                  ),
                  if (user.bio.isNotEmpty)
                    Text(
                      user.bio,
                      style: const TextStyle(
                          color: AppTheme.textMuted, fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _MiniStat(
                          icon: Icons.photo_outlined,
                          value: '$posts',
                          label: 'posts'),
                      const SizedBox(width: 12),
                      _MiniStat(
                          icon: Icons.people_outline_rounded,
                          value: '$followers',
                          label: 'seguidores'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Botão Follow/Unfollow
            GestureDetector(
              onTap: () => db.toggleFollow(user.id),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  gradient: isFollowing ? null : AppTheme.gradientPurplePink,
                  color: isFollowing ? AppTheme.bgSurface : null,
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
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _MiniStat(
      {required this.icon, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 12, color: AppTheme.textMuted),
        const SizedBox(width: 3),
        Text(
          '$value $label',
          style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
        ),
      ],
    );
  }
}
