import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart'; 
import 'dart:io';
import 'dart:convert';

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
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo, primary: Colors.indigo, secondary: Colors.orangeAccent),
        // FIXED: Correct syntax for CardTheme in this build sequence
        cardTheme: CardTheme(
          elevation: 8,
          shadowColor: Colors.black26,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
          clipBehavior: Clip.antiAlias,
        ),
      ),
      home: const SplashScreen(),
    );
  }
}

// --- SHARED UTILS ---
Future<void> handleLogout(BuildContext context) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.remove('userRole'); 
  Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const RoleSelectionPage()), (route) => false);
}

Future<void> startSecureCall(String phone) async {
  final Uri url = Uri(scheme: 'tel', path: phone);
  if (await canLaunchUrl(url)) { await launchUrl(url); }
}

// --- SPLASH SCREEN (Premium Branding) ---
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkSession();
  }
  _checkSession() async {
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
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("THE TRINITY", style: TextStyle(fontSize: 50, fontWeight: FontWeight.w900, color: Colors.indigo, letterSpacing: 4)),
            const SizedBox(height: 5),
            Container(height: 2, width: 100, color: Colors.orangeAccent),
            const SizedBox(height: 15),
            const Text("POWERED BY ABHIMANIU", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 2)),
          ],
        ),
      ),
    );
  }
}

// --- ROLE SELECTION (Premium Look) ---
class RoleSelectionPage extends StatelessWidget {
  const RoleSelectionPage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(colors: [Colors.indigo, Color(0xFF1A237E)], begin: Alignment.topCenter)
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("Welcome to Trinity", style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            const Text("Choose your portal to continue", style: TextStyle(color: Colors.white70)),
            const SizedBox(height: 40),
            _roleTile(context, "Shopkeeper", Icons.store_rounded, Colors.indigoAccent),
            _roleTile(context, "Professional", Icons.handyman_rounded, Colors.orangeAccent),
            _roleTile(context, "Customer", Icons.shopping_basket_rounded, Colors.tealAccent),
          ],
        ),
      ),
    );
  }
  Widget _roleTile(context, title, icon, color) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 10),
    child: InkWell(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => LoginPage(role: title))),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10)]),
        child: Row(
          children: [
            Icon(icon, color: Colors.indigo, size: 30),
            const SizedBox(width: 20),
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.indigo)),
            const Spacer(),
            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          ],
        ),
      ),
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
      appBar: AppBar(title: Text("$role Access")),
      body: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(children: [
          TextField(controller: _phone, decoration: const InputDecoration(labelText: "Mobile", prefixIcon: Icon(Icons.phone), border: OutlineInputBorder())),
          const SizedBox(height: 15),
          TextField(controller: _otp, decoration: const InputDecoration(labelText: "OTP (123456)", prefixIcon: Icon(Icons.lock), border: OutlineInputBorder())),
          const SizedBox(height: 30),
          ElevatedButton(
            onPressed: () async {
              if (_otp.text == "123456") {
                SharedPreferences prefs = await SharedPreferences.getInstance();
                await prefs.setString('userRole', role);
                await prefs.setString('myPhone', _phone.text);
                Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => _getRoute(role)), (r)=>false);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 55)),
            child: const Text("AUTHENTICATE"),
          )
        ]),
      ),
    );
  }
  Widget _getRoute(role) {
    if (role == 'Shopkeeper') return const ShopDashboard();
    if (role == 'Professional') return const ProfessionalDashboard();
    return const CustomerDashboard();
  }
}

// --- 1. SHOPKEEPER (With Images & AI) ---
class ShopDashboard extends StatefulWidget {
  const ShopDashboard({super.key});
  @override
  State<ShopDashboard> createState() => _ShopDashboardState();
}

class _ShopDashboardState extends State<ShopDashboard> {
  final _n = TextEditingController();
  final _p = TextEditingController();
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
    if (_n.text.isEmpty) return;
    products.add({'name': _n.text, 'price': _p.text, 'img': _img?.path ?? ""});
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('trinity_products', json.encode(products));
    setState(() { _n.clear(); _p.clear(); _img = null; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Inventory"), actions: [IconButton(icon: const Icon(Icons.logout), onPressed: () => handleLogout(context))]),
      floatingActionButton: FloatingActionButton(onPressed: () => _showAIChat(context), child: const Icon(Icons.auto_awesome)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(children: [
          _imagePickerArea(),
          TextField(controller: _n, decoration: const InputDecoration(labelText: "Product Name")),
          TextField(controller: _p, decoration: const InputDecoration(labelText: "Price")),
          const SizedBox(height: 20),
          ElevatedButton(onPressed: _save, child: const Text("Add to Store")),
          const Divider(height: 40),
          ...products.asMap().entries.map((e) => Card(
            child: ListTile(
              leading: e.value['img'] != "" ? Image.file(File(e.value['img']), width: 50, fit: BoxFit.cover) : const Icon(Icons.image),
              title: Text(e.value['name']),
              subtitle: Text("₹${e.value['price']}"),
              trailing: IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () {
                setState(() => products.removeAt(e.key));
                _save(); // Resave list
              }),
            ),
          )).toList(),
        ]),
      ),
    );
  }
  Widget _imagePickerArea() => GestureDetector(
    onTap: () async {
      final p = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (p != null) setState(() => _img = File(p.path));
    },
    child: Container(
      height: 150, width: double.infinity, margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.indigo.withOpacity(0.2))),
      child: _img == null ? const Icon(Icons.add_a_photo, size: 40, color: Colors.indigo) : ClipRRect(borderRadius: BorderRadius.circular(20), child: Image.file(_img!, fit: BoxFit.cover)),
    ),
  );
}

