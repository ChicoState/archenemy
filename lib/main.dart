import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
//import 'profile.dart';

import 'pages/login.dart';
import 'pages/settings.dart';
import 'pages/myprofile.dart';
import 'pages/explore.dart';
import 'pages/matches.dart';

import 'auth.dart' as auth;
import 'api.dart' as api;
import 'log.dart' as log;

import 'theme_manager.dart';
import 'package:animated_bottom_navigation_bar/animated_bottom_navigation_bar.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

	log.info(await api.getMyProfile());
  runApp(
    AnimatedBuilder(
      animation: ThemeManager.instance,
      builder: (_, __) {
        final mgr = ThemeManager.instance;
        final vibrantSeed =
            HSLColor.fromColor(mgr.seed).withSaturation(1.0).toColor();
        return MaterialApp(
          theme: ThemeData.from(
            colorScheme: ColorScheme.fromSeed(seedColor: vibrantSeed),
            useMaterial3: true,
          ),
          darkTheme: ThemeData.from(
            colorScheme: ColorScheme.fromSeed(
              brightness: Brightness.dark,
              seedColor: vibrantSeed,
            ),
            useMaterial3: true,
          ),
          themeMode: mgr.mode,
          home: const Root(),
        );
      },
    ),
  );
  //log.i(await api.getMyProfile());
}

class Root extends StatefulWidget {
  const Root({super.key});
  @override
  State<Root> createState() => RootState();
}

class RootState extends State<Root> {
  @override
  void initState() {
    super.initState();
    auth.stateChanges.listen((dynamic _) {
      // This is a mild anti-pattern
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext ctx) {
    if (auth.hasUser) {
      return App();
    } else {
      return LoginPage();
      //return App(); // use to circumvent login issues
    }
  }
}

class App extends StatefulWidget {
  const App({super.key});
  @override
  State<App> createState() => AppState();
}

class AppState extends State<App> {
  int pageIdx = 2;
  final List<Widget Function()> pages = [
    () => SettingsPage(),
    () => MyProfilePage(),
    () => ExplorePage(),
    () => MatchesPage(),
  ];

  final iconList = <IconData>[
    Icons.settings,
    Icons.person,
    Icons.star,
    Icons.heart_broken,
  ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final brightness = Theme.of(context).brightness;
    final hsl = HSLColor.fromColor(cs.surface);
    final barColor = (brightness == Brightness.light
            ? hsl.withLightness((hsl.lightness - 0.20).clamp(0.0, 1.0))
            : hsl.withLightness((hsl.lightness + 0.20).clamp(0.0, 1.0)))
        .toColor();

    return Scaffold(
      extendBody: true,
      body: pages[pageIdx](),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 8,
              spreadRadius: 1,
              offset: const Offset(0, 0),
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: () {/* … */},
          backgroundColor: barColor,
          elevation: 0, // shadow comes from the Container
          shape:
              const CircleBorder(), // ensures the FAB itself is perfectly round
          // child: Icon(Icons.thumb_down, color: Colors.red),
          child: Text(
            '😡', // angry emoji
            style: TextStyle(
              fontSize: 32, // size the emoji
            ),
          ),
        ),
      ),
      bottomNavigationBar: AnimatedBottomNavigationBar(
        icons: iconList,
        activeIndex: pageIdx,
        gapLocation: GapLocation.center,
        notchSmoothness: NotchSmoothness.smoothEdge,
        leftCornerRadius: 32,
        rightCornerRadius: 32,
        activeColor: Colors.red,
        inactiveColor: cs.onSurface.withValues(alpha: 0.6),
        backgroundColor: barColor,
        shadow: BoxShadow(
          color: Colors.black.withValues(alpha: 0.25),
          blurRadius: 8,
          spreadRadius: 1,
          offset: const Offset(0, -2),
        ),
        onTap: (idx) => setState(() => pageIdx = idx),
      ),
    );
  }
}
