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
      // Agar pehle se login hai toh seedha dashboard, nahi toh selection screen
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
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("THE TRINITY", style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.indigo, letterSpacing: 2)),
            const Text("Powered by ABHIMANIU", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.indigoAccent)),
            const SizedBox(height: 50),
            const Text("Please select your profile to continue", style: TextStyle(color: Colors.grey, fontSize: 16)),
            const SizedBox(height: 30),
            _buildRoleCard(context, "Shopkeeper", Icons.storefront_rounded, Colors.indigo),
            _buildRoleCard(context, "Customer", Icons.shopping_cart_rounded, Colors.green),
            _buildRoleCard(context, "Worker", Icons.engineering_rounded, Colors.orange),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleCard(BuildContext context, String role, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
      child: InkWell(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => LoginPage(role: role))),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withOpacity(0.5)),
          ),
          child: Row(
            children: [
              Icon(icon, size: 40, color: color),
              const SizedBox(width: 20),
              Text(role, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
              const Spacer(),
              Icon(Icons.arrow_forward_ios, color: color, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}

// --- 2. Login Page with Demo OTP ---
class LoginPage extends StatefulWidget {
  final String role;
  const LoginPage({super.key, required this.role});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _isOtpSent = false;
  bool _obscurePassword = true;
  final _otpController = TextEditingController();

  void _verifyAndLogin() async {
    // Demo OTP check
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Invalid OTP! Try 123456")));
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(30),
        child: Column(
          children: [
            const SizedBox(height: 20),
            TextField(decoration: InputDecoration(labelText: "Email / Mobile", border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)))),
            const SizedBox(height: 20),
            TextField(
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                labelText: "Password",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                suffixIcon: IconButton(icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility), onPressed: () => setState(() => _obscurePassword = !_obscurePassword)),
              ),
            ),
            if (_isOtpSent) ...[
              const SizedBox(height: 20),
              TextField(controller: _otpController, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: "Enter OTP (Demo: 123456)", border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)))),
            ],
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: () {
                  if (!_isOtpSent) {
                    setState(() => _isOtpSent = true);
                  } else {
                    _verifyAndLogin();
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                child: Text(_isOtpSent ? "LOGIN" : "GET OTP", style: const TextStyle(color: Colors.white, fontSize: 18)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- 3. Dashboards ---

class ShopDashboard extends StatelessWidget {
  const ShopDashboard({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Shopkeeper Dashboard"), actions: [_logoutButton(context)]),
      body: const Center(child: Text("Welcome Shopkeeper!\nUpload products here.", textAlign: TextAlign.center)),
    );
  }
}

class CustomerDashboard extends StatelessWidget {
  const CustomerDashboard({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Customer Dashboard"), actions: [_logoutButton(context)]),
      body: const Center(child: Text("Welcome Customer!\nBrowse and buy products.")),
    );
  }
}

class WorkerDashboard extends StatelessWidget {
  const WorkerDashboard({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Worker Dashboard"), actions: [_logoutButton(context)]),
      body: const Center(child: Text("Welcome Worker!\nCheck your assembly tasks.")),
    );
  }
}

Widget _logoutButton(BuildContext context) {
  return IconButton(
    icon: const Icon(Icons.logout),
    onPressed: () async {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const RoleSelectionPage()), (route) => false);
    },
  );
}
