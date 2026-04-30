import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';
import 'dart:math';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const TrinityApp());
}

// Global functions for logic
Widget getDashboard(String role) {
  if (role == 'Shopkeeper') return const ShopDashboard();
  if (role == 'Professional') return const ProfessionalDashboard();
  return const CustomerDashboard();
}

Future<void> handleLogout(BuildContext context) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.clear();
  if (context.mounted) {
    Navigator.pushAndRemoveUntil(
      context, 
      MaterialPageRoute(builder: (context) => const RoleSelectionPage()), 
      (route) => false
    );
  }
}

class TrinityApp extends StatelessWidget {
  const TrinityApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        cardTheme: CardThemeData(
          elevation: 4,
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
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
  void initState() {
    super.initState();
    _init();
  }

  _init() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? role = prefs.getString('userRole');
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      if (role != null) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => getDashboard(role)));
      } else {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const RoleSelectionPage()));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text("THE TRINITY", style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.indigo, letterSpacing: 2)),
      ),
    );
  }
}

// --- ROLE SELECTION ---
class RoleSelectionPage extends StatelessWidget {
  const RoleSelectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("THE TRINITY", style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
            const Text("Premium Service Hub", style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 50),
            _buildBtn(context, "Shopkeeper", Icons.storefront_rounded, Colors.indigo),
            _buildBtn(context, "Customer", Icons.shopping_cart_rounded, Colors.green),
            _buildBtn(context, "Professional", Icons.handyman_rounded, Colors.orange),
            const SizedBox(height: 40),
            const Text("Powered by ABHIMANIU", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo)),
          ],
        ),
      ),
    );
  }

  Widget _buildBtn(context, role, icon, color) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 10),
    child: ListTile(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => LoginPage(role: role))),
      leading: CircleAvatar(backgroundColor: color.withOpacity(0.1), child: Icon(icon, color: color)),
      title: Text(role, style: const TextStyle(fontWeight: FontWeight.bold)),
      tileColor: color.withOpacity(0.05),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 14),
    ),
  );
}

// --- LOGIN ---
class LoginPage extends StatelessWidget {
  final String role;
  LoginPage({super.key, required this.role});
  final _otp = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("$role Login")),
      body: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(children: [
          const TextField(decoration: InputDecoration(labelText: "Mobile / Email", border: OutlineInputBorder())),
          const SizedBox(height: 20),
          TextField(controller: _otp, decoration: const InputDecoration(labelText: "OTP (123456)", border: OutlineInputBorder())),
          const SizedBox(height: 30),
          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton(
              onPressed: () async {
                if (_otp.text == "123456") {
                  SharedPreferences prefs = await SharedPreferences.getInstance();
                  await prefs.setString('userRole', role);
                  if (context.mounted) {
                    Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => getDashboard(role)), (r) => false);
                  }
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white),
              child: const Text("LOGIN"),
            ),
          ),
        ]),
      ),
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
  final _name = TextEditingController();
  final _price = TextEditingController();
  File? _image;
  List products = [];

  @override
  void initState() { super.initState(); _load(); }

  _load() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? data = prefs.getString('trinity_products');
    if (data != null) setState(() => products = json.decode(data));
  }

  _pick() async {
    final p = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (p != null) setState(() => _image = File(p.path));
  }

  _save() async {
    if (_name.text.isEmpty) return;
    products.add({'name': _name.text, 'price': _price.text, 'img': _image?.path ?? ""});
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('trinity_products', json.encode(products));
    _name.clear(); _price.clear(); _image = null;
    setState(() {});
  }

  _remove(int index) async {
    products.removeAt(index);
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('trinity_products', json.encode(products));
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Inventory"), actions: [IconButton(icon: const Icon(Icons.logout), onPressed: () => handleLogout(context))]),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(children: [
          GestureDetector(
            onTap: _pick,
            child: Container(
              height: 150, width: double.infinity,
              decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(15)),
              child: _image == null ? const Icon(Icons.add_a_photo) : ClipRRect(borderRadius: BorderRadius.circular(15), child: Image.file(_image!, fit: BoxFit.cover)),
            ),
          ),
          TextField(controller: _name, decoration: const InputDecoration(labelText: "Product Name")),
          TextField(controller: _price, decoration: const InputDecoration(labelText: "Price")),
          ElevatedButton(onPressed: _save, child: const Text("Save Product")),
          const Divider(height: 40),
          ...products.asMap().entries.map((e) => Card(
            child: ListTile(
              title: Text(e.value['name']),
              subtitle: Text("₹${e.value['price']}"),
              trailing: IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _remove(e.key)),
            ),
          )).toList(),
        ]),
      ),
    );
  }
}

