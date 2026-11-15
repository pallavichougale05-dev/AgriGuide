import 'package:flutter/material.dart';
import 'l10n/app_localizations.dart';
import 'screens/home_screen.dart';

void main() {
  // Starts the Flutter application.
  // runApp() places AgriGuideApp at the root of the widget tree.
  runApp(const AgriGuideApp());
}


// Root widget of the AgriGuide application.
// It manages app-wide settings such as language and theme.
// StatefulWidget lets us rebuild the app when the language changes.
class AgriGuideApp extends StatefulWidget {
  const AgriGuideApp({super.key});

  @override
  State<AgriGuideApp> createState() => _AgriGuideAppState();
}


// Stores the changing state of AgriGuideApp.
class _AgriGuideAppState extends State<AgriGuideApp> {

  // Stores the currently selected application language.
  // English is the default language when the app starts.
  Locale _locale = const Locale('en');


  // Changes the application language.
  // The language selector in HomeScreen calls this method.
  // setState() tells Flutter to rebuild MaterialApp with the newly selected Locale.
  void changeLanguage(Locale locale) {
    setState(() {
      _locale = locale;
    });
  }


  @override
  Widget build(BuildContext context) {

    // MaterialApp is the main application container.
    // It provides navigation, localization, themes, and many standard Material Design features.
    return MaterialApp(
      // Removes the DEBUG banner from the top-right corner.
      debugShowCheckedModeBanner: false,

      // Name of the application.
      title: 'AgriGuide',

      // Sets the currently active language.
      // Flutter uses this Locale to select the matching localization resource.
      locale: _locale,


      // Registers Flutter's generated localization delegates.
      // These delegates load translated strings from the English and Marathi ARB files.
      localizationsDelegates:
          AppLocalizations.localizationsDelegates,


      // Tells Flutter which languages the app supports.
      //The application currently supports English and Marathi.
      supportedLocales:
          AppLocalizations.supportedLocales,


      // Defines the first screen shown when the app starts.
      // HomeScreen is the main entry point of AgriGuide.
      home: HomeScreen(
        // Passes the language-changing function to HomeScreen.
        onLanguageChanged: changeLanguage,
      ),
    );
  }
}