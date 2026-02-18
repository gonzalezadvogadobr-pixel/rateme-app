import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'feed_screen.dart';
import 'ranking_screen.dart';
import 'profile_screen.dart';
import 'create_post_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // 0=Feed, 1=+ (CreatePost – não é tela), 2=Ranking, 3=Perfil
  // _screenIndex mapeia para as 3 telas reais
  int _navIndex = 0; // índice da barra de navegação
  int _screenIndex = 0; // índice da tela no IndexedStack

  final List<Widget> _screens = const [
    FeedScreen(),
    RankingScreen(),
    ProfileScreen(),
  ];

  void _onTap(int i) {
    if (i == 1) {
      // Botão "+" → abre CreatePost como rota separada
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const CreatePostScreen()),
      );
      return;
    }
    int screenIdx;
    if (i == 0) { screenIdx = 0; }      // Feed
    else if (i == 2) { screenIdx = 1; } // Ranking
    else { screenIdx = 2; }              // Perfil (i==3)

    setState(() {
      _navIndex = i;
      _screenIndex = screenIdx;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _screenIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(color: AppTheme.bgSurface, width: 1),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _navIndex,
          onTap: _onTap,
          items: [
            const BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home_rounded),
              label: 'Feed',
            ),
            BottomNavigationBarItem(
              icon: Container(
                width: 48,
                height: 36,
                decoration: BoxDecoration(
                  gradient: AppTheme.gradientPurplePink,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.add_rounded,
                    color: Colors.white, size: 26),
              ),
              label: '',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.emoji_events_outlined),
              activeIcon: Icon(Icons.emoji_events_rounded),
              label: 'Ranking',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.person_outline_rounded),
              activeIcon: Icon(Icons.person_rounded),
              label: 'Perfil',
            ),
          ],
          selectedItemColor: AppTheme.purpleLight,
          unselectedItemColor: AppTheme.textMuted,
          backgroundColor: AppTheme.bgSecondary,
          type: BottomNavigationBarType.fixed,
          showUnselectedLabels: true,
        ),
      ),
    );
  }
}
