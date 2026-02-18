import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/database_service.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';

class PostDetailScreen extends StatefulWidget {
  final String postId;
  const PostDetailScreen({super.key, required this.postId});

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  bool _pinMode = false;
  Pin? _selectedPin;
  final GlobalKey _imageKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return Consumer<DatabaseService>(builder: (context, db, _) {
      final post = db.getPostById(widget.postId);
      if (post == null) {
        return Scaffold(
          appBar: AppBar(title: const Text('Post')),
          body: const Center(child: Text('Post não encontrado')),
        );
      }
      final visiblePins = db.getVisiblePins(widget.postId);
      final isOwner = db.currentUser?.id == post.ownerId;
      final myPinCount =
          db.getPinCountForUserOnPost(widget.postId, db.currentUser!.id);
      final canAddPin = myPinCount < 10;

      return Scaffold(
        backgroundColor: AppTheme.bgPrimary,
        appBar: AppBar(
          title: Text(post.ownerName),
          actions: [
            if (isOwner)
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                color: AppTheme.bgCard,
                itemBuilder: (_) => [
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(children: [
                      Icon(Icons.delete_outline, color: AppTheme.error),
                      SizedBox(width: 8),
                      Text('Excluir post',
                          style: TextStyle(color: AppTheme.error)),
                    ]),
                  ),
                ],
                onSelected: (v) {
                  if (v == 'delete') {
                    _confirmDelete(context).then((confirm) async {
                      if (confirm == true) {
                        await db.deletePost(post.id);
                        if (mounted) Navigator.pop(context);
                      }
                    });
                  }
                },
              ),
          ],
        ),
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Imagem interativa com pins ───────────────────────────────
              _buildInteractiveImage(context, db, post, visiblePins, canAddPin),
              // ── Info do post ─────────────────────────────────────────────
              _buildPostInfo(post, visiblePins, isOwner, db, myPinCount),
              // ── Lista de pins visíveis ────────────────────────────────────
              _buildPinsList(context, db, visiblePins, post),
              const SizedBox(height: 80),
            ],
          ),
        ),
        floatingActionButton: canAddPin
            ? FloatingActionButton.extended(
                onPressed: () => setState(() => _pinMode = !_pinMode),
                backgroundColor: _pinMode ? AppTheme.pink : AppTheme.purple,
                icon: Icon(_pinMode ? Icons.close : Icons.push_pin_rounded),
                label: Text(_pinMode ? 'Cancelar' : 'Adicionar pin'),
              )
            : FloatingActionButton.extended(
                onPressed: null,
                backgroundColor: AppTheme.bgSurface,
                icon: const Icon(Icons.push_pin_rounded,
                    color: AppTheme.textMuted),
                label: const Text('Limite atingido (10)',
                    style: TextStyle(color: AppTheme.textMuted)),
              ),
      );
    });
  }

  Widget _buildInteractiveImage(
    BuildContext context,
    DatabaseService db,
    Post post,
    List<Pin> visiblePins,
    bool canAddPin,
  ) {
    return Container(
      color: AppTheme.bgSecondary,
      child: AspectRatio(
        aspectRatio: 4 / 3,
        child: LayoutBuilder(builder: (ctx, constraints) {
          return GestureDetector(
            onTapUp: _pinMode && canAddPin
                ? (details) {
                    final box =
                        ctx.findRenderObject() as RenderBox?;
                    if (box == null) return;
                    final localPos = box.globalToLocal(
                        details.globalPosition);
                    final xPct =
                        (localPos.dx / constraints.maxWidth) * 100;
                    final yPct =
                        (localPos.dy / constraints.maxHeight) * 100;
                    setState(() => _pinMode = false);
                    _showCreatePinModal(
                      context,
                      db,
                      post.id,
                      xPct.clamp(0, 100),
                      yPct.clamp(0, 100),
                    );
                  }
                : null,
            child: Stack(
              children: [
                // Imagem
                SizedBox.expand(
                  child: AppImage(
                    imageData: post.imageBase64,
                    fit: BoxFit.cover,
                    key: _imageKey,
                  ),
                ),
                // Overlay modo pin
                if (_pinMode)
                  Container(
                    color: AppTheme.purple.withValues(alpha: 0.15),
                    child: const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.touch_app_rounded,
                              color: Colors.white, size: 48),
                          SizedBox(height: 8),
                          Text(
                            'Toque na imagem para criar um pin',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              shadows: [
                                Shadow(
                                  blurRadius: 4,
                                  color: Colors.black,
                                )
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                // Pins visíveis
                ...visiblePins.map((pin) => Positioned(
                      left: (pin.xPercent / 100) * constraints.maxWidth - 18,
                      top: (pin.yPercent / 100) * constraints.maxHeight - 18,
                      child: PinMarker(
                        label: pin.targetLabel,
                        score: pin.score,
                        isSelected: _selectedPin?.id == pin.id,
                        isOwn: pin.authorId == db.currentUser?.id,
                        onTap: () => setState(() {
                          _selectedPin =
                              _selectedPin?.id == pin.id ? null : pin;
                        }),
                      ),
                    )),
                // Tooltip do pin selecionado
                if (_selectedPin != null)
                  Positioned(
                    bottom: 8,
                    left: 8,
                    right: 8,
                    child: _PinTooltip(
                      pin: _selectedPin!,
                      db: db,
                      onClose: () => setState(() => _selectedPin = null),
                      onEdit: () => _showEditPinModal(
                          context, db, _selectedPin!),
                      onDelete: () async {
                        await db.deletePin(_selectedPin!.id);
                        setState(() => _selectedPin = null);
                      },
                    ),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildPostInfo(
    Post post,
    List<Pin> visiblePins,
    bool isOwner,
    DatabaseService db,
    int myPinCount,
  ) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              UserAvatar(
                avatarBase64: post.ownerAvatarBase64,
                name: post.ownerName,
                size: 42,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(post.ownerName,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 16)),
                    if (post.caption.isNotEmpty)
                      Text(post.caption,
                          style: const TextStyle(
                              color: AppTheme.textSecondary, fontSize: 13)),
                  ],
                ),
              ),
              ScoreBadge(score: post.notaMedia, large: true),
            ],
          ),
          const SizedBox(height: 16),
          // Estatísticas
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.bgSurface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _Stat(
                    icon: Icons.star_rounded,
                    color: AppTheme.warning,
                    value: post.notaMedia.toStringAsFixed(1),
                    label: 'Nota média'),
                _Stat(
                    icon: Icons.push_pin_rounded,
                    color: AppTheme.purpleLight,
                    value: '${post.totalPins}',
                    label: 'Pins'),
                _Stat(
                    icon: Icons.people_rounded,
                    color: AppTheme.pink,
                    value: '${post.totalAvaliadores}',
                    label: 'Avaliadores'),
                _Stat(
                    icon: Icons.visibility_rounded,
                    color: AppTheme.success,
                    value: '${visiblePins.length}',
                    label: 'Visíveis'),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Meus pins
          Row(
            children: [
              const Icon(Icons.push_pin_outlined,
                  size: 14, color: AppTheme.textMuted),
              const SizedBox(width: 4),
              Text(
                'Seus pins: $myPinCount/10',
                style: const TextStyle(
                    color: AppTheme.textMuted, fontSize: 12),
              ),
              if (isOwner) ...[
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: () => _showPrivacySettings(context, db, post),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppTheme.purple.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.settings_outlined,
                            size: 12, color: AppTheme.purpleLight),
                        SizedBox(width: 4),
                        Text('Config. privacidade',
                            style: TextStyle(
                                color: AppTheme.purpleLight,
                                fontSize: 11,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPinsList(
    BuildContext context,
    DatabaseService db,
    List<Pin> visiblePins,
    Post post,
  ) {
    if (visiblePins.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(
          child: Text(
            'Nenhum pin visível neste post.',
            style: TextStyle(color: AppTheme.textMuted),
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Pins visíveis',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 16,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          ...visiblePins.map((pin) => _PinListItem(
                pin: pin,
                db: db,
                onSelect: () => setState(() => _selectedPin = pin),
              )),
        ],
      ),
    );
  }

  void _showCreatePinModal(
    BuildContext ctx,
    DatabaseService db,
    String postId,
    double xPct,
    double yPct,
  ) {
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: AppTheme.bgCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _CreatePinSheet(
        db: db,
        postId: postId,
        xPercent: xPct,
        yPercent: yPct,
      ),
    );
  }

  void _showEditPinModal(BuildContext ctx, DatabaseService db, Pin pin) {
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: AppTheme.bgCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _EditPinSheet(db: db, pin: pin),
    );
  }

  void _showPrivacySettings(
      BuildContext ctx, DatabaseService db, Post post) {
    showDialog(
      context: ctx,
      builder: (_) => _PrivacySettingsDialog(db: db, post: post),
    );
  }

  Future<bool?> _confirmDelete(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.bgCard,
        title: const Text('Excluir post?'),
        content: const Text(
            'Esta ação é irreversível. O post e todos os pins serão apagados.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
  }
}

// ── Sub-widgets ─────────────────────────────────────────────────────────────

class _Stat extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String value;
  final String label;

  const _Stat({
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(value,
            style: TextStyle(
                color: color, fontWeight: FontWeight.w800, fontSize: 16)),
        Text(label,
            style:
                const TextStyle(color: AppTheme.textMuted, fontSize: 10)),
      ],
    );
  }
}

class _PinTooltip extends StatelessWidget {
  final Pin pin;
  final DatabaseService db;
  final VoidCallback onClose;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _PinTooltip({
    required this.pin,
    required this.db,
    required this.onClose,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isOwn = pin.authorId == db.currentUser?.id;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.bgCard.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.purple.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          ScoreBadge(score: pin.score),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  pin.targetLabel,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                ),
                if (pin.comment.isNotEmpty)
                  Text(pin.comment,
                      style: const TextStyle(
                          color: AppTheme.textSecondary, fontSize: 12)),
                Text(
                  'por ${pin.authorName} • ${pin.isPublic ? "público" : "privado"}',
                  style: const TextStyle(
                      color: AppTheme.textMuted, fontSize: 11),
                ),
              ],
            ),
          ),
          if (isOwn) ...[
            IconButton(
              icon: const Icon(Icons.edit_outlined,
                  size: 18, color: AppTheme.purpleLight),
              onPressed: onEdit,
              visualDensity: VisualDensity.compact,
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline,
                  size: 18, color: AppTheme.error),
              onPressed: onDelete,
              visualDensity: VisualDensity.compact,
            ),
          ],
          IconButton(
            icon: const Icon(Icons.close, size: 18, color: AppTheme.textMuted),
            onPressed: onClose,
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}

class _PinListItem extends StatelessWidget {
  final Pin pin;
  final DatabaseService db;
  final VoidCallback onSelect;

  const _PinListItem({required this.pin, required this.db, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final isOwn = pin.authorId == db.currentUser?.id;
    return GestureDetector(
      onTap: onSelect,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.bgSurface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isOwn
                ? AppTheme.pink.withValues(alpha: 0.3)
                : AppTheme.bgSurface,
          ),
        ),
        child: Row(
          children: [
            ScoreBadge(score: pin.score),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        pin.targetLabel,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                            fontSize: 14),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: pin.isPublic
                              ? AppTheme.success.withValues(alpha: 0.15)
                              : AppTheme.textMuted.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          pin.isPublic ? 'público' : 'privado',
                          style: TextStyle(
                            color: pin.isPublic
                                ? AppTheme.success
                                : AppTheme.textMuted,
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (pin.comment.isNotEmpty)
                    Text(
                      pin.comment,
                      style: const TextStyle(
                          color: AppTheme.textMuted, fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  Text(
                    'por ${pin.authorName}',
                    style: const TextStyle(
                        color: AppTheme.textMuted, fontSize: 11),
                  ),
                ],
              ),
            ),
            if (isOwn)
              const Icon(Icons.edit_outlined,
                  size: 16, color: AppTheme.purpleLight),
          ],
        ),
      ),
    );
  }
}

