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

  // Global Theme Toggle Function
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
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1A237E)),
        cardTheme: CardThemeData(elevation: 4, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
      ),
      darkTheme: ThemeData.dark(useMaterial3: true).copyWith(
        cardTheme: CardThemeData(elevation: 4, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
      ),
      home: SplashScreen(toggleTheme: _toggleTheme),
    );
  }
}

// --- GLOBAL SHARED LOGIC ---
class AppActions {
  static void openSettings(BuildContext context, VoidCallback onToggle) {
    showModalBottomSheet(context: context, builder: (c) => Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text("App Settings", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.brightness_6),
            title: const Text("Toggle Dark/Light Mode"),
            onTap: () { onToggle(); Navigator.pop(context); },
          ),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text("Logout"),
            onTap: () async {
              SharedPreferences prefs = await SharedPreferences.getInstance();
              await prefs.remove('userRole');
              Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (c) => const RoleSelectionPage()), (r) => false);
            },
          ),
        ],
      ),
    ));
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
    if (role != null) {
      _navToDashboard(role);
    } else {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (c) => RoleSelectionPage(toggleTheme: widget.toggleTheme)));
    }
  }

  _navToDashboard(String role) {
    Widget next;
    if (role == 'Shopkeeper') next = ShopDashboard(toggleTheme: widget.toggleTheme);
    else if (role == 'Professional') next = ProDashboard(toggleTheme: widget.toggleTheme);
    else next = CustomerDashboard(toggleTheme: widget.toggleTheme);
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (c) => next));
  }

  @override
  Widget build(BuildContext context) => const Scaffold(body: Center(child: Text("THE TRINITY", style: TextStyle(fontSize: 40, fontWeight: FontWeight.w900, color: Color(0xFF1A237E)))));
}

// --- ROLE SELECTION ---
class RoleSelectionPage extends StatelessWidget {
  final VoidCallback? toggleTheme;
  const RoleSelectionPage({super.key, this.toggleTheme});
  @override
  Widget build(BuildContext context) => Scaffold(
    body: Container(
      width: double.infinity,
      decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF1A237E), Color(0xFF3949AB)])),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Text("Luxury Market Hub", style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
        const SizedBox(height: 40),
        _btn(context, "Shopkeeper", Icons.storefront),
        _btn(context, "Customer", Icons.shopping_cart),
        _btn(context, "Professional", Icons.engineering),
      ]),
    ),
  );
  Widget _btn(context, r, i) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 10),
    child: Card(child: ListTile(title: Text(r, style: const TextStyle(fontWeight: FontWeight.bold)), leading: Icon(i, color: Colors.indigo), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => LoginPage(role: r, toggleTheme: toggleTheme!))))),
  );
}

// --- LOGIN ---
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
      TextField(controller: _idC, decoration: const InputDecoration(labelText: "Email or Phone", border: OutlineInputBorder())),
      if (sent) const SizedBox(height: 15),
      if (sent) TextField(controller: _otpC, decoration: const InputDecoration(labelText: "OTP (123456)", border: OutlineInputBorder())),
      const SizedBox(height: 20),
      ElevatedButton(
        style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 55)),
        onPressed: () async {
          if (!sent) setState(() => sent = true);
          else if (_otpC.text == "123456") {
            SharedPreferences prefs = await SharedPreferences.getInstance();
            await prefs.setString('userRole', widget.role);
            Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (c) => SplashScreen(toggleTheme: widget.toggleTheme)), (r) => false);
          }
        }, 
        child: Text(sent ? "LOGIN" : "GET OTP")
      )
    ])),
  );
}

// --- 1. SHOPKEEPER DASHBOARD (INVENTORY FIX) ---
class ShopDashboard extends StatefulWidget {
  final VoidCallback toggleTheme;
  const ShopDashboard({super.key, required this.toggleTheme});
  @override
  State<ShopDashboard> createState() => _ShopDashboardState();
}

