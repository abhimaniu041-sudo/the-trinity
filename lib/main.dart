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

// --- DASHBOARD HEADER ---
class DashboardHeader extends StatelessWidget implements PreferredSizeWidget {
  final String title, role;
  final VoidCallback onTheme, onProfile;
  final ThemeMode mode;

  const DashboardHeader({super.key, required this.title, required this.onTheme, required this.onProfile, required this.mode, required this.role});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5, color: Colors.amberAccent)),
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
        const Text("PREMIUM SETTINGS", style: TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.bold)),
        const Divider(color: Colors.white12),
        ListTile(
          leading: Icon(mode == ThemeMode.light ? Icons.dark_mode : Icons.light_mode, color: Colors.amberAccent),
          title: Text(mode == ThemeMode.light ? "Activate Dark Mode" : "Activate Light Mode", style: const TextStyle(color: Colors.white)),
          onTap: () { Navigator.pop(context); onTheme(); },
        ),
        ListTile(
          leading: const Icon(Icons.logout, color: Colors.redAccent),
          title: const Text("Logout from Trinity", style: TextStyle(color: Colors.white)),
          onTap: () async {
            SharedPreferences prefs = await SharedPreferences.getInstance();
            await prefs.remove('userRole');
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
  Widget build(BuildContext context) => const Scaffold(body: Center(child: Text("THE TRINITY", style: TextStyle(fontSize: 45, fontWeight: FontWeight.w900, color: Colors.amberAccent, letterSpacing: 8))));
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
  String query = "";
  List products = [];
  Map? pro;

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
      if (prefs.getBool('pro_status') ?? false) {
        pro = {
          'name': prefs.getString('pro_name') ?? "Expert",
          'job': prefs.getString('pro_job') ?? "Specialist",
          'img': prefs.getString('pro_img'),
        };
      } else { pro = null; }
    });
  }

  @override
  Widget build(BuildContext context) {
    final filtered = products.where((p) => p['name'].toString().toLowerCase().contains(query.toLowerCase())).toList();
    return Scaffold(
      appBar: DashboardHeader(title: "TRINITY MARKET", onTheme: widget.toggleTheme, mode: widget.mode, role: 'cust', onProfile: _editProfile),
      floatingActionButton: FloatingActionButton(backgroundColor: Colors.amberAccent, onPressed: _openAI, child: const Icon(Icons.auto_awesome, color: Color(0xFF1A1A2E))),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.all(15),
          child: TextField(onChanged: (v) => setState(() => query = v), decoration: InputDecoration(hintText: "Search anything...", prefixIcon: const Icon(Icons.search, color: Colors.amberAccent), filled: true, fillColor: Colors.white10, border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none))),
        ),
        TabBar(controller: _tab, indicatorColor: Colors.amberAccent, labelColor: Colors.amberAccent, tabs: const [Tab(text: "PRODUCTS"), Tab(text: "EXPERTS")]),
        Expanded(
          child: TabBarView(controller: _tab, children: [
            _productList(filtered),
            _expertList(),
          ]),
        )
      ]),
    );
  }

  Widget _productList(List list) => list.isEmpty ? const Center(child: Text("No items available")) : ListView.builder(itemCount: list.length, itemBuilder: (c, i) => Card(margin: const EdgeInsets.all(10), child: ListTile(
    onTap: () => _buyFlow(list[i]),
    leading: ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.file(File(list[i]['imgs'][0]), width: 60, height: 60, fit: BoxFit.cover)),
    title: Text(list[i]['name'], style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
    subtitle: Text("₹${list[i]['price']} | ⭐ 4.8", style: const TextStyle(color: Colors.amberAccent)),
    trailing: const Icon(Icons.shopping_cart_outlined, color: Colors.amberAccent),
  )));

  Widget _expertList() => ListView(children: [
    if (pro != null && (pro!['name'].toLowerCase().contains(query.toLowerCase()) || pro!['job'].toLowerCase().contains(query.toLowerCase())))
      Card(margin: const EdgeInsets.all(15), child: ListTile(leading: CircleAvatar(backgroundImage: FileImage(File(pro!['img']))), title: Text(pro!['name'], style: const TextStyle(color: Colors.white)), subtitle: Text(pro!['job'], style: const TextStyle(color: Colors.white70)), trailing: ElevatedButton(onPressed: _schedule, child: const Text("HIRE"))))
    else const Center(child: Padding(padding: EdgeInsets.all
