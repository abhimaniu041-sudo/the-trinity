import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'dart:io';
import 'dart:convert';
import 'dart:math';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const TrinityApp());
}

// --- PREMIUM THEME ENGINE ---
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
        inputDecorationTheme: InputDecorationTheme(border: OutlineInputBorder(borderRadius: BorderRadius.circular(15))),
        cardTheme: CardTheme(elevation: 5, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
        appBarTheme: const AppBarTheme(centerTitle: true, elevation: 5, backgroundColor: Colors.indigo, foregroundColor: Colors.white),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo, brightness: Brightness.dark),
        scaffoldBackgroundColor: const Color(0xFF121212),
        cardTheme: CardTheme(elevation: 5, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), color: const Color(0xFF1E1E1E)),
        appBarTheme: const AppBarTheme(centerTitle: true, elevation: 5, backgroundColor: Color(0xFF1F1F1F), foregroundColor: Colors.white),
      ),
      home: SplashScreen(toggleTheme: _toggleTheme, mode: _themeMode),
    );
  }
}

// --- GLOBAL UTILS ---
Future<void> handleLogout(BuildContext context, VoidCallback toggleTheme) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.remove('userRole'); 
  // Inventory and Profile data safe in local storage.
  if (context.mounted) {
    Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => RoleSelectionPage(toggleTheme: toggleTheme)), (route) => false);
  }
}

// Secured calling simulation
Future<void> launchCaller(String number) async {
  final Uri launchUri = Uri(scheme: 'tel', path: number);
  if (await canLaunchUrl(launchUri)) {
    await launchUrl(launchUri);
  }
}

// --- SHARED APP BAR COMPONENT ---
class DashboardHeader extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final VoidCallback onTheme, onProfile;
  final ThemeMode mode;
  final String role;
  const DashboardHeader({super.key, required this.title, required this.onTheme, required this.onProfile, required this.mode, required this.role});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      actions: [
        IconButton(icon: const Icon(Icons.account_circle), onPressed: onProfile),
        IconButton(icon: const Icon(Icons.settings), onPressed: () => _openSettings(context)),
      ],
    );
  }

  void _openSettings(context) {
    showModalBottomSheet(context: context, builder: (c) => Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const ListTile(title: Text("App Settings", style: TextStyle(fontWeight: FontWeight.bold))),
          const Divider(),
          ListTile(
            leading: Icon(mode == ThemeMode.light ? Icons.dark_mode : Icons.light_mode),
            title: Text(mode == ThemeMode.light ? "Switch to Dark Mode" : "Switch to Light Mode"),
            onTap: () { onTheme(); Navigator.pop(context); },
          ),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text("Logout"),
            onTap: () => handleLogout(context, onTheme),
          ),
        ],
      ),
    ));
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
  void initState() { super.initState(); _checkStatus(); }
  _checkStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? role = prefs.getString('userRole');
    await Future.delayed(const Duration(seconds: 3));
    if (mounted) {
      if (role != null) {
        if (role == 'Shopkeeper') Navigator.pushReplacement(context, MaterialPageRoute(builder: (c) => ShopDashboard(toggleTheme: widget.toggleTheme, mode: widget.mode)));
        if (role == 'Customer') Navigator.pushReplacement(context, MaterialPageRoute(builder: (c) => CustomerDashboard(toggleTheme: widget.toggleTheme, mode: widget.mode)));
        if (role == 'Professional') Navigator.pushReplacement(context, MaterialPageRoute(builder: (c) => ProfessionalDashboard(toggleTheme: widget.toggleTheme, mode: widget.mode)));
      } else {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (c) => RoleSelectionPage(toggleTheme: widget.toggleTheme)));
      }
    }
  }
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text("THE TRINITY", style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.indigo)),
          SizedBox(height: 10),
          Text("Hyperlocal Superhub", style: TextStyle(color: Colors.grey)),
        ]),
      ),
    );
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
        padding: const EdgeInsets.all(25),
        decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF1A237E), Color(0xFF3949AB)], begin: Alignment.topCenter)),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Text("Welcome to Trinity", style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
          const SizedBox(height: 50),
          _roleBtn(context, "Shopkeeper", Icons.storefront),
          _roleBtn(context, "Customer", Icons.shopping_bag_rounded),
          _roleBtn(context, "Professional", Icons.engineering_rounded),
        ]),
      ),
    );
  }
  Widget _roleBtn(context, title, icon) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 10),
    child: Card(
      child: ListTile(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => LoginPage(role: title, toggleTheme: toggleTheme))),
        leading: CircleAvatar(backgroundColor: Colors.indigo.withOpacity(0.1), child: Icon(icon, color: Colors.indigo)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        trailing: const Icon(Icons.arrow_forward_ios),
      ),
    ),
  );
}

