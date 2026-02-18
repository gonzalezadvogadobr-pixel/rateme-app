import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/database_service.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import 'post_detail_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    // Marcar todas como lidas ao abrir
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DatabaseService>().markAllNotificationsRead();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DatabaseService>(builder: (context, db, _) {
      final notifs = db.getMyNotifications();

      return Scaffold(
        backgroundColor: AppTheme.bgPrimary,
        appBar: AppBar(
          title: const Text('Notificações'),
          actions: [
            if (notifs.isNotEmpty)
              TextButton(
                onPressed: db.markAllNotificationsRead,
                child: const Text(
                  'Marcar tudo lido',
                  style: TextStyle(
                      color: AppTheme.purpleLight, fontSize: 12),
                ),
              ),
          ],
        ),
        body: notifs.isEmpty
            ? _buildEmpty()
            : ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: notifs.length,
                itemBuilder: (context, i) =>
                    _NotifTile(notif: notifs[i], db: db),
              ),
      );
    });
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.bgCard,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.notifications_none_rounded,
                size: 56, color: AppTheme.textMuted),
          ),
          const SizedBox(height: 20),
          const Text(
            'Nenhuma notificação',
            style: TextStyle(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 18),
          ),
          const SizedBox(height: 8),
          const Text(
            'Quando alguém avaliar ou comentar\nnas suas fotos, você será notificado.',
            style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _NotifTile extends StatelessWidget {
  final AppNotification notif;
  final DatabaseService db;

  const _NotifTile({required this.notif, required this.db});

  Color get _typeColor {
    switch (notif.type) {
      case NotifType.newPin:      return AppTheme.purpleLight;
      case NotifType.newComment:  return AppTheme.pink;
      case NotifType.newFollower: return AppTheme.success;
      case NotifType.pinEdited:   return AppTheme.warning;
    }
  }

  IconData get _typeIcon {
    switch (notif.type) {
      case NotifType.newPin:      return Icons.push_pin_rounded;
      case NotifType.newComment:  return Icons.chat_bubble_rounded;
      case NotifType.newFollower: return Icons.person_add_rounded;
      case NotifType.pinEdited:   return Icons.edit_rounded;
    }
  }

  String _timeAgo(DateTime dt) {
    final d = DateTime.now().difference(dt);
    if (d.inSeconds < 60)  return 'agora';
    if (d.inMinutes < 60)  return '${d.inMinutes}min atrás';
    if (d.inHours < 24)    return '${d.inHours}h atrás';
    if (d.inDays < 7)      return '${d.inDays}d atrás';
    return '${dt.day}/${dt.month}';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        db.markNotificationRead(notif.id);
        if (notif.postId != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => PostDetailScreen(postId: notif.postId!)),
          );
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: notif.isRead
              ? AppTheme.bgCard
              : AppTheme.bgCard.withBlue(50).withValues(
                  alpha: 1.0,
                ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: notif.isRead
                ? AppTheme.bgSurface
                : _typeColor.withValues(alpha: 0.35),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar com badge de tipo
            Stack(
              children: [
                UserAvatar(
                  avatarBase64: notif.actorAvatarBase64,
                  name: notif.actorName,
                  size: 44,
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: _typeColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppTheme.bgCard, width: 2),
                    ),
                    child: Icon(_typeIcon,
                        size: 10, color: Colors.white),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notif.body,
                    style: TextStyle(
                      color: notif.isRead
                          ? AppTheme.textSecondary
                          : AppTheme.textPrimary,
                      fontSize: 13,
                      fontWeight: notif.isRead
                          ? FontWeight.w400
                          : FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _timeAgo(notif.createdAt),
                    style: const TextStyle(
                        color: AppTheme.textMuted, fontSize: 11),
                  ),
                ],
              ),
            ),
            // Indicador de não lido
            if (!notif.isRead)
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _typeColor,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
