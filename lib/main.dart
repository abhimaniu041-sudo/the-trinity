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
  ThemeMode _themeMode = ThemeMode.dark; // Default Premium Dark

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
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.red, brightness: Brightness.light),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0F0F0F),
        // FIXED: Correct CardThemeData syntax for build success
        cardTheme: CardThemeData(
          color: const Color(0xFF1E1E1E),
          elevation: 8,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
      ),
      home: SplashScreen(toggleTheme: _toggleTheme),
    );
  }
}

// --- SHARED PROFILE EDITOR ---
class ProfileEditor extends StatefulWidget {
  final String roleKey;
  const ProfileEditor({super.key, required this.roleKey});
  @override
  State<ProfileEditor> createState() => _ProfileEditorState();
}

class _ProfileEditorState extends State<ProfileEditor> {
  final _name = TextEditingController(), _phone = TextEditingController(), _addr = TextEditingController();
  File? _image;

  @override
  void initState() { super.initState(); _load(); }
  _load() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _name.text = prefs.getString('${widget.roleKey}_name') ?? "";
      _phone.text = prefs.getString('${widget.roleKey}_phone') ?? "";
      _addr.text = prefs.getString('${widget.roleKey}_addr') ?? "";
      String? path = prefs.getString('${widget.roleKey}_img');
      if (path != null) _image = File(path);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 25, right: 25, top: 25),
      child: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text("Edit Profile", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.redAccent)),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: () async {
              final p = await ImagePicker().pickImage(source: ImageSource.gallery);
              if (p != null) setState(() => _image = File(p.path));
            },
            child: CircleAvatar(radius: 60, backgroundImage: _image != null ? FileImage(_image!) : null, child: _image == null ? const Icon(Icons.camera_alt) : null),
          ),
          TextField(controller: _name, decoration: const InputDecoration(labelText: "Full Name")),
          TextField(controller: _phone, decoration: const InputDecoration(labelText: "Phone")),
          TextField(controller: _addr, decoration: const InputDecoration(labelText: "Address")),
          const SizedBox(height: 20),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 50)),
            onPressed: () async {
              SharedPreferences prefs = await SharedPreferences.getInstance();
              await prefs.setString('${widget.roleKey}_name', _name.text);
              await prefs.setString('${widget.roleKey}_phone', _phone.text);
              await prefs.setString('${widget.roleKey}_addr', _addr.text);
              if (_image != null) await prefs.setString('${widget.roleKey}_img', _image!.path);
              Navigator.pop(context, true);
            },
            child: const Text("SAVE PROFILE"),
          ),
          const SizedBox(height: 20),
        ]),
      ),
    );
  }
}

// --- SPLASH SCREEN ---
class SplashScreen extends StatefulWidget {
  final VoidCallback toggleTheme;
  const SplashScreen({super.key, required this.toggleTheme});
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
    if (role == 'Shopkeeper') Navigator.pushReplacement(context, MaterialPageRoute(builder: (c) => ShopDashboard(toggleTheme: widget.toggleTheme)));
    else if (role == 'Professional') Navigator.pushReplacement(context, MaterialPageRoute(builder: (c) => ProDashboard(toggleTheme: widget.toggleTheme)));
    else if (role == 'Customer') Navigator.pushReplacement(context, MaterialPageRoute(builder: (c) => CustomerDashboard(toggleTheme: widget.toggleTheme)));
    else Navigator.pushReplacement(context, MaterialPageRoute(builder: (c) => RoleSelectionPage(toggleTheme: widget.toggleTheme)));
  }
  @override
  Widget build(BuildContext context) => const Scaffold(body: Center(child: Text("THE TRINITY", style: TextStyle(fontSize: 40, fontWeight: FontWeight.w900, color: Colors.redAccent))));
}

