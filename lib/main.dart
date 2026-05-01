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
      theme: ThemeData(useMaterial3: true, colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1A237E))),
      darkTheme: ThemeData.dark(useMaterial3: true),
      home: SplashScreen(toggleTheme: _toggleTheme, mode: _themeMode),
    );
  }
}

// --- SHARED HEADER ---
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
        IconButton(icon: const Icon(Icons.logout, color: Colors.red), onPressed: () async {
          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.remove('userRole');
          Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (c) => RoleSelectionPage(toggleTheme: onTheme)), (r) => false);
        }),
      ],
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
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    if (role != null) {
      Widget next = role == 'Shopkeeper' ? ShopDashboard(onTheme: widget.toggleTheme, mode: widget.mode) : 
                    role == 'Professional' ? ProDashboard(onTheme: widget.toggleTheme, mode: widget.mode) : 
                    CustomerDashboard(onTheme: widget.toggleTheme, mode: widget.mode);
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (c) => next));
    } else {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (c) => RoleSelectionPage(toggleTheme: widget.toggleTheme)));
    }
  }
  @override
  Widget build(BuildContext context) => const Scaffold(body: Center(child: Text("THE TRINITY", style: TextStyle(fontSize: 40, fontWeight: FontWeight.w900))));
}

// --- ROLE SELECTION ---
class RoleSelectionPage extends StatelessWidget {
  final VoidCallback toggleTheme;
  const RoleSelectionPage({super.key, required this.toggleTheme});
  @override
  Widget build(BuildContext context) => Scaffold(
    body: Container(
      width: double.infinity,
      decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF1A237E), Color(0xFF3949AB)])),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Text("Luxury Market Hub", style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
        const SizedBox(height: 40),
        _btn(context, "Shopkeeper", Icons.storefront),
        _btn(context, "Customer", Icons.shopping_bag),
        _btn(context, "Professional", Icons.handyman),
      ]),
    ),
  );
  Widget _btn(context, r, i) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 10),
    child: Card(child: ListTile(title: Text(r), leading: Icon(i), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => LoginPage(role: r, toggleTheme: toggleTheme))))),
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
  bool sent = false;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text("${widget.role} Login")),
    body: Padding(padding: const EdgeInsets.all(30), child: Column(children: [
      TextField(controller: _idC, decoration: const InputDecoration(labelText: "Email or Phone")),
      if (sent) const SizedBox(height: 15),
      if (sent) TextField(controller: _otpC, decoration: const InputDecoration(labelText: "OTP (123456)")),
      const SizedBox(height: 20),
      ElevatedButton(onPressed: () async {
        if (!sent) setState(() => sent = true);
        else if (_otpC.text == "123456") {
          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setString('userRole', widget.role);
          await prefs.setString('user_id', _idC.text);
          Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (c) => SplashScreen(toggleTheme: widget.toggleTheme, mode: ThemeMode.light)), (r) => false);
        }
      }, child: Text(sent ? "LOGIN" : "GET OTP"))
    ])),
  );
}

// --- SHOPKEEPER DASHBOARD ---
class ShopDashboard extends StatefulWidget {
  final VoidCallback onTheme; final ThemeMode mode;
  const ShopDashboard({super.key, required this.onTheme, required this.mode});
  @override
  State<ShopDashboard> createState() => _ShopDashboardState();
}

