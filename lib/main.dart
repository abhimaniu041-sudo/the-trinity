import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
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
  ThemeMode _themeMode = ThemeMode.dark;
  final String apiBase = "https://the-trinity.onrender.com/api";

  void _toggleTheme() {
    setState(() {
      _themeMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      themeMode: _themeMode,
      theme: ThemeData(useMaterial3: true, colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo)),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0D0D1A),
        cardTheme: CardThemeData(
          color: const Color(0xFF1A1A2E),
          elevation: 10,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: Colors.amberAccent, width: 0.1)),
        ),
      ),
      home: SplashScreen(toggleTheme: _toggleTheme, mode: _themeMode, apiBase: apiBase),
    );
  }
}

// --- SHARED HEADER ---
class DashboardHeader extends StatelessWidget implements PreferredSizeWidget {
  final String title, role;
  final VoidCallback onTheme, onProfile;
  final ThemeMode mode;

  const DashboardHeader({super.key, required this.title, required this.onTheme, required this.onProfile, required this.mode, required this.role});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.amberAccent, letterSpacing: 1.5)),
      actions: [
        IconButton(icon: const Icon(Icons.account_circle_outlined, color: Colors.amberAccent), onPressed: onProfile),
        IconButton(icon: const Icon(Icons.settings_outlined), onPressed: () => _openSettings(context)),
      ],
    );
  }

  void _openSettings(context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A2E),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
      builder: (c) => Column(mainAxisSize: MainAxisSize.min, children: [
        const SizedBox(height: 20),
        ListTile(
          leading: Icon(mode == ThemeMode.light ? Icons.dark_mode : Icons.light_mode, color: Colors.amberAccent),
          title: Text(mode == ThemeMode.light ? "Switch to Dark" : "Switch to Light", style: const TextStyle(color: Colors.white)),
          onTap: () { Navigator.pop(context); onTheme(); },
        ),
        ListTile(
          leading: const Icon(Icons.logout, color: Colors.redAccent),
          title: const Text("Logout", style: TextStyle(color: Colors.white)),
          onTap: () async {
            SharedPreferences prefs = await SharedPreferences.getInstance();
            await prefs.clear();
            Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (c) => RoleSelectionPage(toggleTheme: onTheme, apiBase: "https://the-trinity.onrender.com/api")), (r) => false);
          },
        ),
        const SizedBox(height: 20),
      ]),
    );
  }
  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

// --- SPLASH SCREEN ---
class SplashScreen extends StatefulWidget {
  final VoidCallback toggleTheme;
  final ThemeMode mode;
  final String apiBase;
  const SplashScreen({super.key, required this.toggleTheme, required this.mode, required this.apiBase});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() { super.initState(); _init(); }
  _init() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? role = prefs.getString('userRole');
    await Future.delayed(const Duration(seconds: 3));
    if (!mounted) return;
    if (role != null) {
      if (role == 'Shopkeeper') Navigator.pushReplacement(context, MaterialPageRoute(builder: (c) => ShopDashboard(toggleTheme: widget.toggleTheme, mode: widget.mode)));
      else if (role == 'Professional') Navigator.pushReplacement(context, MaterialPageRoute(builder: (c) => ProfessionalDashboard(toggleTheme: widget.toggleTheme, mode: widget.mode)));
      else Navigator.pushReplacement(context, MaterialPageRoute(builder: (c) => CustomerDashboard(toggleTheme: widget.toggleTheme, mode: widget.mode)));
    } else {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (c) => RoleSelectionPage(toggleTheme: widget.toggleTheme, apiBase: widget.apiBase)));
    }
  }
  @override
  Widget build(BuildContext context) => const Scaffold(body: Center(child: Text("THE TRINITY", style: TextStyle(fontSize: 45, fontWeight: FontWeight.w900, color: Colors.amberAccent, letterSpacing: 5))));
}

// --- 1. PARTNER PANEL (FIXED & FULL) ---
class ProfessionalDashboard extends StatefulWidget {
  final VoidCallback toggleTheme;
  final ThemeMode mode;
  const ProfessionalDashboard({super.key, required this.toggleTheme, required this.mode});
  @override
  State<ProfessionalDashboard> createState() => _ProfessionalDashboardState();
}

class _ProfessionalDashboardState extends State<ProfessionalDashboard> {
  bool online = false;
  String name = "Expert";
  File? img;

