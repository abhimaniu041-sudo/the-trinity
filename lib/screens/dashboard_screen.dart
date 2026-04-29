import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('TRI-VERSE', style: GoogleFonts.orbitron(letterSpacing: 2)),
        backgroundColor: Colors.black,
        actions: [IconButton(icon: const Icon(Icons.notifications_none, color: Colors.red), onPressed: () {})],
      ),
      body: Container(
        color: const Color(0xFF0F0F0F),
        child: GridView.count(
          padding: const EdgeInsets.all(20),
          crossAxisCount: 2,
          crossAxisSpacing: 15,
          mainAxisSpacing: 15,
          children: [
            _buildMenuCard('PREMIUM FILES', Icons.file_download, Colors.red),
            _buildMenuCard('USER STATS', Icons.analytics, Colors.blue),
            _buildMenuCard('SECURITY', Icons.security, Colors.green),
            _buildMenuCard('SETTINGS', Icons.settings, Colors.orange),
          ],
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
          Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
        ],
      ),
    );
  }
}
