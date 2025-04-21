import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';

class User {
  final String name;
  final DateTime birthDate;
  final String bio;
  final List<String> interests;
  final String assetPath; // URL to a high‑res image

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
        assetPath: 'https://picsum.photos/id/1005/1080/1080',
      ),
      User(
        name: 'Bob Smith',
        birthDate: DateTime(1987, 8, 3),
        bio: 'Passionate about open source.',
        interests: ['Dart', 'Linux', 'Music'],
        assetPath: 'https://picsum.photos/id/1001/1080/1080',
      ),
      User(
        name: 'Chris Evans',
        birthDate: DateTime(1995, 11, 22),
        bio: 'Backpacker, photographer',
        interests: ['Travel', 'Hiking', 'Photography'],
        assetPath: 'https://picsum.photos/id/1003/1080/1080',
      ),
      User(
        name: 'Diana Prince',
        birthDate: DateTime(1992, 6, 10),
        bio: 'Globe-trotter and foodie',
        interests: ['Cuisine', 'Blogging', 'Culture'],
        assetPath: 'https://picsum.photos/id/1011/1080/1080',
      ),
    ],
  );
}

class ExplorePage extends StatefulWidget {
  const ExplorePage({super.key});

  @override
  State<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends State<ExplorePage> {
  final CardSwiperController _controller = CardSwiperController();

  @override
  Widget build(BuildContext context) {
    final community = mockCommunity();
    final members = community.members;
    return Scaffold(
      body: Stack(
        children: [
          CardSwiper(
            controller: _controller,
            cardsCount: members.length,
            numberOfCardsDisplayed: 2,
            backCardOffset: const Offset(20, 20),
            scale: 0.9,
            padding: EdgeInsets.zero,
            isLoop: true,
            cardBuilder: (
              BuildContext context,
              int index,
              int horizontalOffsetPercentage,
              int verticalOffsetPercentage,
            ) {
              if (index < 0 || index >= members.length) return null;
              final user = members[index];
              return Stack(
                children: [
                  // Full-screen image from network URL
                  Positioned.fill(
                    child: Image.network(
                      user.assetPath,
                      fit: BoxFit.cover,
                    ),
                  ),
                  // Semi-transparent overlay with user info (bottom-left)
                  Positioned(
                    left: 16,
                    right: 16,
                    bottom: 100,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            user.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            user.bio,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: user.interests.map((interest) {
                              return Chip(
                                label: Text(
                                  interest,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                  ),
                                ),
                                backgroundColor: Colors.black.withOpacity(0.4),
                              );
                            }).toList(),
                          )
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
            onSwipe: (previousIndex, currentIndex, direction) {
              debugPrint(
                  'Swiped card $previousIndex ${direction.name}; now top is $currentIndex');
              return true;
            },
            onUndo: (previousIndex, currentIndex, direction) {
              debugPrint('Undoing card $currentIndex from ${direction.name}');
              return true;
            },
          ),
          // Fixed two-button overlay at the bottom.
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                FloatingActionButton(
                  heroTag: 'thumbsDown',
                  elevation: 6,
                  backgroundColor: Colors.red,
                  onPressed: () {
                    _controller.swipe(CardSwiperDirection.left);
                  },
                  child: const Icon(Icons.thumb_down),
                ),
                FloatingActionButton(
                  heroTag: 'thumbsUp',
                  elevation: 6,
                  backgroundColor: Colors.green,
                  onPressed: () {
                    _controller.swipe(CardSwiperDirection.right);
                  },
                  child: const Icon(Icons.thumb_up),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

///////////////////////////////////////////////////////////////////////////////

// class ExplorePage extends StatefulWidget {
//   List<Profile> profiles;
//   ExplorePage(this.profiles, {super.key});

//   @override
//   createState() => _ExplorePageState();
// }

// class _ExplorePageState extends State<ExplorePage> {
//   @override
//   build(BuildContext context) {
//     final profiles = widget.profiles;
//     final profileView = profiles.isEmpty
//         ? Center(child: Text("No more profiles!"))
//         : ProfileView(profiles.last);

//     return Stack(children: [
//       profileView,
//       Positioned(
//           bottom: 10.0,
//           left: 10.0,
//           child: IconButton.filled(
//               icon: Icon(Icons.close),
//               onPressed: () {
//                 log.d("Disiked!");
//                 setState(() {
//                   widget.profiles.removeLast();
//                 });
//               })),
//       Positioned(
//         bottom: 10.0,
//         right: 10.0,
//         child: IconButton.filled(
//             icon: Icon(Icons.check),
//             onPressed: () {
//               log.d("Liked!");
//               setState(() {
//                 widget.profiles.removeLast();
//               });
//             }),
//       )
//     ]);
//   }
// }

// import 'package:flutter/material.dart';
// import '../profile.dart';
// import '../log.dart' as log;
// import 'package:hatingapp/api.dart' as api;

// final class ExplorePage extends StatefulWidget {
//   const ExplorePage({super.key});

//   @override
//   createState() => _ExplorePageState();
// }

// class _ExplorePageState extends State<ExplorePage> {
//   //Future<Profile?> future;

//   @override
//   build(BuildContext context) {
//     return FutureBuilder(
//         future: api.getNextExploreProfile(),
//         builder: (context, snapshot) {
//           if (snapshot.connectionState != ConnectionState.done) {
//             return Center(child: CircularProgressIndicator());
//           } else {
//             final profile = snapshot.data;
//             final profileView = profile == null
//                 ? ProfileView(Profile.dummy(
//                     "<no-more-profiles>")) //Center(child: Text("No more profiles!"))
//                 : ProfileView(profile);

//             return Stack(children: [
//               profileView,
//               Positioned(
//                   bottom: 10.0,
//                   left: 10.0,
//                   child: IconButton.filled(
//                       icon: Icon(Icons.close),
//                       onPressed: () async {
//                         await api.popExploreProfile(liked: false);
//                         log.debug("Disiked!");
//                         setState(() {});
//                       })),
//               Positioned(
//                 bottom: 10.0,
//                 right: 10.0,
//                 child: IconButton.filled(
//                     icon: Icon(Icons.check),
//                     onPressed: () async {
//                       await api.popExploreProfile(liked: false);
//                       log.debug("Liked!");
//                       setState(() {});
//                     }),
//               )
//             ]);
//           }
//         });
//   }
// }
