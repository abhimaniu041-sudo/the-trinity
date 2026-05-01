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
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1A237E)),
        cardTheme: CardThemeData(elevation: 5, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
      ),
      darkTheme: ThemeData.dark(useMaterial3: true).copyWith(
        cardTheme: CardThemeData(elevation: 5, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
      ),
      home: const SplashScreen(),
    );
  }
}

// --- SHARED PROFILE & SETTINGS SYSTEM ---
class CommonActions {
  static void openProfile(BuildContext context, String role) {
    showModalBottomSheet(context: context, isScrollControlled: true, builder: (c) => ProfileSheet(role: role));
  }

  static void openSettings(BuildContext context, VoidCallback onToggle) {
    showModalBottomSheet(context: context, builder: (c) => Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const ListTile(title: Text("Settings", style: TextStyle(fontWeight: FontWeight.bold))),
        ListTile(leading: const Icon(Icons.brightness_6), title: const Text("Toggle Dark Mode"), onTap: onToggle),
        ListTile(leading: const Icon(Icons.logout, color: Colors.red), title: const Text("Logout"), onTap: () async {
          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.remove('userRole');
          Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (c) => const RoleSelectionPage()), (r) => false);
        }),
      ],
    ));
  }
}

class ProfileSheet extends StatefulWidget {
  final String role;
  const ProfileSheet({super.key, required this.role});
  @override
  State<ProfileSheet> createState() => _ProfileSheetState();
}

class _ProfileSheetState extends State<ProfileSheet> {
  final _name = TextEditingController(), _addr = TextEditingController(), _phone = TextEditingController();
  File? _img;

  @override
  void initState() { super.initState(); _load(); }
  _load() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _name.text = prefs.getString('${widget.role}_name') ?? "";
      _addr.text = prefs.getString('${widget.role}_addr') ?? "";
      _phone.text = prefs.getString('${widget.role}_phone') ?? "";
      String? path = prefs.getString('${widget.role}_img');
      if (path != null) _img = File(path);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 20, right: 20, top: 20),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Text("Profile Details", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 15),
        GestureDetector(
          onTap: () async {
            final p = await ImagePicker().pickImage(source: ImageSource.gallery);
            if (p != null) setState(() => _img = File(p.path));
          },
          child: CircleAvatar(radius: 50, backgroundImage: _img != null ? FileImage(_img!) : null, child: _img == null ? const Icon(Icons.camera_alt) : null),
        ),
        TextField(controller: _name, decoration: const InputDecoration(labelText: "Full Name")),
        TextField(controller: _phone, decoration: const InputDecoration(labelText: "Mobile Number")),
        TextField(controller: _addr, decoration: const InputDecoration(labelText: "Full Address")),
        const SizedBox(height: 20),
        ElevatedButton(onPressed: () async {
          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setString('${widget.role}_name', _name.text);
          await prefs.setString('${widget.role}_addr', _addr.text);
          await prefs.setString('${widget.role}_phone', _phone.text);
          if (_img != null) await prefs.setString('${widget.role}_img', _img!.path);
          Navigator.pop(context);
        }, child: const Text("Update Profile")),
        const SizedBox(height: 20),
      ]),
    );
  }
}

// --- SPLASH SCREEN (FIXED NO REPEAT) ---
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
  Widget build(BuildContext context) => const Scaffold(body: Center(child: Text("THE TRINITY", style: TextStyle(fontSize: 40, fontWeight: FontWeight.w900, color: Color(0xFF1A237E)))));
}

// --- ROLE SELECTION & LOGIN ---
class RoleSelectionPage extends StatelessWidget {
  const RoleSelectionPage({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    body: Container(
      width: double.infinity,
      decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF1A237E), Color(0xFF3949AB)])),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Text("Luxury Market Hub", style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
        const SizedBox(height: 40),
        _btn(context, "Shopkeeper", Icons.storefront),
        _btn(context, "Customer", Icons.person_search),
        _btn(context, "Professional", Icons.engineering),
      ]),
    ),
  );
  Widget _btn(context, r, i) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 10),
    child: Card(child: ListTile(title: Text(r), leading: Icon(i), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => LoginPage(role: r))))),
  );
}

class LoginPage extends StatefulWidget {
  final String role;
  const LoginPage({super.key, required this.role});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _idC = TextEditingController(), _otpC = TextEditingController();
  bool sent = false;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text("${widget.role} Login")),
    body: Padding(padding: const EdgeInsets.all(30), child: Column(children: [
      TextField(controller: _idC, decoration: const InputDecoration(labelText: "Email or Phone")),
      if (sent) TextField(controller: _otpC, decoration: const InputDecoration(labelText: "OTP (123456)")),
      const SizedBox(height: 20),
      ElevatedButton(onPressed: () async {
        if (!sent) setState(() => sent = true);
        else if (_otpC.text == "123456") {
          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setString('userRole', widget.role);
          if (widget.role == 'Shopkeeper') Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (c) => const ShopDashboard()), (r) => false);
          else if (widget.role == 'Professional') Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (c) => const ProDashboard()), (r) => false);
          else Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (c) => const CustomerDashboard()), (r) => false);
        }
      }, child: Text(sent ? "LOGIN" : "GET OTP"))
    ])),
  );
}