// ── Modais ───────────────────────────────────────────────────────────────────

class _CreatePinSheet extends StatefulWidget {
  final DatabaseService db;
  final String postId;
  final double xPercent;
  final double yPercent;

  const _CreatePinSheet({
    required this.db,
    required this.postId,
    required this.xPercent,
    required this.yPercent,
  });

  @override
  State<_CreatePinSheet> createState() => _CreatePinSheetState();
}

class _CreatePinSheetState extends State<_CreatePinSheet> {
  final _labelCtrl = TextEditingController();
  final _commentCtrl = TextEditingController();
  double _score = 7.0;
  bool _isPublic = true;
  bool _loading = false;

  @override
  void dispose() {
    _labelCtrl.dispose();
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _loading = true);
    final err = await widget.db.createPin(
      postId: widget.postId,
      xPercent: widget.xPercent,
      yPercent: widget.yPercent,
      targetLabel: _labelCtrl.text,
      score: _score,
      comment: _commentCtrl.text.trim(),
      isPublic: _isPublic,
    );
    if (mounted) {
      setState(() => _loading = false);
      if (err != null) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(err), backgroundColor: AppTheme.error));
      } else {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Pin adicionado!'),
          backgroundColor: AppTheme.success,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return _PinFormSheet(
      title: 'Criar Pin',
      labelCtrl: _labelCtrl,
      commentCtrl: _commentCtrl,
      score: _score,
      isPublic: _isPublic,
      loading: _loading,
      xPercent: widget.xPercent,
      yPercent: widget.yPercent,
      onScoreChanged: (v) => setState(() => _score = v),
      onPublicChanged: (v) => setState(() => _isPublic = v),
      onSave: _save,
    );
  }
}

