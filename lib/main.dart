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
        cardTheme: CardThemeData(elevation: 4, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo, brightness: Brightness.dark),
        cardTheme: CardThemeData(elevation: 4, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
      ),
      home: SplashScreen(toggleTheme: _toggleTheme, mode: _themeMode),
    );
  }
}

// --- GLOBAL MODELS ---
class TrinityUser {
  String name, address, phoneEmail, photo;
  TrinityUser({this.name = "", this.address = "", this.phoneEmail = "", this.photo = ""});
}

// --- NAVIGATION HELPER ---
Widget getDashboard(String role, VoidCallback toggle, ThemeMode mode) {
  if (role == 'Shopkeeper') return ShopDashboard(toggleTheme: toggle, mode: mode);
  if (role == 'Professional') return ProDashboard(toggleTheme: toggle, mode: mode);
  return CustomerDashboard(toggleTheme: toggle, mode: mode);
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
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (c) => getDashboard(role, widget.toggleTheme, widget.mode)));
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

// --- LOGIN PAGE (Email/Phone + OTP) ---
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
        TextField(controller: _idC, decoration: const InputDecoration(labelText: "Email or Phone", border: OutlineInputBorder(), prefixIcon: Icon(Icons.person))),
        const SizedBox(height: 20),
        if (otpSent) TextField(controller: _otpC, decoration: const InputDecoration(labelText: "OTP (123456)", border: OutlineInputBorder())),
        const SizedBox(height: 30),
        ElevatedButton(
          style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 55)),
          onPressed: () async {
            if (!otpSent) {
              if (_idC.text.isNotEmpty) setState(() => otpSent = true);
            } else if (_otpC.text == "123456") {
              SharedPreferences prefs = await SharedPreferences.getInstance();
              await prefs.setString('userRole', widget.role);
              await prefs.setString('user_id', _idC.text);
              if (mounted) Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (c) => SplashScreen(toggleTheme: widget.toggleTheme, mode: ThemeMode.light)), (r) => false);
            }
          }, 
          child: Text(otpSent ? "AUTHENTICATE" : "GET OTP")
        )
      ])),
    );
  }
}

// --- SHARED APP BAR COMPONENT ---
class DashboardHeader extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final VoidCallback onTheme, onProfile;
  final ThemeMode mode;
  const DashboardHeader({super.key, required this.title, required this.onTheme, required this.onProfile, required this.mode});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      actions: [
        IconButton(icon: Icon(mode == ThemeMode.light ? Icons.dark_mode : Icons.light_mode), onPressed: onTheme),
        IconButton(icon: const Icon(Icons.account_circle), onPressed: onProfile),
        IconButton(icon: const Icon(Icons.settings), onPressed: () => _settings(context)),
      ],
    );
  }

  void _settings(context) {
    showModalBottomSheet(context: context, builder: (c) => Column(mainAxisSize: MainAxisSize.min, children: [
      const ListTile(title: Text("App Settings", style: TextStyle(fontWeight: FontWeight.bold))),
      ListTile(leading: const Icon(Icons.logout, color: Colors.red), title: const Text("Logout"), onTap: () async {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.remove('userRole');
        Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (c) => RoleSelectionPage(toggleTheme: onTheme)), (r) => false);
      })
    ]));
  }
  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

// --- 1. CUSTOMER DASHBOARD (FIXED SEARCH & PRIVACY) ---
class CustomerDashboard extends StatefulWidget {
  final VoidCallback toggleTheme;
  final ThemeMode mode;
  const CustomerDashboard({super.key, required this.toggleTheme, required this.mode});
  @override
  State<CustomerDashboard> createState() => _CustomerDashboardState();
}

class _CustomerDashboardState extends State<CustomerDashboard> with SingleTickerProviderStateMixin {
  late TabController _tab;
  String query = "", cName = "", cAddr = "";
  List products = [];
  Map? pro;
  bool isHired = false, hasProfile = false;

  @override
  void initState() { super.initState(); _tab = TabController(length: 2, vsync: this); _load(); }
  _load() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      cName = prefs.getString('cust_name') ?? "";
      cAddr = prefs.getString('cust_addr') ?? "";
      hasProfile = cName.isNotEmpty;
      String? data = prefs.getString('shop_products');
      if (data != null) products = json.decode(data);
      if (prefs.getBool('pro_status') ?? false) {
        pro = {'name': prefs.getString('pro_name'), 'job': prefs.getString('pro_job'), 'img': prefs.getString('pro_photo')};
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final filteredProducts = products.where((p) => p['name'].toString().toLowerCase().contains(query.toLowerCase())).toList();
    return Scaffold(
      appBar: DashboardHeader(title: "Trinity Market", onTheme: widget.toggleTheme, mode: widget.mode, onProfile: _editProfile),
      floatingActionButton: FloatingActionButton(onPressed: () => _openAI(context), child: const
