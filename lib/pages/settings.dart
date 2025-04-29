import 'package:flutter/material.dart';
import '../theme_manager.dart';
import '../auth.dart';
import 'login.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});
  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late ThemeMode _currentMode;
  late Color _currentSeed;

  static const Map<String, Color> _seedOptions = {
    'Red': Colors.red,
    'Purple': Colors.deepPurple,
    'Blue': Colors.blue,
    'Green': Colors.green,
    'Yellow': Colors.yellow,
  };

  @override
  void initState() {
    super.initState();
    final mgr = ThemeManager.instance;
    _currentMode = mgr.mode;
    _currentSeed = mgr.seed;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          const ListTile(title: Text('Theme Mode')),
          // iterate over built‑in ThemeMode values
          for (var mode in ThemeMode.values)
            RadioListTile<ThemeMode>(
              title: Text(mode.name.capitalize()),
              value: mode,
              groupValue: _currentMode,
              onChanged: (chosen) {
                if (chosen == null) return;
                setState(() => _currentMode = chosen);
                ThemeManager.instance.updateMode(chosen);
              },
            ),

          const Divider(),
          const ListTile(title: Text('Seed Color')),
          // iterate over our seed options
          for (var entry in _seedOptions.entries)
            RadioListTile<Color>(
              title: Text(entry.key),
              value: entry.value,
              groupValue: _currentSeed,
              onChanged: (chosen) {
                if (chosen == null) return;
                setState(() => _currentSeed = chosen);
                ThemeManager.instance.updateSeed(chosen);
              },
            ),

          const Divider(),
          ElevatedButton.icon(
            icon: const Icon(Icons.logout),
            label: const Text("Logout"),
            onPressed: () => signOut(),
          ),
        ],
      ),
    );
  }
}

// helper to capitalize radio titles
extension on String {
  String capitalize() => isEmpty ? this : this[0].toUpperCase() + substring(1);
}
