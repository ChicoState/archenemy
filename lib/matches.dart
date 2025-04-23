
import 'package:flutter/material.dart';
import 'profile.dart';


/*class Match {
	Profile profile;
	//Profile? profile; // We may not have their profile from the server yet
}*/


class MatchesPage extends StatelessWidget {
	
	final List<Profile> profiles;
	const MatchesPage(this.profiles, { super.key });
	
	@override
	Widget build(BuildContext context) {
		
		Widget profileEntryBuilder(Profile profile) {
			return ListTile(
				title: Text(profile.name),
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



