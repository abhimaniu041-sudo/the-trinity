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
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.red),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0A0A0A),
        colorScheme: const ColorScheme.dark(primary: Colors.redAccent, surface: Color(0xFF121212)),
        cardTheme: CardTheme(
          color: const Color(0xFF1A1A1A),
          elevation: 10,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
      ),
      home: SplashScreen(toggleTheme: _toggleTheme),
    );
  }
}

// --- SHARED PROFILE LOGIC ---
class ProfileManager extends StatefulWidget {
  final String role;
  const ProfileManager({super.key, required this.role});
  @override
  State<ProfileManager> createState() => _ProfileManagerState();
}

class _ProfileEditorState extends State<ProfileManager> {
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
      String? path = prefs.getString('${widget.role}_img');
      if (path != null) _img = File(path);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 20, right: 20, top: 20),
      child: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text("Profile Settings", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.redAccent)),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: () async {
              final p = await ImagePicker().pickImage(source: ImageSource.gallery);
              if (p != null) setState(() => _img = File(p.path));
            },
            child: CircleAvatar(radius: 55, backgroundColor: Colors.white10, backgroundImage: _img != null ? FileImage(_img!) : null, child: _img == null ? const Icon(Icons.add_a_photo, color: Colors.redAccent) : null),
          ),
          TextField(controller: _n, decoration: const InputDecoration(labelText: "Full Name")),
          TextField(controller: _p, decoration: const InputDecoration(labelText: "Phone Number")),
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
              Navigator.pop(context, true);
            },
            child: const Text("UPDATE PROFILE"),
          ),
          const SizedBox(height: 30),
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
    await Future.delayed(const Duration(seconds: 3));
    if (!mounted) return;
    if (role == 'Shopkeeper') Navigator.pushReplacement(context, MaterialPageRoute(builder: (c) => ShopDashboard(toggleTheme: widget.toggleTheme)));
    else if (role == 'Professional') Navigator.pushReplacement(context, MaterialPageRoute(builder: (c) => ProDashboard(toggleTheme: widget.toggleTheme)));
    else if (role == 'Customer') Navigator.pushReplacement(context, MaterialPageRoute(builder: (c) => CustomerDashboard(toggleTheme: widget.toggleTheme)));
    else Navigator.pushReplacement(context, MaterialPageRoute(builder: (c) => RoleSelectionPage(toggleTheme: widget.toggleTheme)));
  }
  @override
  Widget build(BuildContext context) => Scaffold(body: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [const Text("THE TRINITY", style: TextStyle(fontSize: 45, fontWeight: FontWeight.w900, color: Colors.redAccent, letterSpacing: 4)), const Text("POWERED BY ABHIMANIU", style: TextStyle(fontSize: 10, color: Colors.grey, letterSpacing: 2))])));
}

// --- ROLE SELECTION ---
class RoleSelectionPage extends StatelessWidget {
  final VoidCallback toggleTheme;
  const RoleSelectionPage({super.key, required this.toggleTheme});
  @override
  Widget build(BuildContext context) => Scaffold(
    body: Container(
      width: double.infinity,
      decoration: const BoxDecoration(gradient: LinearGradient(colors: [Colors.black, Color(0xFF300000)], begin: Alignment.topCenter)),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Text("Welcome Boss", style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
        const SizedBox(height: 50),
        _btn(context, "Shopkeeper", Icons.storefront),
        _btn(context, "Customer", Icons.shopping_bag),
        _btn(context, "Professional", Icons.engineering),
      ]),
    ),
  );
  Widget _btn(context, r, i) => Padding(padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 10), child: Card(child: ListTile(title: Text(r, style: const TextStyle(fontWeight: FontWeight.bold)), leading: Icon(i, color: Colors.redAccent), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => LoginPage(role: r, toggleTheme: toggleTheme))))));
}

