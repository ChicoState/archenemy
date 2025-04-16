// lib/app.dart
import 'package:flutter/material.dart';
import 'profile.dart';
import 'matches.dart';
import 'explore.dart';
import 'settings.dart';
import 'theme_config.dart';

class App extends StatefulWidget {
  final Function(AppThemeMode, Color) onThemeChanged;
  final AppThemeMode currentThemeMode;
  final Color currentSeedColor;
  const App({
    super.key,
    required this.onThemeChanged,
    required this.currentThemeMode,
    required this.currentSeedColor,
  });

  @override
  State<App> createState() => AppState();
}

class AppState extends State<App> {
  int pageIdx = 0;
  late List<Widget Function()> pageBuilders;

  @override
  void initState() {
    super.initState();
    _buildPages();
  }

  void _buildPages() {
    pageBuilders = [
      () => SettingsPage(
            currentThemeMode: widget.currentThemeMode,
            currentSeedColor: widget.currentSeedColor,
            onThemeModeChanged: (newMode) {
              widget.onThemeChanged(newMode, widget.currentSeedColor);
            },
            onSeedColorChanged: (newColor) {
              widget.onThemeChanged(widget.currentThemeMode, newColor);
            },
          ),
      () => MyProfileView(
            Profile(
                "My Profile", DateTime.now(), "My Bio", ["My1", "My2", "My3"]),
          ),
      () => const ExplorePage(),
      () => MatchesPage([
            Profile("Match 1", DateTime.now(), "Example Bio", ["I1", "I2"]),
            Profile("Match 2", DateTime.now(), "Example Bio", ["I1", "I2"]),
            Profile("Match 3", DateTime.now(), "Example Bio", ["I1", "I2"]),
          ]),
    ];
  }

  @override
  Widget build(BuildContext context) {
    _buildPages();
    return Scaffold(
      body: pageBuilders[pageIdx](),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: pageIdx,
        onTap: (int idx) {
          setState(() {
            pageIdx = idx;
          });
        },
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.settings), label: "Settings"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
          BottomNavigationBarItem(icon: Icon(Icons.star), label: "Explore"),
          BottomNavigationBarItem(
              icon: Icon(Icons.heart_broken), label: "Matches"),
        ],
      ),
    );
  }
}
