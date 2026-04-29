import 'package:flutter/material.dart';

void main() {
  runApp(const TrinityApp());
}

class TrinityApp extends StatelessWidget {
  const TrinityApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0F0F0F), // Deep Black
        primaryColor: Colors.redAccent,
      ),
      home: const Dashboard(),
    );
  }
}

class Dashboard extends StatelessWidget {
  const Dashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with Logo
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Image.asset('assets/icon.png', width: 50, height: 50),
                  const Icon(Icons.notifications_none, color: Colors.white),
                ],
              ),
              const SizedBox(height: 30),
              const Text(
                "Welcome to THE TRINITY",
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, letterSpacing: 1),
              ),
              const Text(
                "Premium Services Active",
                style: TextStyle(color: Colors.redAccent, fontSize: 14),
              ),
              const SizedBox(height: 40),
              
              // Functional Cards
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 15,
                  mainAxisSpacing: 15,
                  children: [
                    _buildMenuCard("Gaming VPN", Icons.security, Colors.blue),
                    _buildMenuCard("Boost Performance", Icons.speed, Colors.orange),
                    _buildMenuCard("Premium Files", Icons.folder_special, Colors.purple),
                    _buildMenuCard("User Profile", Icons.person, Colors.redAccent),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuCard(String title, IconData icon, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 40, color: color),
          const SizedBox(height: 10),
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
