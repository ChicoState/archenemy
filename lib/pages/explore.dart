import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';

import 'package:hatingapp/profile.dart';
import 'package:hatingapp/api.dart' as api;
import 'package:hatingapp/log.dart' as log;
import 'dart:math';

/*class profile {
  final String name;
  final DateTime birthDate;
  final String bio;
  final List<String> interests;
  final String assetPath;

  profile({
    required this.name,
    required this.birthDate,
    required this.bio,
    required this.interests,
    required this.assetPath,
  });
}

class Community {
  final List<profile> members;

  Community({required this.members});
}

Community mockCommunity() {
  return Community(
    members: [
      profile(
        name: 'Alice Johnson',
        birthDate: DateTime(1990, 4, 12),
        bio: 'Flutter fan, coffee addict',
        interests: ['Flutter', 'Coffee', 'UI/UX'],
        assetPath: 'https://picsum.photos/id/1005/1080/1080',
      ),
      profile(
        name: 'Bob Smith',
        birthDate: DateTime(1987, 8, 3),
        bio: 'Passionate about open source.',
        interests: ['Dart', 'Linux', 'Music'],
        assetPath: 'https://picsum.photos/id/1001/1080/1080',
      ),
      profile(
        name: 'Chris Evans',
        birthDate: DateTime(1995, 11, 22),
        bio: 'Backpacker, photographer',
        interests: ['Travel', 'Hiking', 'Photography'],
        assetPath: 'https://picsum.photos/id/1003/1080/1080',
      ),
      profile(
        name: 'Diana Prince',
        birthDate: DateTime(1992, 6, 10),
        bio: 'Globe-trotter and foodie',
        interests: ['Cuisine', 'Blogging', 'Culture'],
        assetPath: 'https://picsum.photos/id/1011/1080/1080',
      ),
    ],
  );
}*/

class ExplorePage extends StatefulWidget {
  const ExplorePage({super.key});

  @override
  State<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends State<ExplorePage> {
  final CardSwiperController _controller = CardSwiperController();

  @override
  Widget build(BuildContext context) {
		
		
		
		return Scaffold(
			body: FutureBuilder(
				future: api.getExploreProfiles(),
				builder: (context, snapshot) {
					final members = snapshot.data;
					if (members == null) {
						return Center(child: CircularProgressIndicator());
					} else {
						log.info(members);
						if (members.isEmpty) {
							members.add(Profile.dummy());
						}
						return CardSwiper(
							controller: _controller,
							cardsCount: members.length + 2,
							//numberOfCardsDisplayed: 2,
							backCardOffset: const Offset(20, 20),
							scale: 0.9,
							padding: EdgeInsets.zero,
							//isLoop: true,
							isLoop: false,
							
							cardBuilder: (
								BuildContext context,
								int index,
								int horizontalOffsetPercentage,
								int verticalOffsetPercentage,
							) {
								if (index < 0 || index > members.length) {
									return null;
								} else if (index == members.length) {
									return Center(
										child: Text("Nobody left!")
									);
								}
								
								const defaultPhotos = [
									'https://picsum.photos/400/600?image=1011',
									'https://picsum.photos/400/600?image=1022',
									'https://picsum.photos/400/600?image=1033',
								];
								
								final profile = members[index];
								final tags = profile.tags ?? [];
								final photos = profile.photos ?? [defaultPhotos[Random().nextInt(3)]];
								
								return Stack(
									children: [
										// Full-screen image from network URL
										Positioned.fill(
											child: Image.network(
												photos.first,
												fit: BoxFit.cover,
											),
										),
										// Semi-transparent overlay with profile info (bottom-left)
										Positioned(
											left: 16,
											right: 16,
											bottom: 130,
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
															profile.displayName,
															style: const TextStyle(
																color: Colors.white,
																fontSize: 24,
																fontWeight: FontWeight.bold,
															),
														),
														const SizedBox(height: 8),
														Text(
															profile.bio,
															style: const TextStyle(
																color: Colors.white,
																fontSize: 16,
															),
														),
														const SizedBox(height: 8),
														Wrap(
															spacing: 6,
															runSpacing: 4,
															children: tags.map((interest) {
																return Chip(
																	label: Text(
																		interest,
																		style: const TextStyle(
																			color: Colors.white,
																			fontSize: 14,
																		),
																	),
																	backgroundColor:
																			Colors.black.withValues(alpha: 0.4),
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
								api.popExploreProfile(liked: true);
								return true;
							},
							onUndo: (previousIndex, currentIndex, direction) {
								debugPrint('Undoing card $currentIndex from ${direction.name}');
								return true;
							},
						);
					}
					
					
					
				}
				
			)
		);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
