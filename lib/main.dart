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
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1A237E), brightness: Brightness.light),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.amberAccent, brightness: Brightness.dark),
        scaffoldBackgroundColor: const Color(0xFF0D0D1A),
        // FIXED: Correct CardThemeData implementation
        cardTheme: CardThemeData(
          color: const Color(0xFF1A1A2E),
          elevation: 10,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: Colors.amberAccent, width: 0.1)),
        ),
      ),
      home: SplashScreen(toggleTheme: _toggleTheme, mode: _themeMode),
    );
  }
}

// --- FIXED DASHBOARD HEADER ---
class DashboardHeader extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final VoidCallback onTheme, onProfile;
  final ThemeMode mode;
  final String role; // Role parameter added

  const DashboardHeader({
    super.key, 
    required this.title, 
    required this.onTheme, 
    required this.onProfile, 
    required this.mode,
    required this.role, // Added to constructor
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.amberAccent)),
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
          title: Text(mode == ThemeMode.light ? "Activate Dark Mode" : "Activate Light Mode", style: const TextStyle(color: Colors.white)),
          onTap: () { Navigator.pop(context); onTheme(); },
        ),
        ListTile(
          leading: const Icon(Icons.logout, color: Colors.redAccent),
          title: const Text("Logout", style: TextStyle(color: Colors.white)),
          onTap: () async {
            SharedPreferences prefs = await SharedPreferences.getInstance();
            await prefs.clear();
            Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (c) => RoleSelectionPage(toggleTheme: onTheme)), (r) => false);
          },
        ),
        const SizedBox(height: 30),
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
    await Future.delayed(const Duration(seconds: 3));
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
  Widget build(BuildContext context) => const Scaffold(body: Center(child: Text("THE TRINITY", style: TextStyle(fontSize: 45, fontWeight: FontWeight.w900, color: Colors.amberAccent, letterSpacing: 5))));
}

// --- CUSTOMER DASHBOARD ---
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
    _load();
  }

  _load() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? data = prefs.getString('global_products');
    if (data != null) setState(() => products = json.decode(data));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: DashboardHeader(title: "MARKET", onTheme: widget.toggleTheme, mode: widget.mode, onProfile: (){}, role: 'cust'),
      body: Column(children: [
        TabBar(controller: _tab, indicatorColor: Colors.amberAccent, labelColor: Colors.amberAccent, tabs: const [Tab(text: "PRODUCTS"), Tab(text: "EXPERTS")]),
        Expanded(
          child: TabBarView(controller: _tab, children: [
            products.isEmpty ? const Center(child: Text("No Products")) : ListView.builder(itemCount: products.length, itemBuilder: (c, i) => Card(margin: const EdgeInsets.all(10), child: ListTile(title: Text(products[i]['name']), subtitle: Text("₹${products[i]['price']}")))),
            const Center(child: Text("No Experts Online")),
          ]),
        )
      ]),
    );
  }
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

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: DashboardHeader(title: "CONSOLE", onTheme: widget.toggleTheme, mode: widget.mode, onProfile: (){}, role: 'shop'),
    body: Column(children: [
      Padding(padding: const EdgeInsets.all(20), child: Column(children: [
        TextField(controller: _n, decoration: const InputDecoration(labelText: "Item Name")),
        TextField(controller: _p, decoration: const InputDecoration(labelText: "Price")),
        ElevatedButton(onPressed: () async {
          products.add({'name': _n.text, 'price': _p.text});
          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setString('global_products', json.encode(products));
          _n.clear(); _p.clear(); _load();
        }, child: const Text("List Item")),
      ])),
      Expanded(child: ListView.builder(itemCount: products.length, itemBuilder: (c, i) => ListTile(title: Text(products[i]['name']))))
    ]),
  );
}

// --- PROFESSIONAL DASHBOARD ---
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
  void initState() { super.initState(); _load(); }
  _load() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() { online = prefs.getBool('pro_status') ?? false; });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: DashboardHeader(title: "PARTNER HUB", onTheme: widget.toggleTheme, mode: widget.mode, onProfile: (){}, role: 'pro'),
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
}

// --- ROLE SELECTION & LOGIN ---
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
