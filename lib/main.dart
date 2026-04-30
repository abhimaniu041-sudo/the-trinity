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

class TrinityApp extends StatelessWidget {
  const TrinityApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1A237E)),
        cardTheme: CardThemeData(elevation: 5, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
      ),
      home: const SplashScreen(),
    );
  }
}

// --- SHARED FUNCTIONS ---
Future<void> handleLogout(BuildContext context) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.remove('userRole'); 
  Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const RoleSelectionPage()), (r) => false);
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
    if (mounted) {
      if (role == 'Shopkeeper') Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const ShopDashboard()));
      else if (role == 'Professional') Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const ProfessionalDashboard()));
      else if (role == 'Customer') Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const CustomerDashboard()));
      else Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const RoleSelectionPage()));
    }
  }
  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: Text("THE TRINITY", style: TextStyle(fontSize: 40, fontWeight: FontWeight.w900, color: Color(0xFF1A237E)))));
  }
}

// --- ROLE SELECTION ---
class RoleSelectionPage extends StatelessWidget {
  const RoleSelectionPage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF1A237E), Color(0xFF3949AB)], begin: Alignment.topCenter)),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Text("Welcome to Trinity", style: TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.bold)),
          const SizedBox(height: 40),
          _btn(context, "Shopkeeper", Icons.storefront),
          _btn(context, "Customer", Icons.person_pin),
          _btn(context, "Professional", Icons.engineering),
        ]),
      ),
    );
  }
  Widget _btn(context, t, icon) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 10),
    child: Card(child: ListTile(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => LoginPage(role: t))),
      leading: Icon(icon, color: const Color(0xFF1A237E)),
      title: Text(t, style: const TextStyle(fontWeight: FontWeight.bold)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
    )),
  );
}

// --- LOGIN PAGE ---
class LoginPage extends StatelessWidget {
  final String role;
  LoginPage({super.key, required this.role});
  final _phone = TextEditingController();
  final _otp = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("$role Login")),
      body: Padding(padding: const EdgeInsets.all(30), child: Column(children: [
        TextField(controller: _phone, decoration: const InputDecoration(labelText: "Mobile", border: OutlineInputBorder())),
        const SizedBox(height: 15),
        TextField(controller: _otp, decoration: const InputDecoration(labelText: "OTP (123456)", border: OutlineInputBorder())),
        const SizedBox(height: 30),
        ElevatedButton(onPressed: () async {
          if (_otp.text == "123456") {
            SharedPreferences prefs = await SharedPreferences.getInstance();
            await prefs.setString('userRole', role);
            await prefs.setString('userPhone', _phone.text);
            Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => role == 'Shopkeeper' ? const ShopDashboard() : role == 'Customer' ? const CustomerDashboard() : const ProfessionalDashboard()), (r) => false);
          }
        }, style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 55)), child: const Text("LOGIN")),
      ])),
    );
  }
}

// --- SHOPKEEPER DASHBOARD ---
class ShopDashboard extends StatefulWidget {
  const ShopDashboard({super.key});
  @override
  State<ShopDashboard> createState() => _ShopDashboardState();
}

class _ShopDashboardState extends State<ShopDashboard> {
  final _n = TextEditingController(), _p = TextEditingController(), _d = TextEditingController();
  final _sName = TextEditingController(), _sCat = TextEditingController();
  List<String> _imgs = [];
  File? _shopImg;
  List products = [];
  bool hasProfile = false;