class _EditPinSheet extends StatefulWidget {
  final DatabaseService db;
  final Pin pin;

  const _EditPinSheet({required this.db, required this.pin});

  @override
  State<_EditPinSheet> createState() => _EditPinSheetState();
}

class _EditPinSheetState extends State<_EditPinSheet> {
  late final TextEditingController _labelCtrl;
  late final TextEditingController _commentCtrl;
  late double _score;
  late bool _isPublic;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _labelCtrl = TextEditingController(text: widget.pin.targetLabel);
    _commentCtrl = TextEditingController(text: widget.pin.comment);
    _score = widget.pin.score;
    _isPublic = widget.pin.isPublic;
  }

  @override
  void dispose() {
    _labelCtrl.dispose();
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _loading = true);
    final err = await widget.db.editPin(
      pinId: widget.pin.id,
      targetLabel: _labelCtrl.text,
      score: _score,
      comment: _commentCtrl.text.trim(),
      isPublic: _isPublic,
    );
    if (mounted) {
      setState(() => _loading = false);
      if (err != null) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(err), backgroundColor: AppTheme.error));
      } else {
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return _PinFormSheet(
      title: 'Editar Pin',
      labelCtrl: _labelCtrl,
      commentCtrl: _commentCtrl,
      score: _score,
      isPublic: _isPublic,
      loading: _loading,
      xPercent: widget.pin.xPercent,
      yPercent: widget.pin.yPercent,
      onScoreChanged: (v) => setState(() => _score = v),
      onPublicChanged: (v) => setState(() => _isPublic = v),
      onSave: _save,
    );
  }
}

