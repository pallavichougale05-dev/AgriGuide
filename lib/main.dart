import 'package:flutter/material.dart';
import 'l10n/app_localizations.dart';
import 'screens/home_screen.dart';

void main() {
  // WHAT: Starts the Flutter application.
  // WHY: Every Flutter app needs an entry point.
  // HOW: runApp() places AgriGuideApp at the root of the widget tree.
  runApp(const AgriGuideApp());
}


// WHAT: Root widget of the AgriGuide application.
// WHY: It manages app-wide settings such as language and theme.
// HOW: StatefulWidget lets us rebuild the app when the language changes.
class AgriGuideApp extends StatefulWidget {
  const AgriGuideApp({super.key});

  @override
  State<AgriGuideApp> createState() => _AgriGuideAppState();
}


// WHAT: Stores the changing state of AgriGuideApp.
class _AgriGuideAppState extends State<AgriGuideApp> {

  // Stores the currently selected application language.
  // English is the default language when the app starts.
  Locale _locale = const Locale('en');


  // WHAT: Changes the application language.
  // WHY: The language selector in HomeScreen calls this method.
  // HOW: setState() tells Flutter to rebuild MaterialApp
  // with the newly selected Locale.
  void changeLanguage(Locale locale) {
    setState(() {
      _locale = locale;
    });
  }


  @override
  Widget build(BuildContext context) {

    // WHAT: MaterialApp is the main application container.
    // WHY: It provides navigation, localization, themes,
    // and many standard Material Design features.
    return MaterialApp(
      // Removes the DEBUG banner from the top-right corner.
      debugShowCheckedModeBanner: false,

      // Name of the application.
      title: 'AgriGuide',

      // WHAT: Sets the currently active language.
      // WHY: Flutter uses this Locale to select the matching
      // localization resource.
      locale: _locale,


      // WHAT: Registers Flutter's generated localization delegates.
      // WHY: These delegates load translated strings from
      // the English and Marathi ARB files.
      localizationsDelegates:
          AppLocalizations.localizationsDelegates,


      // WHAT: Tells Flutter which languages the app supports.
      // WHY: The application currently supports English and Marathi.
      supportedLocales:
          AppLocalizations.supportedLocales,


      // WHAT: Defines the first screen shown when the app starts.
      // WHY: HomeScreen is the main entry point of AgriGuide.
      home: HomeScreen(
        // Passes the language-changing function to HomeScreen.
        onLanguageChanged: changeLanguage,
      ),
    );
  }
}