import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const TrinityApp());
}

// Global function to get correct dashboard based on role
Widget getDashboard(String role) {
  if (role == 'Shopkeeper') return const ShopDashboard();
  if (role == 'Professional') return const ProfessionalDashboard();
  return const CustomerDashboard();
}

// Global logout function
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
        primarySwatch: Colors.indigo,
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
      ),
      home: const SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initApp();
  }

  _initApp() async {
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
        child: Text("THE TRINITY", style: TextStyle(fontSize: 35, fontWeight: FontWeight.bold, color: Colors.indigo, letterSpacing: 2)),
      ),
    );
  }
}

// --- 1. ROLE SELECTION ---
class RoleSelectionPage extends StatelessWidget {
  const RoleSelectionPage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("THE TRINITY", style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold)),
            const Text("Powered by ABHIMANIU", style: TextStyle(color: Colors.indigoAccent)),
            const SizedBox(height: 50),
            _roleBtn(context, "Shopkeeper", Icons.store, Colors.indigo),
            _roleBtn(context, "Customer", Icons.shopping_bag, Colors.green),
            _roleBtn(context, "Professional", Icons.handyman, Colors.orange),
          ],
        ),
      ),
    );
  }

  Widget _roleBtn(context, role, icon, color) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 8),
    child: ListTile(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => LoginPage(role: role))),
      leading: Icon(icon, color: color),
      title: Text(role, style: const TextStyle(fontWeight: FontWeight.bold)),
      tileColor: color.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
    ),
  );
}

// --- 2. LOGIN PAGE ---
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
          ElevatedButton(
            onPressed: () async {
              if (_otp.text == "123456") {
                SharedPreferences prefs = await SharedPreferences.getInstance();
                await prefs.setString('userRole', role);
                Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => getDashboard(role)), (route) => false);
              }
            },
            child: const Text("LOGIN"),
          )
        ]),
      ),
    );
  }
}

// --- 3. SHOPKEEPER DASHBOARD ---
class ShopDashboard extends StatefulWidget {
  const ShopDashboard({super.key});
  @override
  State<ShopDashboard> createState() => _ShopDashboardState();
}

class _ShopDashboardState extends State<ShopDashboard> {
  final _name = TextEditingController();
  final _price = TextEditingController();
  final _qty = TextEditingController();
  List products = [];

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  _loadProducts() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? data = prefs.getString('shop_products');
    if (data != null) setState(() => products = json.decode(data));
  }

  _save() async {
    if (_name.text.isEmpty) return;
    products.add({'name': _name.text, 'price': _price.text, 'stock': _qty.text});
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('shop_products', json.encode(products));
    _name.clear(); _price.clear(); _qty.clear();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Shop Dashboard"), actions: [IconButton(icon: const Icon(Icons.logout), onPressed: () => handleLogout(context))]),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(children: [
          TextField(controller: _name, decoration: const InputDecoration(labelText: "Product Name")),
          TextField(controller: _price, decoration: const InputDecoration(labelText: "Price")),
          TextField(controller: _qty, decoration: const InputDecoration(labelText: "Stock")),
          ElevatedButton(onPressed: _save, child: const Text("Save Product")),
          const Divider(height: 40),
          ...products.map((p) => ListTile(title: Text(p['name']), trailing: Text("₹${p['price']}"))).toList(),
        ]),
      ),
    );
  }
}

// --- 4. PROFESSIONAL DASHBOARD ---
class ProfessionalDashboard extends StatefulWidget {
  const ProfessionalDashboard({super.key});
  @override
  State<ProfessionalDashboard> createState() => _ProfessionalDashboardState();
}

class _ProfessionalDashboardState extends State<ProfessionalDashboard> {
  final _job = TextEditingController();
  bool isLive = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Partner Panel"), actions: [IconButton(icon: const Icon(Icons.logout), onPressed: () => handleLogout(context))]),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(children: [
          TextField(controller: _job, decoration: const InputDecoration(labelText: "Job Title (e.g. Plumber)")),
          const SizedBox(height: 20),
          ElevatedButton(onPressed: () => setState(() => isLive = true), child: const Text("Go Online")),
          if (isLive) const Card(color: Colors.green, child: ListTile(title: Text("You are now LIVE", style: TextStyle(color: Colors.white)))),
        ]),
      ),
    );
  }
}

// --- 5. CUSTOMER DASHBOARD ---
class CustomerDashboard extends StatefulWidget {
  const CustomerDashboard({super.key});
  @override
  State<CustomerDashboard> createState() => _CustomerDashboardState();
}

class _CustomerDashboardState extends State<CustomerDashboard> with SingleTickerProviderStateMixin {
  late TabController _tab;
  List products = [];

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _load();
  }

  _load() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? data = prefs.getString('shop_products');
    if (data != null) setState(() => products = json.decode(data));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Trinity Store"),
        actions: [IconButton(icon: const Icon(Icons.logout), onPressed: () => handleLogout(context))],
        bottom: TabBar(controller: _tab, tabs: const [Tab(text: "Products"), Tab(text: "Pros")]),
      ),
      body: TabBarView(controller: _tab, children: [
        ListView.builder(
          itemCount: products.length,
          itemBuilder: (c, i) => Card(child: ListTile(title: Text(products[i]['name']), trailing: Text("₹${products[i]['price']}"))),
        ),
        const Center(child: Text("Professionals List")),
      ]),
    );
  }
}
