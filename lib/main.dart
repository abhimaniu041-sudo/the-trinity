import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:photo_view/photo_view.dart';
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
      themeMode: _themeMode,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1A237E), brightness: Brightness.light),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo, brightness: Brightness.dark),
      ),
      home: SplashScreen(toggleTheme: _toggleTheme, mode: _themeMode),
    );
  }
}

// --- NAVIGATION HELPER ---
Widget _getRoute(String role, VoidCallback toggle, ThemeMode mode) {
  if (role == 'Shopkeeper') return ShopDashboard(onTheme: toggle, mode: mode);
  if (role == 'Professional') return ProDashboard(onTheme: toggle, mode: mode);
  return CustomerDashboard(onTheme: toggle, mode: mode);
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
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (c) => _getRoute(role, widget.toggleTheme, widget.mode)));
    } else {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (c) => RoleSelectionPage(toggleTheme: widget.toggleTheme)));
    }
  }
  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: Text("THE TRINITY", style: TextStyle(fontSize: 40, fontWeight: FontWeight.w900, color: Color(0xFF1A237E)))));
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
        decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF1A237E), Color(0xFF3949AB)], begin: Alignment.topCenter)),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Text("Welcome to Trinity", style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
          const SizedBox(height: 40),
          _btn(context, "Shopkeeper", Icons.storefront),
          _btn(context, "Customer", Icons.person_search),
          _btn(context, "Professional", Icons.engineering),
        ]),
      ),
    );
  }
  Widget _btn(context, String r, IconData i) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 10),
    child: Card(child: ListTile(
      leading: Icon(i, color: const Color(0xFF1A237E)),
      title: Text(r, style: const TextStyle(fontWeight: FontWeight.bold)),
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => LoginPage(role: r, toggleTheme: toggleTheme))),
    )),
  );
}

// --- LOGIN PAGE ---
class LoginPage extends StatefulWidget {
  final String role;
  final VoidCallback toggleTheme;
  const LoginPage({super.key, required this.role, required this.toggleTheme});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _idC = TextEditingController();
  final _otpC = TextEditingController();
  bool otpSent = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("${widget.role} Login")),
      body: Padding(padding: const EdgeInsets.all(30), child: Column(children: [
        TextField(controller: _idC, decoration: const InputDecoration(labelText: "Email or Phone", border: OutlineInputBorder())),
        const SizedBox(height: 20),
        if (otpSent) TextField(controller: _otpC, decoration: const InputDecoration(labelText: "OTP (123456)", border: OutlineInputBorder())),
        const SizedBox(height: 30),
        ElevatedButton(
          style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 55)),
          onPressed: () async {
            if (!otpSent) { setState(() => otpSent = true); }
            else if (_otpC.text == "123456") {
              SharedPreferences prefs = await SharedPreferences.getInstance();
              await prefs.setString('userRole', widget.role);
              if (mounted) Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (c) => SplashScreen(toggleTheme: widget.toggleTheme, mode: ThemeMode.light)), (r) => false);
            }
          }, 
          child: Text(otpSent ? "AUTHENTICATE" : "GET OTP")
        )
      ])),
    );
  }
}

// --- CUSTOMER DASHBOARD ---
class CustomerDashboard extends StatefulWidget {
  final VoidCallback onTheme;
  final ThemeMode mode;
  const CustomerDashboard({super.key, required this.onTheme, required this.mode});
  @override
  State<CustomerDashboard> createState() => _CustomerDashboardState();
}

