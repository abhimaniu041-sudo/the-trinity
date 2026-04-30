import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
      home: initialRole != null ? _getDashboard(initialRole!) : const RoleSelectionPage(),
    );
  }

  Widget _getDashboard(String role) {
    if (role == 'Shopkeeper') return const ShopDashboard();
    if (role == 'Worker') return const WorkerDashboard();
    return const CustomerDashboard();
  }
}

// --- 1. ROLE SELECTION & LOGIN (Same as before) ---
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
            const SizedBox(height: 50),
            _roleTile(context, "Shopkeeper", Icons.store, Colors.indigo),
            _roleTile(context, "Customer", Icons.shopping_bag, Colors.green),
            _roleTile(context, "Worker", Icons.engineering, Colors.orange),
          ],
        ),
      ),
    );
  }

  Widget _roleTile(BuildContext context, String role, IconData icon, Color color) {
    return Padding(
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
}

class LoginPage extends StatelessWidget {
  final String role;
  const LoginPage({super.key, required this.role});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("$role Login")),
      body: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          children: [
            const TextField(decoration: InputDecoration(labelText: "Mobile / Email", border: OutlineInputBorder())),
            const SizedBox(height: 20),
            const TextField(decoration: InputDecoration(labelText: "OTP (123456)", border: OutlineInputBorder())),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () async {
                SharedPreferences prefs = await SharedPreferences.getInstance();
                await prefs.setString('userRole', role);
                Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => _getDashboard(role)), (route) => false);
              },
              child: const Text("LOGIN"),
            ),
          ],
        ),
      ),
    );
  }
  Widget _getDashboard(String role) {
    if (role == 'Shopkeeper') return const ShopDashboard();
    if (role == 'Worker') return const WorkerDashboard();
    return const CustomerDashboard();
  }
}

// --- 2. CUSTOMER DASHBOARD (Search + Buy + Hire Logic) ---
class CustomerDashboard extends StatefulWidget {
  const CustomerDashboard({super.key});
  @override
  State<CustomerDashboard> createState() => _CustomerDashboardState();
}

class _CustomerDashboardState extends State<CustomerDashboard> {
  String searchQuery = "";

  void _showHireDialog(String product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Hire Worker for $product?"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Based on your purchase, here are available workers:"),
            const SizedBox(height: 10),
            ListTile(
              leading: const Icon(Icons.person, color: Colors.orange),
              title: const Text("Rajesh (Plumber/Technician)"),
              subtitle: const Text("Exp: 4 Years | ₹300 Fix Fee"),
              trailing: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _showPaymentEscrow();
                },
                child: const Text("Hire"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPaymentEscrow() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Payment Held in Escrow"),
        content: const Text("Aapka payment Trinity wallet mein hold kar liya gaya hai. Jab worker kaam khatam kare, tabhi use OTP batayein."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("OK")),
          const Text("Share this OTP with Worker after work: 8899", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Trinity Market"),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              onChanged: (value) => setState(() => searchQuery = value),
              decoration: InputDecoration(
                hintText: "Search products (e.g. Tap, Wire, Fan)...",
                prefixIcon: const Icon(Icons.search),
                fillColor: Colors.white,
                filled: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
              ),
            ),
          ),
        ),
      ),
      body: ListView(
        children: [
          if (searchQuery.isEmpty || "Tap".toLowerCase().contains(searchQuery.toLowerCase()))
            _productCard("Pooja Hardware", "Water Tap (Nal)", "₹ 450", "Sector 5"),
          if (searchQuery.isEmpty || "Wire".toLowerCase().contains(searchQuery.toLowerCase()))
            _productCard("Gupta Electric", "Copper Wire 10m", "₹ 800", "Sector 10"),
        ],
      ),
    );
  }

  Widget _productCard(String shop, String name, String price, String loc) {
    return Card(
      margin: const EdgeInsets.all(12),
      child: Column(
        children: [
          ListTile(title: Text(shop), subtitle: Text(loc), trailing: const Icon(Icons.location_on, color: Colors.red)),
          Container(height: 120, color: Colors.grey[200], child: const Center(child: Icon(Icons.image, size: 40))),
          ListTile(title: Text(name), trailing: Text(price, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green))),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton(
              onPressed: () => _showHireDialog(name),
              style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 45)),
              child: const Text("BUY & FIND WORKER"),
            ),
          )
        ],
      ),
    );
  }
}

// --- 3. WORKER DASHBOARD (Verify OTP to Release Payment) ---
class WorkerDashboard extends StatefulWidget {
  const WorkerDashboard({super.key});
  @override
  State<WorkerDashboard> createState() => _WorkerDashboardState();
}

class _WorkerDashboardState extends State<WorkerDashboard> {
  final _otpVerifyController = TextEditingController();

  void _releasePayment() {
    if (_otpController.text == "8899") {
      showDialog(
        context: context,
        builder: (context) => const AlertDialog(
          title: Text("Payment Released!"),
          content: Text("OTP verified. ₹300 aapke bank account mein bhej diye gaye hain."),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Wrong OTP! Customer se sahi code mangein.")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Worker Panel")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Card(
              color: Colors.orangeAccent,
              child: ListTile(
                title: Text("Active Job: Water Tap Fitting"),
                subtitle: Text("Customer: Abhimaniu | Payment: ₹300 (Held)"),
              ),
            ),
            const SizedBox(height: 30),
            const Text("Kaam khatam hone par customer se OTP lekar yahan bhariye:"),
            const SizedBox(height: 10),
            TextField(
              controller: _otpVerifyController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Enter Customer OTP", border: OutlineInputBorder()),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _releasePayment,
              style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
              child: const Text("FINISH WORK & GET PAID"),
            ),
          ],
        ),
      ),
    );
  }
}

// --- 4. SHOPKEEPER DASHBOARD (Simple for now) ---
class ShopDashboard extends StatelessWidget {
  const ShopDashboard({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Shop Dashboard")),
      body: const Center(child: Text("Shopkeeper can manage products here.")),
    );
  }
}

void _logout(BuildContext context) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.clear();
  Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const RoleSelectionPage()), (route) => false);
}
