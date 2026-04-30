import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
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
        // FIXED: Correct syntax for older/stable Flutter versions
        cardTheme: CardThemeData(
          elevation: 5,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
      ),
      home: SplashScreen(),
    );
  }
}

// --- GLOBAL UTILS ---
Future<void> handleLogout(BuildContext context) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.remove('userRole'); 
  if (context.mounted) {
    Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => RoleSelectionPage()), (route) => false);
  }
}

// --- SPLASH SCREEN ---
class SplashScreen extends StatefulWidget {
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _init();
  }
  _init() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? role = prefs.getString('userRole');
    await Future.delayed(const Duration(seconds: 3));
    if (mounted) {
      if (role == 'Shopkeeper') Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const ShopDashboard()));
      else if (role == 'Professional') Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const ProfessionalDashboard()));
      else if (role == 'Customer') Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const CustomerDashboard()));
      else Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => RoleSelectionPage()));
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("THE TRINITY", style: TextStyle(fontSize: 50, fontWeight: FontWeight.w900, color: Color(0xFF1A237E), letterSpacing: 5)),
            const SizedBox(height: 5),
            const Text("Powered by ABHIMANIU", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}

// --- ROLE SELECTION ---
class RoleSelectionPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF1A237E), Color(0xFF3949AB)], begin: Alignment.topCenter)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("Welcome to Trinity", style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
            const SizedBox(height: 40),
            _roleBtn(context, "Shopkeeper", Icons.store_rounded),
            _roleBtn(context, "Professional", Icons.handyman_rounded),
            _roleBtn(context, "Customer", Icons.shopping_basket_rounded),
          ],
        ),
      ),
    );
  }
  Widget _roleBtn(context, title, icon) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 10),
    child: Card(
      child: ListTile(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => LoginPage(role: title))),
        leading: Icon(icon, color: const Color(0xFF1A237E), size: 28),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 14),
      ),
    ),
  );
}

// --- LOGIN ---
class LoginPage extends StatelessWidget {
  final String role;
  LoginPage({required this.role});
  final _otp = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("$role Access")),
      body: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(children: [
          const TextField(decoration: InputDecoration(labelText: "Mobile", border: OutlineInputBorder())),
          const SizedBox(height: 15),
          TextField(controller: _otp, decoration: const InputDecoration(labelText: "OTP (123456)", border: OutlineInputBorder())),
          const SizedBox(height: 30),
          ElevatedButton(
            onPressed: () async {
              if (_otp.text == "123456") {
                SharedPreferences prefs = await SharedPreferences.getInstance();
                await prefs.setString('userRole', role);
                Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => _route(role)), (r)=>false);
              }
            },
            style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 55)),
            child: const Text("AUTHENTICATE"),
          )
        ]),
      ),
    );
  }
  Widget _route(role) {
    if (role == 'Shopkeeper') return const ShopDashboard();
    if (role == 'Professional') return const ProfessionalDashboard();
    return const CustomerDashboard();
  }
}

// --- 1. SHOPKEEPER (MULTI-IMAGE) ---
class ShopDashboard extends StatefulWidget {
  const ShopDashboard({super.key});
  @override
  State<ShopDashboard> createState() => _ShopDashboardState();
}

class _ShopDashboardState extends State<ShopDashboard> {
  final _n = TextEditingController();
  final _p = TextEditingController();
  List<String> _imgs = [];
  List products = [];

  @override
  void initState() { super.initState(); _load(); }
  _load() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? data = prefs.getString('trinity_products');
    if (data != null) setState(() => products = json.decode(data));
  }
  _save() async {
    if (_n.text.isEmpty || _imgs.isEmpty) return;
    products.add({'name': _n.text, 'price': _p.text, 'imgs': _imgs});
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('trinity_products', json.encode(products));
    setState(() { _n.clear(); _p.clear(); _imgs = []; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Inventory"), actions: [IconButton(icon: const Icon(Icons.logout), onPressed: () => handleLogout(context))]),
      floatingActionButton: FloatingActionButton(onPressed: () => _openAI(context), child: const Icon(Icons.auto_awesome)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(15),
        child: Column(children: [
          GestureDetector(
            onTap: () async {
              final p = await ImagePicker().pickMultiImage();
              if (p.isNotEmpty) setState(() => _imgs = p.map((f) => f.path).toList());
            },
            child: Container(
              height: 120, width: double.infinity, decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(15)),
              child: _imgs.isEmpty ? const Icon(Icons.add_a_photo) : ListView(scrollDirection: Axis.horizontal, children: _imgs.map((f) => Image.file(File(f))).toList()),
            ),
          ),
          TextField(controller: _n, decoration: const InputDecoration(labelText: "Item Name")),
          TextField(controller: _p, decoration: const InputDecoration(labelText: "Price")),
          ElevatedButton(onPressed: _save, child: const Text("Save Product")),
          const Divider(height: 30),
          ...products.asMap().entries.map((e) => Card(
            child: ListTile(
              leading: Image.file(File(e.value['imgs'][0]), width: 50, fit: BoxFit.cover),
              title: Text(e.value['name']),
              trailing: IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () {
                setState(() => products.removeAt(e.key));
                _save(); 
              }),
            ),
          )).toList(),
        ]),
      ),
    );
  }
}

