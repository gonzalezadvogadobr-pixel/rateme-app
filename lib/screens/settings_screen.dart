import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/database_service.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _currentPwCtrl = TextEditingController();
  final _newPwCtrl     = TextEditingController();
  final _confirmPwCtrl = TextEditingController();
  bool _obscureCurrent = true;
  bool _obscureNew     = true;
  bool _obscureConfirm = true;
  bool _changingPw     = false;

  @override
  void dispose() {
    _currentPwCtrl.dispose();
    _newPwCtrl.dispose();
    _confirmPwCtrl.dispose();
    super.dispose();
  }

  Future<void> _changePassword(DatabaseService db) async {
    if (_newPwCtrl.text != _confirmPwCtrl.text) {
      _showSnack('As senhas novas não coincidem.', error: true);
      return;
    }
    if (_newPwCtrl.text.length < 6) {
      _showSnack('A nova senha precisa ter pelo menos 6 caracteres.', error: true);
      return;
    }
    setState(() => _changingPw = true);
    final error = await db.changePassword(
      currentPassword: _currentPwCtrl.text,
      newPassword: _newPwCtrl.text,
    );
    setState(() => _changingPw = false);
    if (error != null) {
      _showSnack(error, error: true);
    } else {
      _currentPwCtrl.clear();
      _newPwCtrl.clear();
      _confirmPwCtrl.clear();
      _showSnack('Senha alterada com sucesso!');
    }
  }

  Future<void> _deleteAccount(DatabaseService db) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.bgCard,
        title: const Text('Excluir conta?',
            style: TextStyle(color: AppTheme.textPrimary)),
        content: const Text(
          'Todos os seus posts, pins e dados serão excluídos permanentemente. Esta ação não pode ser desfeita.',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Excluir conta'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await db.deleteAccount();
    } catch (e) {
      if (mounted) _showSnack('Erro ao excluir conta: $e', error: true);
    }
  }

  void _showSnack(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: error ? AppTheme.error : AppTheme.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DatabaseService>(builder: (context, db, _) {
      final user = db.currentUser!;
      return Scaffold(
        backgroundColor: AppTheme.bgPrimary,
        appBar: AppBar(title: const Text('Configurações')),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Privacidade ──────────────────────────────────────────────
              _SectionHeader('Privacidade'),
              _Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: _Icon(
                        user.allowPublicPinsOnMyPosts
                            ? Icons.public_rounded
                            : Icons.lock_rounded,
                        color: user.allowPublicPinsOnMyPosts
                            ? AppTheme.success
                            : AppTheme.textMuted,
                      ),
                      title: const Text(
                        'Permitir pins públicos',
                        style: TextStyle(
                            color: AppTheme.textPrimary,
                            fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        user.allowPublicPinsOnMyPosts
                            ? 'Outros usuários podem criar pins públicos nas suas fotos'
                            : 'Todos os pins nas suas fotos ficam ocultos para o público',
                        style: const TextStyle(
                            color: AppTheme.textMuted, fontSize: 12),
                      ),
                      trailing: Switch(
                        value: user.allowPublicPinsOnMyPosts,
                        onChanged: (v) =>
                            db.updateUserProfile(allowPublicPins: v),
                        activeThumbColor: Colors.white,
                        activeTrackColor: AppTheme.purple,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ── Alterar Senha ────────────────────────────────────────────
              _SectionHeader('Alterar Senha'),
              _Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _PwField(
                        controller: _currentPwCtrl,
                        label: 'Senha atual',
                        obscure: _obscureCurrent,
                        onToggle: () =>
                            setState(() => _obscureCurrent = !_obscureCurrent),
                      ),
                      const SizedBox(height: 12),
                      _PwField(
                        controller: _newPwCtrl,
                        label: 'Nova senha',
                        obscure: _obscureNew,
                        onToggle: () =>
                            setState(() => _obscureNew = !_obscureNew),
                      ),
                      const SizedBox(height: 12),
                      _PwField(
                        controller: _confirmPwCtrl,
                        label: 'Confirmar nova senha',
                        obscure: _obscureConfirm,
                        onToggle: () =>
                            setState(() => _obscureConfirm = !_obscureConfirm),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _changingPw
                              ? null
                              : () => _changePassword(db),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          child: _changingPw
                              ? const SizedBox(
                                  height: 18,
                                  width: 18,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white),
                                )
                              : const Text('Alterar senha',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // ── Zona de perigo ───────────────────────────────────────────
              _SectionHeader('Zona de Perigo'),
              _Card(
                child: ListTile(
                  leading: _Icon(Icons.delete_forever_rounded,
                      color: AppTheme.error),
                  title: const Text(
                    'Excluir minha conta',
                    style: TextStyle(
                        color: AppTheme.error, fontWeight: FontWeight.w700),
                  ),
                  subtitle: const Text(
                    'Remove permanentemente todos os seus dados',
                    style:
                        TextStyle(color: AppTheme.textMuted, fontSize: 12),
                  ),
                  onTap: () => _deleteAccount(db),
                ),
              ),
              const SizedBox(height: 80),
            ],
          ),
        ),
      );
    });
  }
}

// ── Helpers ─────────────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String text;
  const _SectionHeader(this.text);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
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

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});
  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: AppTheme.bgCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFEEEEF5)),
        ),
        child: child,
      );
}

class _Icon extends StatelessWidget {
  final IconData icon;
  final Color color;
  const _Icon(this.icon, {required this.color});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color, size: 20),
      );
}

class _PwField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool obscure;
  final VoidCallback onToggle;
  const _PwField({
    required this.controller,
    required this.label,
    required this.obscure,
    required this.onToggle,
  });
  @override
  Widget build(BuildContext context) => TextField(
        controller: controller,
        obscureText: obscure,
        style: const TextStyle(color: AppTheme.textPrimary),
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: IconButton(
            icon: Icon(
              obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
              color: AppTheme.textMuted,
              size: 20,
            ),
            onPressed: onToggle,
          ),
        ),
      );
}