// --- LOGIN PAGE ---
class LoginPage extends StatelessWidget {
  final String role;
  final VoidCallback toggleTheme;
  LoginPage({super.key, required this.role, required this.toggleTheme});
  final _nC = TextEditingController();
  final _oC = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("$role Login")),
      body: Padding(padding: const EdgeInsets.all(25), child: Column(children: [
        const Text("Enter Email/Mobile and OTP", style: TextStyle(fontSize: 16)),
        const SizedBox(height: 30),
        TextField(controller: _nC, decoration: const InputDecoration(labelText: "Mobile or Email")),
        const SizedBox(height: 15),
        TextField(controller: _oC, decoration: const InputDecoration(labelText: "OTP (Demo: 123456)")),
        const SizedBox(height: 30),
        SizedBox(width: double.infinity, height: 50, child: ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white),
          onPressed: () async {
            if (_oC.text == "123456") {
              SharedPreferences prefs = await SharedPreferences.getInstance();
              await prefs.setString('userRole', role);
              await prefs.setString('user_id', _nC.text);
              if (context.mounted) {
                if (role == 'Shopkeeper') Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (c) => ShopDashboard(toggleTheme: toggleTheme, mode: ThemeMode.light)), (r) => false);
                if (role == 'Customer') Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (c) => CustomerDashboard(toggleTheme: toggleTheme, mode: ThemeMode.light)), (r) => false);
                if (role == 'Professional') Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (c) => ProfessionalDashboard(toggleTheme: toggleTheme, mode: ThemeMode.light)), (r) => false);
              }
            }
          }, child: const Text("AUTHENTICATE"))),
      ])),
    );
  }
}

// --- SHARED PROFILE SHEET ---
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
      Navigator.pop(context, true);
    }, child: const Text("SAVE PROFILE")),
    const SizedBox(height: 20)
  ]));
}

// --- 1. SHOPKEEPER DASHBOARD (DISCOUNT + MULTI-IMAGE + STOCK + LEADS) ---
class ShopDashboard extends StatefulWidget {
  final VoidCallback toggleTheme;
  final ThemeMode mode;
  const ShopDashboard({super.key, required this.toggleTheme, required this.mode});
  @override
  State<ShopDashboard> createState() => _ShopDashboardState();
}

class _ShopDashboardState extends State<ShopDashboard> {
  final _dukaanC = TextEditingController(), _sLocC = TextEditingController(), _pNC = TextEditingController(), _pPC = TextEditingController(), _pDC = TextEditingController(), _pQC = TextEditingController();
  final picker = ImagePicker();
  File? _dukaanPhoto;
  List<String> _productImages = [];
  List products = [], leads = [];
  bool hasProfile = false;