class _ShopDashboardState extends State<ShopDashboard> {
  List products = [];
  final _nC = TextEditingController(), _pC = TextEditingController(), _dC = TextEditingController(), _qC = TextEditingController();
  List<String> _tempImgs = [];

  @override
  void initState() { super.initState(); _load(); }
  _load() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? data = prefs.getString('global_products');
    if (data != null) setState(() => products = json.decode(data));
  }

  _saveP() async {
    if (_nC.text.isEmpty || _tempImgs.isEmpty) return;
    products.add({'name': _nC.text, 'price': _pC.text, 'disc': _dC.text, 'qty': _qC.text, 'imgs': _tempImgs});
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('global_products', json.encode(products));
    setState(() { _nC.clear(); _pC.clear(); _dC.clear(); _qC.clear(); _tempImgs = []; });
    _load();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text("Shop Hub"), actions: [
      IconButton(icon: const Icon(Icons.person), onPressed: () {}),
      IconButton(icon: const Icon(Icons.settings), onPressed: () => AppActions.openSettings(context, widget.toggleTheme)),
    ]),
    body: ListView(padding: const EdgeInsets.all(20), children: [
      const Text("Add Product", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      const SizedBox(height: 10),
      GestureDetector(
        onTap: () async {
          final p = await ImagePicker().pickMultiImage();
          if (p.isNotEmpty) setState(() => _tempImgs = p.map((f)=>f.path).toList());
        },
        child: Container(height: 120, decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.indigo.withOpacity(0.3))), child: _tempImgs.isEmpty ? const Icon(Icons.add_a_photo, size: 40, color: Colors.indigo) : ListView(scrollDirection: Axis.horizontal, children: _tempImgs.map((f)=>Padding(padding: const EdgeInsets.all(5), child: Image.file(File(f)))).toList())),
      ),
      TextField(controller: _nC, decoration: const InputDecoration(labelText: "Item Name")),
      Row(children: [
        Expanded(child: TextField(controller: _pC, decoration: const InputDecoration(labelText: "Price"))),
        Expanded(child: TextField(controller: _dC, decoration: const InputDecoration(labelText: "Disc%"))),
        Expanded(child: TextField(controller: _qC, decoration: const InputDecoration(labelText: "Qty"))),
      ]),
      const SizedBox(height: 10),
      ElevatedButton(onPressed: _saveP, child: const Text("List Product")),
      const Divider(height: 40),
      const Text("My Inventory", style: TextStyle(fontWeight: FontWeight.bold)),
      ...products.asMap().entries.map((e) => Card(child: ListTile(leading: Image.file(File(e.value['imgs'][0]), width: 50, height: 50, fit: BoxFit.cover), title: Text(e.value['name']), subtitle: Text("₹${e.value['price']} | Stock: ${e.value['qty']}"), trailing: IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () async { products.removeAt(e.key); SharedPreferences prefs = await SharedPreferences.getInstance(); await prefs.setString('global_products', json.encode(products)); _load(); })))).toList()
    ]),
  );
}

// --- 2. PROFESSIONAL DASHBOARD (ID & PROFILE FIX) ---
class ProDashboard extends StatefulWidget {
  final VoidCallback toggleTheme;
  const ProDashboard({super.key, required this.toggleTheme});
  @override
  State<ProDashboard> createState() => _ProDashboardState();
}

class _ProDashboardState extends State<ProDashboard> {
  String name = "", job = ""; bool online = false; File? photo;
  bool hasProfile = false;

