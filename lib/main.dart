import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:karteikarten_manager/theme/theme.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'pages/mainPage.dart';


void main() async {

  await initializeDateFormatting('de_DE');

  runApp(const Karteikarten());
}
class Karteikarten extends StatefulWidget {
  const Karteikarten( {Key? key}) : super(key: key);
  static final ValueNotifier<ThemeMode> themeNotifier =
  ValueNotifier(ThemeMode.light);

  @override
  _KarteikartenState createState() => _KarteikartenState();
}

class _KarteikartenState extends State<Karteikarten> {
  late SharedPreferences _prefs;

  @override
  void initState() {
    super.initState();
    _loadTheme();
  }

  // Load theme preference from SharedPreferences
  _loadTheme() async {
    _prefs = await SharedPreferences.getInstance();
    bool isDarkMode = _prefs.getBool('darkMode') ?? false;
    // Update themeNotifier with the loaded theme preference
    Karteikarten.themeNotifier.value = isDarkMode ? ThemeMode.dark : ThemeMode.light;

  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: Karteikarten.themeNotifier,
      builder: (_, ThemeMode currentMode, __) {
        return MaterialApp(
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('de','DE'),
          ],
          debugShowCheckedModeBanner: false,
          theme: lightmmode,
          darkTheme: darkmmode,
          themeMode: currentMode,
          home: const MyHomePage(title: 'Karteikarten Übersicht'),
        );
      },
    );
  }
}
