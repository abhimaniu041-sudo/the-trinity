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
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.redAccent, brightness: Brightness.light),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.redAccent, brightness: Brightness.dark),
        scaffoldBackgroundColor: const Color(0xFF0A0A0A),
        cardTheme: CardThemeData(
          color: const Color(0xFF151515),
          elevation: 10,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
      ),
      home: SplashScreen(toggleTheme: _toggleTheme, mode: _themeMode),
    );
  }
}

// --- SHARED UI COMPONENTS ---
class DashboardHeader extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final VoidCallback onTheme, onProfile;
  final ThemeMode mode;
  final String role;

  const DashboardHeader({
    super.key,
    required this.title,
    required this.onTheme,
    required this.onProfile,
    required this.mode,
    required this.role,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.transparent,
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5)),
      actions: [
        IconButton(icon: const Icon(Icons.account_circle_outlined), onPressed: onProfile),
        IconButton(
          icon: const Icon(Icons.settings_outlined),
          onPressed: () => _showSettings(context),
        ),
      ],
    );
  }

  void _showSettings(context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF151515),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (c) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 10),
          ListTile(
            leading: Icon(mode == ThemeMode.light ? Icons.dark_mode : Icons.light_mode, color: Colors.redAccent),
            title: Text(mode == ThemeMode.light ? "Switch to Dark Mode" : "Switch to Light Mode"),
            onTap: () {
              Navigator.pop(context);
              onTheme();
            },
          ),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text("Logout"),
            onTap: () async {
              SharedPreferences prefs = await SharedPreferences.getInstance();
              await prefs.remove('userRole');
              Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (c) => RoleSelectionPage(toggleTheme: onTheme)), (r) => false);
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
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
      if (role == 'Shopkeeper') Navigator.pushReplacement(context, MaterialPageRoute(builder: (c) => ShopDashboard(toggleTheme: widget.toggleTheme, mode: widget.mode)));
      else if (role == 'Professional') Navigator.pushReplacement(context, MaterialPageRoute(builder: (c) => ProfessionalDashboard(toggleTheme: widget.toggleTheme, mode: widget.mode)));
      else Navigator.pushReplacement(context, MaterialPageRoute(builder: (c) => CustomerDashboard(toggleTheme: widget.toggleTheme, mode: widget.mode)));
    } else {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (c) => RoleSelectionPage(toggleTheme: widget.toggleTheme)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("THE TRINITY", style: TextStyle(fontSize: 50, fontWeight: FontWeight.w900, color: Colors.redAccent, letterSpacing: 8)),
            const SizedBox(height: 10),
            Container(width: 100, height: 2, color: Colors.redAccent.withOpacity(0.5)),
          ],
        ),
      ),
    );
  }
}

// --- ROLE SELECTION & LOGIN ---
class RoleSelectionPage extends StatelessWidget {
  final VoidCallback toggleTheme;
  const RoleSelectionPage({super.key, required this.toggleTheme});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(gradient: LinearGradient(colors: [Colors.black, Color(0xFF1A0000)], begin: Alignment.topCenter)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("SELECT IDENTITY", style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: 2)),
            const SizedBox(height: 50),
            _btn(context, "Shopkeeper", Icons.storefront_outlined),
            _btn(context, "Customer", Icons.shopping_bag_outlined),
            _btn(context, "Professional", Icons.engineering_outlined),
          ],
        ),
      ),
    );
  }

  Widget _btn(context, String r, IconData i) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 10),
        child: Card(
          child: ListTile(
            leading: Icon(i, color: Colors.redAccent),
            title: Text(r, style: const TextStyle(fontWeight: FontWeight.bold)),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => LoginPage(role: r, toggleTheme: toggleTheme))),
          ),
        ),
      );
}

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
  bool sent = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("${widget.role} Login")),
      body: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(children: [
          TextField(controller: _idC, decoration: const InputDecoration(labelText: "Mobile or Email", border: OutlineInputBorder())),
          const SizedBox(height: 20),
          if (sent) TextField(controller: _otpC, decoration: const InputDecoration(labelText: "OTP (123456)", border: OutlineInputBorder())),
          const SizedBox(height: 30),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 55)),
            onPressed: () async {
              if (!sent) {
                setState(() => sent = true);
              } else if (_otpC.text == "123456") {
                SharedPreferences prefs = await SharedPreferences.getInstance();
                await prefs.setString('userRole', widget.role);
                if (!mounted) return;
                if (widget.role == 'Shopkeeper') Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (c) => ShopDashboard(toggleTheme: widget.toggleTheme, mode: ThemeMode.dark)), (r) => false);
                else if (widget.role == 'Professional') Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (c) => ProfessionalDashboard(toggleTheme: widget.toggleTheme, mode: ThemeMode.dark)), (r) => false);
                else Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (c) => CustomerDashboard(toggleTheme: widget.toggleTheme, mode: ThemeMode.dark)), (r) => false);
              }
            },
            child: Text(sent ? "VERIFY" : "GET OTP"),
          )
        ]),
      ),
    );
  }
}

