import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/database_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {
  // 0 = login, 1 = cadastro
  int _tab = 0;
  bool _loading = false;
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  // Login
  final _loginEmailCtrl    = TextEditingController();
  final _loginPassCtrl     = TextEditingController();
  bool  _loginPassVisible  = false;

  // Signup
  final _signupNameCtrl    = TextEditingController();
  final _signupEmailCtrl   = TextEditingController();
  final _signupPassCtrl    = TextEditingController();
  final _signupPass2Ctrl   = TextEditingController();
  bool  _signupPassVisible = false;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _loginEmailCtrl.dispose();
    _loginPassCtrl.dispose();
    _signupNameCtrl.dispose();
    _signupEmailCtrl.dispose();
    _signupPassCtrl.dispose();
    _signupPass2Ctrl.dispose();
    super.dispose();
  }

  void _switchTab(int t) {
    setState(() => _tab = t);
    _fadeCtrl.forward(from: 0);
  }

  Future<void> _login() async {
    final db = context.read<DatabaseService>();
    setState(() => _loading = true);
    final err = await db.login(
      email:    _loginEmailCtrl.text.trim(),
      password: _loginPassCtrl.text,
    );
    if (mounted) setState(() => _loading = false);
    if (err != null && mounted) _showError(err);
  }

  Future<void> _signup() async {
    if (_signupNameCtrl.text.trim().isEmpty) {
      _showError('Informe seu nome.');
      return;
    }
    if (_signupPassCtrl.text != _signupPass2Ctrl.text) {
      _showError('As senhas não coincidem.');
      return;
    }
    final db = context.read<DatabaseService>();
    setState(() => _loading = true);
    final err = await db.signup(
      name:     _signupNameCtrl.text.trim(),
      email:    _signupEmailCtrl.text.trim(),
      password: _signupPassCtrl.text,
    );
    if (mounted) setState(() => _loading = false);
    if (err != null && mounted) _showError(err);
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: AppTheme.error,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // ── Decoração de fundo — meia-lua gradiente no topo ──────────────
          Positioned(
            top: -size.height * 0.18,
            left: -size.width * 0.25,
            right: -size.width * 0.25,
            child: Container(
              height: size.height * 0.52,
              decoration: const BoxDecoration(
                gradient: AppTheme.gradientPurplePink,
                shape: BoxShape.circle,
              ),
            ),
          ),

          // ── Conteúdo principal ───────────────────────────────────────────
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(height: size.height * 0.07),

                  // ── Logomarca ────────────────────────────────────────────
                  _buildLogo(),

                  SizedBox(height: size.height * 0.06),

                  // ── Alternador Login / Cadastro ──────────────────────────
                  _buildTabToggle(),

                  const SizedBox(height: 28),

                  // ── Formulário com fade ──────────────────────────────────
                  FadeTransition(
                    opacity: _fadeAnim,
                    child: _tab == 0 ? _buildLoginForm() : _buildSignupForm(),
                  ),

                  const SizedBox(height: 24),

                  // ── Dica demo ─────────────────────────────────────────────
                  _buildDemoHint(),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Logo: imagem + nome + tagline ────────────────────────────────────────
  Widget _buildLogo() {
    return Column(
      children: [
        // Imagem da logomarca
        Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppTheme.purple.withValues(alpha: 0.25),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipOval(
            child: Image.asset(
              'assets/icons/rateme_logo.png',
              fit: BoxFit.cover,
            ),
          ),
        ),
        const SizedBox(height: 18),
        // Nome do app
        const Text(
          'PinZap',
          style: TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Avalie. Marque. Zap!',
          style: TextStyle(
            fontSize: 14,
            color: Colors.white.withValues(alpha: 0.85),
            letterSpacing: 0.3,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  // ── Toggle Entrar / Cadastrar ─────────────────────────────────────────────
  Widget _buildTabToggle() {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: const Color(0xFFF0F0F5),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Stack(
        children: [
          // Slider animado
          AnimatedAlign(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            alignment: _tab == 0 ? Alignment.centerLeft : Alignment.centerRight,
            child: FractionallySizedBox(
              widthFactor: 0.5,
              child: Container(
                margin: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  gradient: AppTheme.gradientPurplePink,
                  borderRadius: BorderRadius.circular(11),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.purple.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Labels
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => _switchTab(0),
                  behavior: HitTestBehavior.opaque,
                  child: Center(
                    child: Text(
                      'Entrar',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: _tab == 0 ? Colors.white : AppTheme.textMuted,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () => _switchTab(1),
                  behavior: HitTestBehavior.opaque,
                  child: Center(
                    child: Text(
                      'Cadastrar',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: _tab == 1 ? Colors.white : AppTheme.textMuted,
                      ),
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

  // ── Formulário de Login ───────────────────────────────────────────────────
  Widget _buildLoginForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _InputField(
          controller:  _loginEmailCtrl,
          label:       'E-mail',
          icon:        Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 14),
        _InputField(
          controller:  _loginPassCtrl,
          label:       'Senha',
          icon:        Icons.lock_outline_rounded,
          obscure:     !_loginPassVisible,
          onToggleObscure: () =>
              setState(() => _loginPassVisible = !_loginPassVisible),
          onSubmitted: (_) => _login(),
        ),
        const SizedBox(height: 24),
        GradientButton(
          label:     'Entrar',
          icon:      Icons.login_rounded,
          loading:   _loading,
          onPressed: _login,
        ),
      ],
    );
  }

  // ── Formulário de Cadastro ────────────────────────────────────────────────
  Widget _buildSignupForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _InputField(
          controller: _signupNameCtrl,
          label:      'Nome completo',
          icon:       Icons.person_outline_rounded,
        ),
        const SizedBox(height: 14),
        _InputField(
          controller:   _signupEmailCtrl,
          label:        'E-mail',
          icon:         Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 14),
        _InputField(
          controller:      _signupPassCtrl,
          label:           'Senha',
          icon:            Icons.lock_outline_rounded,
          obscure:         !_signupPassVisible,
          onToggleObscure: () =>
              setState(() => _signupPassVisible = !_signupPassVisible),
        ),
        const SizedBox(height: 14),
        _InputField(
          controller:  _signupPass2Ctrl,
          label:       'Confirmar senha',
          icon:        Icons.lock_outline_rounded,
          obscure:     true,
          onSubmitted: (_) => _signup(),
        ),
        const SizedBox(height: 24),
        GradientButton(
          label:     'Criar conta',
          icon:      Icons.person_add_rounded,
          loading:   _loading,
          onPressed: _signup,
        ),
      ],
    );
  }

  // ── Dica contas demo ─────────────────────────────────────────────────────
  Widget _buildDemoHint() {
    return GestureDetector(
      onTap: () {
        _loginEmailCtrl.text = 'ana@demo.com';
        _loginPassCtrl.text  = '123456';
        _switchTab(0);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F0FF),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.purple.withValues(alpha: 0.15)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: AppTheme.gradientPurplePink,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.bolt_rounded,
                  color: Colors.white, size: 14),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Entrar com conta demo',
                    style: TextStyle(
                      color: AppTheme.purple,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    'ana@demo.com • Senha: 123456',
                    style: TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded,
                size: 12, color: AppTheme.purple.withValues(alpha: 0.5)),
          ],
        ),
      ),
    );
  }
}

// ── Campo de input reutilizável ──────────────────────────────────────────────
class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool obscure;
  final TextInputType? keyboardType;
  final VoidCallback? onToggleObscure;
  final ValueChanged<String>? onSubmitted;

  const _InputField({
    required this.controller,
    required this.label,
    required this.icon,
    this.obscure = false,
    this.keyboardType,
    this.onToggleObscure,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8F8),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE8E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller:   controller,
        obscureText:  obscure,
        keyboardType: keyboardType,
        onSubmitted:  onSubmitted,
        style: const TextStyle(
          color: AppTheme.textPrimary,
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(
            color: AppTheme.textMuted,
            fontSize: 14,
          ),
          prefixIcon: Icon(icon, color: AppTheme.purple, size: 20),
          suffixIcon: onToggleObscure != null
              ? IconButton(
                  icon: Icon(
                    obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                    color: AppTheme.textMuted,
                    size: 20,
                  ),
                  onPressed: onToggleObscure,
                )
              : null,
          filled:      false,
          border:      InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
              horizontal: 16, vertical: 16),
        ),
      ),
    );
  }
}
