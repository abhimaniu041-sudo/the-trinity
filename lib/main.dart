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
  void _toggleTheme() => setState(() => _themeMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      themeMode: _themeMode,
      theme: ThemeData(useMaterial3: true, brightness: Brightness.light, colorScheme: ColorScheme.fromSeed(seedColor: Colors.red)),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0A0A0A),
        colorScheme: const ColorScheme.dark(primary: Colors.redAccent, surface: Color(0xFF121212)),
        cardTheme: CardTheme(color: const Color(0xFF1A1A1A), elevation: 10, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
      ),
      home: const SplashScreen(),
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
  void initState() { super.initState(); _init(); }
  _init() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? role = prefs.getString('userRole');
    await Future.delayed(const Duration(seconds: 3));
    if (!mounted) return;
    if (role != null) {
      if (role == 'Shopkeeper') Navigator.pushReplacement(context, MaterialPageRoute(builder: (c) => const ShopDashboard()));
      else if (role == 'Professional') Navigator.pushReplacement(context, MaterialPageRoute(builder: (c) => const ProDashboard()));
      else Navigator.pushReplacement(context, MaterialPageRoute(builder: (c) => const CustomerDashboard()));
    } else {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (c) => const RoleSelectionPage()));
    }
  }
  @override
  Widget build(BuildContext context) => Scaffold(body: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [const Text("THE TRINITY", style: TextStyle(fontSize: 45, fontWeight: FontWeight.w900, color: Colors.redAccent, letterSpacing: 5)), const Text("ULTIMATE BUILD v2.0", style: TextStyle(fontSize: 10, color: Colors.grey, letterSpacing: 2))])));
}

// --- DASHBOARD ACTIONS (GLOBAL) ---
class DashboardHeader extends StatelessWidget implements PreferredSizeWidget {
  final String title, role;
  const DashboardHeader({super.key, required this.title, required this.role});
  @override
  Widget build(BuildContext context) => AppBar(
    title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
    actions: [
      IconButton(icon: const Icon(Icons.person_outline), onPressed: () => showModalBottomSheet(context: context, isScrollControlled: true, builder: (c) => ProfileSheet(role: role))),
      IconButton(icon: const Icon(Icons.settings), onPressed: () => _openSettings(context)),
    ],
  );
  _openSettings(context) => showModalBottomSheet(context: context, builder: (c) => Column(mainAxisSize: MainAxisSize.min, children: [
    ListTile(leading: const Icon(Icons.history), title: const Text("Transaction History")),
    ListTile(leading: const Icon(Icons.logout, color: Colors.red), title: const Text("Logout"), onTap: () async {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.remove('userRole');
      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (c) => const RoleSelectionPage()), (r) => false);
    })
  ]));
  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

// --- 1. CUSTOMER DASHBOARD (TRACKING & BOOKING) ---
class CustomerDashboard extends StatefulWidget {
  const CustomerDashboard({super.key});
  @override
  State<CustomerDashboard> createState() => _CustomerDashboardState();
}

class _CustomerDashboardState extends State<CustomerDashboard> with SingleTickerProviderStateMixin {
  late TabController _tab; String query = ""; List products = []; Map? pro;