// --- 1. CUSTOMER DASHBOARD (AMAZON STYLE) ---
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
    if (data != null) setState(() => products = json.decode(data));
    if (prefs.getBool('pro_status') ?? false) {
      setState(() => pro = {'name': prefs.getString('pro_name'), 'job': prefs.getString('pro_job'), 'img': prefs.getString('pro_img')});
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = products.where((p) => p['name'].toString().toLowerCase().contains(query.toLowerCase())).toList();
    return Scaffold(
      appBar: DashboardHeader(title: "TRINITY MARKET", onTheme: widget.toggleTheme, mode: widget.mode, role: 'cust', onProfile: _editProfile),
      floatingActionButton: FloatingActionButton(backgroundColor: Colors.redAccent, onPressed: _openAI, child: const Icon(Icons.auto_awesome, color: Colors.white)),
      body: SingleChildScrollView(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.all(15),
            child: TextField(
              onChanged: (v) => setState(() => query = v),
              decoration: InputDecoration(
                hintText: "Search Plumber, Taps, etc...",
                prefixIcon: const Icon(Icons.search, color: Colors.redAccent),
                filled: true,
                fillColor: Colors.white.withOpacity(0.05),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
              ),
            ),
          ),
          // Amazon Style Horizontal Sections
          _sectionTitle("Your Recent Orders"),
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: filtered.length,
              itemBuilder: (c, i) => _amazonSmallCard(filtered[i]),
            ),
          ),
          const SizedBox(height: 10),
          TabBar(controller: _tab, indicatorColor: Colors.redAccent, labelColor: Colors.redAccent, tabs: const [Tab(text: "PRODUCTS"), Tab(text: "EXPERTS")]),
          SizedBox(
            height: 400,
            child: TabBarView(controller: _tab, children: [
              ListView.builder(itemCount: filtered.length, itemBuilder: (c, i) => _productCard(filtered[i])),
              _expertView(),
            ]),
          )
        ]),
      ),
    );
  }

  Widget _sectionTitle(String t) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
    child: Row(children: [Text(t, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), const Spacer(), const Icon(Icons.arrow_forward, size: 18)]),
  );

  Widget _amazonSmallCard(Map p) => Container(
    width: 100, margin: const EdgeInsets.only(left: 15),
    decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(15)),
    child: ClipRRect(borderRadius: BorderRadius.circular(15), child: Image.file(File(p['imgs'][0]), fit: BoxFit.cover)),
  );

  Widget _productCard(Map p) => Card(
    margin: const EdgeInsets.all(10),
    child: ListTile(
      onTap: () => _buyFlow(p),
      leading: ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.file(File(p['imgs'][0]), width: 60, height: 60, fit: BoxFit.cover)),
      title: Text(p['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text("₹${p['price']} | ⭐ 4.8", style: const TextStyle(color: Colors.redAccent)),
      trailing: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent), onPressed: () => _buyFlow(p), child: const Text("BUY", style: TextStyle(color: Colors.white))),
    ),
  );

  Widget _expertView() => ListView(children: [
    if (pro != null) Card(
      margin: const EdgeInsets.all(15),
      child: ListTile(
        leading: CircleAvatar(backgroundImage: FileImage(File(pro!['img']))),
        title: Text(pro!['name']),
        subtitle: const Text("Verified Professional"),
        trailing: ElevatedButton(onPressed: _schedule, child: const Text("HIRE")),
      ),
    )
  ]);

  void _buyFlow(Map p) {
    showModalBottomSheet(context: context, backgroundColor: const Color(0xFF151515), builder: (c) => Padding(
      padding: const EdgeInsets.all(25),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Text("Order Tracking", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.redAccent)),
        const SizedBox(height: 20),
        const LinearProgressIndicator(value: 0.3, color: Colors.green, backgroundColor: Colors.white10),
        const Padding(padding: EdgeInsets.all(15), child: Text("Status: Merchant Packing Your Order")),
        ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text("CONFIRM PURCHASE")),
      ]),
    ));
  }

  void _schedule() {
    showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 7)));
  }

  void _editProfile() {
    showModalBottomSheet(context: context, isScrollControlled: true, builder: (c) => ProfileSheet(role: 'cust'));
  }

  void _openAI() {
    showModalBottomSheet(context: context, isScrollControlled: true, builder: (c) => Container(
      height: 400, padding: const EdgeInsets.all(20),
      child: const Column(children: [Text("AI Assistant", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.redAccent)), Divider(), Expanded(child: Center(child: Text("Hello! How can I help you today?")))]),
    ));
  }
}