class _ShopDashboardState extends State<ShopDashboard> {
  String sName = ""; List products = [];
  final _nC = TextEditingController(), _pC = TextEditingController(), _dC = TextEditingController(), _qC = TextEditingController();
  List<String> _tempImgs = [];
  @override
  void initState() { super.initState(); _load(); }
  _load() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      sName = prefs.getString('shop_name') ?? "";
      String? data = prefs.getString('shop_products');
      if (data != null) products = json.decode(data);
    });
  }
  _saveP() async {
    products.add({'name': _nC.text, 'price': _pC.text, 'disc': _dC.text, 'qty': _qC.text, 'imgs': _tempImgs, 'shop': sName});
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('shop_products', json.encode(products));
    setState(() { _nC.clear(); _pC.clear(); _dC.clear(); _qC.clear(); _tempImgs = []; });
  }
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: DashboardHeader(title: "Shop Hub", onTheme: widget.onTheme, mode: widget.mode, onProfile: (){}),
    body: sName.isEmpty ? _setup() : _inventory(),
  );
  Widget _setup() => Padding(padding: const EdgeInsets.all(40), child: Column(children: [
    TextField(onChanged: (v) => sName = v, decoration: const InputDecoration(labelText: "Shop Name")),
    ElevatedButton(onPressed: () async { SharedPreferences prefs = await SharedPreferences.getInstance(); await prefs.setString('shop_name', sName); _load(); }, child: const Text("Open Shop"))
  ]));
  Widget _inventory() => ListView(padding: const EdgeInsets.all(20), children: [
    GestureDetector(onTap: () async { final p = await ImagePicker().pickMultiImage(); if (p.isNotEmpty) setState(() => _tempImgs = p.map((f)=>f.path).toList()); }, child: Container(height: 100, color: Colors.grey[200], child: _tempImgs.isEmpty ? const Icon(Icons.add_a_photo) : ListView(scrollDirection: Axis.horizontal, children: _tempImgs.map((f)=>Image.file(File(f))).toList()))),
    TextField(controller: _nC, decoration: const InputDecoration(labelText: "Item Name")),
    Row(children: [Expanded(child: TextField(controller: _pC, decoration: const InputDecoration(labelText: "Price"))), Expanded(child: TextField(controller: _dC, decoration: const InputDecoration(labelText: "Disc%"))), Expanded(child: TextField(controller: _qC, decoration: const InputDecoration(labelText: "Qty")))]),
    ElevatedButton(onPressed: _saveP, child: const Text("List Product")),
    ...products.asMap().entries.map((e) => Card(child: ListTile(title: Text(e.value['name']), trailing: IconButton(icon: const Icon(Icons.delete), onPressed: (){ setState(()=>products.removeAt(e.key)); _saveP(); })))).toList()
  ]);
}

// --- PROFESSIONAL DASHBOARD ---
class ProDashboard extends StatefulWidget {
  final VoidCallback onTheme; final ThemeMode mode;
  const ProDashboard({super.key, required this.onTheme, required this.mode});
  @override
  State<ProDashboard> createState() => _ProDashboardState();
}

class _ProDashboardState extends State<ProDashboard> {
  String name = "", job = ""; bool online = false; File? photo;
  @override
  void initState() { super.initState(); _load(); }
  _load() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      name = prefs.getString('pro_name') ?? ""; job = prefs.getString('pro_job') ?? "";
      online = prefs.getBool('pro_status') ?? false;
      if (prefs.getString('pro_photo') != null) photo = File(prefs.getString('pro_photo')!);
    });
  }
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: DashboardHeader(title: "Partner Panel", onTheme: widget.onTheme, mode: widget.mode, onProfile: (){}),
    body: name.isEmpty ? _setup() : _idCard(),
  );
  Widget _setup() => Padding(padding: const EdgeInsets.all(40), child: Column(children: [
    GestureDetector(onTap: () async { final p = await ImagePicker().pickImage(source: ImageSource.camera); if (p != null) setState(() => photo = File(p.path)); }, child: CircleAvatar(radius: 50, backgroundImage: photo != null ? FileImage(photo!) : null, child: photo == null ? const Icon(Icons.add_a_photo) : null)),
    TextField(onChanged: (v) => name = v, decoration: const InputDecoration(labelText: "Name")),
    TextField(onChanged: (v) => job = v, decoration: const InputDecoration(labelText: "Skill")),
    ElevatedButton(onPressed: () async { SharedPreferences prefs = await SharedPreferences.getInstance(); await prefs.setString('pro_name', name); await prefs.setString('pro_job', job); if (photo != null) await prefs.setString('pro_photo', photo!.path); _load(); }, child: const Text("Go Online"))
  ]));
  Widget _idCard() => Column(children: [
    Card(color: Colors.indigo, margin: const EdgeInsets.all(20), child: Padding(padding: const EdgeInsets.all(20), child: Column(children: [
      CircleAvatar(radius: 40, backgroundImage: photo != null ? FileImage(photo!) : null),
      Text(name, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
      Text(job.toUpperCase(), style: const TextStyle(color: Colors.white70)),
    ]))),
    SwitchListTile(title: const Text("Available for Work"), value: online, onChanged: (v) async { SharedPreferences prefs = await SharedPreferences.getInstance(); await prefs.setBool('pro_status', v); setState(() => online = v); }),
  ]);
}

