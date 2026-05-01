import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http; // Naya: Backend connectivity ke liye
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
  final String serverUrl = "https://the-trinity.onrender.com"; // Aapka Render URL

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
      theme: ThemeData(useMaterial3: true, colorScheme: ColorScheme.fromSeed(seedColor: Colors.amber)),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0D0D1A),
        cardTheme: CardThemeData(color: const Color(0xFF1A1A2E), elevation: 10, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
      ),
      home: SplashScreen(toggleTheme: _toggleTheme, mode: _themeMode),
    );
  }
}

// --- HEADER ---
class DashboardHeader extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final VoidCallback onTheme, onProfile;
  final ThemeMode mode;

  const DashboardHeader({super.key, required this.title, required this.onTheme, required this.onProfile, required this.mode});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.amberAccent)),
      actions: [
        IconButton(icon: const Icon(Icons.account_circle, color: Colors.amberAccent), onPressed: onProfile),
        IconButton(icon: const Icon(Icons.settings), onPressed: () => _showSettings(context)),
      ],
    );
  }

  void _showSettings(context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A2E),
      builder: (c) => Column(mainAxisSize: MainAxisSize.min, children: [
        ListTile(
          leading: Icon(mode == ThemeMode.light ? Icons.dark_mode : Icons.light_mode, color: Colors.amberAccent),
          title: Text(mode == ThemeMode.light ? "Switch to Dark" : "Switch to Light"),
          onTap: () { Navigator.pop(context); onTheme(); },
        ),
        ListTile(
          leading: const Icon(Icons.logout, color: Colors.redAccent),
          title: const Text("Logout"),
          onTap: () async {
            SharedPreferences prefs = await SharedPreferences.getInstance();
            await prefs.remove('userRole');
            Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (c) => RoleSelectionPage(toggleTheme: onTheme)), (r) => false);
          },
        ),
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
  const SplashScreen({super.key, required this.toggleTheme, required this.mode});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() { super.initState(); _init(); }
  _init() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? role = prefs.getString('userRole');
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    if (role != null) {
      if (role == 'Shopkeeper') Navigator.pushReplacement(context, MaterialPageRoute(builder: (c) => ShopDashboard(toggleTheme: widget.toggleTheme, mode: widget.mode)));
      else if (role == 'Professional') Navigator.pushReplacement(context, MaterialPageRoute(builder: (c) => ProfessionalDashboard(toggleTheme: widget.toggleTheme, mode: widget.mode)));
      else Navigator.pushReplacement(context, MaterialPageRoute(builder: (c) => CustomerDashboard(toggleTheme: widget.toggleTheme, mode: widget.mode)));
    } else {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (c) => RoleSelectionPage(toggleTheme: widget.toggleTheme)));
    }
  }
  @override
  Widget build(BuildContext context) => const Scaffold(body: Center(child: Text("THE TRINITY", style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.amberAccent))));
}

// --- CUSTOMER DASHBOARD (FIXED) ---
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
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _loadLocal();
  }

  _loadLocal() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? data = prefs.getString('global_products');
    if (data != null) setState(() => products = json.decode(data));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: DashboardHeader(title: "TRINITY MARKET", onTheme: widget.toggleTheme, mode: widget.mode, onProfile: () => _editProfile(context)),
      body: Column(children: [
        TabBar(controller: _tab, indicatorColor: Colors.amberAccent, labelColor: Colors.amberAccent, tabs: const [Tab(text: "PRODUCTS"), Tab(text: "EXPERTS")]),
        Expanded(
          child: TabBarView(controller: _tab, children: [
            products.isEmpty ? const Center(child: Text("No items available")) : ListView.builder(itemCount: products.length, itemBuilder: (c, i) => Card(margin: const EdgeInsets.all(10), child: ListTile(title: Text(products[i]['name']), subtitle: Text("₹${products[i]['price']}")))),
            const Center(child: Text("Experts coming soon from Backend...")),
          ]),
        )
      ]),
    );
  }

  void _editProfile(context) => showModalBottomSheet(context: context, isScrollControlled: true, builder: (c) => const ProfileSheet(role: 'cust'));
}