// --- 2. PROFESSIONAL (With Photo & Hire-Call) ---
class ProfessionalDashboard extends StatefulWidget {
  const ProfessionalDashboard({super.key});
  @override
  State<ProfessionalDashboard> createState() => _ProfessionalDashboardState();
}

class _ProfessionalDashboardState extends State<ProfessionalDashboard> {
  File? _proImg;
  String name = "", job = "";
  bool online = false, hasHired = false;

  @override
  void initState() { super.initState(); _load(); }
  _load() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      name = prefs.getString('pro_name') ?? "";
      job = prefs.getString('pro_job') ?? "";
      if (prefs.getString('pro_img') != null) _proImg = File(prefs.getString('pro_img')!);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Partner Hub"), actions: [IconButton(icon: const Icon(Icons.logout), onPressed: () => handleLogout(context))]),
      floatingActionButton: FloatingActionButton(onPressed: () => _showAIChat(context), child: const Icon(Icons.auto_awesome)),
      body: name == "" ? _createProfile() : _mainDashboard(),
    );
  }

  Widget _createProfile() => Padding(
    padding: const EdgeInsets.all(30),
    child: Column(children: [
      GestureDetector(
        onTap: () async {
          final p = await ImagePicker().pickImage(source: ImageSource.camera);
          if (p != null) setState(() => _proImg = File(p.path));
        },
        child: CircleAvatar(radius: 60, backgroundImage: _proImg != null ? FileImage(_proImg!) : null, child: _proImg == null ? const Icon(Icons.camera_alt) : null),
      ),
      const SizedBox(height: 20),
      const TextField(decoration: InputDecoration(labelText: "Your Speciality (e.g. Plumber)")),
      ElevatedButton(onPressed: () async {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('pro_name', "ABHIMANIU");
        await prefs.setString('pro_job', "Plumber");
        if (_proImg != null) await prefs.setString('pro_img', _proImg!.path);
        _load();
      }, child: const Text("Go Live")),
    ]),
  );

  Widget _mainDashboard() => Column(children: [
    Container(
      margin: const EdgeInsets.all(20), padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(gradient: const LinearGradient(colors: [Colors.indigo, Colors.blue]), borderRadius: BorderRadius.circular(20)),
      child: Row(children: [
        CircleAvatar(radius: 30, backgroundImage: _proImg != null ? FileImage(_proImg!) : null),
        const SizedBox(width: 15),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(name, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)), Text(job, style: const TextStyle(color: Colors.white70))]),
      ]),
    ),
    const Text("Wait for hiring requests to see customer contact."),
    if (hasHired) Card(child: ListTile(title: const Text("Customer Hired You!"), trailing: IconButton(icon: const Icon(Icons.call, color: Colors.green), onPressed: () => startSecureCall("9999999999")))),
  ]);
}

// --- 3. CUSTOMER (With Search Fix & Hire-Call) ---
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
  bool isHired = false;

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
    if (prefs.getString('pro_name') != null) {
      setState(() => pro = {'name': prefs.getString('pro_name'), 'job': prefs.getString('pro_job'), 'img': prefs.getString('pro_img')});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Trinity Market"),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _fetch), IconButton(icon: const Icon(Icons.logout), onPressed: () => handleLogout(context))],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(100),
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: TextField(
                onChanged: (v) => setState(() => query = v.toLowerCase()),
                decoration: InputDecoration(hintText: "Search products/pros...", prefixIcon: const Icon(Icons.search), filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(30))),
              ),
            ),
            TabBar(controller: _tab, indicatorColor: Colors.orangeAccent, tabs: const [Tab(text: "Inventory"), Tab(text: "Experts")]),
          ]),
        ),
      ),
      floatingActionButton: FloatingActionButton(onPressed: () => _showAIChat(context), child: const Icon(Icons.auto_awesome)),
      body: TabBarView(controller: _tab, children: [
        // Tab 1: Products
        ListView(children: products.where((p) => p['name'].toString().toLowerCase().contains(query)).map((p) => Card(
          child: ListTile(
            leading: p['img'] != "" ? Image.file(File(p['img']), width: 50, fit: BoxFit.cover) : const Icon(Icons.image),
            title: Text(p['name']),
            trailing: const Text("BUY NOW", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
          ),
        )).toList()),
        // Tab 2: Professionals
        ListView(children: [
          if (pro != null && pro!['job'].toString().toLowerCase().contains(query))
            Card(
              child: ListTile(
                leading: pro!['img'] != null ? CircleAvatar(backgroundImage: FileImage(File(pro!['img']))) : const CircleAvatar(child: Icon(Icons.person)),
                title: Text(pro!['name']),
                subtitle: Text(pro!['job']),
                trailing: isHired 
                  ? IconButton(icon: const Icon(Icons.call, color: Colors.green), onPressed: () => startSecureCall("8888888888"))
                  : ElevatedButton(onPressed: () => setState(() => isHired = true), child: const Text("HIRE")),
              ),
            ),
        ]),
      ]),
    );
  }
}

// --- AI CHATBOT SYSTEM ---
void _showAIChat(BuildContext context) {
  showModalBottomSheet(
    context: context, isScrollControlled: true, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
    builder: (context) => Container(
      padding: const EdgeInsets.all(25), height: 500,
      child: Column(children: [
        const Text("Trinity AI Assistant", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.indigo)),
        const Divider(),
        const Expanded(child: Center(child: Text("Hello! I am your AI. How can I help you manage your store or find a worker?", textAlign: TextAlign.center))),
        TextField(decoration: InputDecoration(hintText: "Type here...", suffixIcon: const Icon(Icons.send), border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)))),
      ]),
    ),
  );
}