  @override
  void initState() { super.initState(); _tab = TabController(length: 2, vsync: this); _load(); }
  _load() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? data = prefs.getString('global_products');
    if (data != null) products = json.decode(data);
    if (prefs.getBool('pro_status') ?? false) pro = {'name': prefs.getString('pro_name'), 'job': prefs.getString('pro_job'), 'img': prefs.getString('pro_img')};
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final filtered = products.where((p) => p['name'].toString().toLowerCase().contains(query.toLowerCase())).toList();
    return Scaffold(
      appBar: const DashboardHeader(title: "Trinity Market", role: 'cust'),
      floatingActionButton: FloatingActionButton(backgroundColor: Colors.redAccent, onPressed: () => _openAI(context), child: const Icon(Icons.auto_awesome, color: Colors.white)),
      body: Column(children: [
        Padding(padding: const EdgeInsets.all(15), child: TextField(onChanged: (v) => setState(() => query = v), decoration: InputDecoration(hintText: "Search anything...", prefixIcon: const Icon(Icons.search), filled: true, fillColor: Colors.white10, border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none)))),
        TabBar(controller: _tab, indicatorColor: Colors.redAccent, tabs: const [Tab(text: "PRODUCTS"), Tab(text: "HIRE EXPERTS")]),
        Expanded(child: TabBarView(controller: _tab, children: [
          _productList(filtered),
          _expertList()
        ]))
      ]),
    );
  }

  Widget _productList(List list) => ListView.builder(itemCount: list.length, itemBuilder: (c, i) => Card(margin: const EdgeInsets.all(10), child: ListTile(
    onTap: () => _showBuyingFlow(list[i]),
    leading: Image.file(File(list[i]['imgs'][0]), width: 50, height: 50, fit: BoxFit.cover),
    title: Text(list[i]['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
    subtitle: Text("₹${list[i]['price']} | ${list[i]['disc']}% Off"),
    trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.redAccent),
  )));

  Widget _expertList() => ListView(children: [
    if (pro != null) Card(margin: const EdgeInsets.all(15), child: ListTile(
      leading: CircleAvatar(backgroundImage: FileImage(File(pro!['img']))),
      title: Text(pro!['name']), subtitle: Text(pro!['job']),
      trailing: ElevatedButton(onPressed: () => _showBookingFlow(pro!), child: const Text("BOOK NOW")),
    ))
  ]);

  void _showBuyingFlow(Map p) {
    showModalBottomSheet(context: context, builder: (c) => Padding(padding: const EdgeInsets.all(25), child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Text("Amazon-Style Tracking", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.redAccent)),
      const SizedBox(height: 10),
      const LinearProgressIndicator(value: 0.3, backgroundColor: Colors.white10, color: Colors.green),
      const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Text("Status: Order Placed (Processing)")),
      const Divider(),
      ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, minimumSize: const Size(double.infinity, 50)), onPressed: () => Navigator.pop(context), child: const Text("CONFIRM PURCHASE")),
    ])));
  }

  void _showBookingFlow(Map pr) {
    showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 7))).then((date) {
      if (date != null) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Expert Booked for ${date.day}/${date.month}!")));
    });
  }
}

// --- 2. SHOPKEEPER DASHBOARD ---
class ShopDashboard extends StatefulWidget {
  const ShopDashboard({super.key});
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
    appBar: const DashboardHeader(title: "Inventory Master", role: 'shop'),
    body: ListView(padding: const EdgeInsets.all(20), children: [
      const Text("Add Stock", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.redAccent)),
      GestureDetector(
        onTap: () async {
          final p = await ImagePicker().pickMultiImage();
          if (p.isNotEmpty) setState(() => _imgs = p.map((f)=>f.path).toList());
        },
        child: Container(height: 100, margin: const EdgeInsets.symmetric(vertical: 10), decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(15)), child: _imgs.isEmpty ? const Icon(Icons.add_a_photo) : ListView(scrollDirection: Axis.horizontal, children: _imgs.map((f)=>Image.file(File(f))).toList())),
      ),
      TextField(controller: _n, decoration: const InputDecoration(labelText: "Item Name")),
      Row(children: [Expanded(child: TextField(controller: _p, decoration: const InputDecoration(labelText: "Price"))), Expanded(child: TextField(controller: _d, decoration: const InputDecoration(labelText: "Disc%"))), Expanded(child: TextField(controller: _q, decoration: const InputDecoration(labelText: "Qty")))]),
      ElevatedButton(onPressed: _save, style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent), child: const Text("LIST PRODUCT")),
      const Divider(height: 40),
      const Text("My Store Ratings: ⭐ 4.8 (120 Reviews)", style: TextStyle(color: Colors.amber, fontSize: 12)),
      ...products.map((p) => Card(child: ListTile(title: Text(p['name']), subtitle: Text("₹${p['price']}")))).toList()
    ]),
  );
}

// --- 3. PROFESSIONAL DASHBOARD (OTP SECURITY) ---
class ProDashboard extends StatefulWidget {
  const ProDashboard({super.key});
  @override
  State<ProDashboard> createState() => _ProDashboardState();
}

