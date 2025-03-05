import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class Profile {
  String name;
  DateTime birthDate;
  String bio;
  List<String> interests;

  Profile(this.name, this.birthDate, this.bio, this.interests);

  void update(String name_, DateTime birthDate_, String bio_) {
    name = name_;
    birthDate = birthDate_;
    bio = bio_;
  }

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
              context,
              MaterialPageRoute(
                  builder: (context) => EditProfile(
                        myProfile: widget.myProfile,
                      )));
        },
        child: const Icon(Icons.manage_accounts),
      ),
    );
  }
}

class EditProfile extends StatefulWidget {
  const EditProfile({super.key, required this.myProfile});
  final Profile myProfile;
  @override
  State<EditProfile> createState() => _EditProfileState();
}

class _EditProfileState extends State<EditProfile> {
  DateTime? selectedDate = DateTime.now();
  String? enteredName = "name";
  String? enteredBio = "bio";

  Future<void> _selectDate() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1000),
      lastDate: DateTime.now(),
    );

    setState(() {
      selectedDate = pickedDate;
    });
  }

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
                    onSaved: (String? val) {
                      setState(() {
                        enteredName = val;
                      });
                    },
                  ),
                  TextFormField(
                    minLines: 1,
                    maxLines: 10,
                    maxLength: 1000,
                    decoration: const InputDecoration(
                      border: UnderlineInputBorder(),
                      labelText: 'What really grinds your gears',
                    ),
                    onSaved: (String? val) {
                      enteredBio = val;
                    },
                  ),
                  Text(
                    selectedDate != null
                        ? '${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}'
                        : 'No date selected',
                  ),
                  TextButton(
                      onPressed: _selectDate, child: const Text("Birthday")),
                  TextButton(
                    onPressed: () {
                      if (enteredName == null) {
                        final nameSnackBar = SnackBar(
                          content: const Text('Please enter your name'),
                          action: SnackBarAction(
                            label: 'Undo',
                            onPressed: () {
                              // Some code to undo the change.
                            },
                          ),
                        );
                        ScaffoldMessenger.of(context)
                            .showSnackBar(nameSnackBar);
                      } else if (enteredBio == null) {
                        final bioSnackBar = SnackBar(
                          content:
                              const Text('please enter your pio information'),
                          action: SnackBarAction(
                            label: 'Undo',
                            onPressed: () {
                              // Some code to undo the change.
                            },
                          ),
                        );
                        ScaffoldMessenger.of(context).showSnackBar(bioSnackBar);
                      } else if (selectedDate == null) {
                        final dateSnackBar = SnackBar(
                          content: const Text('Please select your birthday'),
                          action: SnackBarAction(
                            label: 'Undo',
                            onPressed: () {
                              // Some code to undo the change.
                            },
                          ),
                        );

                        // Find the ScaffoldMessenger in the widget tree
                        // and use it to show a SnackBar.
                        ScaffoldMessenger.of(context)
                            .showSnackBar(dateSnackBar);
                      } else {
                        widget.myProfile.update(
                            enteredName ?? "Jane doe",
                            selectedDate ?? DateTime.now(),
                            enteredBio ?? "bio");
                      }
                    },
                    child: Text('Save'),
                  )
                ])),
      ),
    );
  }
}
