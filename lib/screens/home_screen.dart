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
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    FeedScreen(),
    RankingScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(color: AppTheme.bgSurface, width: 1),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (i) {
            if (i == 1) {
              // Botão "+" — Criar post
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CreatePostScreen()),
              );
              return;
            }
            // Mapear índices: 0=Feed, 1=skip(+), 2=Ranking → índice real, 3=Perfil → 2
            setState(() {
              if (i == 0) { _currentIndex = 0; }
              else if (i == 2) { _currentIndex = 1; }
              else if (i == 3) { _currentIndex = 2; }
            });
          },
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
