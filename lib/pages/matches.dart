
import 'package:flutter/material.dart';
import '../profile.dart';


/*class Match {
	Profile profile;
	//Profile? profile; // We may not have their profile from the server yet
}*/


class MatchesPage extends StatelessWidget {
	
	final List<Profile> profiles = [
		Profile.dummy("Match 1"),
		Profile.dummy("Match 2"),
		Profile.dummy("Match 3"),
		//Profile("Match 1", DateTime.now(), "Example Bio", ["I1", "I2"]),
		//Profile("Match 2", DateTime.now(), "Example Bio", ["I1", "I2"]),
		//Profile("Match 3", DateTime.now(), "Example Bio", ["I1", "I2"]),
	];
	MatchesPage({ super.key });
	
	@override
	Widget build(BuildContext context) {
		
		Widget profileEntryBuilder(Profile profile) {
			return ListTile(
				title: Text(profile.displayName),
				subtitle: Text("[latest message...]"),
				leading: SizedBox.fromSize(
					size: Size(40.0, 40.0),
					child: Placeholder()
				),
				trailing: Icon(Icons.arrow_right)
			);
		}
		
		return ListView.separated(
			itemCount: profiles.length,
			itemBuilder: (context, i) => profileEntryBuilder(profiles[i]),
			separatorBuilder: (context, i) => Divider(color: Colors.blueGrey[700], thickness: 2, indent: 10, endIndent: 10)
		);
	}
}



