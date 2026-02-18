import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../services/database_service.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import 'post_detail_screen.dart';
import 'search_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _picker = ImagePicker();
  bool _editMode = false;
  final _nameCtrl = TextEditingController();
  final _bioCtrl  = TextEditingController();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _bioCtrl.dispose();
    super.dispose();
  }

  void _showAvatarFullscreen(BuildContext context, AppUser user) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(24),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Avatar ampliado
            ClipOval(
              child: SizedBox(
                width: 260,
                height: 260,
                child: user.avatarBase64 != null && user.avatarBase64!.isNotEmpty
                    ? UserAvatar(
                        avatarBase64: user.avatarBase64,
                        name: user.name,
                        size: 260,
                      )
                    : UserAvatar(name: user.name, size: 260),
              ),
            ),
            // Botão fechar
            Positioned(
              top: -12,
              right: -12,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close_rounded,
                      color: Colors.black87, size: 18),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAvatar(DatabaseService db) async {
    try {
      final file = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 400,
        maxHeight: 400,
        imageQuality: 80,
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      await db.updateUserProfile(avatarBytes: bytes);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e'), backgroundColor: AppTheme.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DatabaseService>(builder: (context, db, _) {
      final user = db.currentUser!;
      final myPosts = db.getUserPosts(user.id);

      return Scaffold(
        backgroundColor: AppTheme.bgPrimary,
        appBar: AppBar(
          title: const Text('Perfil'),
          actions: [
            IconButton(
              icon: Icon(
                _editMode ? Icons.check_rounded : Icons.edit_outlined,
                color: AppTheme.purpleLight,
              ),
              onPressed: () async {
                if (_editMode) {
                  // Salvar nome e bio
                  if (_nameCtrl.text.trim().isNotEmpty) {
                    await db.updateUserProfile(
                      name: _nameCtrl.text.trim(),
                      bio: _bioCtrl.text.trim(),
                    );
                  }
                } else {
                  _nameCtrl.text = user.name;
                  _bioCtrl.text  = user.bio;
                }
                setState(() => _editMode = !_editMode);
              },
            ),
            // Busca
            IconButton(
              icon: const Icon(Icons.search_rounded,
                  color: AppTheme.textSecondary),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SearchScreen()),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.logout_rounded,
                  color: AppTheme.textMuted),
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    backgroundColor: AppTheme.bgCard,
                    title: const Text('Sair?'),
                    content: const Text('Tem certeza que deseja sair?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancelar'),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.error),
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Sair'),
                      ),
                    ],
                  ),
                );
                if (confirm == true && mounted) await db.logout();
              },
            ),
          ],
        ),
        body: SingleChildScrollView(
          child: Column(
            children: [
              // Header do perfil
              _buildProfileHeader(user, db),
              const SizedBox(height: 16),
              // Configurações
              _buildSettings(user, db),
              const SizedBox(height: 16),
              // Posts do usuário
              _buildMyPosts(myPosts),
              const SizedBox(height: 80),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildProfileHeader(AppUser user, DatabaseService db) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEEEEF5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Avatar — 40% maior (112px) e clicável para ver em tela cheia
          Stack(
            children: [
              GestureDetector(
                onTap: () => _showAvatarFullscreen(context, user),
                child: UserAvatar(
                  avatarBase64: user.avatarBase64,
                  name: user.name,
                  size: 112,
                ),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: GestureDetector(
                  onTap: () => _pickAvatar(db),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      gradient: AppTheme.gradientPurplePink,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.camera_alt_rounded,
                        color: Colors.white, size: 16),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Nome
          if (_editMode) ...[
            SizedBox(
              width: 200,
              child: TextField(
                controller: _nameCtrl,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
                decoration: const InputDecoration(
                  border: UnderlineInputBorder(),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: AppTheme.purple),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide:
                        BorderSide(color: AppTheme.pink, width: 2),
                  ),
                  contentPadding: EdgeInsets.symmetric(horizontal: 8),
                  isDense: true,
                  fillColor: Colors.transparent,
                  filled: false,
                ),
              ),
            ),
          ] else ...[
            Text(
              user.name,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          const SizedBox(height: 4),
          // Bio em modo edição ou visualização
          if (_editMode)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: TextField(
                controller: _bioCtrl,
                maxLines: 2,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: AppTheme.textSecondary, fontSize: 13),
                decoration: const InputDecoration(
                  hintText: 'Escreva sua bio…',
                  border: UnderlineInputBorder(),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: AppTheme.purple),
                  ),
                  isDense: true,
                  fillColor: Colors.transparent,
                  filled: false,
                ),
              ),
            )
          else ...[
            if (user.bio.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  user.bio,
                  style: const TextStyle(
                      color: AppTheme.textSecondary, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
              ),
            Text(
              user.email,
              style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
            ),
          ],
          const SizedBox(height: 16),
          // Stats: Posts · Seguidores · Seguindo
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _ProfileStat(
                value: db.getUserPosts(user.id).length.toString(),
                label: 'Posts',
                color: AppTheme.purpleLight,
              ),
              _ProfileStat(
                value: db.followersCount(user.id).toString(),
                label: 'Seguidores',
                color: AppTheme.pink,
              ),
              _ProfileStat(
                value: db.followingCount(user.id).toString(),
                label: 'Seguindo',
                color: AppTheme.success,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSettings(AppUser user, DatabaseService db) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: AppTheme.purple.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'Configurações de privacidade',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w700,
                fontSize: 13,
                letterSpacing: 0.5,
              ),
            ),
          ),
          // Toggle pins públicos
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.purple.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                user.allowPublicPinsOnMyPosts
                    ? Icons.public_rounded
                    : Icons.lock_rounded,
                color: user.allowPublicPinsOnMyPosts
                    ? AppTheme.success
                    : AppTheme.textMuted,
                size: 20,
              ),
            ),
            title: const Text(
              'Permitir pins públicos',
              style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              user.allowPublicPinsOnMyPosts
                  ? 'Pins públicos de outros usuários ficam visíveis em suas fotos'
                  : 'Todos os pins em suas fotos ficam ocultos para o público',
              style: const TextStyle(
                  color: AppTheme.textMuted, fontSize: 11),
            ),
            trailing: Switch(
              value: user.allowPublicPinsOnMyPosts,
              onChanged: (v) async {
                await db.updateUserProfile(allowPublicPins: v);
              },
            ),
          ),
          const Divider(
              color: AppTheme.bgSurface, height: 1, indent: 16),
          // Info
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                const Icon(Icons.info_outline,
                    size: 14, color: AppTheme.textMuted),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Independente desta configuração, a nota média das suas fotos sempre fica visível.',
                    style: TextStyle(
                        color: AppTheme.textMuted, fontSize: 11),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMyPosts(List<Post> posts) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Minhas fotos',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.purple.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${posts.length}',
                  style: const TextStyle(
                      color: AppTheme.purpleLight,
                      fontWeight: FontWeight.w700,
                      fontSize: 13),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (posts.isEmpty) ...[
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.bgCard,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Center(
                child: Text(
                  'Você ainda não publicou nenhuma foto.',
                  style: TextStyle(color: AppTheme.textMuted),
                ),
              ),
            ),
          ] else ...[
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 4,
                mainAxisSpacing: 4,
              ),
              itemCount: posts.length,
              itemBuilder: (context, index) {
                final post = posts[index];
                return GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) =>
                            PostDetailScreen(postId: post.id)),
                  ),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: SizedBox.expand(
                          child: AppImage(
                            imageData: post.imageBase64,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 4,
                        right: 4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.7),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            post.notaMedia.toStringAsFixed(1),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}

class _ProfileStat extends StatelessWidget {
  final String value;
  final String label;
  final Color color;

  const _ProfileStat({
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
              color: AppTheme.textMuted, fontSize: 11),
        ),
      ],
    );
  }
}