class _PinFormSheet extends StatelessWidget {
  final String title;
  final TextEditingController labelCtrl;
  final TextEditingController commentCtrl;
  final double score;
  final bool isPublic;
  final bool loading;
  final double xPercent;
  final double yPercent;
  final ValueChanged<double> onScoreChanged;
  final ValueChanged<bool> onPublicChanged;
  final VoidCallback onSave;

  const _PinFormSheet({
    required this.title,
    required this.labelCtrl,
    required this.commentCtrl,
    required this.score,
    required this.isPublic,
    required this.loading,
    required this.xPercent,
    required this.yPercent,
    required this.onScoreChanged,
    required this.onPublicChanged,
    required this.onSave,
  });

  Color get _scoreColor {
    if (score >= 8) return AppTheme.success;
    if (score >= 5) return AppTheme.warning;
    return AppTheme.error;
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: Container(
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.textMuted,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Título
              Row(
                children: [
                  ShaderMask(
                    shaderCallback: (b) =>
                        AppTheme.gradientPurplePink.createShader(b),
                    child: const Icon(Icons.push_pin_rounded,
                        color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.bgSurface,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'X:${xPercent.toStringAsFixed(0)}% Y:${yPercent.toStringAsFixed(0)}%',
                      style: const TextStyle(
                          color: AppTheme.textMuted, fontSize: 11),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Título/Alvo
              TextField(
                controller: labelCtrl,
                style: const TextStyle(color: AppTheme.textPrimary),
                decoration: const InputDecoration(
                  labelText: 'Título/Alvo *',
                  hintText: 'ex: céu, cabelo, olhos, fundo...',
                  prefixIcon:
                      Icon(Icons.label_outline, color: AppTheme.textMuted),
                ),
              ),
              const SizedBox(height: 16),
              // Score
              Row(
                children: [
                  const Text('Nota: ',
                      style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontWeight: FontWeight.w600)),
                  Text(
                    score.toStringAsFixed(1),
                    style: TextStyle(
                        color: _scoreColor,
                        fontWeight: FontWeight.w800,
                        fontSize: 20),
                  ),
                  const Text('/10',
                      style: TextStyle(
                          color: AppTheme.textMuted, fontSize: 14)),
                ],
              ),
              Slider(
                value: score,
                min: 0,
                max: 10,
                divisions: 20,
                label: score.toStringAsFixed(1),
                onChanged: onScoreChanged,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('0',
                      style: TextStyle(
                          color: AppTheme.error, fontSize: 11)),
                  const Text('5',
                      style: TextStyle(
                          color: AppTheme.warning, fontSize: 11)),
                  const Text('10',
                      style: TextStyle(
                          color: AppTheme.success, fontSize: 11)),
                ],
              ),
              const SizedBox(height: 16),
              // Comentário
              TextField(
                controller: commentCtrl,
                maxLines: 2,
                style: const TextStyle(color: AppTheme.textPrimary),
                decoration: const InputDecoration(
                  labelText: 'Comentário (opcional)',
                  prefixIcon: Icon(Icons.comment_outlined,
                      color: AppTheme.textMuted),
                ),
              ),
              const SizedBox(height: 16),
              // Público/Privado
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppTheme.bgSurface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      isPublic ? Icons.public_rounded : Icons.lock_outline,
                      color: isPublic ? AppTheme.success : AppTheme.textMuted,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isPublic ? 'Pin público' : 'Pin privado',
                            style: TextStyle(
                              color: isPublic
                                  ? AppTheme.success
                                  : AppTheme.textMuted,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            isPublic
                                ? 'Visível para todos (se o dono permitir)'
                                : 'Visível só para você e o dono da foto',
                            style: const TextStyle(
                                color: AppTheme.textMuted, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: isPublic,
                      onChanged: onPublicChanged,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              GradientButton(
                label: 'Salvar pin',
                icon: Icons.check_rounded,
                loading: loading,
                onPressed: onSave,
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class _PrivacySettingsDialog extends StatefulWidget {
  final DatabaseService db;
  final Post post;

  const _PrivacySettingsDialog({required this.db, required this.post});

  @override
  State<_PrivacySettingsDialog> createState() =>
      _PrivacySettingsDialogState();
}

class _PrivacySettingsDialogState extends State<_PrivacySettingsDialog> {
  late bool _allowPublic;

  @override
  void initState() {
    super.initState();
    _allowPublic = widget.post.allowPublicPinsOverride;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppTheme.bgCard,
      title: const Row(
        children: [
          Icon(Icons.privacy_tip_outlined, color: AppTheme.purpleLight),
          SizedBox(width: 8),
          Text('Privacidade do Post'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Controle quem pode ver os pins desta foto.',
            style: TextStyle(color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            value: _allowPublic,
            onChanged: (v) => setState(() => _allowPublic = v),
            title: Text(
              _allowPublic
                  ? 'Pins públicos visíveis'
                  : 'Pins públicos ocultos',
              style: TextStyle(
                color: _allowPublic ? AppTheme.success : AppTheme.textMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Text(
              _allowPublic
                  ? 'Pins marcados como públicos ficam visíveis para todos'
                  : 'Todos os pins ficam visíveis só para você e os autores',
              style: const TextStyle(
                  color: AppTheme.textMuted, fontSize: 11),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () async {
            widget.post.allowPublicPinsOverride = _allowPublic;
            // Salva o post atualizado via service
            await widget.db.updatePostPrivacy(
              widget.post.id,
              _allowPublic,
            );
            if (context.mounted) Navigator.pop(context);
          },
          child: const Text('Salvar'),
        ),
      ],
    );
  }
}
