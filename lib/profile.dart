import 'dart:convert';
import 'package:flutter/material.dart';

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
          map.name, DateTime.parse(map.birthDate), map.bio, map.interests);
    } catch (err) {
      print("Profile JSON parsing error: $err");
      rethrow;
    }
  }
  String toJson() {
    return json.encode({name, birthDate, bio, interests});
  }
}

class ProfileBoard extends StatefulWidget {
  const ProfileBoard({super.key, required this.myProfile});
  final Profile myProfile;
  @override
  State<ProfileBoard> createState() => _ProfileBoardState();
}

class _ProfileBoardState extends State<ProfileBoard> {
  @override
  Widget build(BuildContext context) {
    //return Placeholder();

    return Scaffold(
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
                  Text(style: TextStyle(fontSize: 64), widget.myProfile.name),
                  Expanded(child: Placeholder()),
                  Container(
                    height: MediaQuery.sizeOf(context).height / 4,
                    width: MediaQuery.sizeOf(context).width,
                    padding: EdgeInsets.all(16.0),
                    child: ListView.builder(
                        itemCount: widget.myProfile.interests.length,
                        prototypeItem: ListTile(
                          title: Text(widget.myProfile.interests[0]),
                        ),
                        itemBuilder: (context, index) {
                          return ListTile(
                              title: Text(widget.myProfile.interests[index]));
                        }),
                  )
                ])),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
              context, MaterialPageRoute(builder: (context) => EditProfile()));
        },
        child: const Icon(Icons.manage_accounts),
      ),
    );
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
                    expands: true,
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
