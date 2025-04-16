
import 'package:flutter/material.dart';
import '../profile.dart';
import '../log.dart' as log;
import 'package:hatingapp/api.dart' as api;

final class ExplorePage extends StatefulWidget {
  const ExplorePage({super.key});
	
  @override
  createState() => _ExplorePageState();
}

class _ExplorePageState extends State<ExplorePage> {
	
	//Future<Profile?> future;
	
  @override build(BuildContext context) {
		
		return FutureBuilder(
			future: api.getNextExploreProfile(),
			builder: (context, snapshot) {
				if (snapshot.connectionState != ConnectionState.done) {
					return Center(child: CircularProgressIndicator());
				} else {
					final profile = snapshot.data;
					final profileView = profile == null
						? ProfileView(Profile.dummy("<no-more-profiles>")) //Center(child: Text("No more profiles!"))
						: ProfileView(profile);
					
					return Stack(children: [
						profileView,
						Positioned(
							bottom: 10.0,
							left: 10.0,
							child: IconButton.filled(
								icon: Icon(Icons.close),
								onPressed: () async {
									await api.popExploreProfile(liked: false);
									log.debug("Disiked!");
									setState(() {});
								}
							)
						),
						Positioned(
							bottom: 10.0,
							right: 10.0,
							child: IconButton.filled(
								icon: Icon(Icons.check),
								onPressed: () async {
									await api.popExploreProfile(liked: false);
									log.debug("Liked!");
									setState(() {});
								}
							),
						)
					]);
				}
			}
		);
		
    
  }
}
