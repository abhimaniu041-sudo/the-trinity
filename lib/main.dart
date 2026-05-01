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
  ThemeMode _themeMode = ThemeMode.dark; // Default Dark for Premium Feel

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
        colorScheme: const ColorScheme.dark(
          primary: Colors.redAccent,
          surface: Color(0xFF1A1A1A),
        ),
        cardTheme: CardTheme(
          color: const Color(0xFF1E1E1E),
          elevation: 8,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
      ),
      home: SplashScreen(toggleTheme: _toggleTheme),
    );
  }
}

// --- GLOBAL ACTIONS ---
class AppLogic {
  static Future<void> logout(BuildContext context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('userRole');
    Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (c) => const RoleSelectionPage()), (r) => false);
  }
}

// --- SHARED PROFILE SHEET ---
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
      decoration: const BoxDecoration(borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
      child: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text("Manage Profile", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.redAccent)),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: () async {
              final p = await ImagePicker().pickImage(source: ImageSource.gallery);
              if (p != null) setState(() => _image = File(p.path));
            },
            child: CircleAvatar(radius: 60, backgroundColor: Colors.red.withOpacity(0.1), backgroundImage: _image != null ? FileImage(_image!) : null, child: _image == null ? const Icon(Icons.add_a_photo, size: 30) : null),
          ),
          const SizedBox(height: 20),
          TextField(controller: _name, decoration: const InputDecoration(labelText: "Full Name", prefixIcon: Icon(Icons.person))),
          const SizedBox(height: 10),
          TextField(controller: _phone, decoration: const InputDecoration(labelText: "Mobile", prefixIcon: Icon(Icons.phone))),
          const SizedBox(height: 10),
          TextField(controller: _addr, decoration: const InputDecoration(labelText: "Address", prefixIcon: Icon(Icons.location_on))),
          const SizedBox(height: 30),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 55)),
            onPressed: () async {
              SharedPreferences prefs = await SharedPreferences.getInstance();
              await prefs.setString('${widget.roleKey}_name', _name.text);
              await prefs.setString('${widget.roleKey}_phone', _phone.text);
              await prefs.setString('${widget.roleKey}_addr', _addr.text);
              if (_image != null) await prefs.setString('${widget.roleKey}_img', _image!.path);
              Navigator.pop(context, true);
            },
            child: const Text("SAVE CHANGES", style: TextStyle(fontWeight: FontWeight.bold)),
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
    if (role != null) {
      if (role == 'Shopkeeper') Navigator.pushReplacement(context, MaterialPageRoute(builder: (c) => ShopDashboard(toggleTheme: widget.toggleTheme)));
      else if (role == 'Professional') Navigator.pushReplacement(context, MaterialPageRoute(builder: (c) => ProDashboard(toggleTheme: widget.toggleTheme)));
      else Navigator.pushReplacement(context, MaterialPageRoute(builder: (c) => CustomerDashboard(toggleTheme: widget.toggleTheme)));
    } else {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (c) => RoleSelectionPage(toggleTheme: widget.toggleTheme)));
    }
  }
  @override
  Widget build(BuildContext context) => Scaffold(body: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [const Text("THE TRINITY", style: TextStyle(fontSize: 45, fontWeight: FontWeight.w900, color: Colors.redAccent, letterSpacing: 5)), const SizedBox(height: 5), Text("POWERED BY ABHIMANIU", style: TextStyle(fontSize: 10, color: Colors.grey.shade600, letterSpacing: 2))])));
}

// --- ROLE SELECTION ---
class RoleSelectionPage extends StatelessWidget {
  final VoidCallback? toggleTheme;
  const RoleSelectionPage({super.key, this.toggleTheme});
  @override
  Widget build(BuildContext context) => Scaffold(
    body: Container(
      width: double.infinity,
      decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF000000), Color(0xFF2D0000)], begin: Alignment.topCenter)),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Text("Select Identity", style: TextStyle(color: Colors.white, fontSize: 35, fontWeight: FontWeight.bold)),
        const SizedBox(height: 50),
        _btn(context, "Shopkeeper", Icons.storefront),
        _btn(context, "Customer", Icons.person_pin),
        _btn(context, "Professional", Icons.engineering),
      ]),
    ),
  );
  Widget _btn(context, r, i) => Padding(padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 10), child: Card(child: ListTile(title: Text(r, style: const TextStyle(fontWeight: FontWeight.bold)), leading: Icon(i, color: Colors.redAccent), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => LoginPage(role: r, toggleTheme: toggleTheme!))))));
}