class _CustomerDashboardState extends State<CustomerDashboard> with SingleTickerProviderStateMixin {
  late TabController _tab;
  String query = "", cName = "", cAddr = "";
  List products = [];
  bool hasProfile = false;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _load();
  }

  _load() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      cName = prefs.getString('cust_name') ?? "";
      cAddr = prefs.getString('cust_addr') ?? "";
      hasProfile = cName.isNotEmpty;
      String? data = prefs.getString('shop_products');
      if (data != null) products = json.decode(data);
    });
  }

  void _openAI() {
    showModalBottomSheet(context: context, isScrollControlled: true, builder: (c) => Container(
      height: 400, padding: const EdgeInsets.all(20),
      child: Column(children: [
        const Text("Trinity AI Assistant", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const Expanded(child: Center(child: Text("Hello! How can I help you?"))),
        TextField(decoration: InputDecoration(hintText: "Ask...", suffixIcon: Icon(Icons.send)))
      ]),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Trinity Market"), actions: [
        IconButton(icon: Icon(widget.mode == ThemeMode.light ? Icons.dark_mode : Icons.light_mode), onPressed: widget.onTheme),
        IconButton(icon: const Icon(Icons.logout), onPressed: () async {
          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.remove('userRole');
          Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (c) => RoleSelectionPage(toggleTheme: widget.onTheme)), (r) => false);
        }),
      ]),
      floatingActionButton: FloatingActionButton(onPressed: _openAI, child: const Icon(Icons.auto_awesome)),
      body: !hasProfile ? _setup() : Column(children: [
        Padding(padding: const EdgeInsets.all(15), child: TextField(onChanged: (v) => setState(() => query = v), decoration: InputDecoration(hintText: "Search...", border: OutlineInputBorder(borderRadius: BorderRadius.circular(30))))),
        TabBar(controller: _tab, labelColor: Colors.indigo, tabs: const [Tab(text: "Products"), Tab(text: "Experts")]),
        Expanded(child: TabBarView(controller: _tab, children: [
          ListView.builder(itemCount: products.length, itemBuilder: (c, i) => Card(child: ListTile(title: Text(products[i]['name']), trailing: ElevatedButton(onPressed: (){}, child: Text("BUY"))))),
          const Center(child: Text("No Experts Online"))
        ]))
      ]),
    );
  }

  Widget _setup() => Padding(padding: const EdgeInsets.all(40), child: Column(children: [
    TextField(onChanged: (v) => cName = v, decoration: const InputDecoration(labelText: "Full Name")),
    TextField(onChanged: (v) => cAddr = v, decoration: const InputDecoration(labelText: "Address")),
    ElevatedButton(onPressed: () async {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('cust_name', cName); await prefs.setString('cust_addr', cAddr); _load();
    }, child: const Text("Save"))
  ]));
}

// --- SHOPKEEPER DASHBOARD ---
class ShopDashboard extends StatefulWidget {
  final VoidCallback onTheme;
  final ThemeMode mode;
  const ShopDashboard({super.key, required this.onTheme, required this.mode});
  @override
  State<ShopDashboard> createState() => _ShopDashboardState();
}

class _ShopDashboardState extends State<ShopDashboard> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Trinity Store"), actions: [
        IconButton(icon: Icon(widget.mode == ThemeMode.light ? Icons.dark_mode : Icons.light_mode), onPressed: widget.onTheme),
        IconButton(icon: const Icon(Icons.logout), onPressed: () async {
           SharedPreferences prefs = await SharedPreferences.getInstance();
           await prefs.remove('userRole');
           Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (c) => RoleSelectionPage(toggleTheme: widget.onTheme)), (r) => false);
        })
      ]),
      body: const Center(child: Text("Welcome to Shopkeeper Dashboard")),
    );
  }
}

// --- PROFESSIONAL DASHBOARD ---
class ProDashboard extends StatefulWidget {
  final VoidCallback onTheme;
  final ThemeMode mode;
  const ProDashboard({super.key, required this.onTheme, required this.mode});
  @override
  State<ProDashboard> createState() => _ProDashboardState();
}

class _ProDashboardState extends State<ProDashboard> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Partner Hub"), actions: [
        IconButton(icon: Icon(widget.mode == ThemeMode.light ? Icons.dark_mode : Icons.light_mode), onPressed: widget.onTheme),
        IconButton(icon: const Icon(Icons.logout), onPressed: () async {
           SharedPreferences prefs = await SharedPreferences.getInstance();
           await prefs.remove('userRole');
           Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (c) => RoleSelectionPage(toggleTheme: widget.onTheme)), (r) => false);
        })
      ]),
      body: const Center(child: Text("Welcome to Professional Dashboard")),
    );
  }
}