// --- LOGIN ---
class LoginPage extends StatefulWidget {
  final String role; final VoidCallback toggleTheme;
  const LoginPage({super.key, required this.role, required this.toggleTheme});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _id = TextEditingController(), _otp = TextEditingController(); bool sent = false;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text("${widget.role} Access")),
    body: Padding(padding: const EdgeInsets.all(30), child: Column(children: [
      TextField(controller: _id, decoration: const InputDecoration(labelText: "Mobile / Email", border: OutlineInputBorder())),
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
      }, style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 55)), child: Text(sent ? "VERIFY" : "GET OTP"))
    ])),
  );
}

// --- 1. SHOPKEEPER DASHBOARD ---
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
    products.add({'name': _n.text, 'price': _p.text, 'disc': _d.text, 'qty': _q.text, 'imgs': _imgs, 'shop': 'Trinity Store'});
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('global_products', json.encode(products));
    setState(() { _n.clear(); _p.clear(); _d.clear(); _q.clear(); _imgs = []; });
    _load();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text("Console"), actions: [
      IconButton(icon: const Icon(Icons.person), onPressed: () => showModalBottomSheet(context: context, isScrollControlled: true, builder: (c) => const ProfileManager(role: 'shop'))),
      IconButton(icon: const Icon(Icons.settings), onPressed: () => _settings(context)),
    ]),
    body: ListView(padding: const EdgeInsets.all(20), children: [
      const Text("List New Product", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.redAccent)),
      const SizedBox(height: 15),
      GestureDetector(
        onTap: () async {
          final p = await ImagePicker().pickMultiImage();
          if (p.isNotEmpty) setState(() => _imgs = p.map((f)=>f.path).toList());
        },
        child: Container(height: 100, decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.redAccent.withOpacity(0.3))), child: _imgs.isEmpty ? const Icon(Icons.add_a_photo) : ListView(scrollDirection: Axis.horizontal, children: _imgs.map((f)=>Image.file(File(f))).toList())),
      ),
      TextField(controller: _n, decoration: const InputDecoration(labelText: "Name")),
      Row(children: [Expanded(child: TextField(controller: _p, decoration: const InputDecoration(labelText: "Price"))), Expanded(child: TextField(controller: _d, decoration: const InputDecoration(labelText: "Disc%"))), Expanded(child: TextField(controller: _q, decoration: const InputDecoration(labelText: "Qty")))]),
      ElevatedButton(onPressed: _save, style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white), child: const Text("ADD TO STORE")),
      const Divider(height: 40),
      ...products.asMap().entries.map((e) => Card(child: ListTile(leading: Image.file(File(e.value['imgs'][0]), width: 50, height: 50, fit: BoxFit.cover), title: Text(e.value['name']), subtitle: Text("₹${e.value['price']}"), trailing: IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () async { products.removeAt(e.key); SharedPreferences prefs = await SharedPreferences.getInstance(); await prefs.setString('global_products', json.encode(products)); _load(); })))).toList()
    ]),
  );

  void _settings(context) {
    showModalBottomSheet(context: context, builder: (c) => Column(mainAxisSize: MainAxisSize.min, children: [
      ListTile(leading: const Icon(Icons.brightness_6), title: const Text("Theme Toggle"), onTap: widget.toggleTheme),
      ListTile(leading: const Icon(Icons.logout, color: Colors.red), title: const Text("Sign Out"), onTap: () async { SharedPreferences prefs = await SharedPreferences.getInstance(); await prefs.remove('userRole'); Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (c) => const RoleSelectionPage()), (r) => false); }),
    ]));
  }
}

// --- 2. PROFESSIONAL DASHBOARD ---
class ProDashboard extends StatefulWidget {
  final VoidCallback toggleTheme;
  const ProDashboard({super.key, required this.toggleTheme});
  @override
  State<ProDashboard> createState() => _ProDashboardState();
}

class _ProDashboardState extends State<ProDashboard> {
  String name = "Trinity Expert", job = "Specialist"; bool online = false; File? img;

