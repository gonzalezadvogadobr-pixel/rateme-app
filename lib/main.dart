import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'services/database_service.dart';
import 'theme/app_theme.dart';
import 'screens/auth_screen.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar Firebase — captura qualquer erro para não travar na tela branca
  String? firebaseError;
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    firebaseError = e.toString();
    if (kDebugMode) debugPrint('[Firebase] erro de inicialização: $e');
  }

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Se Firebase falhou, mostra tela com o erro REAL para diagnóstico
  if (firebaseError != null) {
    runApp(_FirebaseErrorApp(error: firebaseError, showDetails: true));
    return;
  }

  final db = DatabaseService();
  await db.init();

  runApp(
    ChangeNotifierProvider<DatabaseService>(
      create: (_) => db,
      child: const RateMeApp(),
    ),
  );
}

class RateMeApp extends StatelessWidget {
  const RateMeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RateMe',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const _AppGate(),
    );
  }
}

class _AppGate extends StatelessWidget {
  const _AppGate();

  @override
  Widget build(BuildContext context) {
    return Consumer<DatabaseService>(
      builder: (context, db, _) {
        if (db.isLoading) {
          return const Scaffold(
            backgroundColor: AppTheme.bgPrimary,
            body: Center(
              child: CircularProgressIndicator(color: AppTheme.purple),
            ),
          );
        }
        if (!db.isLoggedIn) return const AuthScreen();
        return const HomeScreen();
      },
    );
  }
}

class _FirebaseErrorApp extends StatelessWidget {
  final String error;
  final bool showDetails;
  const _FirebaseErrorApp({required this.error, this.showDetails = false});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: const Color(0xFF0D0D1A),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.cloud_off_rounded,
                    color: Color(0xFFEC4899), size: 64),
                const SizedBox(height: 24),
                const Text(
                  'Erro ao conectar com o servidor',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                // Mostrar erro real para diagnóstico
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.withValues(alpha: 0.4)),
                  ),
                  child: SelectableText(
                    error,
                    style: const TextStyle(color: Colors.red, fontSize: 12),
                    textAlign: TextAlign.left,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Recarregue a página (F5) para tentar novamente.',
                  style: TextStyle(color: Colors.white60, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
