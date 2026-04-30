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

// --- 1. Role Selection Page ---
class RoleSelectionPage extends StatelessWidget {
  const RoleSelectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text("THE TRINITY", style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.indigo, letterSpacing: 2)),
              const Text("Powered by ABHIMANIU", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.indigoAccent)),
              const SizedBox(height: 50),
              const Text("Select Your Profile", style: TextStyle(color: Colors.grey, fontSize: 16)),
              const SizedBox(height: 30),
              _buildRoleCard(context, "Shopkeeper", Icons.storefront_rounded, Colors.indigo),
              _buildRoleCard(context, "Customer", Icons.shopping_bag_rounded, Colors.green),
              _buildRoleCard(context, "Worker", Icons.engineering_rounded, Colors.orange),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleCard(BuildContext context, String role, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 35, vertical: 10),
      child: InkWell(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => LoginPage(role: role))),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Icon(icon, size: 35, color: color),
              const SizedBox(width: 20),
              Text(role, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
              const Spacer(),
              Icon(Icons.arrow_forward_ios, size: 16, color: color),
            ],
          ),
        ),
      ),
    );
  }
}

// --- 2. Login Page with Demo OTP (123456) ---
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
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => _getDashboard(widget.role)),
          (route) => false,
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Wrong OTP! Use 123456")));
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
            const TextField(decoration: InputDecoration(labelText: "Email or Mobile Number", border: OutlineInputBorder())),
            const SizedBox(height: 20),
            if (_isOtpSent)
              TextField(
                controller: _otpController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Enter OTP (Demo: 123456)", border: OutlineInputBorder()),
              ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: () {
                  if (!_isOtpSent) setState(() => _isOtpSent = true);
                  else _handleLogin();
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white),
                child: Text(_isOtpSent ? "VERIFY & LOGIN" : "GET OTP", style: const TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- 3. Dashboards with Logout & Features ---

class ShopDashboard extends StatefulWidget {
  const ShopDashboard({super.key});
  @override
  State<ShopDashboard> createState() => _ShopDashboardState();
}

class _ShopDashboardState extends State<ShopDashboard> {
  File? _image;
  final picker = ImagePicker();

  Future pickImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) setState(() => _image = File(pickedFile.path));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Shopkeeper Dashboard"),
        actions: [IconButton(icon: const Icon(Icons.logout), onPressed: () => _logout(context))],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text("Add New Product", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: pickImage,
              child: Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.grey),
                ),
                child: _image == null 
                  ? const Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.add_a_photo, size: 50), Text("Tap to select photo")])
                  : ClipRRect(borderRadius: BorderRadius.circular(15), child: Image.file(_image!, fit: BoxFit.cover)),
              ),
            ),
            const SizedBox(height: 20),
            const TextField(decoration: InputDecoration(labelText: "Product Name", border: OutlineInputBorder())),
            const SizedBox(height: 15),
            const TextField(decoration: InputDecoration(labelText: "Price", border: OutlineInputBorder(), prefixText: "₹ ")),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Product Saved Locally"))),
              style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 55), backgroundColor: Colors.indigo, foregroundColor: Colors.white),
              child: const Text("SAVE PRODUCT"),
            ),
          ],
        ),
      ),
    );
  }
}

class CustomerDashboard extends StatelessWidget {
  const CustomerDashboard({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Customer Store"),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [IconButton(icon: const Icon(Icons.logout), onPressed: () => _logout(context))],
      ),
      body: const Center(child: Text("Products will be displayed here for purchase.")),
    );
  }
}

class WorkerDashboard extends StatelessWidget {
  const WorkerDashboard({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Worker Panel"),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        actions: [IconButton(icon: const Icon(Icons.logout), onPressed: () => _logout(context))],
      ),
      body: const Center(child: Text("New Fitting & Assembly tasks will appear here.")),
    );
  }
}

// --- Common Logout ---
void _logout(BuildContext context) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.clear();
  Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const RoleSelectionPage()), (route) => false);
}
