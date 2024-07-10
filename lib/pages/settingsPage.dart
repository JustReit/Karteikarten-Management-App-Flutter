import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:settings_ui/settings_ui.dart';

import '../main.dart';

class SettingsPage extends StatefulWidget {
  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  // Variable to store whether dates should be filled automatically
  bool fillDatesAutomatically = true;

  // Variable to store the selected rest day
  String selectedRestDay = 'Sonntag';


  // Variable to store whether to display all cards or only today's cards
  bool displayAllCards = true;

  late SharedPreferences _prefs;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  // Load settings from SharedPreferences
  _loadSettings() async {
    _prefs = await SharedPreferences.getInstance();
    setState(() {
      fillDatesAutomatically = _prefs.getBool('fillDatesAutomatically') ?? true;
      selectedRestDay = _prefs.getString('selectedRestDay') ?? 'Sonntag';
      displayAllCards = _prefs.getBool('displayAllCards') ?? true;
      // Load dark mode preference
      Karteikarten.themeNotifier.value =
          _prefs.getBool('darkMode') == true ? ThemeMode.dark : ThemeMode.light;
    });
  }

  // Save settings to SharedPreferences
  _saveSettings() async {
    await _prefs.setBool('fillDatesAutomatically', fillDatesAutomatically);
    await _prefs.setString('selectedRestDay', selectedRestDay);
    await _prefs.setBool('displayAllCards', displayAllCards);
    // Save dark mode preference
    await _prefs.setBool(
        'darkMode', Karteikarten.themeNotifier.value == ThemeMode.dark);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Einstellungen'),
      ),
      body: SettingsList(
        sections: [
          SettingsSection(
            title: const Text('Design'),
            tiles: [
              SettingsTile.switchTile(
                title: Text(Karteikarten.themeNotifier.value == ThemeMode.light ? 'Hellmodus' : 'Dunkelmodus'),
                leading: Karteikarten.themeNotifier.value == ThemeMode.light
                    ? const Icon(Icons.light_mode)
                    : const Icon(Icons.dark_mode),
                onToggle: (value) {
                  Karteikarten.themeNotifier.value =
                      value ? ThemeMode.dark : ThemeMode.light;
                  _saveSettings(); // Save dark mode preference when changed
                },
                initialValue:
                    Karteikarten.themeNotifier.value == ThemeMode.dark,
              ),
            ],
          ),
          SettingsSection(
            title: const Text('Allgemein'),
            tiles: [
              SettingsTile.switchTile(
                title: const Text('Automatisch Datum ausfüllen'),
                leading: const Icon(Icons.date_range),
                onToggle: (value) {
                  setState(() {
                    fillDatesAutomatically = value;
                    _saveSettings(); // Save selected rest day
                  });
                },
                initialValue: fillDatesAutomatically,
              ),
              SettingsTile(
                title:  Text('Ruhetag: $selectedRestDay'),
                leading: const Icon(Icons.calendar_today),
                onPressed: (BuildContext context) {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: const Text('Ruhetag wählen'),
                        content: DropdownButton<String>(
                          value: selectedRestDay,
                          onChanged: (newValue) {
                            setState(() {
                              selectedRestDay = newValue!;
                              _saveSettings(); // Save selected rest day
                              Navigator.of(context).pop();
                            });

                          },

                          items: <String>[
                            'Sonntag',
                            'Montag',
                            'Dienstag',
                            'Mittwoch',
                            'Donnerstag',
                            'Freitag',
                            'Samstag'
                          ].map<DropdownMenuItem<String>>((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();

                            },
                            child: const Text('OK'),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
              SettingsTile.switchTile(
                title:  Text(displayAllCards ? 'Alle Karten anzeigen' :'Karten nur von heute anzeigen' ),
                leading: const Icon(Icons.view_list),
                onToggle: (value) {
                  setState(() {
                    displayAllCards = value;
                  });
                  _saveSettings();
                },
                initialValue: displayAllCards,
              ),
            ],
          ),
        ],
      ),
    );
  }

}
