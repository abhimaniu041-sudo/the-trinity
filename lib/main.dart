import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'utils/constants.dart';

void main() {
  runApp(const TheTrinityApp());
}

class TheTrinityApp extends StatelessWidget {
  const TheTrinityApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'The Trinity',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0F0F0F), // Deep Black
        primaryColor: const Color(0xFFFF0000), // Pure Red
        textTheme: GoogleFonts.orbitronTextTheme(Theme.of(context).textTheme).apply(
          bodyColor: Colors.white,
          displayColor: Colors.white,
        ),
      ),
      home: const SplashScreen(),
    );
  }
}

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1A0000), Color(0xFF000000)],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Yahan aap apna logo laga sakte hain
              const Icon(Icons.shield_rounded, size: 100, color: Color(0xFFFF0000)),
              const SizedBox(height: 20),
              Text(
                'THE TRINITY',
                style: GoogleFonts.orbitron(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 4,
                  color: const Color(0xFFFF0000),
                ),
              ),
              const SizedBox(height: 10),
              const Text('Premium Gaming Services', style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }
}
