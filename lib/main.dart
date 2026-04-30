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

// --- COMMON LOGOUT FUNCTION ---
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

// --- 1. ROLE SELECTION PAGE ---
class RoleSelectionPage extends StatelessWidget {
  const RoleSelectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("THE TRINITY", style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.indigo, letterSpacing: 2)),
            const Text("Powered by ABHIMANIU", style: TextStyle(color: Colors.indigoAccent, fontWeight: FontWeight.bold)),
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
        trailing: const Icon(Icons.arrow_forward_ios, size: 14),
      ),
    );
  }
}

// --- 2. LOGIN PAGE ---
class LoginPage extends StatefulWidget {
  final String role;
  const LoginPage({super.key, required this.role});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _otpController = TextEditingController();

  void _handleLogin() async {
    if (_otpController.text == "123456") {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('userRole', widget.role);
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context, 
          MaterialPageRoute(builder: (context) => TrinityApp.getDashboard(widget.role)), 
          (route) => false
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Invalid OTP! Use 123456"), backgroundColor: Colors.red)
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("${widget.role} Login")),
      body: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          children: [
            const TextField(decoration: InputDecoration(labelText: "Mobile / Email", border: OutlineInputBorder())),
            const SizedBox(height: 20),
            TextField(
              controller: _otpController, 
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Enter OTP (123456)", border: OutlineInputBorder())
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _handleLogin,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white),
                child: const Text("LOGIN", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- 3. CUSTOMER DASHBOARD ---
class CustomerDashboard extends StatefulWidget {
  const CustomerDashboard({super.key});
  @override
  State<CustomerDashboard> createState() => _CustomerDashboardState();
}

class _CustomerDashboardState extends State<CustomerDashboard> {
  String searchQuery = "";

  void _showEscrow() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Payment Held"),
        content: const Text("Share this OTP with worker after work: 8899"),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("OK"))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Trinity Market"),
        actions: [IconButton(icon: const Icon(Icons.logout), onPressed: () => handleLogout(context))],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              onChanged: (val) => setState(() => searchQuery = val),
              decoration: InputDecoration(
                hintText: "Search (Tap, Wire, etc)...",
                prefixIcon: const Icon(Icons.search),
                fillColor: Colors.white, filled: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
              ),
            ),
          ),
        ),
      ),
      body: ListView(
        children: [
          if ("Water Tap".toLowerCase().contains(searchQuery.toLowerCase()))
            Card(
              margin: const EdgeInsets.all(12),
              child: Column(
                children: [
                  const ListTile(title: Text("Pooja Hardware"), trailing: Icon(Icons.location_on, color: Colors.red)),
                  const ListTile(title: Text("Water Tap"), trailing: Text("₹ 450", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green))),
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: ElevatedButton(onPressed: _showEscrow, child: const Text("BUY & FIND WORKER")),
                  )
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// --- 4. WORKER DASHBOARD ---
class WorkerDashboard extends StatefulWidget {
  const WorkerDashboard({super.key});
  @override
  State<WorkerDashboard> createState() => _WorkerDashboardState();
}

class _WorkerDashboardState extends State<WorkerDashboard> {
  final _otpController = TextEditingController();

  void _releasePayment() {
    if (_otpController.text == "8899") {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Payment Released Successfully!")));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Invalid OTP from Customer!")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Worker Panel"), actions: [IconButton(icon: const Icon(Icons.logout), onPressed: () => handleLogout(context))]),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Card(color: Colors.orangeAccent, child: ListTile(title: Text("Job: Water Tap Fitting"), subtitle: Text("Payment: ₹300 (Held)"))),
            const SizedBox(height: 20),
            TextField(controller: _otpController, decoration: const InputDecoration(labelText: "Enter Customer OTP", border: OutlineInputBorder())),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: _releasePayment, child: const Text("FINISH & GET PAID")),
          ],
        ),
      ),
    );
  }
}

// --- 5. SHOPKEEPER DASHBOARD ---
class ShopDashboard extends StatefulWidget {
  const ShopDashboard({super.key});
  @override
  State<ShopDashboard> createState() => _ShopDashboardState();
}

class _ShopDashboardState extends State<ShopDashboard> {
  File? _image;
  Future _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) setState(() => _image = File(picked.path));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Shop Dashboard"), actions: [IconButton(icon: const Icon(Icons.logout), onPressed: () => handleLogout(context))]),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: Container(height: 150, width: double.infinity, color: Colors.grey[200], child: _image == null ? const Icon(Icons.add_a_photo) : Image.file(_image!, fit: BoxFit.cover)),
            ),
            const TextField(decoration: InputDecoration(labelText: "Product Name")),
            const TextField(decoration: InputDecoration(labelText: "Price")),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: (){}, child: const Text("SAVE PRODUCT")),
          ],
        ),
      ),
    );
  }
}
