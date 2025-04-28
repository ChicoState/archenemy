import 'package:flutter/material.dart';
import 'profile.dart'; // Assuming Profile is already defined elsewhere
import 'chat_page.dart'; // <- We will create this next

class MatchesPage extends StatelessWidget {
  final List<Profile> profiles;
  const MatchesPage(this.profiles, {super.key});

  @override
  Widget build(BuildContext context) {
    Widget profileEntryBuilder(Profile profile) {
      return ListTile(
        title: Text(profile.name),
        subtitle: Text("[latest message...]"),
        leading: SizedBox.fromSize(
          size: const Size(40.0, 40.0),
          child: const Placeholder(),
        ),
        trailing: const Icon(Icons.arrow_right),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChatPage(profile: profile),
            ),
          );
        },
      );
    }

    return ListView.separated(
      itemCount: profiles.length,
      itemBuilder: (context, i) => profileEntryBuilder(profiles[i]),
      separatorBuilder: (context, i) => Divider(
        color: Colors.blueGrey[700],
        thickness: 2,
        indent: 10,
        endIndent: 10,
      ),
    );
  }
}
