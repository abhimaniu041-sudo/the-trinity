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
        appBarTheme: const AppBarTheme(centerTitle: true, elevation: 2, backgroundColor: Color(0xFF1A237E), foregroundColor: Colors.white),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo, brightness: Brightness.dark),
        scaffoldBackgroundColor: const Color(0xFF0D0D1A),
        cardTheme: CardThemeData(
          color: const Color(0xFF1A1A2E),
          elevation: 10,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: Colors.amberAccent, width: 0.2)),
        ),
      ),
      home: SplashScreen(toggleTheme: _toggleTheme, mode: _themeMode),
    );
  }
}

// --- SHARED COMPONENTS ---
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
        IconButton(icon: const Icon(Icons.settings_outlined, color: Colors.white70), onPressed: () => _openSettings(context)),
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
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text("THE TRINITY", style: TextStyle(fontSize: 45, fontWeight: FontWeight.w900, color: Colors.amberAccent, letterSpacing: 8)),
          SizedBox(height: 10),
          CircularProgressIndicator(color: Colors.amberAccent, strokeWidth: 2),
        ]),
      ),
    );
  }
}

// --- CUSTOMER DASHBOARD (AMAZON STYLE) ---
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
      floatingActionButton: FloatingActionButton(backgroundColor: Colors.amberAccent, onPressed: _openAI, child: const Icon(Icons.auto_awesome, color: Color(0xFF1A1A2E))),
      body: SingleChildScrollView(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.all(15),
            child: TextField(onChanged: (v) => setState(() => query = v), decoration: InputDecoration(hintText: "Search Flipkart/Amazon Style...", prefixIcon: const Icon(Icons.search, color: Colors.amberAccent), filled: true, fillColor: Colors.white10, border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none))),
          ),
          _sectionTitle("Buy Again"),
          SizedBox(height: 130, child: ListView.builder(scrollDirection: Axis.horizontal, itemCount: filtered.length, itemBuilder: (c, i) => _amazonSmallCard(filtered[i]))),
          TabBar(controller: _tab, indicatorColor: Colors.amberAccent, labelColor: Colors.amberAccent, tabs: const [Tab(text: "PRODUCTS"), Tab(text: "EXPERTS")]),
          SizedBox(height: 500, child: TabBarView(controller: _tab, children: [
            ListView.builder(itemCount: filtered.length, itemBuilder: (c, i) => _productCard(filtered[i])),
            _expertView(),
          ]))
        ]),
      ),
    );
  }

  Widget _sectionTitle(String t) => Padding(padding: const EdgeInsets.all(15), child: Row(children: [Text(t, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)), const Spacer(), const Icon(Icons.arrow_forward, size: 18, color: Colors.amberAccent)]));

  Widget _amazonSmallCard(Map p) => Container(width: 110, margin: const EdgeInsets.only(left: 15), decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.amberAccent.withOpacity(0.3))), child: ClipRRect(borderRadius: BorderRadius.circular(15), child: Image.file(File(p['imgs'][0]), fit: BoxFit.cover)));

  Widget _productCard(Map p) => Card(margin: const EdgeInsets.all(10), child: ListTile(
    onTap: () => _buyFlow(p),
    leading: ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.file(File(p['imgs'][0]), width: 60, height: 60, fit: BoxFit.cover)),
    title: Text(p['name'], style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
    subtitle: Text("₹${p['price']} | ⭐ 4.9", style: const TextStyle(color: Colors.amberAccent)),
    trailing: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.amberAccent), onPressed: () => _buyFlow(p), child: const Text("BUY", style: TextStyle(color: Color(0xFF1A1A2E), fontWeight: FontWeight.bold))),
  ));

  Widget _expertView() => ListView(children: [
    if (pro != null) Card(margin: const EdgeInsets.all(15), child: ListTile(leading: CircleAvatar(backgroundImage: FileImage(File(pro!['img']))), title: Text(pro!['name'], style: const TextStyle(color: Colors.white)), subtitle: const Text("Verified Professional", style: TextStyle(color: Colors.white70)), trailing: ElevatedButton(onPressed: (){}, child: const Text("HIRE"))))
  ]);

  void _buyFlow(Map p) {
    showModalBottomSheet(context: context, backgroundColor: const Color(0xFF1A1A2E), builder: (c) => Padding(padding: const EdgeInsets.all(25), child: Column(mainAxisSize: MainAxisSize.min, children: [const Text("Order Tracking", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.amberAccent)), const SizedBox(height: 10), const LinearProgressIndicator(value: 0.4, color: Colors.green), const Padding(padding: EdgeInsets.all(15), child: Text("Status: Preparing Dispatch", style: TextStyle(color: Colors.white70))), ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text("CONFIRM ORDER"))])));
  }

  void _editProfile() => showModalBottomSheet(context: context, isScrollControlled: true, builder: (c) => const ProfileSheet(role: 'cust'));
  void _openAI() => showModalBottomSheet(context: context, builder: (c) => Container(height: 300, padding: const EdgeInsets.all(20), child: const Center(child: Text("AI Assistant: How can I help you today?", style: TextStyle(color: Colors.amberAccent)))));
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
    appBar: DashboardHeader(title: "CONSOLE", onTheme: widget.toggleTheme, mode: widget.mode, role: 'shop', onProfile: _editProfile),
    body: ListView(padding: const EdgeInsets.all(20), children: [
      const Text("Add New Product", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.amberAccent)),
      const SizedBox(height: 15),
      GestureDetector(onTap: () async {
        final p = await ImagePicker().pickMultiImage();
        if (p.isNotEmpty) setState(() => _imgs = p.map((f)=>f.path).toList());
      }, child: Container(height: 120, decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.amberAccent.withOpacity(0.5))), child: _imgs.isEmpty ? const Icon(Icons.add_a_photo, color: Colors.amberAccent, size: 40) : ListView(scrollDirection: Axis.horizontal, children: _imgs.map((f)=>Padding(padding: const EdgeInsets.all(5), child: Image.file(File(f)))).toList()))),
      TextField(controller: _n, decoration: const InputDecoration(labelText: "Product Name")),
      Row(children: [Expanded(child: TextField(controller: _p, decoration: const InputDecoration(labelText: "Price"))), Expanded(child: TextField(controller: _d, decoration: const InputDecoration(labelText: "Disc%"))), Expanded(child: TextField(controller: _q, decoration: const InputDecoration(labelText: "Stock")))]),
      const SizedBox(height: 15),
      ElevatedButton(onPressed: _save, style: ElevatedButton.styleFrom(backgroundColor: Colors.amberAccent), child: const Text("LIST PRODUCT", style: TextStyle(color: Color(0xFF1A1A2E)))),
      const Divider(height: 50, color: Colors.white12),
      ...products.asMap().entries.map((e) => Card(child: ListTile(leading: Image.file(File(e.value['imgs'][0]), width: 40), title: Text(e.value['name'], style: const TextStyle(color: Colors.white)), trailing: IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () async { products.removeAt(e.key); SharedPreferences prefs = await SharedPreferences.getInstance(); await prefs.setString('global_products', json.encode(products)); _load(); })))).toList()
    ]),
  );
  void _editProfile() => showModalBottomSheet(context: context, isScrollControlled: true, builder: (c) => const ProfileSheet(role: 'shop'));
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
  bool online = false; String name = "Partner"; File? img;
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
    appBar: DashboardHeader(title: "PARTNER HUB", onTheme: widget.toggleTheme, mode: widget.mode, role: 'pro', onProfile: _editProfile),
    body: Column(children: [
      Container(margin: const EdgeInsets.all(20), padding: const EdgeInsets.all(25), decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF1A237E), Color(0xFF0D0D1A)]), borderRadius: BorderRadius.circular(30), border: Border.all(color: Colors.amberAccent.withOpacity(0.5))), child: Column(children: [
        CircleAvatar(radius: 50, backgroundImage: img != null ? FileImage(img!) : null),
        const SizedBox(height: 10),
        Text(name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
        const Text("TRINITY VERIFIED EXPERT", style: TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.bold, fontSize: 12)),
      ])),
      SwitchListTile(title: const Text("Available for Work", style: TextStyle(color: Colors.white)), value: online, activeColor: Colors.amberAccent, onChanged: (v) async {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setBool('pro_status', v); setState(() => online = v);
      }),
      const Padding(padding: EdgeInsets.all(20), child: TextField(decoration: InputDecoration(labelText: "Enter Completion OTP", border: OutlineInputBorder())))
    ]),
  );
  void _editProfile() => showModalBottomSheet(context: context, isScrollControlled: true, builder: (c) => const ProfileSheet(role: 'pro'));
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
  Widget build(BuildContext context) => Padding(padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 20, right: 20, top: 20), child: Column(mainAxisSize: MainAxisSize.min, children: [
    const Text("EDIT PROFILE", style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.amberAccent)),
    const SizedBox(height: 15),
    GestureDetector(onTap: () async { final p = await ImagePicker().pickImage(source: ImageSource.gallery); if (p != null) setState(() => _img = File(p.path)); }, child: CircleAvatar(radius: 50, backgroundImage: _img != null ? FileImage(_img!) : null, child: _img == null ? const Icon(Icons.camera_alt) : null)),
    TextField(controller: _n, decoration: const InputDecoration(labelText: "Full Name")),
    TextField(controller: _p, decoration: const InputDecoration(labelText: "Phone")),
    TextField(controller: _a, decoration: const InputDecoration(labelText: "Address")),
    const SizedBox(height: 20),
    ElevatedButton(onPressed: () async {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('${widget.role}_name', _n.text); await prefs.setString('${widget.role}_phone', _p.text); await prefs.setString('${widget.role}_addr', _a.text);
      if (_img != null) await prefs.setString('${widget.role}_img', _img!.path);
      Navigator.pop(context, true);
    }, child: const Text("SAVE CHANGES")),
    const SizedBox(height: 30)
  ]));
}