class _ProDashboardState extends State<ProDashboard> {
  bool online = false; String name = "Partner"; File? img;
  @override
  void initState() { super.initState(); _load(); }
  _load() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      name = prefs.getString('pro_name') ?? "Expert";
      online = prefs.getBool('pro_status') ?? false;
      String? path = prefs.getString('pro_img'); if (path != null) img = File(path);
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: const DashboardHeader(title: "Partner Hub", role: 'pro'),
    body: Column(children: [
      Container(
        margin: const EdgeInsets.all(20), padding: const EdgeInsets.all(25),
        decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF800000), Colors.black]), borderRadius: BorderRadius.circular(30)),
        child: Column(children: [
          CircleAvatar(radius: 50, backgroundImage: img != null ? FileImage(img!) : null),
          const SizedBox(height: 10),
          Text(name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const Text("VERIFIED EXPERT", style: TextStyle(color: Colors.amber, fontSize: 12, fontWeight: FontWeight.bold)),
        ]),
      ),
      SwitchListTile(title: const Text("Work Availability"), value: online, activeColor: Colors.green, onChanged: (v) async {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setBool('pro_status', v); setState(() => online = v);
      }),
      const Divider(),
      const ListTile(title: Text("Recent Booking"), subtitle: Text("Customer: Abhi | Subah 10:00 AM"), trailing: Icon(Icons.timer, color: Colors.orange)),
      Padding(padding: const EdgeInsets.all(20), child: TextField(decoration: const InputDecoration(labelText: "Enter Completion OTP from Customer", border: OutlineInputBorder()), onSubmitted: (v) {
        if(v == "1234") ScaffoldMessenger.of(context).showSnackBar(const SnackBar(backgroundColor: Colors.green, content: Text("Work Completed! Payment Released.")));
      }))
    ]),
  );
}

// --- SHARED PROFILE SHEET ---
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
    GestureDetector(onTap: () async { final p = await ImagePicker().pickImage(source: ImageSource.gallery); if (p != null) setState(() => _img = File(p.path)); }, child: CircleAvatar(radius: 50, backgroundImage: _img != null ? FileImage(_img!) : null, child: _img == null ? const Icon(Icons.camera_alt) : null)),
    TextField(controller: _n, decoration: const InputDecoration(labelText: "Name")),
    TextField(controller: _p, decoration: const InputDecoration(labelText: "Mobile")),
    TextField(controller: _a, decoration: const InputDecoration(labelText: "Address")),
    const SizedBox(height: 20),
    ElevatedButton(onPressed: () async {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('${widget.role}_name', _n.text);
      await prefs.setString('${widget.role}_phone', _p.text);
      await prefs.setString('${widget.role}_addr', _a.text);
      if (_img != null) await prefs.setString('${widget.role}_img', _img!.path);
      Navigator.pop(context);
    }, child: const Text("SAVE PROFILE")),
    const SizedBox(height: 20)
  ]));
}

// --- AI & ROLE SELECTION (LOGIC ONLY) ---
void _openAI(context) { showModalBottomSheet(context: context, builder: (c) => const Center(child: Text("Trinity Intelligence Online..."))); }

class RoleSelectionPage extends StatelessWidget {
  const RoleSelectionPage({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(body: Container(width: double.infinity, decoration: const BoxDecoration(gradient: LinearGradient(colors: [Colors.black, Color(0xFF400000)])), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
    const Text("SELECT IDENTITY", style: TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.bold)),
    const SizedBox(height: 30),
    ElevatedButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const LoginPage(role: 'Shopkeeper'))), child: const Text("SHOPKEEPER")),
    ElevatedButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const LoginPage(role: 'Customer'))), child: const Text("CUSTOMER")),
    ElevatedButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const LoginPage(role: 'Professional'))), child: const Text("PROFESSIONAL")),
  ])));
}

class LoginPage extends StatelessWidget {
  final String role; const LoginPage({super.key, required this.role});
  @override
  Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: Text(role)), body: Center(child: ElevatedButton(onPressed: () async {
    SharedPreferences prefs = await SharedPreferences.getInstance(); await prefs.setString('userRole', role);
    Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (c) => const SplashScreen()), (r) => false);
  }, child: const Text("LOGIN (BYPASS OTP)"))));
}