// --- LOGIN ---
class LoginPage extends StatefulWidget {
  final String role; final VoidCallback toggleTheme;
  const LoginPage({super.key, required this.role, required this.toggleTheme});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _idC = TextEditingController(), _otpC = TextEditingController(); bool sent = false;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text("${widget.role} Authentication")),
    body: Padding(padding: const EdgeInsets.all(30), child: Column(children: [
      TextField(controller: _idC, decoration: const InputDecoration(labelText: "Mobile or Email", border: OutlineInputBorder())),
      if (sent) const SizedBox(height: 15),
      if (sent) TextField(controller: _otpC, decoration: const InputDecoration(labelText: "OTP (123456)", border: OutlineInputBorder())),
      const SizedBox(height: 30),
      ElevatedButton(onPressed: () async {
        if (!sent) setState(() => sent = true);
        else if (_otpC.text == "123456") {
          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setString('userRole', widget.role);
          Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (c) => SplashScreen(toggleTheme: widget.toggleTheme)), (r) => false);
        }
      }, style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 55)), child: Text(sent ? "LOGIN" : "GET OTP"))
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
    appBar: AppBar(title: const Text("Store Console"), actions: [
      IconButton(icon: const Icon(Icons.person), onPressed: () => showModalBottomSheet(context: context, isScrollControlled: true, builder: (c) => const ProfileEditor(roleKey: 'shop'))),
      IconButton(icon: const Icon(Icons.settings), onPressed: () => _openSettings(context)),
    ]),
    body: ListView(padding: const EdgeInsets.all(20), children: [
      const Text("Inventory Management", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.redAccent)),
      const SizedBox(height: 15),
      GestureDetector(
        onTap: () async {
          final p = await ImagePicker().pickMultiImage();
          if (p.isNotEmpty) setState(() => _tempImgs = p.map((f)=>f.path).toList());
        },
        child: Container(height: 120, decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.redAccent.withOpacity(0.3))), child: _tempImgs.isEmpty ? const Icon(Icons.add_a_photo, size: 40) : ListView(scrollDirection: Axis.horizontal, children: _tempImgs.map((f)=>Padding(padding: const EdgeInsets.all(5), child: Image.file(File(f)))).toList())),
      ),
      TextField(controller: _nC, decoration: const InputDecoration(labelText: "Product Name")),
      Row(children: [
        Expanded(child: TextField(controller: _pC, decoration: const InputDecoration(labelText: "Price"))),
        Expanded(child: TextField(controller: _dC, decoration: const InputDecoration(labelText: "Disc%"))),
        Expanded(child: TextField(controller: _qC, decoration: const InputDecoration(labelText: "Qty"))),
      ]),
      const SizedBox(height: 15),
      ElevatedButton(onPressed: _saveP, style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white), child: const Text("ADD TO CATALOG")),
      const Divider(height: 50),
      ...products.asMap().entries.map((e) => Card(child: ListTile(leading: Image.file(File(e.value['imgs'][0]), width: 50, fit: BoxFit.cover), title: Text(e.value['name']), subtitle: Text("₹${e.value['price']} | Qty: ${e.value['qty']}"), trailing: IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () async { products.removeAt(e.key); SharedPreferences prefs = await SharedPreferences.getInstance(); await prefs.setString('global_products', json.encode(products)); _load(); })))).toList()
    ]),
  );

  void _openSettings(context) {
    showModalBottomSheet(context: context, builder: (c) => Column(mainAxisSize: MainAxisSize.min, children: [
      ListTile(leading: const Icon(Icons.brightness_6), title: const Text("Toggle Theme"), onTap: widget.toggleTheme),
      ListTile(leading: const Icon(Icons.logout, color: Colors.red), title: const Text("Sign Out"), onTap: () => AppLogic.logout(context)),
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
  String name = "Set Name", job = "Set Job"; bool online = false; File? img;

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
    appBar: AppBar(title: const Text("Partner Hub"), actions: [
      IconButton(icon: const Icon(Icons.person), onPressed: () async {
        bool? res = await showModalBottomSheet(context: context, isScrollControlled: true, builder: (c) => const ProfileEditor(roleKey: 'pro'));
        if (res == true) _load();
      }),
      IconButton(icon: const Icon(Icons.settings), onPressed: () => _openSettings(context)),
    ]),
    body: Column(children: [
      const SizedBox(height: 20),
      Container(
        margin: const EdgeInsets.symmetric(horizontal: 25),
        padding: const EdgeInsets.all(25),
        decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFFB71C1C), Color(0xFF000000)]), borderRadius: BorderRadius.circular(30), border: Border.all(color: Colors.redAccent.withOpacity(0.5))),
        child: Column(children: [
          CircleAvatar(radius: 50, backgroundImage: img != null ? FileImage(img!) : null, child: img == null ? const Icon(Icons.person, size: 40) : null),
          const SizedBox(height: 15),
          Text(name, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white)),
          Text(job.toUpperCase(), style: const TextStyle(fontSize: 14, color: Colors.white70, letterSpacing: 2)),
          const Divider(height: 30, color: Colors.white24),
          const Text("TRINITY VERIFIED EXPERT", style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 12)),
        ]),
      ),
      const SizedBox(height: 30),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 30),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(20)),
          child: SwitchListTile(
            title: Text(online ? "YOU ARE ONLINE" : "YOU ARE OFFLINE", style: TextStyle(fontWeight: FontWeight.bold, color: online ? Colors.green : Colors.redAccent)),
            value: online, activeColor: Colors.green, inactiveThumbColor: Colors.redAccent,
            onChanged: (v) async {
              SharedPreferences prefs = await SharedPreferences.getInstance();
              await prefs.setBool('pro_status', v);
              setState(() => online = v);
            },
          ),
        ),
      ),
    ]),
  );

  void _openSettings(context) {
    showModalBottomSheet(context: context, builder: (c) => Column(mainAxisSize: MainAxisSize.min, children: [
      ListTile(leading: const Icon(Icons.brightness_6), title: const Text("Toggle Theme"), onTap: widget.toggleTheme),
      ListTile(leading: const Icon(Icons.logout, color: Colors.red), title: const Text("Sign Out"), onTap: () => AppLogic.logout(context)),
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
      appBar: AppBar(title: const Text("Trinity Marketplace"), actions: [
        IconButton(icon: const Icon(Icons.person), onPressed: () => showModalBottomSheet(context: context, isScrollControlled: true, builder: (c) => const ProfileEditor(roleKey: 'cust'))),
        IconButton(icon: const Icon(Icons.settings), onPressed: () => _openSettings(context)),
      ]),
      floatingActionButton: FloatingActionButton(backgroundColor: Colors.redAccent, onPressed: () => _openAI(context), child: const Icon(Icons.auto_awesome, color: Colors.white)),
      body: Column(children: [
        Padding(padding: const EdgeInsets.all(15), child: TextField(onChanged: (v) => setState(() => query = v), decoration: InputDecoration(hintText: "Search anything...", prefixIcon: const Icon(Icons.search), filled: true, fillColor: Colors.white10, border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none)))),
        TabBar(controller: _tab, indicatorColor: Colors.redAccent, labelColor: Colors.redAccent, tabs: const [Tab(text: "PRODUCTS"), Tab(text: "EXPERTS")]),
        Expanded(child: TabBarView(controller: _tab, children: [
          filtered.isEmpty ? const Center(child: Text("No products listed yet")) : ListView.builder(itemCount: filtered.length, itemBuilder: (c, i) => _productCard(filtered[i])),
          _expertView()
        ]))
      ]),
    );
  }

  Widget _productCard(Map p) => Card(margin: const EdgeInsets.all(10), child: ListTile(
    onTap: () => _zoom(p['imgs']),
    leading: ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.file(File(p['imgs'][0]), width: 60, height: 60, fit: BoxFit.cover)),
    title: Text(p['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
    subtitle: Text("₹${p['price']} (${p['disc']}% Off)", style: const TextStyle(color: Colors.redAccent)),
    trailing: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white), onPressed: () => _buy(p), child: const Text("BUY")),
  ));

  Widget _expertView() => ListView(children: [
    if (pro != null && (pro!['name'].toLowerCase().contains(query.toLowerCase()) || pro!['job'].toLowerCase().contains(query.toLowerCase())))
      Card(margin: const EdgeInsets.all(15), child: ListTile(leading: CircleAvatar(backgroundImage: FileImage(File(pro!['img']))), title: Text(pro!['name']), subtitle: Text(pro!['job']), trailing: ElevatedButton(onPressed: (){}, child: const Text("HIRE"))))
    else if (query.isNotEmpty) const Center(child: Text("No experts matching your search"))
    else const Center(child: Padding(padding: EdgeInsets.all(20), child: Text("No Experts Online currently")))
  ]);

  void _buy(Map p) {
    showModalBottomSheet(context: context, builder: (c) => Container(padding: const EdgeInsets.all(25), child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Text("Confirm Purchase", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.redAccent)),
      const Divider(),
      Text("Item: ${p['name']}"), Text("Total: ₹${p['price']}"),
      const SizedBox(height: 20),
      SizedBox(width: double.infinity, height: 50, child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white), onPressed: () => Navigator.pop(context), child: const Text("PAY & PLACE ORDER"))),
    ])));
  }

  void _zoom(List imgs) { showDialog(context: context, builder: (c) => Dialog.fullscreen(child: Stack(children: [PhotoViewGallery.builder(itemCount: imgs.length, builder: (c, i) => PhotoViewGalleryPageOptions(imageProvider: FileImage(File(imgs[i])))), Positioned(top: 40, right: 20, child: IconButton(icon: const Icon(Icons.close, color: Colors.white, size: 30), onPressed: () => Navigator.pop(c)))]))); }

  void _openSettings(context) {
    showModalBottomSheet(context: context, builder: (c) => Column(mainAxisSize: MainAxisSize.min, children: [
      ListTile(leading: const Icon(Icons.brightness_6), title: const Text("Toggle Theme"), onTap: widget.toggleTheme),
      ListTile(leading: const Icon(Icons.logout, color: Colors.red), title: const Text("Sign Out"), onTap: () => AppLogic.logout(context)),
    ]));
  }
}

