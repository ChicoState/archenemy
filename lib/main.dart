import 'package:flutter/material.dart';
import 'profile.dart';

void main() {
  runApp(Root());
}

class Root extends StatelessWidget {
	const Root({ super.key });
  
  @override
  Widget build(BuildContext ctx) {
		return MaterialApp(
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: App()
    );
	}
}
class App extends StatefulWidget {
	const App({ super.key });
	
	@override
	State<App> createState() => AppState();
}
class AppState extends State<App> {
	int pageIdx = 2;
	List<Widget Function()> pageBuilders = [
    () => ProfileBoard(myProfile: Profile("Jane Doe", DateTime.now(), "My bio", List<String>.from(["one", "two"]))),
    () => Center(child: Text("bcdef")),
    () => Center(child: Text("bcdef")),
    () => Center(child: Text("bcdef"))
  ];
  
  @override
	Widget build(BuildContext context) {
		return Scaffold(
      body: pageBuilders[pageIdx](),
			bottomNavigationBar: BottomNavigationBar(
        // for unknown reasons the navbar becomes (mostly) invisible when in "shifting" mode
        type: BottomNavigationBarType.fixed,
        //backgroundColor: Theme.of(context).
				currentIndex: pageIdx,
				onTap: (int idx) {
					setState(() {
						pageIdx = idx;
					});
				},
				items: [
					BottomNavigationBarItem(icon: Icon(Icons.settings), label: "Settings"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
					BottomNavigationBarItem(icon: Icon(Icons.star), label: "Explore"),
					BottomNavigationBarItem(icon: Icon(Icons.heart_broken), label: "Matches"),
				],
			),
		);
	}
}


