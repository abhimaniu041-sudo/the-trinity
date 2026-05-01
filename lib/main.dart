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
  // TRINITY ENDPOINT (Aapka Render URL)
  final String baseUrl = "https://the-trinity.onrender.com/api";

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
        cardTheme: CardThemeData(color: const Color(0xFF1A1A2E), elevation: 10, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: Colors.amberAccent, width: 0.2))),
      ),
      home: SplashScreen(toggleTheme: _toggleTheme, mode: _themeMode, baseUrl: baseUrl),
    );
  }
}

// --- SHARED HEADER ---
class DashboardHeader extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final VoidCallback onTheme, onProfile;
  final ThemeMode mode;

  const DashboardHeader({super.key, required this.title, required this.onTheme, required this.onProfile, required this.mode});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.amberAccent, letterSpacing: 1.2)),
      actions: [
        IconButton(icon: const Icon(Icons.account_circle, color: Colors.amberAccent), onPressed: onProfile),
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
          title: Text(mode == ThemeMode.light ? "Activate Dark Mode" : "Activate Light Mode"),
          onTap: () { Navigator.pop(context); onTheme(); },
        ),
        ListTile(
          leading: const Icon(Icons.logout, color: Colors.redAccent),
          title: const Text("Logout"),
          onTap: () async {
            SharedPreferences prefs = await SharedPreferences.getInstance();
            await prefs.clear();
            Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (c) => RoleSelectionPage(toggleTheme: onTheme, baseUrl: "https://the-trinity.onrender.com/api")), (r) => false);
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
  final String baseUrl;
  const SplashScreen({super.key, required this.toggleTheme, required this.mode, required this.baseUrl});
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
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (c) => RoleSelectionPage(toggleTheme: widget.toggleTheme, baseUrl: widget.baseUrl)));
    }
  }
  @override
  Widget build(BuildContext context) => const Scaffold(body: Center(child: Text("THE TRINITY", style: TextStyle(fontSize: 45, fontWeight: FontWeight.bold, color: Colors.amberAccent, letterSpacing: 5))));
}

// --- CUSTOMER DASHBOARD (FIXED BLANK SCREEN) ---
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
    setState(() {
      if (data != null) products = json.decode(data);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: DashboardHeader(title: "MARKET", onTheme: widget.toggleTheme, mode: widget.mode, onProfile: (){}, role: 'cust'),
      body: Column(children: [
        TabBar(controller: _tab, indicatorColor: Colors.amberAccent, tabs: const [Tab(text: "PRODUCTS"), Tab(text: "EXPERTS")]),
        Expanded(
          child: TabBarView(controller: _tab, children: [
            products.isEmpty 
              ? const Center(child: Text("No items match your search")) 
              : ListView.builder(itemCount: products.length, itemBuilder: (c, i) => Card(margin: const EdgeInsets.all(10), child: ListTile(title: Text(products[i]['name']), subtitle: Text("₹${products[i]['price']}")))),
            const Center(child: Text("No Experts Online")),
          ]),
        )
      ]),
    );
  }
}

// --- PROFESSIONAL DASHBOARD (FIXED ONLINE STATUS) ---
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

  @override
  void initState() { super.initState(); _load(); }
  _load() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      name = prefs.getString('pro_name') ?? "Set Profile";
      online = prefs.getBool('pro_status') ?? false;
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: DashboardHeader(title: "PARTNER HUB", onTheme: widget.toggleTheme, mode: widget.mode, onProfile: (){}, role: 'pro'),
    body: Column(children: [
      const SizedBox(height: 20),
      CircleAvatar(radius: 50, child: const Icon(Icons.person, size: 50)),
      Text(name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
      const SizedBox(height: 20),
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
        TextField(controller: _n, decoration: const InputDecoration(labelText: "Product Name")),
        TextField(controller: _p, decoration: const InputDecoration(labelText: "Price")),
        ElevatedButton(onPressed: () async {
          products.add({'name': _n.text, 'price': _p.text});
          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setString('global_products', json.encode(products));
          _n.clear(); _p.clear(); _load();
        }, child: const Text("List Product")),
      ])),
      Expanded(child: ListView.builder(itemCount: products.length, itemBuilder: (c, i) => ListTile(title: Text(products[i]['name']))))
    ]),
  );
}

// --- ROLE SELECTION & LOGIN ---
class RoleSelectionPage extends StatelessWidget {
  final VoidCallback toggleTheme;
  final String baseUrl;
  const RoleSelectionPage({super.key, required this.toggleTheme, required this.baseUrl});
  @override
  Widget build(BuildContext context) => Scaffold(body: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
    _btn(context, 'Shopkeeper'), _btn(context, 'Customer'), _btn(context, 'Professional'),
  ])));
  Widget _btn(context, r) => Padding(padding: const EdgeInsets.all(10), child: ElevatedButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (c) => LoginPage(role: r, toggleTheme: toggleTheme, baseUrl: baseUrl))), child: Text(r)));
}

class LoginPage extends StatefulWidget {
  final String role; final VoidCallback toggleTheme; final String baseUrl;
  const LoginPage({super.key, required this.role, required this.toggleTheme, required this.baseUrl});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _id = TextEditingController();
  
  _auth() async {
    // Backend API Call (Render)
    try {
      final res = await http.post(
        Uri.parse("${widget.baseUrl}/auth/login"),
        headers: {"Content-Type": "application/json"},
        body: json.encode({"phone": _id.text, "role": widget.role, "name": "Abhi User"}),
      );
      if (res.statusCode == 200) {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('userRole', widget.role);
        Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (c) => SplashScreen(toggleTheme: widget.toggleTheme, mode: ThemeMode.dark, baseUrl: widget.baseUrl)), (r) => false);
      }
    } catch (e) {
      print("Error connecting to Render: $e");
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: Text(widget.role)), body: Padding(padding: const EdgeInsets.all(30), child: Column(children: [
    TextField(controller: _id, decoration: const InputDecoration(labelText: "Mobile Number")),
    const SizedBox(height: 20),
    ElevatedButton(onPressed: _auth, child: const Text("LOGIN VIA BACKEND"))
  ])));
}
