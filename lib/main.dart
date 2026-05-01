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

// --- MASTER HEADER ---
class DashboardHeader extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final VoidCallback onTheme, onProfile;
  final ThemeMode mode;

  const DashboardHeader({super.key, required this.title, required this.onTheme, required this.onProfile, required this.mode});

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

  void _openSettings(BuildContext context) {
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

// --- PARTNER PANEL ---
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
      appBar: DashboardHeader(title: "PARTNER HUB", onTheme: widget.toggleTheme, onProfile: _editProfile, mode: widget.mode),
      body: Column(children: [
        Container(
          margin: const EdgeInsets.all(20), padding: const EdgeInsets.all(25),
          decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF1A237E), Color(0xFF0D0D1A)]), borderRadius: BorderRadius.circular(30), border: Border.all(color: Colors.amberAccent.withOpacity(0.5))),
          child: Column(children: [
            CircleAvatar(radius: 50, backgroundImage: img != null ? FileImage(img!) : null, child: img == null ? const Icon(Icons.person, size: 50) : null),
            const SizedBox(height: 10),
            Text(name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
            const Text("TRINITY VERIFIED EXPERT", style: TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.bold, fontSize: 10)),
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
  void initState() { super.initState(); _tab = TabController(length: 2, vsync: this); _load(); }
  _load() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? data = prefs.getString('global_products');
    if (data != null) setState(() { products = json.decode(data); });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: DashboardHeader(title: "MARKET", onTheme: widget.toggleTheme, onProfile: _editProfile, mode: widget.mode),
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
    appBar: DashboardHeader(title: "CONSOLE", onTheme: widget.toggleTheme, onProfile: _editProfile, mode: widget.mode),
    body: Column(children: [
      Padding(padding: const EdgeInsets.all(20), child: Column(children: [
        TextField(controller: _n, decoration: const InputDecoration(labelText: "Product Name")),
        TextField(controller: _p, decoration: const InputDecoration(labelText: "Price")),
        const SizedBox(height: 10),
        ElevatedButton(onPressed: () async {
          if(_n.text.isEmpty) return;
          products.add({'name': _n.text, 'price': _p.text});
          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setString('global_products', json.encode(products));
          _n.clear(); _p.clear(); _load();
        }, child: const Text("List Product")),
      ])),
      Expanded(child: ListView.builder(itemCount: products.length, itemBuilder: (c, i) => ListTile(title: Text(products[i]['name']))))
    ]),
  );
  void _editProfile() async { bool? res = await showModalBottomSheet(context: context, isScrollControlled: true, builder: (c) => const ProfileSheet(role: 'shop')); if(res == true) _load(); }
}

// --- PROFILE SHEET ---
class ProfileSheet extends StatefulWidget {
  final String role;
  const ProfileSheet({super.key, required this.role});
  @override
  State<ProfileSheet> createState() => _ProfileSheetState();
}

class _ProfileSheetState extends State<ProfileSheet> {
  final _n = TextEditingController(), _p = TextEditingController(), _a = TextEditingController(); File? _img;
  @override
  void initState() { super.initState(); _load(); }
  _load() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _n.text = prefs.getString('${widget.role}_name') ?? "";
      _p.text = prefs.getString('${widget.role}_phone') ?? "";
      _a.text = prefs.getString('${widget.role}_addr') ?? "";
      String? path = prefs.getString('${widget.role}_img'); if (path != null) _img = File(path);
    });
  }
  @override
  Widget build(BuildContext context) => Padding(padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 20, right: 20, top: 20), child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
    const Text("EDIT PROFILE", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.amberAccent)),
    const SizedBox(height: 15),
    GestureDetector(onTap: () async { final p = await ImagePicker().pickImage(source: ImageSource.gallery); if (p != null) setState(() => _img = File(p.path)); }, child: CircleAvatar(radius: 50, backgroundImage: _img != null ? FileImage(_img!) : null, child: const Icon(Icons.camera_alt))),
    TextField(controller: _n, decoration: const InputDecoration(labelText: "Full Name")),
    TextField(controller: _p, decoration: const InputDecoration(labelText: "Phone")),
    TextField(controller: _a, decoration: const InputDecoration(labelText: "Address")),
    ElevatedButton(onPressed: () async {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('${widget.role}_name', _n.text); await prefs.setString('${widget.role}_phone', _p.text); await prefs.setString('${widget.role}_addr', _a.text);
      if (_img != null) await prefs.setString('${widget.role}_img', _img!.path);
      if (mounted) Navigator.pop(context, true);
    }, child: const Text("SAVE CHANGES")),
    const SizedBox(height: 30)
  ])));
}

// --- LOGIN & ROLE SELECTION ---
class RoleSelectionPage extends StatelessWidget {
  final VoidCallback toggleTheme; final String apiBase;
  const RoleSelectionPage({super.key, required this.toggleTheme, this.apiBase = "https://the-trinity.onrender.com/api"});
  @override
  Widget build(BuildContext context) => Scaffold(body: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
    const Text("THE TRINITY", style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.amberAccent)),
    const SizedBox(height: 50),
    _btn(context, 'Shopkeeper'), _btn(context, 'Customer'), _btn(context, 'Professional'),
  ])));
  Widget _btn(context, String r) => Padding(padding: const EdgeInsets.all(10), child: ElevatedButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (c) => LoginPage(role: r, toggleTheme: toggleTheme, apiBase: apiBase))), child: Text(r)));
}

class LoginPage extends StatefulWidget {
  final String role; final VoidCallback toggleTheme; final String apiBase;
  const LoginPage({super.key, required this.role, required this.toggleTheme, required this.apiBase});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _id = TextEditingController();
  @override
  Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: Text(widget.role)), body: Padding(padding: const EdgeInsets.all(30), child: Column(children: [
    TextField(controller: _id, decoration: const InputDecoration(labelText: "Mobile or Email")),
    const SizedBox(height: 20),
    ElevatedButton(onPressed: () async {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('userRole', widget.role);
      if (mounted) Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (c) => SplashScreen(toggleTheme: widget.toggleTheme, mode: ThemeMode.dark, apiBase: widget.apiBase)), (r) => false);
    }, child: const Text("LOGIN"))
  ])));
}