// --- SHOPKEEPER DASHBOARD ---
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
    if (data != null) setState(() => products = json.decode(data));
  }

  _save() async {
    products.add({'name': _n.text, 'price': _p.text});
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('global_products', json.encode(products));
    _n.clear(); _p.clear(); _load();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: DashboardHeader(title: "SHOP CONSOLE", onTheme: widget.toggleTheme, mode: widget.mode, onProfile: () => _editProfile(context)),
    body: Column(children: [
      Padding(padding: const EdgeInsets.all(20), child: Column(children: [
        TextField(controller: _n, decoration: const InputDecoration(labelText: "Product Name")),
        TextField(controller: _p, decoration: const InputDecoration(labelText: "Price")),
        ElevatedButton(onPressed: _save, child: const Text("List Product")),
      ])),
      Expanded(child: ListView.builder(itemCount: products.length, itemBuilder: (c, i) => ListTile(title: Text(products[i]['name']))))
    ]),
  );
  void _editProfile(context) => showModalBottomSheet(context: context, isScrollControlled: true, builder: (c) => const ProfileSheet(role: 'shop'));
}

// --- PROFESSIONAL DASHBOARD (FIXED STATUS) ---
class ProfessionalDashboard extends StatefulWidget {
  final VoidCallback toggleTheme;
  final ThemeMode mode;
  const ProfessionalDashboard({super.key, required this.toggleTheme, required this.mode});
  @override
  State<ProfessionalDashboard> createState() => _ProfessionalDashboardState();
}

class _ProfessionalDashboardState extends State<ProfessionalDashboard> {
  bool online = false;

  @override
  void initState() { super.initState(); _loadStatus(); }
  _load() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() { online = prefs.getBool('pro_status') ?? false; });
  }

  _loadStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() { online = prefs.getBool('pro_status') ?? false; });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: DashboardHeader(title: "PARTNER PANEL", onTheme: widget.toggleTheme, mode: widget.mode, onProfile: () => _editProfile(context)),
    body: Column(children: [
      SwitchListTile(
        title: Text(online ? "YOU ARE ONLINE" : "OFFLINE", style: TextStyle(color: online ? Colors.green : Colors.red, fontWeight: FontWeight.bold)),
        value: online,
        activeColor: Colors.green,
        onChanged: (v) async {
          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setBool('pro_status', v);
          setState(() { online = v; });
        },
      ),
    ]),
  );
  void _editProfile(context) => showModalBottomSheet(context: context, isScrollControlled: true, builder: (c) => const ProfileSheet(role: 'pro'));
}

// --- SHARED PROFILE SHEET ---
class ProfileSheet extends StatelessWidget {
  final String role;
  const ProfileSheet({super.key, required this.role});
  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.all(30), child: Column(mainAxisSize: MainAxisSize.min, children: [
    const Text("Edit Profile", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
    const TextField(decoration: InputDecoration(labelText: "Full Name")),
    ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text("Save"))
  ]));
}

// --- ROLE SELECTION ---
class RoleSelectionPage extends StatelessWidget {
  final VoidCallback toggleTheme;
  const RoleSelectionPage({super.key, required this.toggleTheme});
  @override
  Widget build(BuildContext context) => Scaffold(body: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
    ElevatedButton(onPressed: () => _login(context, 'Shopkeeper'), child: const Text("Shopkeeper")),
    ElevatedButton(onPressed: () => _login(context, 'Customer'), child: const Text("Customer")),
    ElevatedButton(onPressed: () => _login(context, 'Professional'), child: const Text("Professional")),
  ])));
  _login(context, role) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('userRole', role);
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (c) => SplashScreen(toggleTheme: toggleTheme, mode: ThemeMode.dark)));
  }
}
