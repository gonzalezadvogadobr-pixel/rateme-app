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

  // Inicializar Firebase com opções multiplataforma
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

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
