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

// --- COMMON LOGOUT ---
void _logout(BuildContext context) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.clear();
  Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const RoleSelectionPage()), (route) => false);
}

// --- 1. ROLE SELECTION PAGE ---
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
            _roleTile(context, "Worker", Icons.build, Colors.orange),
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

// --- 2. LOGIN PAGE (With Demo OTP: 123456) ---
class LoginPage extends StatefulWidget {
  final String role;
  const LoginPage({super.key, required this.role});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _isOtpSent = false;
  final _otpController = TextEditingController();

  void _handleLogin() async {
    if (_otpController.text == "123456") {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('userRole', widget.role);
      if (mounted) {
        Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => _getDashboard(widget.role)), (route) => false);
      }
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
            const TextField(decoration: InputDecoration(labelText: "Email / Mobile", border: OutlineInputBorder())),
            const SizedBox(height: 20),
            if (_isOtpSent)
              TextField(controller: _otpController, decoration: const InputDecoration(labelText: "OTP (123456)", border: OutlineInputBorder())),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () => setState(() => _isOtpSent = true),
              style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 55)),
              child: Text(_isOtpSent ? "LOGIN" : "GET OTP"),
            ),
            if (_isOtpSent) TextButton(onPressed: _handleLogin, child: const Text("Verify Demo OTP")),
          ],
        ),
      ),
    );
  }
}

// --- 3. SHOPKEEPER DASHBOARD (Manage Shop & Products) ---
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
      appBar: AppBar(title: const Text("My Shop Management"), actions: [IconButton(icon: const Icon(Icons.logout), onPressed: () => _logout(context))]),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Register / Update Shop", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const TextField(decoration: InputDecoration(hintText: "Shop Name")),
            const TextField(decoration: InputDecoration(hintText: "Real Location Address")),
            const Divider(height: 40),
            const Text("Add Product", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 150, width: double.infinity,
                decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(15)),
                child: _productImage == null ? const Icon(Icons.add_a_photo, size: 50) : Image.file(_productImage!, fit: BoxFit.cover),
              ),
            ),
            const TextField(decoration: InputDecoration(hintText: "Product Name")),
            const TextField(decoration: InputDecoration(hintText: "Price", prefixText: "₹ ")),
            const TextField(decoration: InputDecoration(hintText: "Available Pieces (Quantity)")),
            SwitchListTile(
              title: const Text("In Stock"),
              value: _isStockAvailable,
              onChanged: (val) => setState(() => _isStockAvailable = val),
            ),
            ElevatedButton(onPressed: () {}, child: const Text("Save Product & Shop")),
          ],
        ),
      ),
    );
  }
}

// --- 4. CUSTOMER DASHBOARD (View & Buy) ---
class CustomerDashboard extends StatelessWidget {
  const CustomerDashboard({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Trinity Market"), actions: [IconButton(icon: const Icon(Icons.logout), onPressed: () => _logout(context))]),
      body: ListView.builder(
        itemCount: 3, // Demo list
        itemBuilder: (context, index) {
          return Card(
            margin: const EdgeInsets.all(10),
            child: Column(
              children: [
                ListTile(
                  title: const Text("Sample Shop Name", style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text("Location: Main Road, Sector 5"),
                  trailing: const Icon(Icons.location_on, color: Colors.red),
                ),
                Image.network('https://via.placeholder.com/150', height: 150, width: double.infinity, fit: BoxFit.cover),
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Product Name", style: TextStyle(fontSize: 16)),
                      Text("₹ 500", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Row(
                    children: [
                      const Text("Qty: "),
                      DropdownButton<int>(value: 1, items: [1,2,3,4,5].map((i) => DropdownMenuItem(value: i, child: Text("$i"))).toList(), onChanged: (v){}),
                      const Spacer(),
                      ElevatedButton(onPressed: () {}, child: const Text("BUY NOW")),
                    ],
                  ),
                )
              ],
            ),
          );
        },
      ),
    );
  }
}

// --- 5. WORKER DASHBOARD (Profile & Hire) ---
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
            const CircleAvatar(radius: 50, child: Icon(Icons.person, size: 50)),
            const SizedBox(height: 20),
            const TextField(decoration: InputDecoration(labelText: "Full Name")),
            const TextField(decoration: InputDecoration(labelText: "Job Title (e.g. Plumber, Electrician)")),
            const TextField(decoration: InputDecoration(labelText: "Experience (Years)")),
            const SizedBox(height: 30),
            const Text("Customers will see you like this:", style: TextStyle(color: Colors.grey)),
            Card(
              child: ListTile(
                leading: const Icon(Icons.build, color: Colors.orange),
                title: const Text("Amit Kumar (Electrician)"),
                subtitle: const Text("5 Years Exp | Rating: ⭐ 4.5"),
                trailing: ElevatedButton(onPressed: () {}, child: const Text("HIRE")),
              ),
            ),
            const Spacer(),
            ElevatedButton(onPressed: () {}, style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 55)), child: const Text("Save & Go Online")),
          ],
        ),
      ),
    );
  }
}
