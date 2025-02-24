

import 'dart:convert';

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
				map.name,
				DateTime.parse(map.birthDate),
				map.bio,
				map.interests
			);
		} catch(err) {
			print("Profile JSON parsing error: $err");
			rethrow;
		}
	}
	String toJson() {
		return json.encode({
			name,
			birthDate,
			bio,
			interests
		});
	}
}

