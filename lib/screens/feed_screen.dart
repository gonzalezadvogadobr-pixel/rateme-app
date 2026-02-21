import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../services/database_service.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import 'post_detail_screen.dart';
import 'create_post_screen.dart';
import 'search_screen.dart';
import 'notifications_screen.dart';
import 'user_profile_screen.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  bool _showFollowingOnly = false;

  @override
  Widget build(BuildContext context) {
    final db = context.watch<DatabaseService>();
    final unread = db.unreadNotifCount;
    final hasFollowing = db.followingIds(db.currentUser?.id ?? '').isNotEmpty;
    final followedIds = db.followingIds(db.currentUser?.id ?? '').toSet();
    final myId = db.currentUser?.id ?? '';

    return Scaffold(
      backgroundColor: AppTheme.bgPrimary,
      appBar: AppBar(
        title: ShaderMask(
          shaderCallback: (bounds) =>
              AppTheme.gradientPurplePink.createShader(bounds),
          child: Text(
            'PinZap',
            style: GoogleFonts.dmSans(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
              color: Colors.white,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded, color: AppTheme.textSecondary),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SearchScreen()),
            ),
          ),
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined, color: AppTheme.textSecondary),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                ),
              ),
              if (unread > 0)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: const BoxDecoration(color: AppTheme.pink, shape: BoxShape.circle),
                    child: Center(
                      child: Text(
                        unread > 9 ? '9+' : '$unread',
                        style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700),
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
                      _TabChip(label: 'Todos', active: !_showFollowingOnly,
                          onTap: () => setState(() => _showFollowingOnly = false)),
                      const SizedBox(width: 8),
                      _TabChip(label: 'Seguindo', active: _showFollowingOnly,
                          onTap: () => setState(() => _showFollowingOnly = true)),
                    ],
                  ),
                ),
              )
            : null,
      ),
      body: Column(
        children: [
          // ── Stories ──────────────────────────────────────────────────────────
          _StoriesBar(),
          // ── Feed ─────────────────────────────────────────────────────────────
          Expanded(
            child: StreamBuilder<List<Post>>(
              stream: db.postsStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator(color: AppTheme.purple));
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.wifi_off_rounded, size: 64, color: AppTheme.textMuted),
                        const SizedBox(height: 16),
                        const Text('Erro ao carregar feed.\nVerifique sua conexão.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AppTheme.textSecondary, fontSize: 16)),
                        const SizedBox(height: 16),
                        ElevatedButton(onPressed: () => setState(() {}), child: const Text('Tentar novamente')),
                      ],
                    ),
                  );
                }

                List<Post> allPosts = snapshot.data ?? [];
                List<Post> feedPosts;
                if (_showFollowingOnly && followedIds.isNotEmpty) {
                  final relevant = {...followedIds, myId};
                  feedPosts = allPosts.where((p) => relevant.contains(p.ownerId)).toList();
                  if (feedPosts.isEmpty) feedPosts = allPosts;
                } else {
                  feedPosts = allPosts;
                }

                if (feedPosts.isEmpty) return _buildEmpty(context);

                return RefreshIndicator(
                  color: AppTheme.purple,
                  backgroundColor: Colors.white,
                  onRefresh: () async => setState(() {}),
                  child: ListView.builder(
                    padding: const EdgeInsets.only(bottom: 80),
                    itemCount: feedPosts.length,
                    itemBuilder: (context, index) => _PostCard(post: feedPosts[index]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.photo_library_outlined, size: 64, color: AppTheme.textMuted),
          const SizedBox(height: 16),
          Text(
            _showFollowingOnly ? 'Nenhum post de quem você segue' : 'Nenhum post ainda',
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            _showFollowingOnly ? 'Siga mais pessoas para ver o feed deles.' : 'Seja o primeiro a compartilhar uma foto!',
            style: const TextStyle(color: AppTheme.textMuted),
          ),
          const SizedBox(height: 24),
          if (!_showFollowingOnly)
            ElevatedButton.icon(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CreatePostScreen())),
              icon: const Icon(Icons.add_photo_alternate_rounded),
              label: const Text('Criar post'),
            ),
        ],
      ),
    );
  }
}