// --- 1. SHOPKEEPER (MULTI-IMAGE, INVENTORY, DISCOUNTS) ---
class ShopDashboard extends StatefulWidget {
  const ShopDashboard({super.key});
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
    String? data = prefs.getString('shop_products');
    if (data != null) setState(() => products = json.decode(data));
  }

  _saveP() async {
    if (_nC.text.isEmpty || _tempImgs.isEmpty) return;
    products.add({'name': _nC.text, 'price': _pC.text, 'disc': _dC.text, 'qty': _qC.text, 'imgs': _tempImgs});
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('shop_products', json.encode(products));
    setState(() { _nC.clear(); _pC.clear(); _dC.clear(); _qC.clear(); _tempImgs = []; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Shop Hub"), actions: [
        IconButton(icon: const Icon(Icons.person), onPressed: () => CommonActions.openProfile(context, 'shop')),
        IconButton(icon: const Icon(Icons.settings), onPressed: () => CommonActions.openSettings(context, (){})),
      ]),
      body: ListView(padding: const EdgeInsets.all(20), children: [
        const Text("Add Product", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        GestureDetector(onTap: () async {
          final p = await ImagePicker().pickMultiImage();
          if (p.isNotEmpty) setState(() => _tempImgs = p.map((f)=>f.path).toList());
        }, child: Container(height: 100, margin: const EdgeInsets.symmetric(vertical: 10), decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(15)), child: _tempImgs.isEmpty ? const Icon(Icons.add_a_photo) : ListView(scrollDirection: Axis.horizontal, children: _tempImgs.map((f)=>Image.file(File(f))).toList()))),
        TextField(controller: _nC, decoration: const InputDecoration(labelText: "Item Name")),
        Row(children: [
          Expanded(child: TextField(controller: _pC, decoration: const InputDecoration(labelText: "Price"))),
          Expanded(child: TextField(controller: _dC, decoration: const InputDecoration(labelText: "Disc%"))),
          Expanded(child: TextField(controller: _qC, decoration: const InputDecoration(labelText: "Qty"))),
        ]),
        const SizedBox(height: 10),
        ElevatedButton(onPressed: _saveP, child: const Text("List Product")),
        const Divider(height: 40),
        ...products.asMap().entries.map((e) => Card(child: ListTile(leading: Image.file(File(e.value['imgs'][0]), width: 40), title: Text(e.value['name']), subtitle: Text("₹${e.value['price']} | ${e.value['disc']}% Off"), trailing: IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: (){ setState(()=>products.removeAt(e.key)); _saveP(); })))).toList()
      ]),
    );
  }
}

// --- 2. PROFESSIONAL (AVAILABILITY & ID CARD) ---
class ProDashboard extends StatefulWidget {
  const ProDashboard({super.key});
  @override
  State<ProDashboard> createState() => _ProDashboardState();
}

class _ProDashboardState extends State<ProDashboard> {
  bool online = false; String name = "Partner", job = "Expert"; File? img;
  @override
  void initState() { super.initState(); _load(); }
  _load() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      name = prefs.getString('pro_name') ?? "Set Name";
      job = prefs.getString('pro_job') ?? "Set Job";
      online = prefs.getBool('pro_status') ?? false;
      String? path = prefs.getString('pro_img'); if (path != null) img = File(path);
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text("Partner Panel"), actions: [
      IconButton(icon: const Icon(Icons.person), onPressed: () => CommonActions.openProfile(context, 'pro')),
      IconButton(icon: const Icon(Icons.settings), onPressed: () => CommonActions.openSettings(context, (){})),
    ]),
    body: Column(children: [
      Card(color: Colors.indigo, margin: const EdgeInsets.all(20), child: Padding(padding: const EdgeInsets.all(20), child: Column(children: [
        CircleAvatar(radius: 40, backgroundImage: img != null ? FileImage(img!) : null),
        Text(name, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
        Text(job.toUpperCase(), style: const TextStyle(color: Colors.white70)),
      ]))),
      SwitchListTile(title: const Text("Available for Work"), value: online, onChanged: (v) async {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setBool('pro_status', v); setState(() => online = v);
      }),
    ]),
  );
}