  @override
  void initState() { super.initState(); _load(); }
  _load() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      hasProfile = prefs.containsKey('shop_name');
      _sName.text = prefs.getString('shop_name') ?? "";
      String? data = prefs.getString('shop_products');
      if (data != null) products = json.decode(data);
    });
  }

  _saveProfile() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('shop_name', _sName.text);
    await prefs.setString('shop_cat', _sCat.text);
    if (_shopImg != null) await prefs.setString('shop_img', _shopImg!.path);
    _load();
  }

  _saveProduct() async {
    if (_n.text.isEmpty || _imgs.isEmpty) return;
    products.add({'name': _n.text, 'price': _p.text, 'disc': _d.text, 'imgs': _imgs, 'shop': _sName.text});
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('shop_products', json.encode(products));
    setState(() { _n.clear(); _p.clear(); _d.clear(); _imgs = []; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("My Store"), actions: [IconButton(icon: const Icon(Icons.logout), onPressed: () => handleLogout(context))]),
      floatingActionButton: FloatingActionButton(onPressed: () => _openAI(context), child: const Icon(Icons.auto_awesome)),
      body: SingleChildScrollView(padding: const EdgeInsets.all(20), child: !hasProfile ? _profileSetup() : _inventory()),
    );
  }

  Widget _profileSetup() => Column(children: [
    const Text("Setup Shop Profile", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
    GestureDetector(onTap: () async {
      final p = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (p != null) setState(() => _shopImg = File(p.path));
    }, child: CircleAvatar(radius: 60, backgroundImage: _shopImg != null ? FileImage(_shopImg!) : null, child: _shopImg == null ? const Icon(Icons.add_a_photo) : null)),
    TextField(controller: _sName, decoration: const InputDecoration(labelText: "Shop Name")),
    TextField(controller: _sCat, decoration: const InputDecoration(labelText: "Category (e.g. Hardware)")),
    ElevatedButton(onPressed: _saveProfile, child: const Text("Create Shop"))
  ]);

  Widget _inventory() => Column(children: [
    GestureDetector(onTap: () async {
      final p = await ImagePicker().pickMultiImage();
      if (p.isNotEmpty) setState(() => _imgs = p.map((f) => f.path).toList());
    }, child: Container(height: 100, width: double.infinity, color: Colors.grey[200], child: _imgs.isEmpty ? const Icon(Icons.add_photo_alternate) : ListView(scrollDirection: Axis.horizontal, children: _imgs.map((f) => Image.file(File(f))).toList()))),
    TextField(controller: _n, decoration: const InputDecoration(labelText: "Item Name")),
    Row(children: [
      Expanded(child: TextField(controller: _p, decoration: const InputDecoration(labelText: "Price"))),
      const SizedBox(width: 10),
      Expanded(child: TextField(controller: _d, decoration: const InputDecoration(labelText: "Discount %"))),
    ]),
    ElevatedButton(onPressed: _saveProduct, child: const Text("Save Product")),
    const Divider(height: 40),
    ...products.asMap().entries.map((e) => Card(child: ListTile(
      leading: Image.file(File(e.value['imgs'][0]), width: 50, fit: BoxFit.cover),
      title: Text(e.value['name']),
      subtitle: Text("₹${e.value['price']} (${e.value['disc']}% Off)"),
      trailing: IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () {
        setState(() => products.removeAt(e.key));
        _saveProduct();
      }),
    ))).toList()
  ]);
}

// --- PROFESSIONAL DASHBOARD ---
class ProfessionalDashboard extends StatefulWidget {
  const ProfessionalDashboard({super.key});
  @override
  State<ProfessionalDashboard> createState() => _ProfessionalDashboardState();
}

class _ProfessionalDashboardState extends State<ProfessionalDashboard> {
  String name = "", job = "";
  bool online = false, hasRequest = false;
  File? _img;