// --- ROLE SELECTION ---
class RoleSelectionPage extends StatelessWidget {
  final VoidCallback toggleTheme;
  const RoleSelectionPage({super.key, required this.toggleTheme});
  @override
  Widget build(BuildContext context) => Scaffold(
    body: Container(
      width: double.infinity,
      decoration: const BoxDecoration(gradient: LinearGradient(colors: [Colors.black, Color(0xFF330000)], begin: Alignment.topCenter)),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Text("The Trinity Hub", style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
        const SizedBox(height: 50),
        _btn(context, "Shopkeeper", Icons.storefront),
        _btn(context, "Customer", Icons.person),
        _btn(context, "Professional", Icons.handyman),
      ]),
    ),
  );
  Widget _btn(context, r, i) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 10),
    child: Card(child: ListTile(title: Text(r), leading: Icon(i, color: Colors.redAccent), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => LoginPage(role: r, toggleTheme: toggleTheme))))),
  );
}

// --- LOGIN ---
class LoginPage extends StatefulWidget {
  final String role; final VoidCallback toggleTheme;
  const LoginPage({super.key, required this.role, required this.toggleTheme});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _id = TextEditingController(); final _otp = TextEditingController(); bool sent = false;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text("${widget.role} Login")),
    body: Padding(padding: const EdgeInsets.all(30), child: Column(children: [
      TextField(controller: _id, decoration: const InputDecoration(labelText: "Email/Phone", border: OutlineInputBorder())),
      if (sent) const SizedBox(height: 15),
      if (sent) TextField(controller: _otp, decoration: const InputDecoration(labelText: "OTP (123456)", border: OutlineInputBorder())),
      const SizedBox(height: 30),
      ElevatedButton(onPressed: () async {
        if (!sent) setState(() => sent = true);
        else if (_otp.text == "123456") {
          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setString('userRole', widget.role);
          Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (c) => SplashScreen(toggleTheme: widget.toggleTheme)), (r) => false);
        }
      }, style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 55)), child: Text(sent ? "LOGIN" : "GET OTP"))
    ])),
  );
}

// --- SHOPKEEPER DASHBOARD ---
class ShopDashboard extends StatefulWidget {
  final VoidCallback toggleTheme;
  const ShopDashboard({super.key, required this.toggleTheme});
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
    appBar: AppBar(title: const Text("Store Console"), actions: [
      IconButton(icon: const Icon(Icons.person), onPressed: () => showModalBottomSheet(context: context, isScrollControlled: true, builder: (c) => const ProfileEditor(roleKey: 'shop'))),
      IconButton(icon: const Icon(Icons.settings), onPressed: () => _openSettings(context)),
    ]),
    body: ListView(padding: const EdgeInsets.all(20), children: [
      GestureDetector(
        onTap: () async {
          final p = await ImagePicker().pickMultiImage();
          if (p.isNotEmpty) setState(() => _imgs = p.map((f)=>f.path).toList());
        },
        child: Container(height: 100, color: Colors.white10, child: _imgs.isEmpty ? const Icon(Icons.add_a_photo) : ListView(scrollDirection: Axis.horizontal, children: _imgs.map((f)=>Image.file(File(f))).toList())),
      ),
      TextField(controller: _n, decoration: const InputDecoration(labelText: "Product Name")),
      Row(children: [Expanded(child: TextField(controller: _p, decoration: const InputDecoration(labelText: "Price"))), Expanded(child: TextField(controller: _d, decoration: const InputDecoration(labelText: "Disc%"))), Expanded(child: TextField(controller: _q, decoration: const InputDecoration(labelText: "Qty")))]),
      ElevatedButton(onPressed: _save, style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white), child: const Text("LIST PRODUCT")),
      const Divider(height: 40),
      ...products.asMap().entries.map((e) => Card(child: ListTile(title: Text(e.value['name']), subtitle: Text("₹${e.value['price']}"), trailing: IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () async { products.removeAt(e.key); SharedPreferences prefs = await SharedPreferences.getInstance(); await prefs.setString('global_products', json.encode(products)); _load(); })))).toList()
    ]),
  );

  void _openSettings(context) {
    showModalBottomSheet(context: context, builder: (c) => Column(mainAxisSize: MainAxisSize.min, children: [
      ListTile(leading: const Icon(Icons.brightness_6), title: const Text("Toggle Theme"), onTap: widget.toggleTheme),
      ListTile(leading: const Icon(Icons.logout, color: Colors.red), title: const Text("Logout"), onTap: () async { SharedPreferences prefs = await SharedPreferences.getInstance(); await prefs.remove('userRole'); Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (c) => const RoleSelectionPage()), (r) => false); }),
    ]));
  }
}