  @override
  void initState() { super.initState(); _load(); }
  _load() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      name = prefs.getString('pro_name') ?? "Set Name";
      job = prefs.getString('pro_job') ?? "Set Job";
      online = prefs.getBool('pro_status') ?? false;
      String? p = prefs.getString('pro_img'); if (p != null) img = File(p);
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text("Expert Panel"), actions: [
      IconButton(icon: const Icon(Icons.person), onPressed: () async { await showModalBottomSheet(context: context, isScrollControlled: true, builder: (c) => const ProfileManager(role: 'pro')); _load(); }),
      IconButton(icon: const Icon(Icons.settings), onPressed: () => _settings(context)),
    ]),
    body: Column(children: [
      Container(
        margin: const EdgeInsets.all(20), padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF800000), Colors.black]), borderRadius: BorderRadius.circular(25), border: Border.all(color: Colors.redAccent.withOpacity(0.5))),
        child: Column(children: [
          CircleAvatar(radius: 50, backgroundImage: img != null ? FileImage(img!) : null, child: img == null ? const Icon(Icons.person, size: 40) : null),
          const SizedBox(height: 10),
          Text(name, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
          Text(job.toUpperCase(), style: const TextStyle(color: Colors.white70, letterSpacing: 2)),
          const Divider(color: Colors.white24),
          const Text("VERIFIED BY TRINITY", style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 12)),
        ]),
      ),
      SwitchListTile(title: Text(online ? "YOU ARE ONLINE" : "OFFLINE", style: TextStyle(color: online ? Colors.green : Colors.red, fontWeight: FontWeight.bold)), value: online, activeColor: Colors.green, onChanged: (v) async {
         SharedPreferences prefs = await SharedPreferences.getInstance();
         await prefs.setBool('pro_status', v); setState(() => online = v);
      }),
    ]),
  );

  void _settings(context) {
    showModalBottomSheet(context: context, builder: (c) => Column(mainAxisSize: MainAxisSize.min, children: [
      ListTile(leading: const Icon(Icons.brightness_6), title: const Text("Theme Toggle"), onTap: widget.toggleTheme),
      ListTile(leading: const Icon(Icons.logout, color: Colors.red), title: const Text("Sign Out"), onTap: () async { SharedPreferences prefs = await SharedPreferences.getInstance(); await prefs.remove('userRole'); Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (c) => const RoleSelectionPage()), (r) => false); }),
    ]));
  }
}

// --- 3. CUSTOMER DASHBOARD ---
class CustomerDashboard extends StatefulWidget {
  final VoidCallback toggleTheme;
  const CustomerDashboard({super.key, required this.toggleTheme});
  @override
  State<CustomerDashboard> createState() => _CustomerDashboardState();
}

class _CustomerDashboardState extends State<CustomerDashboard> with SingleTickerProviderStateMixin {
  late TabController _tab; String query = ""; List products = []; Map? pro;