  @override
  void initState() { super.initState(); _load(); }
  _load() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      name = prefs.getString('pro_name') ?? "";
      job = prefs.getString('pro_job') ?? "";
      online = prefs.getBool('pro_status') ?? false;
      String? path = prefs.getString('pro_img');
      if (path != null) _img = File(path);
      hasRequest = prefs.getBool('hired_msg') ?? false; // Simulating notification
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Partner Panel"), actions: [IconButton(icon: const Icon(Icons.logout), onPressed: () => handleLogout(context))]),
      floatingActionButton: FloatingActionButton(onPressed: () => _openAI(context), child: const Icon(Icons.auto_awesome)),
      body: SingleChildScrollView(padding: const EdgeInsets.all(20), child: name == "" ? _setup() : _main()),
    );
  }

  Widget _setup() => Column(children: [
    GestureDetector(onTap: () async {
      final p = await ImagePicker().pickImage(source: ImageSource.camera);
      if (p != null) setState(() => _img = File(p.path));
    }, child: CircleAvatar(radius: 60, backgroundImage: _img != null ? FileImage(_img!) : null, child: const Icon(Icons.camera_alt))),
    TextField(onChanged: (v) => name = v, decoration: const InputDecoration(labelText: "Full Name")),
    TextField(onChanged: (v) => job = v, decoration: const InputDecoration(labelText: "Expertise")),
    ElevatedButton(onPressed: () async {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('pro_name', name); await prefs.setString('pro_job', job);
      if (_img != null) await prefs.setString('pro_img', _img!.path);
      _load();
    }, child: const Text("Go Online"))
  ]);

  Widget _main() => Column(children: [
    Card(color: Colors.indigo, child: Padding(padding: const EdgeInsets.all(20), child: Column(children: [
      CircleAvatar(radius: 40, backgroundImage: _img != null ? FileImage(_img!) : null),
      Text(name, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
      Text(job, style: const TextStyle(color: Colors.white70)),
    ]))),
    SwitchListTile(title: const Text("Online Status"), value: online, onChanged: (v) async {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setBool('pro_status', v); setState(() => online = v);
    }),
    if (hasRequest) Card(color: Colors.orangeAccent, child: ListTile(
      title: const Text("New Work Request!"), subtitle: const Text("Customer: Abhimaniu | Tap Repair"),
      trailing: ElevatedButton(onPressed: () => launchUrl(Uri.parse("tel:9999999999")), child: const Text("Accept & Call")),
    )),
  ]);
}

// --- CUSTOMER DASHBOARD ---
class CustomerDashboard extends StatefulWidget {
  const CustomerDashboard({super.key});
  @override
  State<CustomerDashboard> createState() => _CustomerDashboardState();
}

