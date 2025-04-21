import 'package:flutter/material.dart';
import 'log.dart';

class Profile {
  //String name;
  //DateTime birthDate;
  //String bio;
  //List<String> interests;

  final String id;
  String username; // should maybe be final
  String displayName;
  String avatarUrl;
  String bio;
  List<String>? tags;
  //List<double> embedding;
  //DateTime createdAt;
  //DateTime updatedAt;

  Profile({
    required this.id,
    required this.username,
    required this.displayName,
    required this.avatarUrl,
    required this.bio,
    this.tags,
  });
  factory Profile.dummy(String displayName,
      {String bio = "<test bio>",
      List<String> tags = const ["Test Tag #1", "Test Tag #2"]}) {
    return Profile(
        id: "dummy",
        username: "dummy",
        displayName: displayName,
        avatarUrl: "",
        bio: bio,
        tags: tags);
  }

  /*void update(String name, DateTime birthDate, String bio) {
    name = name_;
    birthDate = birthDate_;
    bio = bio_;
  }*/
}

class ProfileView extends StatelessWidget {
  final Profile profile;
  final bool editable; // doesn't work yet
  // not sure whether profile editing should happen on another page or not

  const ProfileView(this.profile, {super.key, this.editable = false});

  @override
  Widget build(BuildContext context) {
    //return Placeholder();

    Widget? interestsView(List<String>? interests) {
      if (interests == null) return null;
      return Text.rich(TextSpan(
          children: interests.map((interest) {
        return WidgetSpan(
            child: Card(
          margin: EdgeInsets.fromLTRB(3.0, 3.0, 3.0, 3.0),
          color: Colors.grey[400], //Theme.of(context).cardColor,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(4.0))),
          child: Padding(
              padding: EdgeInsets.fromLTRB(5.0, 3.0, 5.0, 3.0),
              child: Text(interest)),
        ));
      }).toList()));
    }

    final children = [
      Text(style: TextStyle(fontSize: 24), profile.displayName),
      SizedBox(height: 160, child: Placeholder()),
      interestsView(profile.tags),
      Text(profile.bio),
      SizedBox(height: 160, child: Placeholder()),
      SizedBox(height: 160, child: Placeholder()),
    ];

    // Unbelievably, this is the easiest way I could find to do this
    List<Widget> spacedChildren = [];
    for (Widget? child in children) {
      if (child == null) continue;
      spacedChildren.add(child);
      spacedChildren.add(SizedBox(height: 10));
    }

    return Padding(
        padding: EdgeInsets.all(16.0),
        child: ListView(
            //mainAxisAlignment: MainAxisAlignment.center,
            children: spacedChildren));

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
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => EditProfile(
                        myProfile: widget.myProfile,
                      ))).then((_) {
            setState(() {
              widget.myProfile;
            });
          });
        },
        child: const Icon(Icons.manage_accounts),
      ),
    );*/
  }
}
