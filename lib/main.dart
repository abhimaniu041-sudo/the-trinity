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

// --- GLOBAL THEME & UTILS ---
class TrinityApp extends StatelessWidget {
  const TrinityApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        // FIXED: Correct CardTheme syntax for latest Flutter
        cardTheme: const CardTheme(
          elevation: 2,
          margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        ),
      ),
      home: const SplashScreen(),
    );
  }
}

// Global functions
Future<void> handleLogout(BuildContext context) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.clear();
  Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const RoleSelectionPage()), (route) => false);
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
    _checkLogin();
  }
  _checkLogin() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? role = prefs.getString('userRole');
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      if (role == 'Shopkeeper') Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const ShopDashboard()));
      else if (role == 'Professional') Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const ProfessionalDashboard()));
      else if (role == 'Customer') Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const CustomerDashboard()));
      else Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const RoleSelectionPage()));
    }
  }
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text("THE TRINITY", style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.indigo, letterSpacing: 2))),
    );
  }
}

// --- ROLE SELECTION ---
class RoleSelectionPage extends StatelessWidget {
  const RoleSelectionPage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("THE TRINITY", style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
            const Text("Premium Marketplace", style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 40),
            _roleCard(context, "Shopkeeper", Icons.storefront_rounded, Colors.indigo),
            _roleCard(context, "Customer", Icons.shopping_bag_rounded, Colors.green),
            _roleCard(context, "Professional", Icons.handyman_rounded, Colors.orange),
            const SizedBox(height: 50),
            const Text("Powered by ABHIMANIU", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.indigo)),
          ],
        ),
      ),
    );
  }

  Widget _roleCard(context, title, icon, color) => Card(
    child: ListTile(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => LoginPage(role: title))),
      leading: CircleAvatar(backgroundColor: color.withOpacity(0.1), child: Icon(icon, color: color)),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
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
        padding: const EdgeInsets.all(25),
        child: Column(children: [
          TextField(decoration: InputDecoration(labelText: "Mobile/Email", border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
          const SizedBox(height: 15),
          TextField(controller: _otp, decoration: InputDecoration(labelText: "OTP (123456)", border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
          const SizedBox(height: 30),
          ElevatedButton(
            onPressed: () async {
              if (_otp.text == "123456") {
                SharedPreferences prefs = await SharedPreferences.getInstance();
                await prefs.setString('userRole', role);
                if (role == 'Shopkeeper') Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const ShopDashboard()), (r)=>false);
                else if (role == 'Customer') Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const CustomerDashboard()), (r)=>false);
                else Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const ProfessionalDashboard()), (r)=>false);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 50)),
            child: const Text("VERIFY & LOGIN"),
          )
        ]),
      ),
    );
  }
}

// --- 1. SHOPKEEPER DASHBOARD ---
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

  _pickImg() async {
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
      appBar: AppBar(title: const Text("Shop Inventory"), actions: [IconButton(icon: const Icon(Icons.logout), onPressed: () => handleLogout(context))]),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(15),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text("Add New Product", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: _pickImg,
            child: Container(
              height: 150, width: double.infinity,
              decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.indigo.withOpacity(0.3))),
              child: _image == null ? const Icon(Icons.add_a_photo, size: 40, color: Colors.indigo) : ClipRRect(borderRadius: BorderRadius.circular(15), child: Image.file(_image!, fit: BoxFit.cover)),
            ),
          ),
          const SizedBox(height: 15),
          TextField(controller: _name, decoration: const InputDecoration(labelText: "Product Name", border: OutlineInputBorder())),
          const SizedBox(height: 10),
          TextField(controller: _price, decoration: const InputDecoration(labelText: "Price (₹)", border: OutlineInputBorder())),
          const SizedBox(height: 10),
          ElevatedButton(onPressed: _save, style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 45)), child: const Text("Save Product")),
          const Divider(height: 40),
          const Text("Live Inventory", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 10),
          ...products.asMap().entries.map((entry) => Card(
            child: ListTile(
              leading: entry.value['img'] != "" ? ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.file(File(entry.value['img']), width: 50, height: 50, fit: BoxFit.cover)) : const Icon(Icons.image),
              title: Text(entry.value['name']),
              subtitle: Text("₹${entry.value['price']}"),
              trailing: IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red), onPressed: () => _remove(entry.key)),
            ),
          )).toList(),
        ]),
      ),
    );
  }
}

// --- 2. PROFESSIONAL DASHBOARD ---
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
    if (_name.text.isEmpty || _job.text.isEmpty) return;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String id = "TRIN-${Random().nextInt(9999)}";
    await prefs.setString('pro_name', _name.text);
    await prefs.setString('pro_job', _job.text);
    await prefs.setString('pro_id', id);
    setState(() { hasProfile = true; proID = id; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Partner Panel"), actions: [IconButton(icon: const Icon(Icons.logout), onPressed: () => handleLogout(context))]),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: hasProfile ? Column(children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Colors.indigo, Colors.blueAccent]),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: Colors.indigo.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))]
            ),
            child: Column(children: [
              const CircleAvatar(radius: 40, backgroundColor: Colors.white, child: Icon(Icons.person, size: 50, color: Colors.indigo)),
              const SizedBox(height: 15),
              Text(_name.text.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
              Text(_job.text, style: const TextStyle(color: Colors.white70, fontSize: 16)),
              const Divider(color: Colors.white24, height: 30),
              Text("OFFICIAL PARTNER ID: $proID", style
