import 'package:flutter/material.dart';
import 'screens/app_shell.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const TouristGuideApp());
}

class TouristGuideApp extends StatelessWidget {
  const TouristGuideApp({super.key});

  @override
  Widget build(BuildContext context) {
    const seed = Color(0xFF087E8B);
    return MaterialApp(
      title: 'Bohol Explorer | Tourist Information and Travel Guide',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: seed,
          brightness: Brightness.light,
          surface: const Color(0xFFFCFDFD),
        ),
        scaffoldBackgroundColor: const Color(0xFFF6F8F8),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFFCFDFD),
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          centerTitle: false,
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: const BorderSide(color: Color(0xFFE8EEEE)),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFF1F5F5),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: seed, width: 1.5),
          ),
        ),
      ),
      home: const AppShell(),
    );
  }
}