  @override
  void initState() { super.initState(); _tab = TabController(length: 2, vsync: this); _sync(); }
  _sync() async {
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
        IconButton(icon: const Icon(Icons.person), onPressed: () => showModalBottomSheet(context: context, isScrollControlled: true, builder: (c) => const ProfileManager(role: 'cust'))),
        IconButton(icon: const Icon(Icons.settings), onPressed: () => _settings(context)),
      ]),
      floatingActionButton: FloatingActionButton(backgroundColor: Colors.redAccent, onPressed: () => _openAI(context), child: const Icon(Icons.auto_awesome, color: Colors.white)),
      body: Column(children: [
        Padding(padding: const EdgeInsets.all(15), child: TextField(onChanged: (v) => setState(() => query = v), decoration: InputDecoration(hintText: "Search for everything...", prefixIcon: const Icon(Icons.search), filled: true, fillColor: Colors.white10, border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none)))),
        TabBar(controller: _tab, indicatorColor: Colors.redAccent, labelColor: Colors.redAccent, tabs: const [Tab(text: "PRODUCTS"), Tab(text: "EXPERTS")]),
        Expanded(child: TabBarView(controller: _tab, children: [
          filtered.isEmpty ? const Center(child: Text("No items found")) : ListView.builder(itemCount: filtered.length, itemBuilder: (c, i) => _card(filtered[i])),
          _expertView()
        ]))
      ]),
    );
  }

  Widget _card(Map p) => Card(margin: const EdgeInsets.all(10), child: ListTile(
    onTap: () => _zoom(p['imgs']),
    leading: Image.file(File(p['imgs'][0]), width: 60, height: 60, fit: BoxFit.cover),
    title: Text(p['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
    subtitle: Text("₹${p['price']} | ${p['disc']}% Off"),
    trailing: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent), onPressed: () => _buy(p), child: const Text("BUY", style: TextStyle(color: Colors.white))),
  ));

  Widget _expertView() => ListView(children: [
    if (pro != null && (pro!['name'].toLowerCase().contains(query.toLowerCase()) || pro!['job'].toLowerCase().contains(query.toLowerCase())))
      Card(margin: const EdgeInsets.all(15), child: ListTile(leading: CircleAvatar(backgroundImage: FileImage(File(pro!['img']))), title: Text(pro!['name']), subtitle: Text(pro!['job']), trailing: ElevatedButton(onPressed: (){}, child: const Text("HIRE"))))
  ]);

  void _buy(Map p) {
    showModalBottomSheet(context: context, builder: (c) => Container(padding: const EdgeInsets.all(25), child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Text("Trinity Checkout", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.redAccent)),
      const Divider(),
      Text("Item: ${p['name']}"), Text("Total: ₹${p['price']}"),
      const SizedBox(height: 20),
      SizedBox(width: double.infinity, height: 50, child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent), onPressed: () => Navigator.pop(context), child: const Text("CONFIRM ORDER", style: TextStyle(color: Colors.white)))),
    ])));
  }

  void _zoom(List imgs) { showDialog(context: context, builder: (c) => Dialog.fullscreen(child: Stack(children: [PhotoViewGallery.builder(itemCount: imgs.length, builder: (c, i) => PhotoViewGalleryPageOptions(imageProvider: FileImage(File(imgs[i])))), Positioned(top: 40, right: 20, child: IconButton(icon: const Icon(Icons.close, color: Colors.white, size: 30), onPressed: () => Navigator.pop(c)))]))); }

  void _settings(context) {
    showModalBottomSheet(context: context, builder: (c) => Column(mainAxisSize: MainAxisSize.min, children: [
      ListTile(leading: const Icon(Icons.brightness_6), title: const Text("Theme Toggle"), onTap: widget.toggleTheme),
      ListTile(leading: const Icon(Icons.logout, color: Colors.red), title: const Text("Sign Out"), onTap: () async { SharedPreferences prefs = await SharedPreferences.getInstance(); await prefs.remove('userRole'); Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (c) => const RoleSelectionPage()), (r) => false); }),
    ]));
  }
}

// --- AI CHATBOT ---
void _openAI(BuildContext context) {
  final ctrl = TextEditingController();
  List<Map<String, String>> chat = [{'r': 'ai', 'm': 'Trinity AI Online. How can I help you, Boss?'}];
  showModalBottomSheet(context: context, isScrollControlled: true, builder: (c) => StatefulBuilder(builder: (context, setS) => Padding(
    padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
    child: Container(height: 450, padding: const EdgeInsets.all(20), child: Column(children: [
      const Text("Trinity Intelligence", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.redAccent)),
      Expanded(child: ListView.builder(itemCount: chat.length, itemBuilder: (c, i) => Align(
        alignment: chat[i]['r'] == 'u' ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(margin: const EdgeInsets.symmetric(vertical: 5), padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: chat[i]['r'] == 'u' ? Colors.redAccent : Colors.white10, borderRadius: BorderRadius.circular(15)), child: Text(chat[i]['m']!, style: const TextStyle(color: Colors.white))),
      ))),
      TextField(controller: ctrl, decoration: InputDecoration(hintText: "Enter command...", suffixIcon: IconButton(icon: const Icon(Icons.send, color: Colors.redAccent), onPressed: () {
        setS(() {
          chat.add({'r': 'u', 'm': ctrl.text});
          String r = "Analyzing request... Command executed.";
          if (ctrl.text.toLowerCase().contains("hire")) r = "Navigate to Experts tab to hire verified professionals.";
          chat.add({'r': 'ai', 'm': r}); ctrl.clear();
        });
      })))
    ])),
  )));
}