// --- PROFESSIONAL DASHBOARD ---
class ProfessionalDashboard extends StatefulWidget {
  const ProfessionalDashboard({super.key});
  @override
  State<ProfessionalDashboard> createState() => _ProfessionalDashboardState();
}

class _ProfessionalDashboardState extends State<ProfessionalDashboard> {
  bool isOnline = false;
  bool hasProfile = false;
  final _name = TextEditingController();
  final _job = TextEditingController();
  String proID = "";

  @override
  void initState() { super.initState(); _load(); }

  _load() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      isOnline = prefs.getBool('pro_status') ?? false;
      _name.text = prefs.getString('pro_name') ?? "";
      _job.text = prefs.getString('pro_job') ?? "";
      proID = prefs.getString('pro_id') ?? "";
      if (_name.text.isNotEmpty) hasProfile = true;
    });
  }

  _save() async {
    if (_name.text.isEmpty) return;
    String id = "TRIN-${Random().nextInt(9999)}";
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('pro_name', _name.text);
    await prefs.setString('pro_job', _job.text);
    await prefs.setString('pro_id', id);
    setState(() { proID = id; hasProfile = true; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Partner Panel"), actions: [IconButton(icon: const Icon(Icons.logout), onPressed: () => handleLogout(context))]),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: hasProfile ? Column(children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(gradient: const LinearGradient(colors: [Colors.indigo, Colors.blue]), borderRadius: BorderRadius.circular(20)),
            child: Column(children: [
              const CircleAvatar(radius: 40, child: Icon(Icons.person, size: 40)),
              const SizedBox(height: 10),
              Text(_name.text.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              Text(_job.text, style: const TextStyle(color: Colors.white70)),
              const Divider(color: Colors.white24),
              Text("ID: $proID", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ]),
          ),
          SwitchListTile(
            title: Text(isOnline ? "ONLINE" : "OFFLINE", style: TextStyle(color: isOnline ? Colors.green : Colors.red, fontWeight: FontWeight.bold)),
            value: isOnline,
            onChanged: (v) async {
              SharedPreferences prefs = await SharedPreferences.getInstance();
              await prefs.setBool('pro_status', v);
              setState(() => isOnline = v);
            },
          )
        ]) : Column(children: [
          TextField(controller: _name, decoration: const InputDecoration(labelText: "Name")),
          TextField(controller: _job, decoration: const InputDecoration(labelText: "Job (e.g. Plumber)")),
          ElevatedButton(onPressed: _save, child: const Text("Create Profile"))
        ]),
      ),
    );
  }
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
  Map? onlinePro;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _fetch();
  }

  _fetch() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? pData = prefs.getString('trinity_products');
    if (pData != null) products = json.decode(pData);
    bool online = prefs.getBool('pro_status') ?? false;
    if (online) {
      onlinePro = {'name': prefs.getString('pro_name'), 'job': prefs.getString('pro_job'), 'id': prefs.getString('pro_id')};
    } else {
      onlinePro = null;
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Trinity Market"),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _fetch), IconButton(icon: const Icon(Icons.logout), onPressed: () => handleLogout(context))],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(100),
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                onChanged: (v) => setState(() => query = v.toLowerCase()),
                decoration: InputDecoration(hintText: "Search...", prefixIcon: const Icon(Icons.search), filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(30))),
              ),
            ),
            TabBar(controller: _tab, tabs: const [Tab(text: "Products"), Tab(text: "Professionals")]),
          ]),
        ),
      ),
      body: TabBarView(controller: _tab, children: [
        ListView(children: products.where((p) => p['name'].toLowerCase().contains(query)).map((p) => Card(
          child: ListTile(title: Text(p['name']), trailing: Text("₹${p['price']}")),
        )).toList()),
        ListView(children: [
          if (onlinePro != null && onlinePro!['job'].toLowerCase().contains(query))
            Card(child: ListTile(leading: const CircleAvatar(child: Icon(Icons.person)), title: Text(onlinePro!['name']), subtitle: Text(onlinePro!['job']))),
          if (onlinePro == null) const Center(child: Padding(padding: EdgeInsets.all(20), child: Text("No Professionals online"))),
        ]),
      ]),
    );
  }
}
