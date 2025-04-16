import 'package:flutter/material.dart';
import '../auth.dart';
import '../main.dart'; // Import to access themeModeNotifier
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Settings"),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Main settings items at the top
              ValueListenableBuilder<ThemeMode>(
                valueListenable: themeModeNotifier,
                builder: (context, currentTheme, child) {
                  bool isDarkMode = currentTheme == ThemeMode.dark;
                  return SwitchListTile(
                    title: const Text("Dark Mode"),
                    value: isDarkMode,
                    onChanged: (bool value) async {
                      themeModeNotifier.value =
                          value ? ThemeMode.dark : ThemeMode.light;
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setBool('darkMode', value);
                    },
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.info),
                title: const Text("About"),
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) {
                      return AlertDialog(
                        title: const Text("Archnemesis"),
                        content: SingleChildScrollView(
                          child: Text(
                            "By the sting of betrayal and the glory of vendetta, I vow eternal opposition. "
                            "From petty slights to apocalyptic confrontations, I sharpen my wit as my weapon and fan the flames of rivalry. "
                            "I shall lurk in shadows of your triumphs, mirror your rise with my own, and forge my legacy in the ashes of your comfort.\n\n"
                            "Where you stand tall, I crouch in defiance. Where you find peace, I sow glorious chaos. "
                            "Let every smirk, every success, be a battle cry echoing through our lifelong feud.\n\n"
                            "For every hero needs a villain. And I am yours.",
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text("OK"),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
              // Add more settings here if needed

              // Spacer pushes the logout to the bottom
              const Spacer(),

              // Logout button at the bottom center
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  style: TextButton.styleFrom(
                    // Adjust the background color to your liking.
                    // You might choose a slightly tinted color or even transparent until pressed.
                    backgroundColor: Theme.of(context).colorScheme.error,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: () async {
                    await signOut();
                    // Navigator.of(context).pushReplacement(
                    //   MaterialPageRoute(builder: (_) => LoginPage()),
                    // );
                  },
                  child: Text(
                    "Logout",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onError,
                      // You can also set the color here explicitly, or use Theme.of(context).colorScheme.error, for example.
                    ),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
