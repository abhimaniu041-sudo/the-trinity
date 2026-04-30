import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart'; // Calling ke liye
import 'dart:io';
import 'dart:convert';
import 'dart:math';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const TrinityApp());
}

class TrinityApp extends StatelessWidget {
  const TrinityApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo, brightness: Brightness.light),
        cardTheme: CardThemeData(
          elevation: 5,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
      ),
      home: const SplashScreen(),
    );
  }
}

// --- GLOBAL UTILS ---
// FIXED: Logout ab data delete nahi karega
Future<void> handleLogout(BuildContext context) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.remove('userRole'); // Sirf login session hataya
  if (context.mounted) {
    Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const RoleSelectionPage()), (route) => false);
  }
}

// Function to handle calls
Future<void> makeSecureCall(String number) async {
  final Uri launchUri = Uri(scheme: 'tel', path: number);
  if (await canLaunchUrl(launchUri)) {
    await launchUrl(launchUri);
  }
}

// --- SPLASH SCREEN ---
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkStatus();
  }
  _checkStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? role = prefs.getString('userRole');
    await Future.delayed(const Duration(seconds: 3));
    if (mounted) {
      if (role == 'Shopkeeper') Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const ShopDashboard()));
      else if (role == 'Professional') Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const ProfessionalDashboard()));
      else if (role == 'Customer') Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const CustomerDashboard()));
      else Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const RoleSelectionPage()));
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("THE TRINITY", style: TextStyle(fontSize: 45, fontWeight: FontWeight.bold, color: Colors.indigo, letterSpacing: 3)),
            const SizedBox(height: 10),
            Text("Powered by ABHIMANIU".toUpperCase(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.indigo, letterSpacing: 1.5)),
          ],
        ),
      ),
    );
  }
}

// --- ROLE SELECTION ---
class RoleSelectionPage extends StatelessWidget {
  const RoleSelectionPage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        padding: const EdgeInsets.all(25),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("THE TRINITY", style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
            const Text("Powered by ABHIMANIU", style: TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold, fontSize: 10)),
            const SizedBox(height: 50),
            _roleTile(context, "Shopkeeper", Icons.store_rounded, Colors.indigo),
            _roleTile(context, "Professional", Icons.engineering_rounded, Colors.orange),
            _roleTile(context, "Customer", Icons.person_search_rounded, Colors.green),
          ],
        ),
      ),
    );
  }
  Widget _roleTile(context, title, icon, color) => Card(
    margin: const EdgeInsets.only(bottom: 15),
    child: ListTile(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => LoginPage(role: title))),
      leading: CircleAvatar(backgroundColor: color.withOpacity(0.1), child: Icon(icon, color: color)),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      trailing: const Icon(Icons.chevron_right),
    ),
  );
}

// --- LOGIN PAGE ---
class LoginPage extends StatelessWidget {
  final String role;
  LoginPage({super.key, required this.role});
  final _phone = TextEditingController();
  final _otp = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("$role Login")),
      body: Padding(
        padding: const EdgeInsets.all(25),
        child: Column(children: [
          TextField(controller: _phone, decoration: const InputDecoration(labelText: "Mobile Number", border: OutlineInputBorder(), prefixIcon: Icon(Icons.phone))),
          const SizedBox(height: 15),
          TextField(controller: _otp, decoration: const InputDecoration(labelText: "OTP (123456)", border: OutlineInputBorder(), prefixIcon: Icon(Icons.lock_clock))),
          const SizedBox(height: 30),
          SizedBox(
            width: double.infinity, height: 50,
            child: ElevatedButton(
              onPressed: () async {
                if (_otp.text == "123456") {
                  SharedPreferences prefs = await SharedPreferences.getInstance();
                  await prefs.setString('userRole', role);
                  await prefs.setString('myPhone', _phone.text); // Phone save for calling
                  if (context.mounted) {
                    if (role == 'Shopkeeper') Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const ShopDashboard()), (r)=>false);
                    else if (role == 'Customer') Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const CustomerDashboard()), (r)=>false);
                    else Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const ProfessionalDashboard()), (r)=>false);
                  }
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white),
              child: const Text("AUTHENTICATE"),
            ),
          )
        ]),
      ),
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
  final _name = TextEditingController();
  final _price = TextEditingController();
  File? _img;
  List products = [];

  @override
  void initState() { super.initState(); _load(); }
  _load() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? data = prefs.getString('trinity_products');
    if (data != null) setState(() => products = json.decode(data));
  }
  _save() async {
    if (_name.text.isEmpty) return;
    products.add({'name': _name.text, 'price': _price.text, 'img': _img?.path ?? ""});
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('trinity_products', json.encode(products));
    setState(() { _name.clear(); _price.clear(); _img = null; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("My Store"), actions: [IconButton(icon: const Icon(Icons.logout), onPressed: () => handleLogout(context))]),
      body: ListView(
        padding: const EdgeInsets.all(15),
        children: [
          const Text("Add Product", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          TextField(controller: _name, decoration: const InputDecoration(hintText: "Item Name", border: OutlineInputBorder())),
          const SizedBox(height: 10),
          TextField(controller: _price, decoration: const InputDecoration(hintText: "Price (₹)", border: OutlineInputBorder())),
          const SizedBox(height: 10),
          ElevatedButton(onPressed: _save, child: const Text("List Product")),
          const Divider(height: 40),
          ...products.map((p) => Card(child: ListTile(title: Text(p['name']), trailing: Text("₹${p['price']}")))).toList()
        ],
      ),
    );
  }
}

