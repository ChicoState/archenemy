import 'package:flutter/material.dart';
import 'profile.dart';
import 'matches.dart';

void main() {
  runApp(Root());
}

class Root extends StatelessWidget {
  const Root({super.key});

  @override
  Widget build(BuildContext ctx) {
    return MaterialApp(
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        home: App());
  }
}

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => AppState();
}

class AppState extends State<App> {
  int pageIdx = 2;
  List<Widget Function()> pageBuilders = [
    () => Center(child: Text("Settings Placeholder")),
    () => ProfileView(
        Profile("My Profile", DateTime.now(), "My Bio", ["My1", "My2", "My3"])),
    //() => ProfileView(Profile("Example Profile", DateTime.now(), "Example Bio", ["Ex1", "Ex2", "Ex3", "Ex4"])),
    () => ExplorePage([
          Profile("Example Profile #2", DateTime.now(), "Example Bio #2",
              ["Interest #1", "Interest #2", "Interest #3", "Interest #4"]),
          Profile("Example Profile #1", DateTime.now(), "Example Bio",
              ["Ex1", "Ex2", "Ex3", "Ex4"]),
        ]),
    () => MatchesPage([
          Profile("Match 1", DateTime.now(), "Example Bio", ["I1", "I2"]),
          Profile("Match 2", DateTime.now(), "Example Bio", ["I1", "I2"]),
          Profile("Match 3", DateTime.now(), "Example Bio", ["I1", "I2"]),
        ])
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: pageBuilders[pageIdx](),
      bottomNavigationBar: BottomNavigationBar(
        // for unknown reasons the navbar becomes (mostly) invisible when in "shifting" mode
        type: BottomNavigationBarType.fixed,
        currentIndex: pageIdx,
        onTap: (int idx) {
          setState(() {
            pageIdx = idx;
          });
        },
        items: [
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
