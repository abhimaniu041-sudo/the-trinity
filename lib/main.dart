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
    if (role == 'Worker') return const WorkerDashboard();
    return const CustomerDashboard();
  }
}

// --- LOGOUT ---
Future<void> handleLogout(BuildContext context) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.clear();
  if (context.mounted) {
    Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const RoleSelectionPage()), (route) => false);
  }
}

// --- ROLE SELECTION ---
class RoleSelectionPage extends StatelessWidget {
  const RoleSelectionPage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Text("THE TRINITY", style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.indigo)),
          const SizedBox(height: 50),
          _roleBtn(context, "Shopkeeper", Icons.store, Colors.indigo),
          _roleBtn(context, "Customer", Icons.shopping_bag, Colors.green),
          _roleBtn(context, "Worker", Icons.engineering, Colors.orange),
        ]),
      ),
    );
  }
  Widget _roleBtn(context, role, icon, color) => Padding(
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
        const TextField(decoration: InputDecoration(labelText: "Mobile/Email", border: OutlineInputBorder())),
        const SizedBox(height: 15),
        TextField(controller: _otp, decoration: const InputDecoration(labelText: "OTP (123456)", border: OutlineInputBorder())),
        const SizedBox(height: 25),
        ElevatedButton(onPressed: () async {
          if (_otp.text == "123456") {
            SharedPreferences prefs = await SharedPreferences.getInstance();
            await prefs.setString('userRole', role);
            Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => TrinityApp.getDashboard(role)), (route) => false);
          }
        }, child: const Text("LOGIN")),
      ])),
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
  late TabController _tabController;
  int stock = 10;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Trinity Store"),
        actions: [IconButton(icon: const Icon(Icons.logout), onPressed: () => handleLogout(context))],
        bottom: TabBar(controller: _tabController, tabs: const [Tab(text: "Products"), Tab(text: "Workers")]),
      ),
      body: TabBarView(controller: _tabController, children: [
        ListView(padding: const EdgeInsets.all(10), children: [
          Card(child: ListTile(title: const Text("Water Tap"), subtitle: Text("Stock: $stock"), trailing: ElevatedButton(onPressed: (){}, child: const Text("BUY")))),
        ]),
        ListView(padding: const EdgeInsets.all(10), children: [
          Card(child: ListTile(title: const Text("Amit (Plumber)"), trailing: const Icon(Icons.phone_locked, color: Colors.green))),
        ]),
      ]),
    );
  }
}

// --- WORKER DASHBOARD ---
class WorkerDashboard extends StatelessWidget {
  const WorkerDashboard({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Worker Panel"), actions: [IconButton(icon: const Icon(Icons.logout), onPressed: () => handleLogout(context))]),
      body: const Center(child: Text("Welcome to Worker Profile")),
    );
  }
}

// --- SHOPKEEPER DASHBOARD ---
class ShopDashboard extends StatelessWidget {
  const ShopDashboard({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Shopkeeper"), actions: [IconButton(icon: const Icon(Icons.logout), onPressed: () => handleLogout(context))]),
      body: const Center(child: Text("Shop Inventory")),
    );
  }
}