// --- 3. CUSTOMER (AMAZON UI, SEARCH, BUYING, AI) ---
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
    String? data = prefs.getString('shop_products');
    if (data != null) products = json.decode(data);
    if (prefs.getBool('pro_status') ?? false) {
      pro = {'name': prefs.getString('pro_name'), 'job': prefs.getString('pro_job'), 'img': prefs.getString('pro_img')};
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final filtered = products.where((p) => p['name'].toString().toLowerCase().contains(query.toLowerCase())).toList();
    return Scaffold(
      appBar: AppBar(title: const Text("Trinity Market"), actions: [
        IconButton(icon: const Icon(Icons.person), onPressed: () => CommonActions.openProfile(context, 'cust')),
        IconButton(icon: const Icon(Icons.settings), onPressed: () => CommonActions.openSettings(context, (){})),
      ]),
      floatingActionButton: FloatingActionButton(onPressed: () => _openAI(context), child: const Icon(Icons.auto_awesome)),
      body: Column(children: [
        Padding(padding: const EdgeInsets.all(15), child: TextField(onChanged: (v) => setState(() => query = v), decoration: InputDecoration(hintText: "Search Plumber, Taps...", prefixIcon: const Icon(Icons.search), border: OutlineInputBorder(borderRadius: BorderRadius.circular(30))))),
        TabBar(controller: _tab, labelColor: Colors.indigo, tabs: const [Tab(text: "Products"), Tab(text: "Experts")]),
        Expanded(child: TabBarView(controller: _tab, children: [
          ListView.builder(itemCount: filtered.length, itemBuilder: (c, i) => _amazonCard(filtered[i])),
          ListView(children: [if (pro != null && pro!['job'].toLowerCase().contains(query.toLowerCase())) _expertCard()])
        ]))
      ]),
    );
  }

  Widget _amazonCard(Map p) => Card(margin: const EdgeInsets.all(10), child: ListTile(
    onTap: () => _showZoom(p['imgs']),
    leading: Image.file(File(p['imgs'][0]), width: 60, height: 60, fit: BoxFit.cover),
    title: Text(p['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
    subtitle: Text("₹${p['price']} (${p['disc']}% Off)"),
    trailing: ElevatedButton(onPressed: () => _confirmOrder(p), child: const Text("BUY")),
  ));

  Widget _expertCard() => Card(margin: const EdgeInsets.all(10), child: ListTile(
    leading: CircleAvatar(backgroundImage: FileImage(File(pro!['img']))),
    title: Text(pro!['name']), subtitle: Text(pro!['job']),
    trailing: ElevatedButton(onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Hiring details shared!"))), child: const Text("HIRE")),
  ));

  void _confirmOrder(Map p) {
    showModalBottomSheet(context: context, builder: (c) => Padding(padding: const EdgeInsets.all(20), child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Text("Confirm Order", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
      const Divider(),
      Text("Item: ${p['name']}"),
      Text("Price: ₹${p['price']}"),
      const SizedBox(height: 20),
      SizedBox(width: double.infinity, child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.orange), onPressed: () => Navigator.pop(context), child: const Text("PROCEED TO PAY (DEMO)"))),
    ])));
  }

  void _showZoom(List imgs) {
    showDialog(context: context, builder: (c) => Dialog.fullscreen(child: Stack(children: [
      PhotoViewGallery.builder(itemCount: imgs.length, builder: (c, i) => PhotoViewGalleryPageOptions(imageProvider: FileImage(File(imgs[i])))),
      Positioned(top: 40, right: 20, child: IconButton(icon: const Icon(Icons.close, color: Colors.white, size: 30), onPressed: () => Navigator.pop(c)))
    ])));
  }
}

// --- AI CHATBOT (FIXED & FUNCTIONAL) ---
void _openAI(BuildContext context) {
  final ctrl = TextEditingController();
  List<Map<String, String>> msgs = [{'r': 'ai', 'm': 'Hello! I am Trinity Assistant. How can I help you?'}];
  showModalBottomSheet(context: context, isScrollControlled: true, builder: (c) => StatefulBuilder(builder: (context, setS) => Padding(
    padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
    child: Container(height: 400, padding: const EdgeInsets.all(20), child: Column(children: [
      const Text("Trinity AI Support", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
      Expanded(child: ListView.builder(itemCount: msgs.length, itemBuilder: (c, i) => Align(
        alignment: msgs[i]['r'] == 'u' ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(padding: const EdgeInsets.all(10), margin: const EdgeInsets.symmetric(vertical: 5), decoration: BoxDecoration(color: msgs[i]['r'] == 'u' ? Colors.blue[100] : Colors.grey[200], borderRadius: BorderRadius.circular(10)), child: Text(msgs[i]['m']!)),
      ))),
      TextField(controller: ctrl, decoration: InputDecoration(hintText: "Ask about hire, price...", suffixIcon: IconButton(icon: const Icon(Icons.send), onPressed: () {
        setS(() {
          msgs.add({'r': 'u', 'm': ctrl.text});
          String r = "Let me check... Search in Experts/Products tab for details.";
          if (ctrl.text.toLowerCase().contains("hire")) r = "To hire, go to Experts tab and click HIRE.";
          msgs.add({'r': 'ai', 'm': r}); ctrl.clear();
        });
      })))
    ])),
  )));
}
