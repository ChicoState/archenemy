import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'profile.dart';


import 'pages/login.dart';
import 'pages/settings.dart';
import 'pages/myprofile.dart';
import 'pages/explore.dart';
import 'pages/matches.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'auth.dart' as auth;
import 'api.dart' as api;
import 'log.dart' as log;

// Global notifier for theme mode
final ValueNotifier<ThemeMode> themeModeNotifier =
    ValueNotifier(ThemeMode.light);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
	
  // Load the saved dark mode preference
  final prefs = await SharedPreferences.getInstance();
  bool isDarkMode = prefs.getBool('darkMode') ?? false;
  themeModeNotifier.value = isDarkMode ? ThemeMode.dark : ThemeMode.light;

  runApp(MaterialApp(
		// theme: ThemeData(
		// 	colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
    //   useMaterial3: true,
		// ),
		home: Root()
	));
	//log.i(await api.getMyProfile());
}


class Root extends StatefulWidget {
  const Root({super.key});
  @override
  State<Root> createState() => RootState();
}

// <<<<<<< HEAD

//   @override
//   Widget build(BuildContext ctx) {
//     return ValueListenableBuilder<ThemeMode>(
//       valueListenable: themeModeNotifier,
//       builder: (context, currentTheme, child) {
//         return MaterialApp(
//           theme: ThemeData(
//             colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
//             useMaterial3: true,
//           ),
//           darkTheme: ThemeData.dark(),
//           // Here, 'currentTheme' is the local variable provided by the builder
//           themeMode: currentTheme,
//           home: LoginPage(),
//         );
//       },
//     );

// 	@override State<Root> createState() => RootState();

// }
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
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeModeNotifier,
      builder: (context, currentTheme, child) {
        return MaterialApp(
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
            useMaterial3: true,
          ),
          darkTheme: ThemeData.dark(),
          // Here, 'currentTheme' is the local variable provided by the builder
          themeMode: currentTheme,
          home: auth.hasUser ? App() : LoginPage(),
        );
      },
    );
  }
}

class App extends StatefulWidget {
  const App({super.key});
	@override State<App> createState() => AppState();
}

class AppState extends State<App> {

  
	int pageIdx = 2;
	final List<Widget Function()> pages = [
		() => SettingsPage(),
		() => MyProfilePage(),
		() => ExplorePage(),
		() => MatchesPage(),
	];
	final List<BottomNavigationBarItem> icons = [
		BottomNavigationBarItem(icon: Icon(Icons.settings), label: "Settings"),
		BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
		BottomNavigationBarItem(icon: Icon(Icons.star), label: "Explore"),
		BottomNavigationBarItem(icon: Icon(Icons.heart_broken), label: "Matches"),
	];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: pages[pageIdx](),
      bottomNavigationBar: BottomNavigationBar(
        // for unknown reasons the navbar becomes (mostly) invisible when in "shifting" mode
        type: BottomNavigationBarType.fixed,
        currentIndex: pageIdx,
        onTap: (int idx) {
          setState(() => pageIdx = idx);
        },
        items: icons
      ),
    );
  }
}
