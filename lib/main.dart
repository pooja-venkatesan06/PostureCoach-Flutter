// PostureCoach Flutter App - Entry Point
// Connects to ESP32 PostureCoach device via BLE and displays real-time posture data

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/posture_provider.dart';
import 'screens/scan_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const PostureCoachApp());
}

class PostureCoachApp extends StatelessWidget {
  const PostureCoachApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      // Provide PostureProvider to the entire widget tree
      create: (_) => PostureProvider(),
      child: MaterialApp(
        title: 'PostureCoach',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF1565C0), // Blue seed for BLE theme
            brightness: Brightness.light,
          ),
          useMaterial3: true,
          // Large readable text theme
          textTheme: const TextTheme(
            displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            displayMedium: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            bodyLarge: TextStyle(fontSize: 18),
            bodyMedium: TextStyle(fontSize: 16),
          ),
          appBarTheme: const AppBarTheme(
            centerTitle: true,
            elevation: 0,
          ),
        ),
        home: const ScanScreen(),
      ),
    );
  }
}
