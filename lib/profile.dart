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
  const ProfileBoard({super.key});
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
        title: Text('My Profile'),
      ),
      body: Center(
        child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text(style: TextStyle(fontSize: 64), 'Jane Doe'),
                  Expanded(child: Placeholder()),
                  Text('Diskiles....'),
                  Text('chocolate'),
                  Text('ur mom'),
                  Text('Chevrolet')
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
                ])),
      ),
    );
  }
}