  @override
  void initState() { super.initState(); _load(); }
  _load() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _dukaanC.text = prefs.getString('shop_name') ?? "";
      if (prefs.getString('shop_photo') != null) _dukaanPhoto = File(prefs.getString('shop_photo')!);
      if (_dukaanC.text.isNotEmpty) hasProfile = true;
      String? data = prefs.getString('shop_products');
      if (data != null) products = json.decode(data);
      String? lData = prefs.getString('shop_leads');
      if (lData != null) leads = json.decode(lData);
    });
  }

  _pickDukaanPhoto() async {
    final p = await picker.pickImage(source: ImageSource.gallery);
    if (p != null) setState(() => _dukaanPhoto = File(p.path));
  }
  _pickProductsImages() async {
    final p = await picker.pickMultiImage();
    if (p.isNotEmpty) setState(() => _productImages = p.map((f)=>f.path).toList());
  }

  _saveProfile() async {
    if (_dukaanPhoto == null) return;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('shop_name', _dukaanC.text);
    await prefs.setString('shop_loc', _sLocC.text);
    await prefs.setString('shop_photo', _dukaanPhoto!.path);
    _load();
  }

  _saveProduct() async {
    if (_pNC.text.isEmpty || _productImages.isEmpty) return;
    int disc = int.tryParse(_pDC.text) ?? 0;
    products.add({'name': _pNC.text, 'price': _pPC.text, 'disc': disc, 'stock': _pQC.text, 'imgs': _productImages, 'shop': _dukaanC.text});
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('shop_products', json.encode(products));
    setState(() { _pNC.clear(); _pPC.clear(); _pDC.clear(); _pQC.clear(); _productImages = []; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: DashboardHeader(title: "Trinity Store", onTheme: widget.toggleTheme, mode: widget.mode, role: 'shop', onProfile: _editProfile),
      floatingActionButton: FloatingActionButton(onPressed: () => _openAI(context), child: const Icon(Icons.auto_awesome)),
      body: SingleChildScrollView(padding: const EdgeInsets.all(15), child: !hasProfile ? _profileSetup() : _mainView()),
    );
  }

  Widget _profileSetup() => Column(children: [
    const Text("Register Your Shop", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
    GestureDetector(onTap: _pickDukaanPhoto, child: CircleAvatar(radius: 60, backgroundImage: _dukaanPhoto != null ? FileImage(_dukaanPhoto!) : null, child: _dukaanPhoto == null ? const Icon(Icons.add_a_photo) : null)),
    TextField(controller: _dukaanC, decoration: const InputDecoration(hintText: "Dukaan Name")),
    TextField(controller: _sLocC, decoration: const InputDecoration(hintText: "Full Location")),
    ElevatedButton(onPressed: _saveProfile, child: const Text("Create Profile"))
  ]);

  Widget _mainView() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Container(padding: const EdgeInsets.all(15), decoration: BoxDecoration(color: Colors.indigo[50], borderRadius: BorderRadius.circular(15)), child: Row(children: [
      CircleAvatar(backgroundImage: _dukaanPhoto != null ? FileImage(_dukaanPhoto!) : null),
      const SizedBox(width: 10), Text(_dukaanC.text, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18))
    ])),
    const SizedBox(height: 20),
    const Text("Add New Inventory", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
    const SizedBox(height: 10),
    GestureDetector(onTap: _pickProductsImages, child: Container(height: 80, width: double.infinity, color: Colors.grey[200], child: _productImages.isEmpty ? const Icon(Icons.add_photo_alternate) : ListView(scrollDirection: Axis.horizontal, children: _productImages.map((f)=>Image.file(File(f))).toList()))),
    TextField(controller: _pNC, decoration: const InputDecoration(hintText: "Item Name")),
    Row(children: [
      Expanded(child: TextField(controller: _pPC, decoration: const InputDecoration(hintText: "Price"))),
      Expanded(child: TextField(controller: _pDC, decoration: const InputDecoration(hintText: "Discount %"))),
      Expanded(child: TextField(controller: _pQC, decoration: const InputDecoration(hintText: "Stock Qty"))),
    ]),
    ElevatedButton(onPressed: _saveProduct, child: const Text("Save Product")),
    const Divider(),
    const Text("Active Inventory:", style: TextStyle(fontWeight: FontWeight.bold)),
    ...products.asMap().entries.map((e) => Card(child: ListTile(leading: Image.file(File(e.value['imgs'][0]), width: 40, fit: BoxFit.cover), title: Text("${e.value['name']} (Qty: ${e.value['stock']})"), trailing: Text("₹${e.value['price']}")))).toList(),
    const Divider(),
    const Text("New Orders/Leads:", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
    ...leads.map((l) => Card(color: Colors.green[50], child: ListTile(title: Text("Item: ${l['item']}"), subtitle: Text("Customer: ${l['cust']}\nAddr: ${l['addr']}")))).toList()
  ]);

  void _editProfile() async {
     bool? res = await showModalBottomSheet(context: context, isScrollControlled: true, builder: (c) => const ProfileSheet(role: 'shop'));
     if (res == true) _load();
  }
}

