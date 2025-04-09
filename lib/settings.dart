// lib/settings.dart

import 'package:flutter/material.dart';
import 'theme_config.dart';

class SettingsPage extends StatefulWidget {
  final AppThemeMode currentThemeMode;
  final Color currentSeedColor;
  final Function(AppThemeMode) onThemeModeChanged;
  final Function(Color) onSeedColorChanged;

  const SettingsPage({
    Key? key,
    required this.currentThemeMode,
    required this.currentSeedColor,
    required this.onThemeModeChanged,
    required this.onSeedColorChanged,
  }) : super(key: key);

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late AppThemeMode _selectedThemeMode;
  late Color _selectedSeedColor;

  final List<Map<String, dynamic>> _seedColorOptions = [
    {'name': 'Red', 'color': Colors.red},
    {'name': 'Purple', 'color': Colors.deepPurple},
    {'name': 'Blue', 'color': Colors.blue},
    {'name': 'Green', 'color': Colors.green},
  ];

  @override
  void initState() {
    super.initState();
    _selectedThemeMode = widget.currentThemeMode;
    _selectedSeedColor = widget.currentSeedColor;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          const ListTile(title: Text('Theme Mode')),
          RadioListTile<AppThemeMode>(
            title: const Text('System'),
            value: AppThemeMode.system,
            groupValue: _selectedThemeMode,
            onChanged: (value) {
              setState(() {
                _selectedThemeMode = value!;
              });
              widget.onThemeModeChanged(value!);
            },
          ),
          RadioListTile<AppThemeMode>(
            title: const Text('Light'),
            value: AppThemeMode.light,
            groupValue: _selectedThemeMode,
            onChanged: (value) {
              setState(() {
                _selectedThemeMode = value!;
              });
              widget.onThemeModeChanged(value!);
            },
          ),
          RadioListTile<AppThemeMode>(
            title: const Text('Dark'),
            value: AppThemeMode.dark,
            groupValue: _selectedThemeMode,
            onChanged: (value) {
              setState(() {
                _selectedThemeMode = value!;
              });
              widget.onThemeModeChanged(value!);
            },
          ),
          const Divider(),
          const ListTile(title: Text('Seed Color')),
          ..._seedColorOptions.map((option) {
            return RadioListTile<Color>(
              title: Text(option['name']),
              value: option['color'],
              groupValue: _selectedSeedColor,
              onChanged: (color) {
                setState(() {
                  _selectedSeedColor = color!;
                });
                widget.onSeedColorChanged(color!);
              },
            );
          }),
        ],
      ),
    );
  }
}
