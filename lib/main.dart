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
  Widget build(BuildContext context) => const Scaffold(body: Center(child: Text("THE TRINITY", style: TextStyle(fontSize: 45, fontWeight: FontWeight.w900, color: Colors.redAccent, letterSpacing: 5))));
}

// --- PROFILE SHEET COMPONENT ---
class ProfileSheet extends StatefulWidget {
  final String role;
  const ProfileSheet({super.key, required this.role});
  @override
  State<ProfileSheet> createState() => _ProfileSheetState();
}

class _ProfileSheetState extends State<ProfileSheet> {
  final _n = TextEditingController(), _p = TextEditingController(), _a = TextEditingController();
  File? _img;

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
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 20, right: 20, top: 20),
    child: SingleChildScrollView(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Text("PROFILE SETTINGS", style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.redAccent)),
        const SizedBox(height: 20),
        GestureDetector(
          onTap: () async {
            final p = await ImagePicker().pickImage(source: ImageSource.gallery);
            if (p != null) setState(() => _img = File(p.path));
          },
          child: CircleAvatar(radius: 50, backgroundImage: _img != null ? FileImage(_img!) : null, child: _img == null ? const Icon(Icons.camera_alt) : null),
        ),
        TextField(controller: _n, decoration: const InputDecoration(labelText: "Full Name")),
        TextField(controller: _p, decoration: const InputDecoration(labelText: "Mobile Number")),
        TextField(controller: _a, decoration: const InputDecoration(labelText: "Full Address")),
        const SizedBox(height: 20),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 50)),
          onPressed: () async {
            SharedPreferences prefs = await SharedPreferences.getInstance();
            await prefs.setString('${widget.role}_name', _n.text);
            await prefs.setString('${widget.role}_phone', _p.text);
            await prefs.setString('${widget.role}_addr', _a.text);
            if (_img != null) await prefs.setString('${widget.role}_img', _img!.path);
            if (mounted) Navigator.pop(context, true);
          },
          child: const Text("SAVE CHANGES"),
        ),
        const SizedBox(height: 30),
      ]),
    ),
  );
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
      setState(() => pro = {
        'name': prefs.getString('pro_name') ?? "Expert",
        'job': prefs.getString('pro_job') ?? "Specialist",
        'img': prefs.getString('pro_img')
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = products.where((p) => p['name'].toString().toLowerCase().contains(query.toLowerCase())).toList();
    return Scaffold(
      appBar: AppBar(
        title: const Text("TRINITY MARKET", style: TextStyle(fontWeight: FontWeight.w900)),
        actions: [
          IconButton(icon: const Icon(Icons.account_circle_outlined), onPressed: () => showModalBottomSheet(context: context, isScrollControlled: true, builder: (c) => const ProfileSheet(role: 'cust'))),
          IconButton(icon: const Icon(Icons.settings_outlined), onPressed: () => _settings(context)),
        ],
      ),
      floatingActionButton: FloatingActionButton(backgroundColor: Colors.redAccent, onPressed: _openAI, child: const Icon(Icons.auto_awesome, color: Colors.white)),
      body: SingleChildScrollView(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.all(15),
            child: TextField(
              onChanged: (v) => setState(() => query = v),
              decoration: InputDecoration(
                hintText: "Search anything...",
                prefixIcon: const Icon(Icons.search, color: Colors.redAccent),
                filled: true,
                fillColor: Colors.white10,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
              ),
            ),
          ),
          _rowTitle("Buy Again"),
          SizedBox(height: 120, child: ListView.builder(scrollDirection: Axis.horizontal, itemCount: filtered.length, itemBuilder: (c, i) => _amazonSmallCard(filtered[i]))),
          TabBar(controller: _tab, indicatorColor: Colors.redAccent, labelColor: Colors.redAccent, tabs: const [Tab(text: "PRODUCTS"), Tab(text: "EXPERTS")]),
          SizedBox(height: 500, child: TabBarView(controller: _tab, children: [
            ListView.builder(itemCount: filtered.length, itemBuilder: (c, i) => _productCard(filtered[i])),
            _expertView(),
          ]))
        ]),
      ),
    );
  }

  Widget _rowTitle(String t) => Padding(padding: const EdgeInsets.all(15), child: Row(children: [Text(t, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), const Spacer(), const Icon(Icons.arrow_forward)]));
  
  Widget _amazonSmallCard(Map p) => Container(width: 100, margin: const EdgeInsets.only(left: 15), decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(15)), child: ClipRRect(borderRadius: BorderRadius.circular(15), child: Image.file(File(p['imgs'][0]), fit: BoxFit.cover)));

  Widget _productCard(Map p) => Card(margin: const EdgeInsets.all(10), child: ListTile(
    onTap: () => _buyFlow(p),
    leading: ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.file(File(p['imgs'][0]), width: 60, height: 60, fit: BoxFit.cover)),
    title: Text(p['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
    subtitle: Text("₹${p['price']} | ⭐ 4.8", style: const TextStyle(color: Colors.redAccent)),
    trailing: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent), onPressed: () => _buyFlow(p), child: const Text("BUY", style: TextStyle(color: Colors.white))),
  ));

  Widget _expertView() => ListView(children: [
    if (pro != null) Card(margin: const EdgeInsets.all(15), child: ListTile(leading: CircleAvatar(backgroundImage: FileImage(File(pro!['img']))), title: Text(pro!['name']), subtitle: Text(pro!['job']), trailing: ElevatedButton(onPressed: (){}, child: const Text("HIRE"))))
  ]);

  void _buyFlow(Map p) {
    showModalBottomSheet(context: context, builder: (c) => Padding(padding: const EdgeInsets.all(25), child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Text("Order Tracking", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.redAccent)),
      const SizedBox(height: 10),
      const LinearProgressIndicator(value: 0.3, color: Colors.green),
      const Padding(padding: EdgeInsets.all(15), child: Text("Status: Merchant Packing Your Order")),
      ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text("CONFIRM PURCHASE")),
    ])));
  }

  void _settings(context) {
    showModalBottomSheet(context: context, builder: (c) => Column(mainAxisSize: MainAxisSize.min, children: [
      ListTile(leading: Icon(widget.mode == ThemeMode.light ? Icons.dark_mode : Icons.light_mode), title: const Text("Switch Theme"), onTap: () { Navigator.pop(context); widget.toggleTheme(); }),
      ListTile(leading: const Icon(Icons.logout, color: Colors.red), title: const Text("Logout"), onTap: () async { SharedPreferences prefs = await SharedPreferences.getInstance(); await prefs.remove('userRole'); Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (c) => RoleSelectionPage(toggleTheme: widget.toggleTheme)), (r) => false); }),
    ]));
  }

  void _openAI() {
    showModalBottomSheet(context: context, builder: (c) => Container(height: 300, padding: const EdgeInsets.all(20), child: const Center(child: Text("AI: Hello! How can I help you?"))));
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
    appBar: AppBar(title: const Text("CONSOLE"), actions: [
      IconButton(icon: const Icon(Icons.account_circle_outlined), onPressed: () => showModalBottomSheet(context: context, isScrollControlled: true, builder: (c) => const ProfileSheet(role: 'shop'))),
    ]),
    body: ListView(padding: const EdgeInsets.all(20), children: [
      const Text("Add New Product", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.redAccent)),
      GestureDetector(
        onTap: () async {
          final p = await ImagePicker().pickMultiImage();
          if (p.isNotEmpty) setState(() => _imgs = p.map((f)=>f.path).toList());
        },
        child: Container(height: 100, decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(15)), child: _imgs.isEmpty ? const Icon(Icons.add_a_photo) : ListView(scrollDirection: Axis.horizontal, children: _imgs.map((f)=>Image.file(File(f))).toList())),
      ),
      TextField(controller: _n, decoration: const InputDecoration(labelText: "Product Name")),
      Row(children: [Expanded(child: TextField(controller: _p, decoration: const InputDecoration(labelText: "Price"))), Expanded(child: TextField(controller: _d, decoration: const InputDecoration(labelText: "Disc%"))), Expanded(child: TextField(controller: _q, decoration: const InputDecoration(labelText: "Qty")))]),
      ElevatedButton(onPressed: _save, style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent), child: const Text("LIST PRODUCT")),
      const Divider(height: 40),
      ...products.asMap().entries.map((e) => Card(child: ListTile(leading: Image.file(File(e.value['imgs'][0]), width: 40), title: Text(e.value['name']), trailing: IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () async { products.removeAt(e.key); SharedPreferences prefs = await SharedPreferences.getInstance(); await prefs.setString('global_products', json.encode(products)); _load(); })))).toList()
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
  String name = "Set Profile";
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
    appBar: AppBar(title: const Text("PARTNER PANEL"), actions: [
      IconButton(icon: const Icon(Icons.account_circle_outlined), onPressed: () async { await showModalBottomSheet(context: context, isScrollControlled: true, builder: (c) => const ProfileSheet(role: 'pro')); _load(); }),
    ]),
    body: Column(children: [
      Container(margin: const EdgeInsets.all(20), padding: const EdgeInsets.all(25), decoration: BoxDecoration(color: Colors.redAccent, borderRadius: BorderRadius.circular(30)), child: Column(children: [
        CircleAvatar(radius: 50, backgroundImage: img != null ? FileImage(img!) : null),
        Text(name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
        const Text("TRINITY VERIFIED EXPERT", style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
      ])),
      SwitchListTile(title: const Text("Available for Work"), value: online, activeColor: Colors.green, onChanged: (v) async {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setBool('pro_status', v); setState(() => online = v);
      }),
      const Padding(padding: EdgeInsets.all(20), child: TextField(decoration: InputDecoration(labelText: "Enter Work Completion OTP", border: OutlineInputBorder())))
    ]),
  );
}

