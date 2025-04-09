// lib/explore.dart

import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'samples.dart';

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
    return PopScope(
      canPop: false,
      child: Scaffold(
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
                    // Full-screen image from local assets
                    Positioned.fill(
                      child: Image.asset(
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
                          color: Colors.black.withValues(alpha: 0.4),
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
                            ChipTheme(
                              data: ChipTheme.of(context).copyWith(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 4, vertical: 2),
                                labelPadding: const EdgeInsets.symmetric(
                                    horizontal: 2, vertical: -3),
                                labelStyle: const TextStyle(
                                    fontSize: 14, color: Colors.white),
                                backgroundColor:
                                    Colors.black.withValues(alpha: 0.4),
                              ),
                              child: Wrap(
                                spacing: 6,
                                runSpacing: 4,
                                children: user.interests.map((interest) {
                                  return Chip(label: Text(interest));
                                }).toList(),
                              ),
                            )
                          ],
                        ),
                      ),
                    ),
                    // Removed the buttons from here
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