  @override
  void initState() { super.initState(); _load(); }
  _load() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      name = prefs.getString('pro_name') ?? "";
      job = prefs.getString('pro_job') ?? "";
      online = prefs.getBool('pro_status') ?? false;
      hasProfile = name.isNotEmpty;
      String? p = prefs.getString('pro_photo'); if (p != null) photo = File(p);
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text("Partner Panel"), actions: [
      IconButton(icon: const Icon(Icons.settings), onPressed: () => AppActions.openSettings(context, widget.toggleTheme)),
    ]),
    body: !hasProfile ? _setup() : _mainPro(),
  );

  Widget _setup() => Padding(padding: const EdgeInsets.all(30), child: Column(children: [
    const Text("Create Professional ID", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
    const SizedBox(height: 20),
    GestureDetector(onTap: () async {
      final p = await ImagePicker().pickImage(source: ImageSource.camera);
      if (p != null) setState(() => photo = File(p.path));
    }, child: CircleAvatar(radius: 60, backgroundImage: photo != null ? FileImage(photo!) : null, child: photo == null ? const Icon(Icons.camera_alt, size: 30) : null)),
    TextField(onChanged: (v) => name = v, decoration: const InputDecoration(labelText: "Full Name")),
    TextField(onChanged: (v) => job = v, decoration: const InputDecoration(labelText: "Your Skill (e.g. Plumber)")),
    const SizedBox(height: 20),
    ElevatedButton(onPressed: () async {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('pro_name', name); await prefs.setString('pro_job', job);
      if (photo != null) await prefs.setString('pro_photo', photo!.path);
      _load();
    }, child: const Text("Generate ID & Go Live"))
  ]));

  Widget _mainPro() => Column(children: [
    Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF1A237E), Colors.indigo]), borderRadius: BorderRadius.circular(25)),
      child: Column(children: [
        CircleAvatar(radius: 50, backgroundImage: photo != null ? FileImage(photo!) : null),
        const SizedBox(height: 10),
        Text(name, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
        Text(job.toUpperCase(), style: const TextStyle(color: Colors.white70, letterSpacing: 2)),
        const Divider(color: Colors.white24),
        const Text("TRINITY VERIFIED PARTNER", style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 12)),
      ]),
    ),
    SwitchListTile(title: const Text("Availability for Work"), value: online, onChanged: (v) async {
       SharedPreferences prefs = await SharedPreferences.getInstance();
       await prefs.setBool('pro_status', v); setState(() => online = v);
    }),
  ]);
}

