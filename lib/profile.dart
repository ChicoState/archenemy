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
                      ))).then((_) {
            setState(() {
              widget.myProfile;
            });
          });
        },
        child: const Icon(Icons.manage_accounts),
      ),
    );
  }
}

////////////////////////////////////////////////////
/// Use: use navigator.push and pass a profile class.
/// then put :
///
/// .then((_) {
///   setState(() {
///     widget.myProfile;
///   });
/// }
/// immediately after the Navigator.push argument
/// the profile will be edited in the next page
/// once the data is saved and pop'd off the widget tree
/// the profile data will be updated on the current page
///////////////////////////////////////////////////////
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

  final TextEditingController nameController = TextEditingController();
  final TextEditingController bioController = TextEditingController();
  final GlobalKey<FormState> nameFormKey = GlobalKey<FormState>();
  String? forceErrorText;
  bool isLoading = false;

  @override
  void dispose() {
    nameController.dispose();
    bioController.dispose();
    super.dispose();
  }

  String? validator(String? value) {
    if (value == null || value.isEmpty) {
      return 'This field is required';
    }
    if (int.tryParse(value[0]) != null) {
      return 'Name must not start with a number';
    }
    return null;
  }

  String? bioValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'This field is required';
    }
    return null;
  }

  void onChanged(String value) {
    // Nullify forceErrorText if the input changed.
    if (forceErrorText != null) {
      setState(() {
        forceErrorText = null;
      });
    }
  }

  Future<void> onSave() async {
    // Providing a default value in case this was called on the
    // first frame, the [fromKey.currentState] will be null.
    final bool isValid = nameFormKey.currentState?.validate() ?? false;
    if (!isValid) {
      return;
    }

    setState(() => isLoading = true);
    final String? errorText =
        await validateUsernameFromServer(nameController.text);

    if (context.mounted) {
      setState(() => isLoading = false);
      if (errorText != null) {
        setState(() {
          forceErrorText = errorText;
        });
      }

      setState(() {
        // widget.myProfile.update(nameController.text,
        //     selectedDate ?? DateTime.now(), bioController.text);
        widget.myProfile.name = nameController.text;
        widget.myProfile.birthDate = selectedDate ?? DateTime.now();
        widget.myProfile.bio = bioController.text;
        //print("Saved");
      });
    }
  }

  Future<String?> validateUsernameFromServer(String username) async {
    final Set<String> takenUsernames = <String>{'jack', 'alex'};

    await Future<void>.delayed(Duration(seconds: 1));

    final bool isValid = !takenUsernames.contains(username);
    if (isValid) {
      return null;
    }

    return 'Username $username is already taken';
  }

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
            child: Form(
                key: nameFormKey,
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      TextFormField(
                        forceErrorText: forceErrorText,
                        controller: nameController,
                        validator: validator,
                        onChanged: onChanged,
                        decoration: const InputDecoration(
                          border: UnderlineInputBorder(),
                          labelText: 'Enter your name',
                        ),
                      ),
                      TextFormField(
                        minLines: 1,
                        maxLines: 10,
                        maxLength: 1000,
                        decoration: const InputDecoration(
                          border: UnderlineInputBorder(),
                          labelText: 'What really grinds your gears',
                        ),
                        forceErrorText: forceErrorText,
                        controller: bioController,
                        validator: bioValidator,
                        onChanged: onChanged,
                      ),
                      Text(
                        selectedDate != null
                            ? '${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}'
                            : 'No date selected',
                      ),
                      TextButton(
                          onPressed: _selectDate,
                          child: const Text("Birthday")),
                      if (isLoading)
                        const CircularProgressIndicator()
                      else
                        TextButton(
                          onPressed: onSave,
                          child: Text('Save'),
                        )
                    ]))),
      ),
    );
  }
}
