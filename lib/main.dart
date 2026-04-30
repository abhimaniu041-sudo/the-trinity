import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert'; // Data convert karne ke liye

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
        primarySwatch: Colors.indigo,
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
      ),
      home: const SplashScreen(),
    );
  }
}

// --- SPLASH SCREEN (Login Check) ---
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
    Future.delayed(const Duration(seconds: 2), () {
      if (role != null) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => getDashboard(role)));
      } else {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const RoleSelectionPage()));
      }
    });
  }

  Widget getDashboard(String role) {
    if (role == 'Shopkeeper') return const ShopDashboard();
    if (role == 'Professional') return const ProfessionalDashboard();
    return const CustomerDashboard();
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text("THE TRINITY", style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.indigo))),
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
            const Text("WELCOME TO TRINITY", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
            const Text("Powered by ABHIMANIU", style: TextStyle(color: Colors.indigo)),
            const SizedBox(height: 40),
            _roleTile(context, "Shopkeeper", Icons.store, Colors.indigo),
            _roleTile(context, "Customer", Icons.shopping_bag, Colors.green),
            _roleTile(context, "Professional", Icons.handyman, Colors.orange),
          ],
        ),
      ),
    );
  }

  Widget _roleTile(context, role, icon, color) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 10),
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
                Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => SplashScreen().getDashboard(role)), (route) => false);
              }
            },
            child: const Text("LOGIN"),
          )
        ]),
      ),
    );
  }
}

// --- 3. SHOPKEEPER DASHBOARD (Real Saving) ---
class ShopDashboard extends StatefulWidget {
  const ShopDashboard({super.key});
  @override
  State<ShopDashboard> createState() => _ShopDashboardState();
}

class _ShopDashboardState extends State<ShopDashboard> {
  final _name = TextEditingController();
  final _price = TextEditingController();
  final _qty = TextEditingController();
  List<Map<String, dynamic>> products = [];

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  _loadProducts() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? data = prefs.getString('shop_products');
    if (data != null) {
      setState(() => products = List<Map<String, dynamic>>.from(json.decode(data)));
    }
  }

  _saveProduct() async {
    if (_name.text.isEmpty || _price.text.isEmpty) return;
    
    Map<String, dynamic> newProduct = {
      'name': _name.text,
      'price': _price.text,
      'stock': _qty.text,
    };

    products.add(newProduct);
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('shop_products', json.encode(products));
    
    _name.clear(); _price.clear(); _qty.clear();
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Product Saved Successfully!")));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("My Shop Inventory"), actions: [IconButton(icon: const Icon(Icons.logout), onPressed: () => _logout(context))]),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(children: [
          const Text("Add New Item", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          TextField(controller: _name, decoration: const InputDecoration(labelText: "Item Name")),
          TextField(controller: _price, decoration: const InputDecoration(labelText: "Price (₹)")),
          TextField(controller: _qty, decoration: const InputDecoration(labelText: "Stock Quantity")),
          const SizedBox(height: 20),
          ElevatedButton(onPressed: _saveProduct, child: const Text("SAVE TO STORE")),
          const Divider(height: 40),
          const Text("Live Inventory", style: TextStyle(fontWeight: FontWeight.bold)),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: products.length,
            itemBuilder: (context, i) => ListTile(
              title: Text(products[i]['name']),
              subtitle: Text("Stock: ${products[i]['stock']}"),
              trailing: Text("₹${products[i]['price']}"),
            ),
          )
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
  final _name = TextEditingController();
  final _job = TextEditingController();
  final _exp = TextEditingController();
  bool hasProfile = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  _loadProfile() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (prefs.containsKey('pro_name')) {
      setState(() {
        hasProfile = true;
        _name.text = prefs.getString('pro_name')!;
        _job.text = prefs.getString('pro_job')!;
        _exp.text = prefs.getString('pro_exp')!;
      });
    }
  }

  _saveProfile() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('pro_name', _name.text);
    await prefs.setString('pro_job', _job.text);
    await prefs.setString('pro_exp', _exp.text);
    setState(() => hasProfile = true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Partner Panel"), actions: [IconButton(icon: const Icon(Icons.logout), onPressed: () => _logout(context))]),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: hasProfile 
        ? Column(children: [
            const Card(
              color: Colors.orangeAccent,
              child: ListTile(
                leading: Icon(Icons.verified, color: Colors.white),
                title: Text("Profile Live!", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 20),
            _proInfoTile("Name", _name.text),
            _proInfoTile("Expertise", _job.text),
            _proInfoTile("Experience", "${_exp.text} Years"),
            const Spacer(),
            ElevatedButton(onPressed: () => setState(() => hasProfile = false), child: const Text("Edit Profile")),
          ])
        : Column(children: [
            const Text("Enter Professional Details", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            TextField(controller: _name, decoration: const InputDecoration(labelText: "Full Name")),
            TextField(controller: _job, decoration: const InputDecoration(labelText: "Job (e.g. Electrician)")),
            TextField(controller: _exp, decoration: const InputDecoration(labelText: "Experience (Years)")),
            const SizedBox(height: 30),
            ElevatedButton(onPressed: _saveProfile, child: const Text("GO ONLINE & SAVE")),
          ]),
      ),
    );
  }

  Widget _proInfoTile(label, val) => ListTile(title: Text(label), subtitle: Text(val, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)));
}