  @override
  void initState() { super.initState(); _load(); }
  _load() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      name = prefs.getString('pro_name') ?? "Set Profile";
      online = prefs.getBool('pro_status') ?? false;
      String? p = prefs.getString('pro_img'); if (p != null) img = File(p);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: DashboardHeader(title: "PARTNER PANEL", onTheme: widget.toggleTheme, mode: widget.mode, role: 'pro', onProfile: _editProfile),
      body: Column(children: [
        Container(
          margin: const EdgeInsets.all(20), padding: const EdgeInsets.all(25),
          decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF1A237E), Color(0xFF0D0D1A)]), borderRadius: BorderRadius.circular(30), border: Border.all(color: Colors.amberAccent.withOpacity(0.5))),
          child: Column(children: [
            CircleAvatar(radius: 50, backgroundImage: img != null ? FileImage(img!) : null, child: img == null ? const Icon(Icons.person, size: 50) : null),
            const SizedBox(height: 10),
            Text(name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
            const Text("TRINITY VERIFIED EXPERT", style: TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.bold, fontSize: 12)),
          ]),
        ),
        SwitchListTile(
          title: Text(online ? "YOU ARE ONLINE" : "OFFLINE", style: TextStyle(color: online ? Colors.green : Colors.red, fontWeight: FontWeight.bold)),
          value: online, activeColor: Colors.green,
          onChanged: (v) async {
            SharedPreferences prefs = await SharedPreferences.getInstance();
            await prefs.setBool('pro_status', v);
            setState(() { online = v; });
          },
        ),
        const Padding(padding: EdgeInsets.all(20), child: TextField(decoration: InputDecoration(labelText: "Enter Completion OTP", border: OutlineInputBorder()))),
      ]),
    );
  }
  void _editProfile() async { bool? res = await showModalBottomSheet(context: context, isScrollControlled: true, builder: (c) => const ProfileSheet(role: 'pro')); if(res == true) _load(); }
}

// --- 2. CUSTOMER DASHBOARD (AMAZON STYLE) ---
class CustomerDashboard extends StatefulWidget {
  final VoidCallback toggleTheme;
  final ThemeMode mode;
  const CustomerDashboard({super.key, required this.toggleTheme, required this.mode});
  @override
  State<CustomerDashboard> createState() => _CustomerDashboardState();
}

class _CustomerDashboardState extends State<CustomerDashboard> with SingleTickerProviderStateMixin {
  late TabController _tab;
  List products = [];

  @override
  void initState() { super.initState(); _tab = TabController(length: 2, vsync: this); _load(); }
  _load() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? data = prefs.getString('global_products');
    if (data != null) setState(() { products = json.decode(data); });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: DashboardHeader(title: "TRINITY MARKET", onTheme: widget.toggleTheme, mode: widget.mode, role: 'cust', onProfile: _editProfile),
      body: Column(children: [
        TabBar(controller: _tab, indicatorColor: Colors.amberAccent, labelColor: Colors.amberAccent, tabs: const [Tab(text: "PRODUCTS"), Tab(text: "EXPERTS")]),
        Expanded(child: TabBarView(controller: _tab, children: [
          products.isEmpty ? const Center(child: Text("No products found")) : ListView.builder(itemCount: products.length, itemBuilder: (c, i) => Card(margin: const EdgeInsets.all(10), child: ListTile(title: Text(products[i]['name']), subtitle: Text("₹${products[i]['price']}")))),
          const Center(child: Text("No Experts Online")),
        ])),
      ]),
    );
  }
  void _editProfile() => showModalBottomSheet(context: context, isScrollControlled: true, builder: (c) => const ProfileSheet(role: 'cust'));
}

// --- 3. SHOPKEEPER DASHBOARD ---
class ShopDashboard extends StatefulWidget {
  final VoidCallback toggleTheme;
  final ThemeMode mode;
  const ShopDashboard({super.key, required this.toggleTheme, required this.mode});
  @override
  State<ShopDashboard> createState() => _ShopDashboardState();
}

class _ShopDashboardState extends State<ShopDashboard> {
  List products = [];
  final _n = TextEditingController(), _p = TextEditingController();

  @override
  void initState() { super.initState(); _load(); }
  _load() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? data = prefs.getString('global_products');
    if (