// --- PROFESSIONAL DASHBOARD ---
class ProDashboard extends StatefulWidget {
  final VoidCallback toggleTheme;
  const ProDashboard({super.key, required this.toggleTheme});
  @override
  State<ProDashboard> createState() => _ProDashboardState();
}

class _ProDashboardState extends State<ProDashboard> {
  String name = "Set Name", job = "Set Job"; bool online = false; File? img; bool hasProfile = false;

  @override
  void initState() { super.initState(); _load(); }
  _load() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      name = prefs.getString('pro_name') ?? "Set Name";
      job = prefs.getString('pro_job') ?? "Set Job";
      online = prefs.getBool('pro_status') ?? false;
      hasProfile = prefs.containsKey('pro_name');
      String? p = prefs.getString('pro_img'); if (p != null) img = File(p);
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text("Partner Panel"), actions: [
      IconButton(icon: const Icon(Icons.settings), onPressed: () => _openSettings(context)),
    ]),
    body: !hasProfile ? _setup() : _mainPro(),
  );

  Widget _setup() => Padding(padding: const EdgeInsets.all(30), child: Column(children: [
    GestureDetector(onTap: () async { final p = await ImagePicker().pickImage(source: ImageSource.camera); if (p != null) setState(() => img = File(p.path)); }, child: CircleAvatar(radius: 50, backgroundImage: img != null ? FileImage(img!) : null, child: const Icon(Icons.camera_alt))),
    TextField(onChanged: (v) => name = v, decoration: const InputDecoration(labelText: "Full Name")),
    TextField(onChanged: (v) => job = v, decoration: const InputDecoration(labelText: "Job Title")),
    ElevatedButton(onPressed: () async { SharedPreferences prefs = await SharedPreferences.getInstance(); await prefs.setString('pro_name', name); await prefs.setString('pro_job', job); if (img != null) await prefs.setString('pro_img', img!.path); _load(); }, child: const Text("Create ID"))
  ]));

  Widget _mainPro() => Column(children: [
    Container(margin: const EdgeInsets.all(20), padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: Colors.redAccent, borderRadius: BorderRadius.circular(20)), child: Column(children: [
      CircleAvatar(radius: 40, backgroundImage: img != null ? FileImage(img!) : null),
      Text(name, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
      Text(job.toUpperCase(), style: const TextStyle(color: Colors.white70)),
    ])),
    SwitchListTile(title: const Text("Available for Work"), value: online, onChanged: (v) async { SharedPreferences prefs = await SharedPreferences.getInstance(); await prefs.setBool('pro_status', v); setState(() => online = v); }),
  ]);

  void _openSettings(context) {
    showModalBottomSheet(context: context, builder: (c) => Column(mainAxisSize: MainAxisSize.min, children: [
      ListTile(leading: const Icon(Icons.brightness_6), title: const Text("Toggle Theme"), onTap: widget.toggleTheme),
      ListTile(leading: const Icon(Icons.logout, color: Colors.red), title: const Text("Logout"), onTap: () async { SharedPreferences prefs = await SharedPreferences.getInstance(); await prefs.remove('userRole'); Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (c) => const RoleSelectionPage()), (r) => false); }),
    ]));
  }
}

// --- CUSTOMER DASHBOARD ---
class CustomerDashboard extends StatefulWidget {
  final VoidCallback toggleTheme;
  const CustomerDashboard({super.key, required this.toggleTheme});
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
      appBar: AppBar(title: const Text("Marketplace"), actions: [
        IconButton(icon: const Icon(Icons.person), onPressed: () => showModalBottomSheet(context: context, isScrollControlled
