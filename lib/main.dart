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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("THE TRINITY", style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.indigo)),
            const Text("Powered by ABHIMANIU", style: TextStyle(color: Colors.indigoAccent, fontWeight: FontWeight.bold)),
            const SizedBox(height: 50),
            _roleBtn(context, "Shopkeeper", Icons.store, Colors.indigo),
            _roleBtn(context, "Customer", Icons.shopping_bag, Colors.green),
            _roleBtn(context, "Worker", Icons.engineering, Colors.orange),
          ],
        ),
      ),
    );
  }
  Widget _roleBtn(context, role, icon, color) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 8),
    child: ListTile(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => LoginPage(role: role))),
      leading: Icon(icon, color: color),
      title: Text(role),
      tileColor: color.withOpacity(0.1),
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
      body: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(children: [
          const TextField(decoration: InputDecoration(labelText: "Mobile/Email", border: OutlineInputBorder())),
          const SizedBox(height: 15),
          TextField(controller: _otp, decoration: const InputDecoration(labelText: "OTP (123456)", border: OutlineInputBorder())),
          const SizedBox(height: 25),
          ElevatedButton(
            onPressed: () async {
              if (_otp.text == "123456") {
                SharedPreferences prefs = await SharedPreferences.getInstance();
                await prefs.setString('userRole', role);
                Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => TrinityApp.getDashboard(role)), (route) => false);
              }
            },
            child: const Text("LOGIN"),
          )
        ]),
      ),
    );
  }
}

// --- CUSTOMER DASHBOARD (With Stock Logic) ---
class CustomerDashboard extends StatefulWidget {
  const CustomerDashboard({super.key});
  @override
  State<CustomerDashboard> createState() => _CustomerDashboardState();
}

class _CustomerDashboardState extends State<CustomerDashboard> {
  int stock = 10; // Default Stock
  int buyQty = 1;

  void _buyProduct() {
    if (stock >= buyQty) {
      setState(() => stock -= buyQty);
      _showSuccess();
    } else {
      _showError("Not enough stock!");
    }
  }

  void _showSuccess() {
    showDialog(context: context, builder: (c) => AlertDialog(
      title: const Text("Purchase Success!"),
      content: Text("OTP for Worker: 8899\nRemaining Stock: $stock"),
      actions: [TextButton(onPressed: () => Navigator.pop(c), child: const Text("OK"))],
    ));
  }

  void _showError(msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Trinity Store"), actions: [IconButton(icon: const Icon(Icons.logout), onPressed: () => handleLogout(context))]),
      body: ListView(padding: const EdgeInsets.all(15), children: [
        Card(child: Column(children: [
          const ListTile(title: Text("Shop: Pooja Electronics"), subtitle: Text("Product: Water Tap")),
          Text("Available Stock: $stock", style: TextStyle(color: stock > 0 ? Colors.green : Colors.red, fontWeight: FontWeight.bold)),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Text("Qty: "),
            DropdownButton<int>(value: buyQty, items: [1,2,3,4,5].map((i) => DropdownMenuItem(value: i, child: Text("$i"))).toList(), onChanged: (v) => setState(() => buyQty = v!)),
          ]),
          Padding(
            padding: const EdgeInsets.all(10),
            child: ElevatedButton(onPressed: stock > 0 ? _buyProduct : null, child: Text(stock > 0 ? "BUY NOW" : "OUT OF STOCK")),
          )
        ]))
      ]),
    );
  }
}

// --- WORKER DASHBOARD (With Profile Creation) ---
class WorkerDashboard extends StatefulWidget {
  const WorkerDashboard({super.key});
  @override
  State<WorkerDashboard> createState() => _WorkerDashboardState();
}

class _WorkerDashboardState extends State<WorkerDashboard> {
  final _name = TextEditingController();
  final _job = TextEditingController();
  final _exp = TextEditingController();
  final _otpVerify = TextEditingController();
  bool isProfileCreated = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  _loadProfile() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _name.text = prefs.getString('wName') ?? "";
      _job.text = prefs.getString('wJob') ?? "";
      _exp.text = prefs.getString('wExp') ?? "";
      if (_name.text.isNotEmpty) isProfileCreated = true;
    });
  }

  _saveProfile() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('wName', _name.text);
    await prefs.setString('wJob', _job.text);
    await prefs.setString('wExp', _exp.text);
    setState(() => isProfileCreated = true);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Profile Saved Online!")));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Worker Panel"), actions: [IconButton(icon: const Icon(Icons.logout), onPressed: () => handleLogout(context))]),
      body: SingleChildScrollView(padding: const EdgeInsets.all(20), child: Column(children: [
        if (!isProfileCreated) ...[
          const Text("Create Your Worker Profile", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          TextField(controller: _name, decoration: const InputDecoration(labelText: "Full Name")),
          TextField(controller: _job, decoration: const InputDecoration(labelText: "Job Title (e.g. Plumber)")),
          TextField(controller: _exp, decoration: const InputDecoration(labelText: "Experience (Years)")),
          const SizedBox(height: 20),
          ElevatedButton(onPressed: _saveProfile, child: const Text("CREATE PROFILE")),
        ] else ...[
          Card(color: Colors.indigo.withOpacity(0.1), child: ListTile(
            leading: const Icon(Icons.person),
            title: Text(_name.text),
            subtitle: Text("${_job.text} | ${_exp.text} Years Exp"),
            trailing: IconButton(icon: const Icon(Icons.edit), onPressed: () => setState(() => isProfileCreated = false)),
          )),
          const Divider(height: 40),
          const Text("Verify Completion", style: TextStyle(fontWeight: FontWeight.bold)),
          TextField(controller: _otpVerify, decoration: const InputDecoration(labelText: "Enter Customer OTP (8899)")),
          ElevatedButton(onPressed: () {
            if (_otpVerify.text == "8899") ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Payment Released!")));
          }, child: const Text("VERIFY & GET PAID"))
        ]
      ])),
    );
  }
}

// --- SHOPKEEPER DASHBOARD ---
class ShopDashboard extends StatefulWidget {
  const ShopDashboard({super.key});
  @override
  State<ShopDashboard> createState() => _ShopDashboardState();
}

class _ShopDashboardState extends State<ShopDashboard> {
  File? _img;
  final _name = TextEditingController();
  final _price = TextEditingController();

  Future _pick() async {
    final p = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (p != null) setState(() => _img = File(p.path));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Shop Management"), actions: [IconButton(icon: const Icon(Icons.logout), onPressed: () => handleLogout(context))]),
      body: Padding(padding: const EdgeInsets.all(20), child: Column(children: [
        GestureDetector(onTap: _pick, child: Container(height: 100, width: double.infinity, color: Colors.grey[200], child: _img == null ? const Icon(Icons.camera_alt) : Image.file(_img!, fit: BoxFit.cover))),
        TextField(controller: _name, decoration: const InputDecoration(labelText: "Product Name")),
        TextField(controller: _price, decoration: const InputDecoration(labelText: "Price")),
        const SizedBox(height: 20),
        ElevatedButton(onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Product Saved!"))), child: const Text("SAVE PRODUCT")),
      ])),
    );
  }
}
