class User {
  final String name;
  final DateTime birthDate;
  final String bio;
  final List<String> interests;
  final String assetPath; // local asset path

  User({
    required this.name,
    required this.birthDate,
    required this.bio,
    required this.interests,
    required this.assetPath,
  });
}

class Community {
  final List<User> members;

  Community({required this.members});
}

Community mockCommunity() {
  return Community(
    members: [
      User(
        name: 'Alice Johnson',
        birthDate: DateTime(1990, 4, 12),
        bio: 'Flutter fan, coffee addict',
        interests: ['Flutter', 'Coffee', 'UI/UX'],
        assetPath: 'assets/images/1.jpg',
      ),
      User(
        name: 'Bob Smith',
        birthDate: DateTime(1987, 8, 3),
        bio: 'Passionate about open source. Passionate about open source',
        interests: ['Dart', 'Linux', 'Music'],
        assetPath: 'assets/images/2.jpg',
      ),
      User(
        name: 'Chris Evans',
        birthDate: DateTime(1995, 11, 22),
        bio: 'Backpacker, photographer',
        interests: ['Travel', 'Hiking', 'Photography'],
        assetPath: 'assets/images/3.jpg',
      ),
      User(
        name: 'Diana Prince',
        birthDate: DateTime(1992, 6, 10),
        bio: 'Globe-trotter and foodie',
        interests: ['Cuisine', 'Blogging', 'Culture'],
        assetPath: 'assets/images/4.jpeg',
      ),
    ],
  );
}
