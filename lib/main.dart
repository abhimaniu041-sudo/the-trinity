import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart'; // Calling ke liye

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
      theme: ThemeData(primarySwatch: Colors.indigo, useMaterial3: true),
      home: initialRole != null ? getDashboard(initialRole!) : const RoleSelectionPage(),
    );
  }

  static Widget getDashboard(String role) {
    if (role == 'Shopkeeper') return const ShopDashboard();
    if (role == 'Worker') return const WorkerDashboard();
    return const CustomerDashboard();
  }
}

// --- 1. CUSTOMER DASHBOARD (Products + Independent Worker Hiring) ---
class CustomerDashboard extends StatefulWidget {
  const CustomerDashboard({super.key});
  @override
  State<CustomerDashboard> createState() => _CustomerDashboardState();
}

class _CustomerDashboardState extends State<CustomerDashboard> with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  void _makeSecureCall(String name) {
    // Real App mein yahan Twilio API call hogi
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Connecting Secure Call to $name... Your number is hidden.")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("The Trinity"),
        actions: [IconButton(icon: const Icon(Icons.logout), onPressed: () => handleLogout(context))],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.shopping_basket), text: "Products"),
            Tab(icon: Icon(Icons.engineering), text: "Hire Workers"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Section 1: Only Products
          ListView(padding: const EdgeInsets.all(10), children: [
            _itemCard("Pooja Hardware", "Water Tap", "₹ 450", "In Stock"),
            _itemCard("Electric World", "Ceiling Fan", "₹ 2100", "5 Left"),
          ]),
          // Section 2: Independent Worker Hiring
          ListView(padding: const EdgeInsets.all(10), children: [
            _workerCard("Amit (Plumber)", "5 Yrs Exp", "4.8 ⭐"),
            _workerCard("Suresh (Electrician)", "3 Yrs Exp", "4.5 ⭐"),
          ]),
        ],
      ),
    );
  }

  Widget _itemCard(shop, name, price, status) => Card(
    child: ListTile(
      title: Text(name),
      subtitle: Text("$shop | $status"),
      trailing: ElevatedButton(onPressed: () {}, child: const Text("BUY")),
    ),
  );

  Widget _workerCard(name, exp, rating) => Card(
    child: ListTile(
      leading: const CircleAvatar(child: Icon(Icons.person)),
      title: Text(name),
      subtitle: Text("$exp | $rating"),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(icon: const Icon(Icons.phone_locked, color: Colors.green), onPressed: () => _makeSecureCall(name)),
          ElevatedButton(onPressed: () {}, child: const Text("HIRE")),
        ],
      ),
    ),
  );
}

// --- 2. WORKER DASHBOARD (With Profile & Secure Call) ---
class WorkerDashboard extends StatelessWidget {
  const WorkerDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Worker Panel"), actions: [IconButton(icon: const Icon(Icons.logout), onPressed: () => handleLogout(context))]),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Card(
              color: Colors.indigoAccent,
              child: ListTile(
                textColor: Colors.white,
                title: Text("Active Request: Tap Fitting"),
                subtitle: Text("Customer: Abhimaniu | Loc: Sector 22"),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Calling Customer securely..."))),
              icon: const Icon(Icons.phone_callback),
              label: const Text("Call Customer (Privacy Mode)"),
              style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
            ),
            const Spacer(),
            const Text("OTP for Payment Release:", style: TextStyle(fontWeight: FontWeight.bold)),
            const TextField(decoration: InputDecoration(hintText: "Enter 4-digit OTP")),
          ],
        ),
      ),
    );
  }
}

// --- REST OF THE CODE (RoleSelection, Login, Shopkeeper, Logout) ---
// (Baki logic pichle code jaisi hi rahegi)

class RoleSelectionPage extends StatelessWidget {
  const RoleSelectionPage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Text("THE TRINITY", style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.indigo)),
          const SizedBox(height: 40),
          _btn(context, "Shopkeeper", Icons.store, Colors.indigo),
          _btn(context, "Customer", Icons.shopping_bag, Colors.green),
          _btn(context, "Worker", Icons.engineering, Colors.orange),
        ]),
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
        ]),
      ),
    );
  }
}

class ShopDashboard extends StatelessWidget {
  const ShopDashboard({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Shopkeeper"), actions: [IconButton(icon: const Icon(Icons.logout), onPressed: () => handleLogout(context))]),
      body: const Center(child: Text("Shop Inventory Management")),
    );
  }
}

Future<void> handleLogout(BuildContext context) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.clear();
  Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const RoleSelectionPage()), (route) => false);
}
