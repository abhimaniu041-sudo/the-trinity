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
  void _toggleTheme() => setState(() => _themeMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      themeMode: _themeMode,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1A237E)),
        cardTheme: CardThemeData(elevation: 5, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
      ),
      darkTheme: ThemeData.dark(useMaterial3: true).copyWith(
        cardTheme: CardThemeData(elevation: 5, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
      ),
      home: const SplashScreen(),
    );
  }
}

// --- SHARED COMPONENTS ---
class ProfileSheet extends StatefulWidget {
  final String role;
  const ProfileSheet({super.key, required this.role});
  @override
  State<ProfileSheet> createState() => _ProfileSheetState();
}

class _ProfileSheetState extends State<ProfileSheet> {
  final _name = TextEditingController();
  final _addr = TextEditingController();
  File? _img;

  @override
  void initState() {
    super.initState();
    _load();
  }

  _load() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _name.text = prefs.getString('${widget.role}_name') ?? "";
      _addr.text = prefs.getString('${widget.role}_addr') ?? "";
      String? path = prefs.getString('${widget.role}_img');
      if (path != null) _img = File(path);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text("Edit Profile", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: () async {
              final p = await ImagePicker().pickImage(source: ImageSource.gallery);
              if (p != null) setState(() => _img = File(p.path));
            },
            child: CircleAvatar(radius: 50, backgroundImage: _img != null ? FileImage(_img!) : null, child: _img == null ? const Icon(Icons.camera_alt) : null),
          ),
          TextField(controller: _name, decoration: const InputDecoration(labelText: "Full Name")),
          TextField(controller: _addr, decoration: const InputDecoration(labelText: "Address")),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () async {
              SharedPreferences prefs = await SharedPreferences.getInstance();
              await prefs.setString('${widget.role}_name', _name.text);
              await prefs.setString('${widget.role}_addr', _addr.text);
              if (_img != null) await prefs.setString('${widget.role}_img', _img!.path);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Profile Updated!")));
            },
            child: const Text("Save Details"),
          )
        ],
      ),
    );
  }
}

// --- SPLASH SCREEN ---
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _init();
  }

  _init() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? role = prefs.getString('userRole');
    await Future.delayed(const Duration(seconds: 3));
    if (!mounted) return;
    if (role != null) {
      _directNav(role);
    } else {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (c) => const RoleSelectionPage()));
    }
  }

  void _directNav(String role) {
    Widget next = role == 'Shopkeeper' ? const ShopDashboard() : 
                  role == 'Professional' ? const ProDashboard() : const CustomerDashboard();
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (c) => next));
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: Text("THE TRINITY", style: TextStyle(fontSize: 40, fontWeight: FontWeight.w900, color: Color(0xFF1A237E)))));
  }
}

// --- ROLE SELECTION ---
class RoleSelectionPage extends StatelessWidget {
  const RoleSelectionPage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF1A237E), Color(0xFF3949AB)])),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Text("Select Identity", style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
          const SizedBox(height: 40),
          _btn(context, "Shopkeeper", Icons.storefront),
          _btn(context, "Customer", Icons.person_search),
          _btn(context, "Professional", Icons.engineering),
        ]),
      ),
    );
  }
  Widget _btn(context, r, i) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 10),
    child: Card(child: ListTile(title: Text(r), leading: Icon(i), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => LoginPage(role: r))))),
  );
}

// --- LOGIN ---
class LoginPage extends StatefulWidget {
  final String role;
  const LoginPage({super.key, required this.role});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _idC = TextEditingController();
  final _otpC = TextEditingController();
  bool sent = false;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text("${widget.role} Login")),
    body: Padding(padding: const EdgeInsets.all(30), child: Column(children: [
      TextField(controller: _idC, decoration: const InputDecoration(labelText: "Email or Phone")),
      if (sent) TextField(controller: _otpC, decoration: const InputDecoration(labelText: "OTP (123456)")),
      const SizedBox(height: 20),
      ElevatedButton(onPressed: () async {
        if (!sent) setState(() => sent = true);
        else if (_otpC.text == "123456") {
          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setString('userRole', widget.role);
          Widget next = widget.role == 'Shopkeeper' ? const ShopDashboard() : widget.role == 'Professional' ? const ProDashboard() : const CustomerDashboard();
          Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (c) => next), (r) => false);
        }
      }, child: Text(sent ? "LOGIN" : "GET OTP"))
    ])),
  );
}