// --- CUSTOMER DASHBOARD ---
class CustomerDashboard extends StatefulWidget {
  final VoidCallback onTheme; final ThemeMode mode;
  const CustomerDashboard({super.key, required this.onTheme, required this.mode});
  @override
  State<CustomerDashboard> createState() => _CustomerDashboardState();
}

class _CustomerDashboardState extends State<CustomerDashboard> with SingleTickerProviderStateMixin {
  late TabController _tab; String query = "", cName = "", cAddr = ""; List products = []; Map? pro; bool hasProfile = false;
  @override
  void initState() { super.initState(); _tab = TabController(length: 2, vsync: this); _load(); }
  _load() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      cName = prefs.getString('cust_name') ?? ""; cAddr = prefs.getString('cust_addr') ?? ""; hasProfile = cName.isNotEmpty;
      String? data = prefs.getString('shop_products'); if (data != null) products = json.decode(data);
      if (prefs.getBool('pro_status') ?? false) pro = {'name': prefs.getString('pro_name'), 'job': prefs.getString('pro_job'), 'img': prefs.getString('pro_photo')};
    });
  }
  @override
  Widget build(BuildContext context) {
    final filtered = products.where((p) => p['name'].toString().toLowerCase().contains(query.toLowerCase())).toList();
    return Scaffold(
      appBar: DashboardHeader(title: "Trinity Market", onTheme: widget.onTheme, mode: widget.mode, onProfile: (){}),
      floatingActionButton: FloatingActionButton(onPressed: () => _openAI(context), child: const Icon(Icons.auto_awesome)),
      body: !hasProfile ? _setup() : Column(children: [
        Padding(padding: const EdgeInsets.all(15), child: TextField(onChanged: (v) => setState(() => query = v), decoration: InputDecoration(hintText: "Search Plumber, Taps...", border: OutlineInputBorder(borderRadius: BorderRadius.circular(30))))),
        TabBar(controller: _tab, labelColor: Colors.indigo, tabs: const [Tab(text: "Products"), Tab(text: "Experts")]),
        Expanded(child: TabBarView(controller: _tab, children: [
          ListView.builder(itemCount: filtered.length, itemBuilder: (c, i) => Card(child: ListTile(onTap: () => _zoom(filtered[i]['imgs']), leading: Image.file(File(filtered[i]['imgs'][0]), width: 50, fit: BoxFit.cover), title: Text(filtered[i]['name']), trailing: ElevatedButton(onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Order confirmed!"))), child: const Text("BUY"))))),
          ListView(children: [if (pro != null && pro!['job'].toLowerCase().contains(query.toLowerCase())) Card(child: ListTile(leading: CircleAvatar(backgroundImage: FileImage(File(pro!['img']))), title: Text(pro!['name']), subtitle: Text(pro!['job']), trailing: ElevatedButton(onPressed: (){}, child: const Text("HIRE"))))])
        ]))
      ]),
    );
  }
  Widget _setup() => Padding(padding: const EdgeInsets.all(40), child: Column(children: [TextField(onChanged: (v) => cName = v, decoration: const InputDecoration(labelText: "Name")), TextField(onChanged: (v) => cAddr = v, decoration: const InputDecoration(labelText: "Address")), ElevatedButton(onPressed: () async { SharedPreferences prefs = await SharedPreferences.getInstance(); await prefs.setString('cust_name', cName); await prefs.setString('cust_addr', cAddr); _load(); }, child: const Text("Save"))]));
  void _zoom(List imgs) { showDialog(context: context, builder: (c) => Dialog.fullscreen(child: Stack(children: [PhotoViewGallery.builder(itemCount: imgs.length, builder: (c, i) => PhotoViewGalleryPageOptions(imageProvider: FileImage(File(imgs[i])))), Positioned(top: 40, right: 20, child: IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => Navigator.pop(c)))]))); }
}

void _openAI(BuildContext context) {
  showModalBottomSheet(context: context, isScrollControlled: true, builder: (c) => Container(height: 400, padding: const EdgeInsets.all(20), child: const Column(children: [Text("AI Assistant", style: TextStyle(fontWeight: FontWeight.bold)), Expanded(child: Center(child: Text("How can I help you?")))])));
}