class _CustomerDashboardState extends State<CustomerDashboard> with SingleTickerProviderStateMixin {
  late TabController _tab;
  String query = "";
  List products = [];
  Map? pro;
  bool isHired = false, hasProfile = false;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _fetch();
  }

  _fetch() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      hasProfile = prefs.containsKey('cust_name');
      String? pData = prefs.getString('shop_products');
      if (pData != null) products = json.decode(pData);
      if (prefs.getBool('pro_status') ?? false) {
        pro = {'name': prefs.getString('pro_name'), 'job': prefs.getString('pro_job'), 'img': prefs.getString('pro_img')};
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final filtered = products.where((p) => p['name'].toString().toLowerCase().contains(query)).toList();

    return Scaffold(
      appBar: AppBar(title: const Text("Trinity Market"), actions: [IconButton(icon: const Icon(Icons.logout), onPressed: () => handleLogout(context))]),
      floatingActionButton: FloatingActionButton(onPressed: () => _openAI(context), child: const Icon(Icons.auto_awesome)),
      body: !hasProfile ? _setupProfile() : Column(children: [
        Padding(padding: const EdgeInsets.all(10), child: TextField(onChanged: (v) => setState(() => query = v.toLowerCase()), decoration: InputDecoration(hintText: "Search anything...", prefixIcon: const Icon(Icons.search), border: OutlineInputBorder(borderRadius: BorderRadius.circular(30))))),
        TabBar(controller: _tab, labelColor: Colors.indigo, tabs: const [Tab(text: "Products"), Tab(text: "Experts")]),
        Expanded(child: TabBarView(controller: _tab, children: [
          ListView.builder(itemCount: filtered.length, itemBuilder: (c, i) => Card(child: ListTile(
            onTap: () => _showZoom(filtered[i]['imgs']),
            leading: Image.file(File(filtered[i]['imgs'][0]), width: 50, fit: BoxFit.cover),
            title: Text(filtered[i]['name']),
            subtitle: Text("${filtered[i]['disc']}% Off | ${filtered[i]['shop']}"),
            trailing: ElevatedButton(onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Purchase Success!"))), child: const Text("BUY")),
          ))),
          ListView(children: [
            if (pro != null && pro!['job'].toString().toLowerCase().contains(query))
              Card(child: ListTile(
                leading: CircleAvatar(backgroundImage: FileImage(File(pro!['img']))),
                title: Text(pro!['name']), subtitle: Text(pro!['job']),
                trailing: isHired 
                  ? IconButton(icon: const Icon(Icons.call, color: Colors.green), onPressed: () => launchUrl(Uri.parse("tel:8888888888")))
                  : ElevatedButton(onPressed: () async {
                      SharedPreferences prefs = await SharedPreferences.getInstance();
                      await prefs.setBool('hired_msg', true);
                      setState(() => isHired = true);
                    }, child: const Text("HIRE")),
              ))
          ])
        ]))
      ]),
    );
  }

  Widget _setupProfile() => Padding(padding: const EdgeInsets.all(40), child: Column(children: [
    const Text("Setup Profile"),
    const TextField(decoration: InputDecoration(labelText: "Your Full Name")),
    ElevatedButton(onPressed: () async {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('cust_name', "User"); _fetch();
    }, child: const Text("Save"))
  ]));

  void _showZoom(List imgs) {
    showDialog(context: context, builder: (c) => Dialog.fullscreen(child: Stack(children: [
      PhotoViewGallery.builder(
        itemCount: imgs.length,
        builder: (c, i) => PhotoViewGalleryPageOptions(imageProvider: FileImage(File(imgs[i])), minScale: PhotoViewComputedScale.contained, maxScale: PhotoViewComputedScale.covered * 2),
      ),
      Positioned(top: 40, right: 20, child: IconButton(icon: const Icon(Icons.close, color: Colors.white, size: 30), onPressed: () => Navigator.pop(c)))
    ])));
  }
}

// --- AI ASSISTANT ---
void _openAI(BuildContext context) {
  final List<Map<String, String>> chat = [{'r': 'ai', 'm': 'Hello! I am Trinity AI. Ask me about hiring or inventory.'}];
  final ctrl = TextEditingController();
  showModalBottomSheet(context: context, isScrollControlled: true, builder: (c) => StatefulBuilder(builder: (c, setS) => Padding(
    padding: EdgeInsets.only(bottom: MediaQuery.of(c).viewInsets.bottom),
    child: Container(height: 400, padding: const EdgeInsets.all(20), child: Column(children: [
      const Text("Trinity AI Assistant", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
      Expanded(child: ListView.builder(itemCount: chat.length, itemBuilder: (c, i) => Align(
        alignment: chat[i]['r'] == 'u' ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(padding: const EdgeInsets.all(10), margin: const EdgeInsets.symmetric(vertical: 5), decoration: BoxDecoration(color: chat[i]['r'] == 'u' ? Colors.blue[100] : Colors.grey[200], borderRadius: BorderRadius.circular(10)), child: Text(chat[i]['m']!)),
      ))),
      TextField(controller: ctrl, decoration: InputDecoration(hintText: "Ask...", suffixIcon: IconButton(icon: const Icon(Icons.send), onPressed: () {
        setS(() {
          chat.add({'r': 'u', 'm': ctrl.text});
          String reply = "I am a demo AI. For real help, contact ABHIMANIU.";
          if (ctrl.text.toLowerCase().contains("hire")) reply = "Go to 'Experts' tab and click HIRE to connect.";
          chat.add({'r': 'ai', 'm': reply});
          ctrl.clear();
        });
      })))
    ])),
  )));
}