// --- PROFESSIONAL DASHBOARD ---
class ProfessionalDashboard extends StatefulWidget {
  const ProfessionalDashboard({super.key});
  @override
  State<ProfessionalDashboard> createState() => _ProfessionalDashboardState();
}

class _ProfessionalDashboardState extends State<ProfessionalDashboard> {
  bool isOnline = false;
  String name = "", job = "", phone = "";
  final _n = TextEditingController();
  final _j = TextEditingController();

  @override
  void initState() { super.initState(); _load(); }
  _load() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      name = prefs.getString('pro_name') ?? "";
      job = prefs.getString('pro_job') ?? "";
      isOnline = prefs.getBool('pro_online') ?? false;
      phone = prefs.getString('myPhone') ?? "9999999999";
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Pro Panel"), actions: [IconButton(icon: const Icon(Icons.logout), onPressed: () => handleLogout(context))]),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: name == "" ? Column(children: [
          TextField(controller: _n, decoration: const InputDecoration(labelText: "Full Name")),
          TextField(controller: _j, decoration: const InputDecoration(labelText: "Expertise (e.g. Plumber)")),
          ElevatedButton(onPressed: () async {
            SharedPreferences prefs = await SharedPreferences.getInstance();
            await prefs.setString('pro_name', _n.text);
            await prefs.setString('pro_job', _j.text);
            _load();
          }, child: const Text("Create Profile"))
        ]) : Column(children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(gradient: const LinearGradient(colors: [Colors.indigo, Colors.blue]), borderRadius: BorderRadius.circular(20)),
            child: Column(children: [
              const CircleAvatar(radius: 30, child: Icon(Icons.person)),
              Text(name, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
              Text(job, style: const TextStyle(color: Colors.white70)),
            ]),
          ),
          SwitchListTile(
            title: const Text("Go Online to get Hired"),
            value: isOnline,
            onChanged: (v) async {
              SharedPreferences prefs = await SharedPreferences.getInstance();
              await prefs.setBool('pro_online', v);
              setState(() => isOnline = v);
            },
          ),
          const Spacer(),
          const Text("Recent Requests", style: TextStyle(fontWeight: FontWeight.bold)),
          Card(child: ListTile(
            title: const Text("Customer #9283"),
            subtitle: const Text("Urgent Requirement"),
            trailing: IconButton(icon: const Icon(Icons.call, color: Colors.green), onPressed: () => makeSecureCall("8888888888")), // Fixed Call
          ))
        ]),
      ),
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
  late TabController _tab;
  String query = "";
  List products = [];
  Map? pro;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _fetch();
  }

  _fetch() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? pData = prefs.getString('trinity_products');
    if (pData != null) setState(() => products = json.decode(pData));
    
    if (prefs.getBool('pro_online') ?? false) {
      setState(() {
        pro = {'name': prefs.getString('pro_name'), 'job': prefs.getString('pro_job'), 'phone': prefs.getString('myPhone')};
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Marketplace"),
        actions: [IconButton(icon: const Icon(Icons.logout), onPressed: () => handleLogout(context))],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(110),
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.all(10),
              child: TextField(
                onChanged: (v) => setState(() => query = v.toLowerCase()),
                decoration: InputDecoration(hintText: "Search anything...", prefixIcon: const Icon(Icons.search), filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(30))),
              ),
            ),
            TabBar(controller: _tab, tabs: const [Tab(text: "Products"), Tab(text: "Hire Pros")]),
          ]),
        ),
      ),
      body: TabBarView(controller: _tab, children: [
        // FIXED: Search Results
        ListView(children: products.where((p) => p['name'].toLowerCase().contains(query)).map((p) => Card(child: ListTile(title: Text(p['name']), trailing: Text("₹${p['price']}")))).toList()),
        
        ListView(children: [
          if (pro != null && (pro!['name'].toLowerCase().contains(query) || pro!['job'].toLowerCase().contains(query)))
            Card(child: ListTile(
              leading: const CircleAvatar(child: Icon(Icons.engineering)),
              title: Text(pro!['name']),
              subtitle: Text(pro!['job']),
              trailing: ElevatedButton(
                onPressed: () => makeSecureCall(pro!['phone']), // Anonymous Call Logic
                child: const Text("HIRE & CALL"),
              ),
            )),
          if (pro == null) const Center(child: Text("No Professionals Online"))
        ]),
      ]),
    );
  }
}