// --- 2. SHOPKEEPER DASHBOARD ---
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: DashboardHeader(title: "CONSOLE", onTheme: widget.toggleTheme, mode: widget.mode, role: 'shop', onProfile: _editProfile),
      body: ListView(padding: const EdgeInsets.all(20), children: [
        const Text("Add New Catalog", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.redAccent)),
        const SizedBox(height: 15),
        GestureDetector(
          onTap: () async {
            final p = await ImagePicker().pickMultiImage();
            if (p.isNotEmpty) setState(() => _imgs = p.map((f)=>f.path).toList());
          },
          child: Container(
            height: 100, decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(15)),
            child: _imgs.isEmpty ? const Icon(Icons.add_a_photo, color: Colors.redAccent) : ListView(scrollDirection: Axis.horizontal, children: _imgs.map((f)=>Image.file(File(f))).toList()),
          ),
        ),
        TextField(controller: _n, decoration: const InputDecoration(labelText: "Product Name")),
        Row(children: [
          Expanded(child: TextField(controller: _p, decoration: const InputDecoration(labelText: "Price"))),
          Expanded(child: TextField(controller: _d, decoration: const InputDecoration(labelText: "Disc%"))),
          Expanded(child: TextField(controller: _q, decoration: const InputDecoration(labelText: "Stock"))),
        ]),
        const SizedBox(height: 15),
        ElevatedButton(onPressed: _save, style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent), child: const Text("LIST PRODUCT")),
        const Divider(height: 50),
        ...products.asMap().entries.map((e) => Card(child: ListTile(
          leading: Image.file(File(e.value['imgs'][0]), width: 40),
          title: Text(e.value['name']),
          trailing: IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () async {
            products.removeAt(e.key);
            SharedPreferences prefs = await SharedPreferences.getInstance();
            await prefs.setString('global_products', json.encode(products));
            _load();
          }),
        ))).toList()
      ]),
    );
  }
  void _editProfile() => showModalBottomSheet(context: context, isScrollControlled: true, builder: (c) => ProfileSheet(role: 'shop'));
}

// --- 3. PROFESSIONAL DASHBOARD ---
class ProfessionalDashboard extends StatefulWidget {
  final VoidCallback toggleTheme;
  final ThemeMode mode;
  const ProfessionalDashboard({super.key, required this.toggleTheme, required this.mode});
  @override
  State<ProfessionalDashboard> createState() => _ProfessionalDashboardState();
}

class _ProfessionalDashboardState extends State<ProfessionalDashboard> {
  bool online = false