// --- ROLE SELECTION & LOGIN ---
class RoleSelectionPage extends StatelessWidget {
  final VoidCallback toggleTheme;
  const RoleSelectionPage({super.key, required this.toggleTheme});
  @override
  Widget build(BuildContext context) => Scaffold(body: Container(width: double.infinity, decoration: const BoxDecoration(gradient: LinearGradient(colors: [Colors.black, Color(0xFF330000)])), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
    const Text("THE TRINITY", style: TextStyle(color: Colors.white, fontSize: 35, fontWeight: FontWeight.bold)),
    const SizedBox(height: 30),
    _btn(context, "Shopkeeper"), _btn(context, "Customer"), _btn(context, "Professional"),
  ])));
  Widget _btn(context, String r) => Padding(padding: const EdgeInsets.all(10), child: ElevatedButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (c) => LoginPage(role: r, toggleTheme: toggleTheme))), child: Text(r)));
}

class LoginPage extends StatelessWidget {
  final String role; final VoidCallback toggleTheme;
  const LoginPage({super.key, required this.role, required this.toggleTheme});
  @override
  Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: Text(role)), body: Center(child: ElevatedButton(onPressed: () async {
    SharedPreferences prefs = await SharedPreferences.getInstance(); await prefs.setString('userRole', role);
    Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (c) => SplashScreen(toggleTheme: toggleTheme, mode: ThemeMode.dark)), (r) => false);
  }, child: const Text("LOGIN"))));
}
