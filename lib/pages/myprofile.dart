
import 'package:flutter/material.dart';
import '../profile.dart';
import '../api.dart' as api;

class MyProfilePage extends StatefulWidget {
  const MyProfilePage({super.key});
  @override createState() => _MyProfilePageState();
}

class _MyProfilePageState extends State<MyProfilePage> {
  @override
  build(BuildContext context) {
		return FutureBuilder(
			future: api.getMyProfile(),
			builder: (context, snapshot) {
				final Profile? profile = snapshot.data;
				if (profile == null) {
					return Center(child: CircularProgressIndicator());
				} else {
					return Stack(children: [
						ProfileView(profile),
						Positioned(
							top: 60,
							right: 10,
							child: IconButton.filled(
								icon: Icon(Icons.menu),
								onPressed: () async {
									await Navigator.push(
										context,
										MaterialPageRoute(
											builder: (context) => EditProfile(profile)
										)
									);
                  setState(() {});
								},
							)
						)
					]);
				}
			}
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
  const EditProfile(this.myProfile, {super.key});
  final Profile myProfile;
  @override
  State<EditProfile> createState() => _EditProfileState();
}

class _EditProfileState extends State<EditProfile> {
  DateTime? selectedDate = DateTime.now();

  late final TextEditingController nameController;
  late final TextEditingController bioController;
  final GlobalKey<FormState> nameFormKey = GlobalKey<FormState>();
  String? forceErrorText;
  bool isLoading = false;
  
  _EditProfileState();
  
  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.myProfile.displayName);
    bioController = TextEditingController(text: widget.myProfile.bio);
  }

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
        widget.myProfile.displayName = nameController.text;
        //widget.myProfile.birthDate = selectedDate ?? DateTime.now();
        widget.myProfile.bio = bioController.text;
        api.patchMyProfile(widget.myProfile);
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
        title: Text('Edit Profile'),
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

