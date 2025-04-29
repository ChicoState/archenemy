import 'package:flutter/material.dart';

class DummyProfile {
  final List<String> photoUrls;
  final String displayName;
  final DateTime birthDate;
  final String bio;
  final List<String> interests;
  final String longDescription;

  DummyProfile({
    required this.photoUrls,
    required this.displayName,
    required this.birthDate,
    required this.bio,
    required this.interests,
    required this.longDescription,
  });

  factory DummyProfile.example() => DummyProfile(
        photoUrls: [
          'https://picsum.photos/400/600?image=1011',
          'https://picsum.photos/400/600?image=1022',
          'https://picsum.photos/400/600?image=1033',
        ],
        displayName: 'Alex',
        birthDate: DateTime(1995, 6, 15),
        bio: 'Lover of hikes, coffee, and spontaneous road trips.',
        interests: ['Hiking', 'Coffee', 'Music', 'Cooking'],
        longDescription:
            'Software engineer by day, amateur photographer by weekend. '
            'Always looking for the next adventure or a lazy Sunday in.',
      );
}

class MyProfilePage extends StatefulWidget {
  const MyProfilePage({super.key});

  @override
  MyProfilePageState createState() => MyProfilePageState();
}

class MyProfilePageState extends State<MyProfilePage> {
  @override
  Widget build(BuildContext context) {
    final profile = DummyProfile.example();
    final cs = Theme.of(context).colorScheme;
    // final txt = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: cs.surface,
      body: Stack(
        children: [
          ProfileView(profile),
          Positioned(
            top: 60,
            right: 10,
            child: IconButton(
              icon: Icon(Icons.menu, color: cs.onSurface),
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    ////////////////Commented out until api integration//////////
                    /// builder: (context) => EditProfile(profile),
                    ////////////////////////////////////////////////////////////
                    builder: (context) => EditProfile(), // use for now
                  ),
                );
                setState(() {});
              },
            ),
          ),
        ],
      ),
    );
  }
}

class ProfileView extends StatefulWidget {
  final DummyProfile profile;
  const ProfileView(this.profile, {super.key});

  @override
  ProfileViewState createState() => ProfileViewState();
}

class ProfileViewState extends State<ProfileView> {
  late final PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  int get age {
    final now = DateTime.now();
    final bd = widget.profile.birthDate;
    var a = now.year - bd.year;
    if (now.month < bd.month || (now.month == bd.month && now.day < bd.day)) {
      a--;
    }
    return a;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final txt = Theme.of(context).textTheme;
    final photos = widget.profile.photoUrls;

    return Scaffold(
      backgroundColor: cs.surface,
      body: NestedScrollView(
        headerSliverBuilder: (_, __) => [
          SliverAppBar(
            backgroundColor: cs.surface,
            expandedHeight: 480,
            pinned: true,
            automaticallyImplyLeading: false,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  PageView.builder(
                    controller: _pageController,
                    itemCount: photos.length,
                    onPageChanged: (i) => setState(() => _currentPage = i),
                    itemBuilder: (_, i) => Image.network(
                      photos[i],
                      fit: BoxFit.cover,
                      loadingBuilder: (ctx, child, prog) => prog == null
                          ? child
                          : const Center(child: CircularProgressIndicator()),
                    ),
                  ),
                  Positioned(
                    bottom: 16,
                    left: 0,
                    right: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(photos.length, (i) {
                        final selected = i == _currentPage;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: selected ? 12 : 8,
                          height: selected ? 12 : 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: cs.onSurface.withValues(
                              alpha: selected ? 0.9 : 0.4,
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
        body: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${widget.profile.displayName}, $age',
                  style: txt.headlineSmall?.copyWith(
                    color: cs.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Icon(Icons.mail, color: cs.onSurface),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              widget.profile.bio,
              style: txt.bodyMedium?.copyWith(
                color: cs.onSurface.withValues(alpha: 0.8),
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: widget.profile.interests.map((tag) {
                return Chip(
                  label: Text(
                    tag,
                    style: txt.bodySmall?.copyWith(
                      color: cs.onPrimaryContainer,
                    ),
                  ),
                  backgroundColor: cs.primaryContainer,
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            Text(
              'About me',
              style: txt.titleMedium?.copyWith(
                color: cs.onSurface,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.profile.longDescription,
              style: txt.bodyMedium?.copyWith(
                color: cs.onSurface.withValues(alpha: 0.8),
              ),
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}

class EditProfile extends StatefulWidget {
  ////////////////Commented out until api integration/////////////////
  // const EditProfile(this.myProfile, {super.key});
  // final Profile myProfile;
  ///////////////////////////////////////////////////////////////
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
    final String? errorText = await validateUsernameFromServer(
      nameController.text,
    );

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

        ////////////////Commented out until api integration//////////
        /// widget.myProfile.displayName = nameController.text;
        /////////////////////////////////////////////////////////////

        //widget.myProfile.birthDate = selectedDate ?? DateTime.now();

        ////////////////Commented out until api integration//////////
        /// widget.myProfile.bio = bioController.text;
        /// api.patchMyProfile(widget.myProfile);
        ////////////////////////////////////////////////////////////

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
                  child: const Text("Birthday"),
                ),
                if (isLoading)
                  const CircularProgressIndicator()
                else
                  TextButton(onPressed: onSave, child: Text('Save')),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