// --- ROLE SELECTION & LOGIN ---
class RoleSelectionPage extends StatelessWidget {
  final VoidCallback toggleTheme;
  const RoleSelectionPage({super.key, required this.toggleTheme});
  @override
  Widget build(BuildContext context) => Scaffold(body: Container(width: double.infinity, decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF0D0D1A), Color(0xFF1A237E)], begin: Alignment.topCenter)), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
    const Text("THE TRINITY", style: TextStyle(color: Colors.amberAccent, fontSize: 40, fontWeight: FontWeight.w900, letterSpacing: 5)),
    const SizedBox(height: 50),
    _btn(context, "Shopkeeper", Icons.storefront), _btn(context, "Customer", Icons.person), _btn(context, "Professional", Icons.handyman),
  ])));
  Widget _btn(context, String r, IconData i) => Padding(padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 10), child: Card(child: ListTile(leading: Icon(i, color: Colors.amberAccent), title: Text(r, style: const TextStyle(fontWeight: FontWeight.bold)), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => LoginPage(role: r, toggleTheme: toggleTheme))))));
}

class LoginPage extends StatefulWidget {
  final String role; final VoidCallback toggleTheme;
  const LoginPage({super.key, required this.role, required this.toggleTheme});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _id = TextEditingController(), _otp = TextEditingController(); bool sent = false;
  @override
  Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: Text("${widget.role} Login")), body: Padding(padding: const EdgeInsets.all(30), child: Column(children: [
    TextField(controller: _id, decoration: const InputDecoration(labelText: "Email/Phone")),
    if (sent) TextField(controller: _otp, decoration: const InputDecoration(labelText: "OTP (123456)")),
    const SizedBox(height: 20),
    ElevatedButton(onPressed: () async {
      if (!sent) setState(() => sent = true);
      else if (_otp.text == "123456") {
        SharedPreferences prefs = await SharedPreferences.getInstance(); await prefs.setString('userRole', widget.role);
        if (mounted) Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (c) => SplashScreen(toggleTheme: widget.toggleTheme, mode: ThemeMode.dark)), (r) => false);
      }
    }, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A237E), foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 50)), child: Text(sent ? "LOGIN" : "GET OTP"))
  ])));
}