// ── Stories Bar ──────────────────────────────────────────────────────────────
class _StoriesBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final db = context.watch<DatabaseService>();
    final myId = db.currentUser?.id ?? '';

    return StreamBuilder<List<Story>>(
      stream: db.storiesStream,
      builder: (context, snapshot) {
        final stories = snapshot.data ?? [];
        // Agrupa stories por usuário (mostra apenas o mais recente de cada um)
        final Map<String, Story> latest = {};
        for (final s in stories) {
          if (!s.isExpired) latest[s.ownerId] = s;
        }
        final storyList = latest.values.toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

        return Container(
          height: 100,
          color: AppTheme.bgSecondary,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            itemCount: storyList.length + 1,
            itemBuilder: (context, i) {
              if (i == 0) {
                // Botão "Adicionar story"
                return _AddStoryButton();
              }
              final story = storyList[i - 1];
              final viewed = story.viewedBy.contains(myId);
              return GestureDetector(
                onTap: () => _openStory(context, storyList, i - 1, db),
                child: Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: viewed ? null : AppTheme.gradientPurplePink,
                          color: viewed ? AppTheme.bgSurface : null,
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppTheme.bgSecondary,
                          ),
                          child: UserAvatar(
                            avatarBase64: story.ownerAvatarBase64,
                            name: story.ownerName,
                            size: 52,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      SizedBox(
                        width: 60,
                        child: Text(
                          story.ownerName,
                          style: const TextStyle(color: AppTheme.textMuted, fontSize: 10),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  void _openStory(BuildContext context, List<Story> stories, int index, DatabaseService db) {
    db.markStoryViewed(stories[index].id);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => StoryViewScreen(stories: stories, initialIndex: index)),
    );
  }
}

class _AddStoryButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _pickAndCreateStory(context),
      child: Padding(
        padding: const EdgeInsets.only(right: 12),
        child: Column(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.bgCard,
                border: Border.all(color: AppTheme.purple.withValues(alpha: 0.4)),
              ),
              child: const Icon(Icons.add_rounded, color: AppTheme.purple, size: 28),
            ),
            const SizedBox(height: 4),
            const Text('Seu story', style: TextStyle(color: AppTheme.textMuted, fontSize: 10)),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAndCreateStory(BuildContext context) async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery, maxWidth: 1080, maxHeight: 1920, imageQuality: 80);
    if (file == null) return;
    final bytes = await file.readAsBytes();
    final compressed = await _compressForStory(bytes);
    if (context.mounted) {
      final db = context.read<DatabaseService>();
      await db.createStory(imageBytes: compressed);
    }
  }

  Future<Uint8List> _compressForStory(Uint8List input) async {
    final codec = await ui.instantiateImageCodec(input, targetWidth: 720);
    final frame = await codec.getNextFrame();
    final byteData = await frame.image.toByteData(format: ui.ImageByteFormat.png);
    return byteData?.buffer.asUint8List() ?? input;
  }
}

// ── Story Viewer ─────────────────────────────────────────────────────────────
class StoryViewScreen extends StatefulWidget {
  final List<Story> stories;
  final int initialIndex;
  const StoryViewScreen({super.key, required this.stories, required this.initialIndex});

  @override
  State<StoryViewScreen> createState() => _StoryViewScreenState();
}

class _StoryViewScreenState extends State<StoryViewScreen> with SingleTickerProviderStateMixin {
  late int _current;
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _current = widget.initialIndex;
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 5))
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) _next();
      })
      ..forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _next() {
    if (_current < widget.stories.length - 1) {
      final db = context.read<DatabaseService>();
      db.markStoryViewed(widget.stories[_current + 1].id);
      setState(() => _current++);
      _ctrl.forward(from: 0);
    } else {
      Navigator.pop(context);
    }
  }

  void _prev() {
    if (_current > 0) {
      setState(() => _current--);
      _ctrl.forward(from: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final story = widget.stories[_current];
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTapDown: (d) {
          final x = d.globalPosition.dx;
          final w = MediaQuery.of(context).size.width;
          if (x < w / 3) _prev(); else _next();
        },
        child: Stack(
          children: [
            // Imagem
            SizedBox.expand(
              child: AppImage(imageData: story.imageBase64, fit: BoxFit.cover),
            ),
            // Barra de progresso
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Row(
                  children: List.generate(widget.stories.length, (i) {
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: LinearProgressIndicator(
                          value: i < _current ? 1 : (i == _current ? _ctrl.value : 0),
                          backgroundColor: Colors.white30,
                          valueColor: const AlwaysStoppedAnimation(Colors.white),
                          minHeight: 2,
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),
            // Header com nome
            Positioned(
              top: 48,
              left: 12,
              right: 12,
              child: Row(
                children: [
                  UserAvatar(avatarBase64: story.ownerAvatarBase64, name: story.ownerName, size: 36),
                  const SizedBox(width: 8),
                  Text(story.ownerName,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Tab Chip ────────────────────────────────────────────────────────────────
class _TabChip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _TabChip({required this.label, required this.active, required this.onTap});

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

// ── Post Card ────────────────────────────────────────────────────────────────
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
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppTheme.bgCard,
          border: const Border(
            top: BorderSide(color: Color(0xFFEEEEF5)),
            bottom: BorderSide(color: Color(0xFFEEEEF5)),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header — clicável para ir ao perfil do dono
            GestureDetector(
              onTap: () {
                final db = context.read<DatabaseService>();
                final isSelf = post.ownerId == db.currentUser?.id;
                if (!isSelf) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => UserProfileScreen(userId: post.ownerId)),
                  );
                }
              },
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                child: Row(
                  children: [
                    UserAvatar(avatarBase64: post.ownerAvatarBase64, name: post.ownerName, size: 38),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(post.ownerName,
                              style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w700, fontSize: 14)),
                          Text(_timeAgo(post.createdAt),
                              style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                        ],
                      ),
                    ),
                    ScoreBadge(score: post.notaMedia),
                  ],
                ),
              ),
            ),
            // Imagem — edge-to-edge (sem margens laterais)
            AspectRatio(
              aspectRatio: 4 / 5,
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
                            style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w700, fontSize: 13),
                          ),
                          TextSpan(
                            text: post.caption,
                            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  Row(
                    children: [
                      const Icon(Icons.push_pin_rounded, size: 14, color: AppTheme.purpleLight),
                      const SizedBox(width: 4),
                      Text('${post.totalPins} pins', style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                      const SizedBox(width: 12),
                      const Icon(Icons.chat_bubble_outline_rounded, size: 14, color: AppTheme.pink),
                      const SizedBox(width: 4),
                      Text('${post.totalComments}', style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                      const SizedBox(width: 12),
                      const Icon(Icons.people_outline_rounded, size: 14, color: AppTheme.success),
                      const SizedBox(width: 4),
                      Text('${post.totalAvaliadores}', style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                      const Spacer(),
                      const Text('Ver →', style: TextStyle(color: AppTheme.purpleLight, fontSize: 12, fontWeight: FontWeight.w600)),
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
    if (diff.inHours < 24) return 'há ${diff.inHours}h';
    if (diff.inDays < 7) return 'há ${diff.inDays}d';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}
