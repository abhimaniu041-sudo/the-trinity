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

// --- SHARED HEADER COMPONENT ---
class DashboardHeader extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final VoidCallback onTheme, onProfile;
  final ThemeMode mode;

  const DashboardHeader({super.key, required this.title, required this.onTheme, required this.onProfile, required this.mode});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.transparent,
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5, color: Colors.amberAccent)),
      actions: [
        IconButton(icon: const Icon(Icons.account_circle_outlined, color: Colors.amberAccent), onPressed: onProfile),
        IconButton(icon: const Icon(Icons.settings_outlined), onPressed: () => _showSettings(context)),
      ],
    );
  }

  void _showSettings(context) {
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
          title: const Text("Logout from System", style: TextStyle(color: Colors.white)),
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
  String query = "";
  List products = [];
  Map? pro;

  @override
  void initState() { super.initState(); _tab = TabController(length: 2, vsync: this); _load(); }
  _load() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? data = prefs.getString('global_products');
    setState(() {
      if (data != null) products = json.decode(data);
      if (prefs.getBool('pro_status') ?? false) {
        pro = {'name': prefs.getString('pro_name'), 'job': prefs.getString('pro_job'), 'img': prefs.getString('pro_img')};
      } else { pro = null; }
    });
  }

  @override
  Widget build(BuildContext context) {
    final filtered = products.where((p) => p['name'].toString().toLowerCase().contains(query.toLowerCase())).toList();
    return Scaffold(
      appBar: DashboardHeader(title: "TRINITY MARKET", onTheme: widget.toggleTheme, mode: widget.mode, onProfile: _editProfile),
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

  Widget _productList(List list) => list.isEmpty ? const Center(child: Text("No products found")) : ListView.builder(itemCount: list.length, itemBuilder: (c, i) => Card(margin: const EdgeInsets.all(10), child: ListTile(
    onTap: () => _buyFlow(list[i]),
    leading: ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.file(File(list[i]['imgs'][0]), width: 60, height: 60, fit: BoxFit.cover)),
    title: Text(list[i]['name'], style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
    subtitle: Text("₹${list[i]['price']} | ⭐ 4.8", style: const TextStyle(color: Colors.amberAccent)),
    trailing: const Icon(Icons.shopping_cart_outlined, color: Colors.amberAccent),
  )));

  Widget _expertList() => ListView(children: [
    if (pro != null) Card(margin: const EdgeInsets.all(15), child: ListTile(leading: CircleAvatar(backgroundImage: FileImage(File(pro!['img']))), title: Text(pro!['name'], style: const TextStyle(color: Colors.white)), subtitle: Text(pro!['job'], style: const TextStyle(color: Colors.white70)), trailing: ElevatedButton(onPressed: _schedule, child: const Text("HIRE"))))
    else const Center(child: Padding(padding: EdgeInsets.all(20), child: Text("No experts online")))
  ]);

  void _buyFlow(Map p) {
    showModalBottomSheet(context: context, backgroundColor: const Color(0xFF1A1A2E), builder: (c) => Padding(padding: const EdgeInsets.all(25), child: Column(mainAxisSize: MainAxisSize.min, children: [const Text("Order Tracking", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.amberAccent)), const SizedBox(height: 10), const LinearProgressIndicator(value: 0.3, color: Colors.green), const Text("Packing your order...", style: TextStyle(color: Colors.white70)), ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text("CONFIRM"))])));
  }

  void _schedule() { showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 7))); }
  void _editProfile() async { bool? res = await showModalBottomSheet(context: context, isScrollControlled: true, builder: (c) => const ProfileSheet(role: 'cust')); if(res == true) _load(); }
  void _openAI() { showModalBottomSheet(context: context, builder: (c) => Container(height: 300, padding: const EdgeInsets.all(20), child: const Center(child: Text("AI Assistant: How can I help you?", style: TextStyle(color: Colors.amberAccent))))); }
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
  final _n = TextEditingController(), _p = TextEditingController(), _d = TextEditingController(), _q = TextEditingController();
  List<String> _imgs = [];

  @override
  void initState() { super.initState(); _load(); }
  _load() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? data = prefs.getString('global_products');
    if (data != null) setState(() => products = json.decode(data));
  }

  _save() async {
    if (_n.text.isEmpty || _imgs.isEmpty) return;
    products.add({'name': _n.text, 'price': _p.text, 'disc': _d.text, 'qty': _q.text, 'imgs': _imgs});
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('global_products', json.encode(products));
    setState(() { _n.clear(); _p.clear(); _d.clear(); _q.clear(); _imgs = []; });
    _load();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: DashboardHeader(title: "SHOP CONSOLE", onTheme: widget.toggleTheme, mode: widget.mode, onProfile: _editProfile),
    body: ListView(padding: const EdgeInsets.all(20), children: [
      const Text("Add New Catalog", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.amberAccent)),
      GestureDetector(onTap: () async {
        final p = await ImagePicker().pickMultiImage();
        if (p.isNotEmpty) setState(() => _imgs = p.map((f)=>f.path).toList());
      }, child: Container(height: 120, decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(15)), child: _imgs.isEmpty ? const Icon(Icons.add_a_photo, color: Colors.amberAccent, size: 40) : ListView(scrollDirection: Axis.horizontal, children: _imgs.map((f)=>Padding(padding: const EdgeInsets.all(5), child: Image.file(File(f)))).toList()))),
      TextField(controller: _n, decoration: const InputDecoration(labelText: "Product Name")),
      Row(children: [Expanded(child: TextField(controller: _p, decoration: const InputDecoration(labelText: "Price"))), Expanded(child: TextField(controller: _d, decoration: const InputDecoration(labelText: "Disc%"))), Expanded(child: TextField(controller: _q, decoration: const InputDecoration(labelText: "Stock")))]),
      ElevatedButton(onPressed: _save, style: ElevatedButton.styleFrom(backgroundColor: Colors.amberAccent), child: const Text("LIST PRODUCT", style: TextStyle(color: Color(0xFF1A1A2E)))),
      const Divider(height: 40),
      ...products.asMap().entries.map((e) => Card(child: ListTile(leading: Image.file(File(e.value['imgs'][0]), width: 40), title: Text(e.value['name'], style: const TextStyle(color: Colors.white)), trailing: IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () async { products.removeAt(e.key); SharedPreferences prefs = await SharedPreferences.getInstance(); await prefs.setString('global_products', json.encode(products)); _load(); })))).toList()
    ]),
  );
  void _editProfile() async { bool? res = await showModalBottomSheet(context: context, isScrollControlled: true, builder: (c) => const ProfileSheet(role: 'shop')); if(res == true) _load(); }
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
  String name = "Partner";
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
  Widget build(BuildContext context) => Scaffold(
    appBar: DashboardHeader(title: "PARTNER HUB", onTheme: widget.toggleTheme, mode: widget.mode, onProfile: _editProfile),
    body: Column(children: [
      Container(margin: const EdgeInsets.all(20), padding: const EdgeInsets.all(25), decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF1A237E), Color(0xFF0D0D1A)]), borderRadius: BorderRadius.circular(30), border: Border.all(color: Colors.amberAccent.withOpacity(0.5))), child: Column(children: [
        CircleAvatar(radius: 50, backgroundImage: img != null ? FileImage(img!) : null, child: img == null ? const Icon(Icons.person, size: 40) : null),
        const SizedBox(height: 10),
        Text(name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
        const Text("TRINITY VERIFIED EXPERT", style: TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.bold, fontSize: 12)),
      ])),
      SwitchListTile(
        title: Text(online ? "YOU ARE ONLINE" : "OFFLINE", style: TextStyle(color: online ? Colors.green : Colors.red, fontWeight: FontWeight.bold)),
        value: online, activeColor: Colors.green,
        onChanged: (v) async {
          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setBool('pro_status', v);
          setState(() { online = v; });
        },
      ),
      const Padding(padding: EdgeInsets.all(20), child: TextField(decoration: InputDecoration(labelText: "Enter Completion OTP", border: OutlineInputBorder())))
    ]),
  );
  void _editProfile() async { bool? res = await showModalBottomSheet(context: context, isScrollControlled: true, builder: (c) => const ProfileSheet(role: 'pro')); if(res == true) _load(); }
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
    const Text("EDIT PROFILE", style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.amberAccent)),