// --- 5. CUSTOMER DASHBOARD (Search + Logic) ---
class CustomerDashboard extends StatefulWidget {
  const CustomerDashboard({super.key});
  @override
  State<CustomerDashboard> createState() => _CustomerDashboardState();
}

class _CustomerDashboardState extends State<CustomerDashboard> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String query = "";
  List products = [];
  Map<String, dynamic>? pro;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  _loadData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? pData = prefs.getString('shop_products');
    if (pData != null) setState(() => products = json.decode(pData));
    
    if (prefs.containsKey('pro_name')) {
      setState(() => pro = {
        'name': prefs.getString('pro_name'),
        'job': prefs.getString('pro_job'),
        'exp': prefs.getString('pro_exp'),
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Trinity Market"),
        actions: [IconButton(icon: const Icon(Icons.logout), onPressed: () => _logout(context))],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(110),
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: TextField(
                onChanged: (v) => setState(() => query = v.toLowerCase()),
                decoration: InputDecoration(
                  hintText: "Search here...",
                  prefixIcon: const Icon(Icons.search),
                  filled: true, fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
                ),
              ),
            ),
            TabBar(controller: _tabController, tabs: const [Tab(text: "Products"), Tab(text: "Pros")]),
          ]),
        ),
      ),
      body: TabBarView(controller: _tabController, children: [
        // Tab 1: Dynamic Products
        ListView.builder(
          itemCount: products.length,
          itemBuilder: (context, i) {
            if (products[i]['name'].toLowerCase().contains(query)) {
              return Card(
                margin: const EdgeInsets.all(10),
                child: ListTile(
                  title: Text(products[i]['name']),
                  subtitle: Text("Stock: ${products[i]['stock']}"),
                  trailing: ElevatedButton(onPressed: (){}, child: Text("₹${products[i]['price']} BUY")),
                ),
              );
            }
            return const SizedBox();
          },
        ),
        // Tab 2: Dynamic Pro
        ListView(children: [
          if (pro != null && pro!['job'].toLowerCase().contains(query))
            Card(
              margin: const EdgeInsets.all(10),
              child: ListTile(
                leading: const CircleAvatar(backgroundColor: Colors.orange, child: Icon(Icons.person, color: Colors.white)),
                title: Text("${pro!['name']} (${pro!['job']})"),
                subtitle: Text("${pro!['exp']} Years Experience"),
                trailing: const Icon(Icons.phone_locked, color: Colors.green),
              ),
            ),
        ]),
      ]),
    );
  }
}

_logout(context) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.clear();
  Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const RoleSelectionPage()), (route) => false);
}
