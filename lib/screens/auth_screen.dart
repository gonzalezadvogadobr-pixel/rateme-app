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
  late TabController _tabController;
  bool _loading = false;

  // Login
  final _loginEmailCtrl = TextEditingController();
  final _loginPassCtrl = TextEditingController();
  bool _loginPassVisible = false;

  // Signup
  final _signupNameCtrl = TextEditingController();
  final _signupEmailCtrl = TextEditingController();
  final _signupPassCtrl = TextEditingController();
  final _signupPass2Ctrl = TextEditingController();
  bool _signupPassVisible = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _loginEmailCtrl.dispose();
    _loginPassCtrl.dispose();
    _signupNameCtrl.dispose();
    _signupEmailCtrl.dispose();
    _signupPassCtrl.dispose();
    _signupPass2Ctrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final db = context.read<DatabaseService>();
    setState(() => _loading = true);
    final err = await db.login(
      email: _loginEmailCtrl.text.trim(),
      password: _loginPassCtrl.text,
    );
    if (mounted) setState(() => _loading = false);
    if (err != null && mounted) {
      _showError(err);
    }
  }

  Future<void> _signup() async {
    if (_signupPassCtrl.text != _signupPass2Ctrl.text) {
      _showError('As senhas não coincidem.');
      return;
    }
    if (_signupNameCtrl.text.trim().isEmpty) {
      _showError('Informe seu nome.');
      return;
    }
    final db = context.read<DatabaseService>();
    setState(() => _loading = true);
    final err = await db.signup(
      name: _signupNameCtrl.text.trim(),
      email: _signupEmailCtrl.text.trim(),
      password: _signupPassCtrl.text,
    );
    if (mounted) setState(() => _loading = false);
    if (err != null && mounted) _showError(err);
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: AppTheme.error,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.gradientBg),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const SizedBox(height: 40),
                // Logo
                ShaderMask(
                  shaderCallback: (bounds) =>
                      AppTheme.gradientPurplePink.createShader(bounds),
                  child: const Text(
                    'RateMe',
                    style: TextStyle(
                      fontSize: 42,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 2,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Avalie fotos com precisão',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 48),
                // Card
                Container(
                  decoration: BoxDecoration(
                    color: AppTheme.bgCard,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppTheme.purple.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    children: [
                      // Tabs
                      Container(
                        decoration: BoxDecoration(
                          color: AppTheme.bgSurface,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(20),
                            topRight: Radius.circular(20),
                          ),
                        ),
                        child: TabBar(
                          controller: _tabController,
                          indicator: BoxDecoration(
                            gradient: AppTheme.gradientPurplePink,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(20),
                              topRight: Radius.circular(20),
                            ),
                          ),
                          labelColor: Colors.white,
                          unselectedLabelColor: AppTheme.textMuted,
                          labelStyle: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                          tabs: const [
                            Tab(text: 'Entrar'),
                            Tab(text: 'Cadastrar'),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(24),
                        child: SizedBox(
                          height: 300,
                          child: TabBarView(
                            controller: _tabController,
                            children: [
                              _buildLoginForm(),
                              _buildSignupForm(),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // Demo hint
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.bgSurface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: AppTheme.purple.withValues(alpha: 0.2)),
                  ),
                  child: const Column(
                    children: [
                      Text(
                        '💡 Contas demo disponíveis:',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'ana@demo.com • pedro@demo.com • mariana@demo.com\nSenha: 123456',
                        style: TextStyle(
                          color: AppTheme.textMuted,
                          fontSize: 11,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginForm() {
    return Column(
      children: [
        TextField(
          controller: _loginEmailCtrl,
          keyboardType: TextInputType.emailAddress,
          style: const TextStyle(color: AppTheme.textPrimary),
          decoration: const InputDecoration(
            labelText: 'E-mail',
            prefixIcon: Icon(Icons.email_outlined, color: AppTheme.textMuted),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _loginPassCtrl,
          obscureText: !_loginPassVisible,
          style: const TextStyle(color: AppTheme.textPrimary),
          decoration: InputDecoration(
            labelText: 'Senha',
            prefixIcon:
                const Icon(Icons.lock_outline, color: AppTheme.textMuted),
            suffixIcon: IconButton(
              icon: Icon(
                _loginPassVisible ? Icons.visibility_off : Icons.visibility,
                color: AppTheme.textMuted,
              ),
              onPressed: () =>
                  setState(() => _loginPassVisible = !_loginPassVisible),
            ),
          ),
          onSubmitted: (_) => _login(),
        ),
        const SizedBox(height: 24),
        GradientButton(
          label: 'Entrar',
          icon: Icons.login_rounded,
          loading: _loading,
          onPressed: _login,
        ),
      ],
    );
  }

  Widget _buildSignupForm() {
    return SingleChildScrollView(
      child: Column(
        children: [
          TextField(
            controller: _signupNameCtrl,
            style: const TextStyle(color: AppTheme.textPrimary),
            decoration: const InputDecoration(
              labelText: 'Nome',
              prefixIcon:
                  Icon(Icons.person_outline, color: AppTheme.textMuted),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _signupEmailCtrl,
            keyboardType: TextInputType.emailAddress,
            style: const TextStyle(color: AppTheme.textPrimary),
            decoration: const InputDecoration(
              labelText: 'E-mail',
              prefixIcon:
                  Icon(Icons.email_outlined, color: AppTheme.textMuted),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _signupPassCtrl,
            obscureText: !_signupPassVisible,
            style: const TextStyle(color: AppTheme.textPrimary),
            decoration: InputDecoration(
              labelText: 'Senha',
              prefixIcon:
                  const Icon(Icons.lock_outline, color: AppTheme.textMuted),
              suffixIcon: IconButton(
                icon: Icon(
                  _signupPassVisible ? Icons.visibility_off : Icons.visibility,
                  color: AppTheme.textMuted,
                ),
                onPressed: () =>
                    setState(() => _signupPassVisible = !_signupPassVisible),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _signupPass2Ctrl,
            obscureText: true,
            style: const TextStyle(color: AppTheme.textPrimary),
            decoration: const InputDecoration(
              labelText: 'Confirmar senha',
              prefixIcon:
                  Icon(Icons.lock_outline, color: AppTheme.textMuted),
            ),
            onSubmitted: (_) => _signup(),
          ),
          const SizedBox(height: 20),
          GradientButton(
            label: 'Criar conta',
            icon: Icons.person_add_rounded,
            loading: _loading,
            onPressed: _signup,
          ),
        ],
      ),
    );
  }
}
