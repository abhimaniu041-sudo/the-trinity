import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const TrinityApp());
}

// --- GLOBAL UTILS ---
Widget getDashboard(String role) {
  if (role == 'Shopkeeper') return const ShopDashboard();
  if (role == 'Professional') return const ProfessionalDashboard();
  return const CustomerDashboard();
}

Future<void> handleLogout(BuildContext context) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.clear();
  if (context.mounted) {
    Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const RoleSelectionPage()), (route) => false);
  }
}

class TrinityApp extends StatelessWidget {
  const TrinityApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.indigo, useMaterial3: true),
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
    _checkStatus();
  }
  _checkStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? role = prefs.getString('userRole');
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => role != null ? getDashboard(role) : const RoleSelectionPage()));
    }
  }
  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: Text("THE TRINITY", style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.indigo))));
  }
}

// --- ROLE SELECTION ---
class RoleSelectionPage extends StatelessWidget {
  const RoleSelectionPage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text("THE TRINITY", style: TextStyle(fontSize: 35, fontWeight: FontWeight.bold)),
          const SizedBox(height: 40),
          _btn(context, "Shopkeeper", Icons.store, Colors.indigo),
          _btn(context, "Customer", Icons.shopping_bag, Colors.green),
          _btn(context, "Professional", Icons.handyman, Colors.orange),
        ],
      ),
    );
  }
  Widget _btn(context, role, icon, color) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 8),
    child: ListTile(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => LoginPage(role: role))),
      leading: Icon(icon, color: color), title: Text(role), tileColor: color.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
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
      body: Padding(padding: const EdgeInsets.all(30), child: Column(children: [
        const TextField(decoration: InputDecoration(labelText: "Enter Mobile", border: OutlineInputBorder())),
        const SizedBox(height: 20),
        TextField(controller: _otp, decoration: const InputDecoration(labelText: "OTP (123456)", border: OutlineInputBorder())),
        const SizedBox(height: 20),
        ElevatedButton(onPressed: () async {
          if (_otp.text == "123456") {
            SharedPreferences prefs = await SharedPreferences.getInstance();
            await prefs.setString('userRole', role);
            Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => getDashboard(role)), (route) => false);
          }
        }, child: const Text("LOGIN")),
      ])),
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
  List products = [];

  @override
  void initState() { super.initState(); _load(); }
  
  _load() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? data = prefs.getString('trinity_products');
    if (data != null) setState(() => products = json.decode(data));
  }

  _save() async {
    if (_name.text.isEmpty) return;
    products.add({'name': _name.text, 'price': _price.text});
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('trinity_products', json.encode(products));
    _name.clear(); _price.clear();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Shop Inventory"), actions: [IconButton(icon: const Icon(Icons.logout), onPressed: () => handleLogout(context))]),
      body: Padding(padding: const EdgeInsets.all(20), child: Column(children: [
        TextField(controller: _name, decoration: const InputDecoration(labelText: "Product Name")),
        TextField(controller: _price, decoration: const InputDecoration(labelText: "Price")),
        ElevatedButton(onPressed: _save, child: const Text("Save Product")),
        const Divider(),
        Expanded(child: ListView.builder(itemCount: products.length, itemBuilder: (c, i) => ListTile(title: Text(products[i]['name']), trailing: Text("₹${products[i]['price']}")))),
      ])),
    );
  }
}

// --- 2. PROFESSIONAL DASHBOARD (Online/Offline Logic) ---
class ProfessionalDashboard extends StatefulWidget {
  const ProfessionalDashboard({super.key});
  @override
  State<ProfessionalDashboard> createState() => _ProfessionalDashboardState();
}

class _ProfessionalDashboardState extends State<ProfessionalDashboard> {
  bool isOnline = false;
  final _job = TextEditingController();

  @override
  void initState() { super.initState(); _load(); }
  
  _load() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      isOnline = prefs.getBool('pro_status') ?? false;
      _job.text = prefs.getString('pro_job') ?? "";
    });
  }

  _toggle(bool val) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('pro_status', val);
    await prefs.setString('pro_job', _job.text);
    setState(() => isOnline = val);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Professional Panel"), actions: [IconButton(icon: const Icon(Icons.logout), onPressed: () => handleLogout(context))]),
      body: Padding(padding: const EdgeInsets.all(20), child: Column(children: [
        TextField(controller: _job, decoration: const InputDecoration(labelText: "Your Job (e.g. Electrician)")),
        const SizedBox(height: 20),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(isOnline ? "YOU ARE ONLINE" : "YOU ARE OFFLINE", style: TextStyle(fontWeight: FontWeight.bold, color: isOnline ? Colors.green : Colors.red)),
          Switch(value: isOnline, onChanged: _toggle),
        ]),
        const Spacer(),
        if (isOnline) const Card(color: Colors.green, child: ListTile(title: Text("Customers can now see you", style: TextStyle(color: Colors.white)))),
      ])),
    );
  }
}

// --- 3. CUSTOMER DASHBOARD (Fixed Search & Visibility) ---
class CustomerDashboard extends StatefulWidget {
  const CustomerDashboard({super.key});
  @override
  State<CustomerDashboard> createState() => _CustomerDashboardState();
}

class _CustomerDashboardState extends State<CustomerDashboard> with SingleTickerProviderStateMixin {
  late TabController _tab;
  String query = "";
  List allProducts = [];
  Map<String, dynamic>? proData;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _fetch();
  }

  _fetch() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    // Products load
    String? pData = prefs.getString('trinity_products');
    if (pData != null) allProducts = json.decode(pData);
    
    // Pro Status check
    bool proOnline = prefs.getBool('pro_status') ?? false;
    if (proOnline) {
      proData = {'name': 'Abhimaniu Pro', 'job': prefs.getString('pro_job') ?? 'Pro'};
    } else {
      proData = null; // Agar offline hai toh data clear
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
          preferredSize: const Size.fromHeight(110),
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: TextField(
                onChanged: (v) => setState(() => query = v.toLowerCase()),
                decoration: InputDecoration(hintText: "Search anything...", prefixIcon: const Icon(Icons.search), filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(30))),
              ),
            ),
            TabBar(controller: _tab, tabs: const [Tab(text: "Products"), Tab(text: "Professionals")]),
          ]),
        ),
      ),
      body: TabBarView(controller: _tab, children: [
        // Tab 1: Products Search
        ListView(children: allProducts.map((p) {
          if (p['name'].toString().toLowerCase().contains(query)) {
            return Card(child: ListTile(title: Text(p['name']), trailing: Text("₹${p['price']}")));
          }
          return const SizedBox();
        }).toList()),
        
        // Tab 2: Professionals (Visible ONLY if Online)
        ListView(children: [
          if (proData != null && proData!['job'].toString().toLowerCase().contains(query))
            Card(child: ListTile(leading: const CircleAvatar(child: Icon(Icons.person)), title: Text(proData!['name']), subtitle: Text(proData!['job']), trailing: const Icon(Icons.phone_locked, color: Colors.green))),
          if (proData == null) const Center(padding: EdgeInsets.all(20), child: Text("No Professionals online right now")),
        ]),
      ]),
    );
  }
}