// --- 2. PROFESSIONAL ---
class ProfessionalDashboard extends StatefulWidget {
  const ProfessionalDashboard({super.key});
  @override
  State<ProfessionalDashboard> createState() => _ProfessionalDashboardState();
}

class _ProfessionalDashboardState extends State<ProfessionalDashboard> {
  File? _photo;
  String name = "";
  @override
  void initState() { super.initState(); _load(); }
  _load() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() { name = prefs.getString('pro_name') ?? ""; });
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Partner Panel"), actions: [IconButton(icon: const Icon(Icons.logout), onPressed: () => handleLogout(context))]),
      floatingActionButton: FloatingActionButton(onPressed: () => _openAI(context), child: const Icon(Icons.auto_awesome)),
      body: name == "" ? _create() : const Center(child: Text("Welcome back, Partner!")),
    );
  }
  Widget _create() => Padding(
    padding: const EdgeInsets.all(40),
    child: Column(children: [
      GestureDetector(
        onTap: () async {
          final p = await ImagePicker().pickImage(source: ImageSource.camera);
          if (p != null) setState(() => _photo = File(p.path));
        },
        child: CircleAvatar(radius: 60, backgroundImage: _photo != null ? FileImage(_photo!) : null, child: _photo == null ? const Icon(Icons.camera_alt) : null),
      ),
      const TextField(decoration: InputDecoration(labelText: "Expertise")),
      ElevatedButton(onPressed: () async {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('pro_name', "PARTNER");
        _load();
      }, child: const Text("GO LIVE")),
    ]),
  );
}

// --- 3. CUSTOMER (SEARCH FIXED) ---
class CustomerDashboard extends StatefulWidget {
  const CustomerDashboard({super.key});
  @override
  State<CustomerDashboard> createState() => _CustomerDashboardState();
}

class _CustomerDashboardState extends State<CustomerDashboard> with SingleTickerProviderStateMixin {
  late TabController _tab;
  String query = "";
  List products = [];
  bool hired = false;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _fetch();
  }
  _fetch() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? data = prefs.getString('trinity_products');
    if (data != null) setState(() => products = json.decode(data));
  }

  @override
  Widget build(BuildContext context) {
    final filtered = products.where((p) => p['name'].toString().toLowerCase().contains(query)).toList();
    return Scaffold(
      appBar: AppBar(
        title: const Text("Trinity Marketplace"),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(100),
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: TextField(
                onChanged: (v) => setState(() => query = v.toLowerCase()),
                decoration: InputDecoration(hintText: "Search...", filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(30))),
              ),
            ),
            TabBar(controller: _tab, tabs: const [Tab(text: "Products"), Tab(text: "Experts")]),
          ]),
        ),
      ),
      floatingActionButton: FloatingActionButton(onPressed: () => _openAI(context), child: const Icon(Icons.auto_awesome)),
      body: TabBarView(controller: _tab, children: [
        ListView.builder(
          itemCount: filtered.length,
          itemBuilder: (c, i) => Card(
            child: ListTile(
              onTap: () => _view(filtered[i]),
              leading: Image.file(File(filtered[i]['imgs'][0]), width: 50, fit: BoxFit.cover),
              title: Text(filtered[i]['name']),
              trailing: ElevatedButton(onPressed: (){}, child: const Text("BUY")),
            ),
          ),
        ),
        const Center(child: Text("Professionals List")),
      ]),
    );
  }
  void _view(Map p) {
    showDialog(context: context, builder: (c) => AlertDialog(
      title: Text(p['name']),
      content: SizedBox(height: 200, child: ListView(scrollDirection: Axis.horizontal, children: (p['imgs'] as List).map((f) => Image.file(File(f))).toList())),
    ));
  }
}

// --- AI CHATBOT (FIXED) ---
void _openAI(BuildContext context) {
  final _msg = TextEditingController();
  showModalBottomSheet(
    context: context, isScrollControlled: true, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
    builder: (context) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        height: 400, padding: const EdgeInsets.all(20),
        child: Column(children: [
          const Text("Trinity AI Assistant", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const Expanded(child: Center(child: Text("Hello! How can I help you manage orders today?"))),
          TextField(controller: _msg, decoration: InputDecoration(hintText: "Ask something...", suffixIcon: IconButton(icon: const Icon(Icons.send), onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("AI: I am checking your request...")));
            _msg.clear();
          }))),
        ]),
      ),
    ),
  );
}
