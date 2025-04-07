import 'package:flutter/material.dart';
import 'app.dart';
import 'theme.dart';
import 'theme_config.dart';

void main() {
  runApp(const Root());

import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'profile.dart';
import 'matches.dart';
import 'login.dart';
import 'api.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await init(); // this calls Firebase.initializeApp under the hood
  runApp(Root());
}

class Root extends StatefulWidget {
  const Root({super.key});
  @override
  State<Root> createState() => _RootState();
  Widget build(BuildContext ctx) {
    return MaterialApp(
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        home: LoginPage());
  }
}

class _RootState extends State<Root> {
  AppThemeMode _themeMode = AppThemeMode.system;
  Color _seedColor = Colors.red;

  ThemeMode get materialThemeMode {
    switch (_themeMode) {
      case AppThemeMode.light:
        return ThemeMode.light;
      case AppThemeMode.dark:
        return ThemeMode.dark;
      default:
        return ThemeMode.dark;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HatingApp',
      theme: lightTheme(_seedColor),
      darkTheme: darkTheme(_seedColor),
      themeMode: materialThemeMode,
      home: App(
        onThemeChanged: (mode, seedColor) {
          setState(() {
            _themeMode = mode;
            _seedColor = seedColor;
          });
        },
        currentThemeMode: _themeMode,
        currentSeedColor: _seedColor,
      ),
    );
  }
}

// import 'package:flutter/material.dart';
// import 'profile.dart';
// import 'matches.dart';

// import 'explore.dart';

// void main() {
//   runApp(Root());
// }

// class Root extends StatelessWidget {
//   const Root({super.key});

//   @override
//   Widget build(BuildContext ctx) {
//     return MaterialApp(
//         theme: ThemeData(
//           colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
//           useMaterial3: true,
//         ),
//         home: App());
//   }
// }

// class App extends StatefulWidget {
//   const App({super.key});

//   @override
//   State<App> createState() => AppState();
// }

// class AppState extends State<App> {
//   int pageIdx = 2;
//   List<Widget Function()> pageBuilders = [
//     () => Center(child: Text("Settings Placeholder")),
//     () => MyProfileView(
//         Profile("My Profile", DateTime.now(), "My Bio", ["My1", "My2", "My3"])),
//     //() => ProfileView(Profile("Example Profile", DateTime.now(), "Example Bio", ["Ex1", "Ex2", "Ex3", "Ex4"])),
//     () => const ExplorePage(),
//     // () => ExplorePage([
//     //       Profile("Example Profile #2", DateTime.now(), "Example Bio #2",
//     //           ["Interest #1", "Interest #2", "Interest #3", "Interest #4"]),
//     //       Profile("Example Profile #1", DateTime.now(), "Example Bio",
//     //           ["Ex1", "Ex2", "Ex3", "Ex4"]),
//     //     ]),
//     () => MatchesPage([
//           Profile("Match 1", DateTime.now(), "Example Bio", ["I1", "I2"]),
//           Profile("Match 2", DateTime.now(), "Example Bio", ["I1", "I2"]),
//           Profile("Match 3", DateTime.now(), "Example Bio", ["I1", "I2"]),
//         ])
//   ];

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: pageBuilders[pageIdx](),
//       bottomNavigationBar: BottomNavigationBar(
//         // for unknown reasons the navbar becomes (mostly) invisible when in "shifting" mode
//         type: BottomNavigationBarType.fixed,
//         currentIndex: pageIdx,
//         onTap: (int idx) {
//           setState(() {
//             pageIdx = idx;
//           });
//         },
//         items: [
//           BottomNavigationBarItem(
//               icon: Icon(Icons.settings), label: "Settings"),
//           BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
//           BottomNavigationBarItem(icon: Icon(Icons.star), label: "Explore"),
//           BottomNavigationBarItem(
//               icon: Icon(Icons.heart_broken), label: "Matches"),
//         ],
//       ),
//     );
//   }
// }