// --- CUSTOMER DASHBOARD ---
class CustomerDashboard extends StatefulWidget {
  const CustomerDashboard({super.key});
  @override
  State<CustomerDashboard> createState() => _CustomerDashboardState();
}

class _CustomerDashboardState extends State<CustomerDashboard> with SingleTickerProviderStateMixin {
  late TabController _tab;
  String query = "";
  List products = [];

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _load();
  }

  _load() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? data = prefs.getString('shop_products');
    if (data != null) setState(() => products = json.decode(data));
  }

  void _openAI() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (c) => StatefulBuilder(builder: (context, setS) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Container(
            height: 400, padding: const EdgeInsets.all(20),
            child: Column(children: [
              const Text("Trinity AI", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const Expanded(child: Center(child: Text("AI: How can I help you with hiring or buying?"))),
              TextField(
                decoration: const InputDecoration(hintText: "Ask something...", suffixIcon: Icon(Icons.send)),
                onSubmitted: (v) {
                   // Add logic for real-time text response simulation here
                },
              )
            ]),
          ),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = products.where((p) => p['name'].toString().toLowerCase().contains(query.toLowerCase())).toList();
    return Scaffold(
      appBar: AppBar(title: const Text("Trinity Market"), actions: [
        IconButton(icon: const Icon(Icons.person), onPressed: () => showModalBottomSheet(context: context, builder: (c) => const ProfileSheet(role: 'cust'))),
        IconButton(icon: const Icon(Icons.settings), onPressed: () => _showSettings(context)),
      ]),
      floatingActionButton: FloatingActionButton(onPressed: _openAI, child: const Icon(Icons.auto_awesome)),
      body: Column(children: [
        Padding(padding: const EdgeInsets.all(15), child: TextField(onChanged: (v) => setState(() => query = v), decoration: InputDecoration(hintText: "Search Flipkart style...", prefixIcon: const Icon(Icons.search), border: OutlineInputBorder(borderRadius: BorderRadius.circular(30))))),
        TabBar(controller: _tab, labelColor: Colors.indigo, tabs: const [Tab(text: "Products"), Tab(text: "Experts")]),
        Expanded(child: TabBarView(controller: _tab, children: [
          ListView.builder(itemCount: filtered.length, itemBuilder: (c, i) => Card(child: ListTile(title: Text(filtered[i]['name']), trailing: ElevatedButton(onPressed: (){}, child: const Text("BUY"))))),
          const Center(child: Text("No Experts Online"))
        ]))
      ]),
    );
  }

  _showSettings(context) {
    showModalBottomSheet(context: context, builder: (c) => ListTile(leading: const Icon(Icons.logout), title: const Text("Logout"), onTap: () async {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.remove('userRole');
      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (c) => const RoleSelectionPage()), (r) => false);
    }));
  }
}

// --- SHOPKEEPER DASHBOARD ---
class ShopDashboard extends StatelessWidget {
  const ShopDashboard({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Shop Hub"), actions: [
        IconButton(icon: const Icon(Icons.person), onPressed: () => showModalBottomSheet(context: context, builder: (c) => const ProfileSheet(role: 'shop'))),
        IconButton(icon: const Icon(Icons.settings), onPressed: () {}),
      ]),
      body: const Center(child: Text("Shopkeeper Panel: Add Products Here")),
    );
  }
}

// --- PROFESSIONAL DASHBOARD ---
class ProDashboard extends StatelessWidget {
  const ProDashboard({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Partner Panel"), actions: [
        IconButton(icon: const Icon(Icons.person), onPressed: () => showModalBottomSheet(context: context, builder: (c) => const ProfileSheet(role: 'pro'))),
        IconButton(icon: const Icon(Icons.settings), onPressed: () {}),
      ]),
      body: const Center(child: Text("Expert Panel: View Leads Here")),
    );
  }
}
