import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String? savedRole = prefs.getString('userRole');
  runApp(TrinityApp(initialRole: savedRole));
}

class TrinityApp extends StatelessWidget {
  final String? initialRole;
  const TrinityApp({super.key, this.initialRole});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
      ),
      home: initialRole != null ? getDashboard(initialRole!) : const RoleSelectionPage(),
    );
  }

  static Widget getDashboard(String role) {
    if (role == 'Shopkeeper') return const ShopDashboard();
    if (role == 'Professional') return const ProfessionalDashboard();
    return const CustomerDashboard();
  }
}

// --- COMMON LOGOUT ---
Future<void> handleLogout(BuildContext context) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.clear();
  if (context.mounted) {
    Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const RoleSelectionPage()), (route) => false);
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
            const Text("THE TRINITY", style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.indigo)),
            const Text("Powered by ABHIMANIU", style: TextStyle(color: Colors.indigoAccent, fontWeight: FontWeight.bold)),
            const SizedBox(height: 50),
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
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () async {
                if (_otp.text == "123456") {
                  SharedPreferences prefs = await SharedPreferences.getInstance();
                  await prefs.setString('userRole', role);
                  Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => TrinityApp.getDashboard(role)), (route) => false);
                }
              },
              child: const Text("LOGIN"),
            ),
          )
        ]),
      ),
    );
  }
}

// --- 3. CUSTOMER DASHBOARD (SEARCH + BUY + HIRE) ---
class CustomerDashboard extends StatefulWidget {
  const CustomerDashboard({super.key});
  @override
  State<CustomerDashboard> createState() => _CustomerDashboardState();
}

class _CustomerDashboardState extends State<CustomerDashboard> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String searchQuery = "";

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Trinity Market"),
        actions: [IconButton(icon: const Icon(Icons.logout), onPressed: () => handleLogout(context))],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(110),
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                onChanged: (val) => setState(() => searchQuery = val),
                decoration: InputDecoration(
                  hintText: "Search products or professionals...",
                  prefixIcon: const Icon(Icons.search),
                  fillColor: Colors.white, filled: true,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
                ),
              ),
            ),
            TabBar(controller: _tabController, tabs: const [Tab(text: "Products"), Tab(text: "Pros")]),
          ]),
        ),
      ),
      body: TabBarView(controller: _tabController, children: [
        // Tab 1: Products
        ListView(children: [
          if ("Tap".toLowerCase().contains(searchQuery.toLowerCase()))
            _itemCard("Pooja Hardware", "Water Tap", "₹ 450", "Stock: 10"),
        ]),
        // Tab 2: Professionals
        ListView(children: [
          if ("Plumber".toLowerCase().contains(searchQuery.toLowerCase()))
            _proCard("Rajesh", "Plumber", "5 Yrs Exp", "4.8 ⭐"),
        ]),
      ]),
    );
  }

  Widget _itemCard(shop, name, price, stock) => Card(
    margin: const EdgeInsets.all(10),
    child: ListTile(
      title: Text(name),
      subtitle: Text("$shop | $stock"),
      trailing: Text(price, style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
      onTap: () {},
    ),
  );

  Widget _proCard(name, job, exp, rating) => Card(
    margin: const EdgeInsets.all(10),
    child: ListTile(
      leading: const CircleAvatar(child: Icon(Icons.person)),
      title: Text("$name ($job)"),
      subtitle: Text(exp),
      trailing: ElevatedButton(onPressed: () {}, child: const Text("HIRE")),
    ),
  );
}

// --- 4. SHOPKEEPER DASHBOARD (INVENTORY MANAGEMENT) ---
class ShopDashboard extends StatefulWidget {
  const ShopDashboard({super.key});
  @override
  State<ShopDashboard> createState() => _ShopDashboardState();
}

class _ShopDashboardState extends State<ShopDashboard> {
  File? _image;
  final _name = TextEditingController();
  final _price = TextEditingController();
  final _qty = TextEditingController();

  Future _pick() async {
    final p = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (p != null) setState(() => _image = File(p.path));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("My Shop"), actions: [IconButton(icon: const Icon(Icons.logout), onPressed: () => handleLogout(context))]),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(children: [
          const Text("Add New Product", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 15),
          GestureDetector(
            onTap: _pick,
            child: Container(height: 150, width: double.infinity, color: Colors.grey[200], child: _image == null ? const Icon(Icons.add_a_photo) : Image.file(_image!, fit: BoxFit.cover)),
          ),
          TextField(controller: _name, decoration: const InputDecoration(labelText: "Product Name")),
          TextField(controller: _price, decoration: const InputDecoration(labelText: "Price")),
          TextField(controller: _qty, decoration: const InputDecoration(labelText: "Available Stock")),
          const SizedBox(height: 20),
          ElevatedButton(onPressed: (){}, style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)), child: const Text("SAVE TO INVENTORY")),
        ]),
      ),
    );
  }
}

// --- 5. PROFESSIONAL DASHBOARD (PROFILE & JOBS) ---
class ProfessionalDashboard extends StatefulWidget {
  const ProfessionalDashboard({super.key});
  @override
  State<ProfessionalDashboard> createState() => _ProfessionalDashboardState();
}

class _ProfessionalDashboardState extends State<ProfessionalDashboard> {
  final _name = TextEditingController();
  final _job = TextEditingController();
  final _exp = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Partner Panel"), actions: [IconButton(icon: const Icon(Icons.logout), onPressed: () => handleLogout(context))]),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(children: [
          const CircleAvatar(radius: 50, child: Icon(Icons.person, size: 50)),
          const SizedBox(height: 20),
          const Text("Create Professional Profile", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          TextField(controller: _name, decoration: const InputDecoration(labelText: "Full Name")),
          TextField(controller: _job, decoration: const InputDecoration(labelText: "Job Title (e.g. Plumber)")),
          TextField(controller: _exp, decoration: const InputDecoration(labelText: "Total Experience (Years)")),
          const SizedBox(height: 30),
          ElevatedButton(onPressed: (){}, child: const Text("GO ONLINE & SAVE")),
        ]),
      ),
    );
  }
}
