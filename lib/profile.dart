import 'dart:convert';
import 'package:flutter/material.dart';
import 'log.dart';


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
								margin: EdgeInsets.fromLTRB(3.0, 3.0, 3.0, 3.0),
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