// --- AI CHATBOT (FIXED) ---
void _openAI(BuildContext context) {
  final ctrl = TextEditingController();
  List<Map<String, String>> chat = [{'r': 'ai', 'm': 'Hello Boss! Trinity AI here. How can I help?'}];
  showModalBottomSheet(context: context, isScrollControlled: true, builder: (c) => StatefulBuilder(builder: (context, setS) => Padding(
    padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
    child: Container(height: 450, padding: const EdgeInsets.all(20), child: Column(children: [
      const Text("Trinity Command Center", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.redAccent)),
      Expanded(child: ListView.builder(itemCount: chat.length, itemBuilder: (c, i) => Align(
        alignment: chat[i]['r'] == 'u' ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(margin: const EdgeInsets.symmetric(vertical: 5), padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: chat[i]['r'] == 'u' ? Colors.redAccent : Colors.white10, borderRadius: BorderRadius.circular(15)), child: Text(chat[i]['m']!, style: const TextStyle(color: Colors.white))),
      ))),
      TextField(controller: ctrl, decoration: InputDecoration(hintText: "Enter command...", suffixIcon: IconButton(icon: const Icon(Icons.send, color: Colors.redAccent), onPressed: () {
        setS(() {
          chat.add({'r': 'u', 'm': ctrl.text});
          String r = "Command received. Checking marketplace database...";
          if (ctrl.text.toLowerCase().contains("hire")) r = "Navigate to Experts tab to recruit professionals.";
          if (ctrl.text.toLowerCase().contains("price")) r = "Check catalog for latest discounted rates.";
          chat.add({'r': 'ai', 'm': r}); ctrl.clear();
        });
      })))
    ])),
  )));
}