// --- 2. PROFESSIONAL DASHBOARD (ID CARD, AVAILABILITY, LEADS) ---
class ProfessionalDashboard extends StatefulWidget {
  final VoidCallback toggleTheme;
  final ThemeMode mode;
  const ProfessionalDashboard({super.key, required this.toggleTheme, required this.mode});
  @override
  State<ProfessionalDashboard> createState() => _ProfessionalDashboardState();
}

class _ProfessionalDashboardState extends State<ProfessionalDashboard> {
  final _nameC = TextEditingController(), _jtC = TextEditingController();
  File? _photo; String name = "", job = "", id = "";
  bool hasProfile = false, online = false, leadAccept = false;

  @override
  void initState() { super.initState(); _load(); }
  _load() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      name = prefs.getString('pro_name') ?? ""; job = prefs.getString('pro_job') ?? "";
      id = prefs.getString('user_id') ?? ""; online = prefs.getBool('pro_status') ?? false;
      if (prefs.getString('pro_photo') != null) _photo = File(prefs.getString('pro_photo')!);
      if (name.isNotEmpty) hasProfile = true;
    });
  }

  _saveProfile() async {
    if (_nameC.text.isEmpty || _jtC.text.isEmpty) return;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('pro_name', _nameC.text);
    await prefs.setString('pro_job', _jtC.text);
    if (_photo != null) await prefs.setString('pro_photo', _photo!.path);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: DashboardHeader(title: "Partner Panel", onTheme: widget.toggleTheme, mode: widget.mode, role: 'pro', onProfile: _editProfile),
      floatingActionButton: FloatingActionButton(onPressed: () => _openAI(context), child: const Icon(Icons.auto_awesome)),
      body: SingleChildScrollView(padding: const EdgeInsets.all(15), child: !hasProfile ? _profileSetup() : _mainProView()),
    );
  }

  Widget _profileSetup() => Column(children: [
    const Text("Expert Profile Setup", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
    GestureDetector(onTap: () async {
      final p = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (p != null) setState(() => _photo = File(p.path));
    }, child: CircleAvatar(radius: 60, backgroundImage: _photo != null ? FileImage(_photo!) : null, child: _photo == null ? const Icon(Icons.add_a_photo) : null)),
    TextField(controller: _nameC, decoration: const InputDecoration(hintText: "Full Name")),
    TextField(controller: _jtC, decoration: const InputDecoration(hintText: "Job Title (Plumber, Electrician)")),
    ElevatedButton(onPressed: _saveProfile, child: const Text("Go Live"))
  ]);

  Widget _mainProView() => Column(children: [
    Card(color: Colors.indigo, child: Padding(padding: const EdgeInsets.all(20), child: Column(children: [
      CircleAvatar(radius: 40, backgroundImage: _photo != null ? FileImage(_photo!) : null),
      Text(name, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
      Text(job.toUpperCase(), style: const TextStyle(color: Colors.white70)),
      const Divider(color: Colors.white24),
      Text("ID: $id", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
    ]))),
    SwitchListTile(title: Text(online ? "YOU ARE ONLINE (Lead Mode)" : "YOU ARE OFFLINE", style: TextStyle(color: online ? Colors.green : Colors.red, fontWeight: FontWeight.bold)), value: online, onChanged: (v) async {
       SharedPreferences prefs = await SharedPreferences.getInstance();
       await prefs.setBool('pro_status', v); setState(() => online = v);
    }),
    Card(color: Colors.green[50], child: ListTile(title: const Text("New Service Request"), subtitle: const Text("Sector 22 Chandigarh | Tap Fitting"),
