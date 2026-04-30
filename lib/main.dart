import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'dart:io';
import 'dart:convert';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const TrinityApp());
}

class TrinityApp extends StatefulWidget {
  const TrinityApp({super.key});
  @override
  State<TrinityApp> createState() => _TrinityAppState();
}

class _TrinityAppState extends State<TrinityApp> {
  ThemeMode _themeMode = ThemeMode.light;

  void _toggleTheme() {
    setState(() {
      _themeMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'The Trinity',
      themeMode: _themeMode,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1A237E), brightness: Brightness.light),
        cardTheme: CardThemeData(elevation: 5, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo, brightness: Brightness.dark),
        cardTheme: CardThemeData(elevation: 5, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
      ),
      home: SplashScreen(toggleTheme: _toggleTheme, currentMode: _themeMode),
    );
  }
}

// --- GLOBAL NAVIGATION HELPER ---
Widget getRoleDashboard(String role, VoidCallback toggle, ThemeMode mode) {
  if (role == 'Shopkeeper') return ShopDashboard(toggleTheme: toggle, currentMode: mode);
  if (role == 'Professional') return ProDashboard(toggleTheme: toggle, currentMode: mode);
  return CustomerDashboard(toggleTheme: toggle, currentMode: mode);
}

// --- SPLASH SCREEN ---
class SplashScreen extends StatefulWidget {
  final VoidCallback toggleTheme;
  final ThemeMode currentMode;
  const SplashScreen({super.key, required this.toggleTheme, required this.currentMode});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  _checkAuth() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? role = prefs.getString('userRole');
    await Future.delayed(const Duration(seconds: 3));
    if (!mounted) return;

    if (role != null) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (c) => getRoleDashboard(role, widget.toggleTheme, widget.currentMode)));
    } else {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (c) => RoleSelectionPage(toggleTheme: widget.toggleTheme)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("THE TRINITY", style: TextStyle(fontSize: 45, fontWeight: FontWeight.w900, color: Color(0xFF1A237E), letterSpacing: 4)),
            SizedBox(height: 10),
            Text("POWERED BY ABHIMANIU", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}

// --- ROLE SELECTION ---
class RoleSelectionPage extends StatelessWidget {
  final VoidCallback toggleTheme;
  const RoleSelectionPage({super.key, required this.toggleTheme});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(colors: [Color(0xFF1A237E), Color(0xFF3949AB)], begin: Alignment.topCenter),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("Select Identity", style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
            const SizedBox(height: 50),
            _roleBtn(context, "Shopkeeper", Icons.storefront),
            _roleBtn(context, "Customer", Icons.person_search),
            _roleBtn(context, "Professional", Icons.engineering),
          ],
        ),
      ),
    );
  }

  Widget _roleBtn(context, String role, IconData icon) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 10),
    child: Card(
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFF1A237E)),
        title: Text(role, style: const TextStyle(fontWeight: FontWeight.bold)),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => LoginPage(role: role, toggleTheme: toggleTheme))),
      ),
    ),
  );
}

// --- LOGIN PAGE ---
class LoginPage extends StatelessWidget {
  final String role;
  final VoidCallback toggleTheme;
  LoginPage({super.key, required this.role, required this.toggleTheme});
  final _otp = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("$role Login")),
      body: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(children: [
          TextField(controller: _otp, decoration: const InputDecoration(labelText: "OTP (123456)", border: OutlineInputBorder())),
          const SizedBox(height: 30),
          ElevatedButton(
            style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 55)),
            onPressed: () async {
              if (_otp.text == "123456") {
                SharedPreferences prefs = await SharedPreferences.getInstance();
                await prefs.setString('userRole', role);
                if (context.mounted) {
                  Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (c) => SplashScreen(toggleTheme: toggleTheme, currentMode: ThemeMode.light)), (r) => false);
                }
              }
            },
            child: const Text("AUTHENTICATE"),
          )
        ]),
      ),
    );
  }
}

// --- DASHBOARDS (Stubs with logic fixed) ---
class ShopDashboard extends StatelessWidget {
  final VoidCallback toggleTheme;
  final ThemeMode currentMode;
  const ShopDashboard({super.key, required this.toggleTheme, required this.currentMode});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Shop Dashboard"), actions: [
        IconButton(icon: Icon(currentMode == ThemeMode.light ? Icons.dark_mode : Icons.light_mode), onPressed: toggleTheme),
        IconButton(icon: const Icon(Icons.logout), onPressed: () async {
          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.remove('userRole');
          Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (c) => RoleSelectionPage(toggleTheme: toggleTheme)), (r) => false);
        }),
      ]),
      body: const Center(child: Text("Welcome Shopkeeper")),
    );
  }
}

class CustomerDashboard extends StatelessWidget {
  final VoidCallback toggleTheme;
  final ThemeMode currentMode;
  const CustomerDashboard({super.key, required this.toggleTheme, required this.currentMode});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Customer Market"), actions: [
        IconButton(icon: Icon(currentMode == ThemeMode.light ? Icons.dark_mode : Icons.light_mode), onPressed: toggleTheme),
        IconButton(icon: const Icon(Icons.logout), onPressed: () async {
          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.remove('userRole');
          Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (c) => RoleSelectionPage(toggleTheme: toggleTheme)), (r) => false);
        }),
      ]),
      body: const Center(child: Text("Welcome Customer")),
    );
  }
}

class ProDashboard extends StatelessWidget {
  final VoidCallback toggleTheme;
  final ThemeMode currentMode;
  const ProDashboard({super.key, required this.toggleTheme, required this.currentMode});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Partner Panel"), actions: [
        IconButton(icon: Icon(currentMode == ThemeMode.light ? Icons.dark_mode : Icons.light_mode), onPressed: toggleTheme),
        IconButton(icon: const Icon(Icons.logout), onPressed: () async {
          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.remove('userRole');
          Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (c) => RoleSelectionPage(toggleTheme: toggleTheme)), (r) => false);
        }),
      ]),
      body: const Center(child: Text("Welcome Partner")),
    );
  }
}
