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
      home: initialRole != null ? _getDashboard(initialRole!) : const RoleSelectionPage(),
    );
  }

  Widget _getDashboard(String role) {
    if (role == 'Shopkeeper') return const ShopDashboard();
    if (role == 'Worker') return const WorkerDashboard();
    return const CustomerDashboard();
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

// --- 2. LOGIN PAGE (Fix: Direct Login Button) ---
class LoginPage extends StatefulWidget {
  final String role;
  const LoginPage({super.key, required this.role});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _otpController = TextEditingController();

  void _handleLogin() async {
    // Agar OTP 123456 hai toh login kar do
    if (_otpController.text == "123456") {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('userRole', widget.role);
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context, 
          MaterialPageRoute(builder: (context) => _getDashboard(widget.role)), 
          (route) => false
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Invalid OTP! Please use 123456"), backgroundColor: Colors.red)
      );
    }
  }

  Widget _getDashboard(String role) {
    if (role == 'Shopkeeper') return const ShopDashboard();
    if (role == 'Worker') return const WorkerDashboard();
    return const CustomerDashboard();
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

// --- 3. SHOPKEEPER DASHBOARD ---
class ShopDashboard extends StatefulWidget {
  const ShopDashboard({super.key});
  @override
  State<ShopDashboard> createState() => _ShopDashboardState();
}

class _ShopDashboardState extends State<ShopDashboard> {
  File? _productImage;
  bool _isStockAvailable = true;

  Future _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) setState(() => _productImage = File(picked.path));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Shop Management"), actions: [IconButton(icon: const Icon(Icons.logout), onPressed: () => _logout(context))]),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Register Your Shop", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const TextField(decoration: InputDecoration(hintText: "Shop Name")),
            const TextField(decoration: InputDecoration(hintText: "Full Address / Location")),
            const Divider(height: 40),
            const Text("Add Product Details", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 150, width: double.infinity,
                decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.grey)),
                child: _productImage == null ? const Icon(Icons.add_a_photo, size: 50) : ClipRRect(borderRadius: BorderRadius.circular(15), child: Image.file(_productImage!, fit: BoxFit.cover)),
              ),
            ),
            const TextField(decoration: InputDecoration(hintText: "Product Name")),
            const TextField(decoration: InputDecoration(hintText: "Price", prefixText: "₹ ")),
            const TextField(decoration: InputDecoration(hintText: "Total Pieces Available")),
            SwitchListTile(
              title: const Text("Is in Stock?"),
              value: _isStockAvailable,
              activeColor: Colors.indigo,
              onChanged: (val) => setState(() => _isStockAvailable = val),
            ),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: () {}, style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)), child: const Text("SAVE PRODUCT")),
          ],
        ),
      ),
    );
  }
}

// --- 4. CUSTOMER DASHBOARD ---
class CustomerDashboard extends StatelessWidget {
  const CustomerDashboard({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Trinity Market"), actions: [IconButton(icon: const Icon(Icons.logout), onPressed: () => _logout(context))]),
      body: ListView.builder(
        itemCount: 2, 
        itemBuilder: (context, index) {
          return Card(
            margin: const EdgeInsets.all(10),
            child: Column(
              children: [
                const ListTile(
                  title: Text("Pooja Electronics", style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text("Sector 22, Chandigarh"),
                  trailing: Icon(Icons.location_on, color: Colors.red),
                ),
                Container(height: 150, color: Colors.grey[300], child: const Center(child: Icon(Icons.image, size: 50))),
                const ListTile(
                  title: Text("Washing Machine Spare Part"),
                  trailing: Text("₹ 1,200", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 16)),
                ),
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: ElevatedButton(onPressed: () {}, style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 45)), child: const Text("BUY NOW")),
                )
              ],
            ),
          );
        },
      ),
    );
  }
}

// --- 5. WORKER DASHBOARD ---
class WorkerDashboard extends StatelessWidget {
  const WorkerDashboard({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Worker Profile"), actions: [IconButton(icon: const Icon(Icons.logout), onPressed: () => _logout(context))]),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const CircleAvatar(radius: 50, backgroundColor: Colors.orange, child: Icon(Icons.person, size: 50, color: Colors.white)),
            const SizedBox(height: 20),
            const TextField(decoration: InputDecoration(labelText: "Name")),
            const TextField(decoration: InputDecoration(labelText: "Job (e.g. Plumber)")),
            const TextField(decoration: InputDecoration(labelText: "Experience (Years)")),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: () {}, style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)), child: const Text("UPDATE PROFILE")),
          ],
        ),
      ),
    );
  }
}

// --- COMMON LOGOUT ---
void _logout(BuildContext context) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.clear();
  Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const RoleSelectionPage()), (route) => false);
}