// --- 3. CUSTOMER DASHBOARD (SEARCH & SYNC FIX) ---
class CustomerDashboard extends StatefulWidget {
  final VoidCallback toggleTheme;
  const CustomerDashboard({super.key, required this.toggleTheme});
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
    _syncData();
  }

  _syncData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? data = prefs.getString('global_products');
    setState(() {
      if (data != null) products = json.decode(data);
      if (prefs.getBool('pro_status') ?? false) {
        pro = {'name': prefs.getString('pro_name'), 'job': prefs.getString('pro_job'), 'img': prefs.getString('pro_photo')};
      } else { pro = null; }
    });
  }

  @override
  Widget build(BuildContext context) {
    final filtered = products.where((p) => p['name'].toString().toLowerCase().contains(query.toLowerCase())).toList();
    return Scaffold(
      appBar: AppBar(title: const Text("Trinity Market"), actions: [
        IconButton(icon: const Icon(Icons.settings), onPressed: () => AppActions.openSettings(context, widget.toggleTheme)),
      ]),
      floatingActionButton: FloatingActionButton(onPressed: () => _openAI(context), child: const Icon(Icons.auto_awesome)),
      body: Column(children: [
        Padding(padding: const EdgeInsets.all(15), child: TextField(onChanged: (v) => setState(() => query = v), decoration: InputDecoration(hintText: "Search anything...", prefixIcon: const Icon(Icons.search), border: OutlineInputBorder(borderRadius: BorderRadius.circular(30))))),
        TabBar(controller: _tab, labelColor: Colors.indigo, tabs: const [Tab(text: "Products"), Tab(text: "Experts")]),
        Expanded(child: TabBarView(controller: _tab, children: [
          filtered.isEmpty ? const Center(child: Text("No products found")) : ListView.builder(itemCount: filtered.length, itemBuilder: (c, i) => _productCard(filtered[i])),
          _expertSection()
        ]))
      ]),
    );
  }

  Widget _productCard(Map p) => Card(margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 8), child: ListTile(
    onTap: () => _showZoom(p['imgs']),
    leading: Image.file(File(p['imgs'][0]), width: 60, height: 60, fit: BoxFit.cover),
    title: Text(p['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
    subtitle: Text("₹${p['price']} (${p['disc']}% Off)"),
    trailing: ElevatedButton(onPressed: () => _confirmOrder(p), child: const Text("BUY")),
  ));

  Widget _expertSection() => ListView(children: [
    if (pro != null && (pro!['name'].toLowerCase().contains(query.toLowerCase()) || pro!['job'].toLowerCase().contains(query.toLowerCase())))
      Card(margin: const EdgeInsets.all(15), child: ListTile(leading: CircleAvatar(backgroundImage: FileImage(File(pro!['img']))), title: Text(pro!['name']), subtitle: Text(pro!['job']), trailing: ElevatedButton(onPressed: (){}, child: const Text("HIRE"))))
    else if (query.isNotEmpty) const Center(child: Padding(padding: EdgeInsets.all(20), child: Text("No matching experts online")))
  ]);

  void _confirmOrder(Map p) {
    showModalBottomSheet(context: context, builder: (c) => Container(
      padding: const EdgeInsets.all(25),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Text("Amazon-Style Checkout", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const Divider(),
        Text("Product: ${p['name']}"),
        Text("Final Price: ₹${p['price']}"),
        const SizedBox(height: 20),
        SizedBox(width: double.infinity, height: 50, child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white), onPressed: () => Navigator.pop(context), child: const Text("PLACE ORDER"))),
      ]),
    ));
  }

  void _showZoom(List imgs) {
    showDialog(context: context, builder: (c) => Dialog.fullscreen(child: Stack(children: [
      PhotoViewGallery.builder(itemCount: imgs.length, builder: (c, i) => PhotoViewGalleryPageOptions(imageProvider: FileImage(File(imgs[i])))),
      Positioned(top: 40, right: 20, child: IconButton(icon: const Icon(Icons.close, color: Colors.white, size: 30), onPressed: () => Navigator.pop(c)))
    ])));
  }
}

// --- AI CHATBOT (FIXED & RESPONSIVE) ---
void _openAI(BuildContext context) {
  final ctrl = TextEditingController();
  List<Map<String, String>> chat = [{'r': 'ai', 'm': 'Hello! I am Trinity AI. Ask me about Price, Hire or Stock.'}];
  showModalBottomSheet(context: context, isScrollControlled: true, builder: (c) => StatefulBuilder(builder: (context, setS) => Padding(
    padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
    child: Container(height: 450, padding: const EdgeInsets.all(20), child: Column(children: [
      const Text("Trinity Support AI", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
      Expanded(child: ListView.builder(itemCount: chat.length, itemBuilder: (c, i) => Align(
        alignment: chat[i]['r'] == 'u' ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(margin: const EdgeInsets.symmetric(vertical: 5), padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: chat[i]['r'] == 'u' ? Colors.indigo[100] : Colors.grey[200], borderRadius: BorderRadius.circular(15)), child: Text(chat[i]['m']!)),
      ))),
      TextField(controller: ctrl, decoration: InputDecoration(hintText: "Type hire, price or support...", suffixIcon: IconButton(icon: const Icon(Icons.send), onPressed: () {
        setS(() {
          chat.add({'r': 'u', 'm': ctrl.text});
          String r = "Let me check that... You can find details in the respective tabs.";
          if (ctrl.text.toLowerCase().contains("hire")) r = "Go to 'Experts' tab and click HIRE to connect.";
          if (ctrl.text.toLowerCase().contains("price")) r = "Prices are set by shopkeepers and shown in the Products tab.";
          chat.add({'r': 'ai', 'm': r});
          ctrl.clear();
        });
      })))
    ])),
  )));
}
