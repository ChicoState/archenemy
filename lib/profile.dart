import 'dart:convert';
import 'package:flutter/material.dart';
import 'log.dart';


class Profile {
  String name;
  DateTime birthDate;
  String bio;
  List<String> interests;

  Profile(this.name, this.birthDate, this.bio, this.interests);

  // Not a particularly great implementation
  factory Profile.fromJson(String raw) {
    try {
      var map = json.decode(raw);
      return Profile(
				map.name,
				DateTime.parse(map.birthDate),
				map.bio,
				map.interests
			);
    } catch (err) {
      log.e("Profile JSON parsing error: $err");
      rethrow;
    }
  }
  String toJson() {
    return json.encode({name, birthDate, bio, interests});
  }
}

class ProfileView extends StatelessWidget {
	
	final Profile profile;
	final bool editable; // doesn't work yet
	// not sure whether profile editing should happen on another page or not
	
  const ProfileView(this.profile, {
		super.key,
		this.editable = false
	});
  
	@override
  Widget build(BuildContext context) {
    //return Placeholder();
		
		Widget interestsView(List<String> interests) {
			return Text.rich(
				TextSpan(
					children: interests.map((interest) {
						return WidgetSpan(
							child: Card(
								margin: EdgeInsets.fromLTRB(3.0, 0.0, 3.0, 0.0),
								color: Colors.grey[400],//Theme.of(context).cardColor,
								shape: RoundedRectangleBorder(
									borderRadius: BorderRadius.all(Radius.circular(4.0))
								),
								child: Padding(
									padding: EdgeInsets.fromLTRB(5.0, 3.0, 5.0, 3.0),
									child: Text(interest)
								),
							)
						);
					}).toList()
				)
			);
		}
		
		final children = [
			Text(style: TextStyle(fontSize: 24), profile.name),
			SizedBox(height: 160, child: Placeholder()),
			interestsView(profile.interests),
			Text(profile.bio),
			SizedBox(height: 160, child: Placeholder()),
			SizedBox(height: 160, child: Placeholder()),
		];
		
		
		// Unbelievably, this is the easiest way I could find to do this
		List<Widget> spacedChildren = [];
		for (Widget child in children) {
			spacedChildren.add(child);
			spacedChildren.add(SizedBox(height: 10));
		}
		
		return Padding(
			padding: EdgeInsets.all(16.0),
			child: ListView(
				//mainAxisAlignment: MainAxisAlignment.center,
				children: spacedChildren
			)
		);
		
    /*return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text("Profile"),
      ),
      body: Center(
        child: Padding(
					padding: EdgeInsets.all(16.0),
					child: Column(
						mainAxisAlignment: MainAxisAlignment.center,
						children: <Widget>[
							Text(style: TextStyle(fontSize: 64), profile.name),
							Expanded(child: Placeholder()),
							Container(
								height: MediaQuery.sizeOf(context).height / 4,
								width: MediaQuery.sizeOf(context).width,
								padding: EdgeInsets.all(16.0),
								child: ListView.builder(
									itemCount: profile.interests.length,
									prototypeItem: ListTile(
										title: Text(profile.interests[0]),
									),
									itemBuilder: (context, index) {
										return ListTile(
											title: Text(profile.interests[index]));
									}),
							)
						]
					)
				),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
					final route = MaterialPageRoute(builder: (context) => EditProfile());
          Navigator.push(context, route);
        },
        child: const Icon(Icons.manage_accounts),
      ),
    );*/
  }
}

class EditProfile extends StatefulWidget {
  const EditProfile({super.key});
  @override
  State<EditProfile> createState() => _EditProfileState();
}

class _EditProfileState extends State<EditProfile> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text('My Profile'),
      ),
      body: Center(
        child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  TextFormField(
                    decoration: const InputDecoration(
                      border: UnderlineInputBorder(),
                      labelText: 'Enter your name',
                    ),
                  ),
                  TextFormField(
                    decoration: const InputDecoration(
                      border: UnderlineInputBorder(),
                      labelText: 'What really grinds your gears',
                    ),
                  )
                ])),
      ),
    );
  }
}
