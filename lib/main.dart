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
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1A237E)),
        // FIXED: Correct syntax for CardThemeData
        cardTheme: CardThemeData(
          elevation: 10,
          shadowColor: Colors.black26,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        ),
      ),
      home: const SplashScreen(),
    );
  }
}

// --- SHARED FUNCTIONS ---
Future<void> handleLogout(BuildContext context) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.remove('userRole'); 
  Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const RoleSelectionPage()), (route) => false);
}

Future<void> startSecureCall(String phone) async {
  final Uri url = Uri(scheme: 'tel', path: phone);
  if (await canLaunchUrl(url)) { await launchUrl(url); }
}

// --- LUXURY SPLASH SCREEN ---
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
            const Text("THE TRINITY", style: TextStyle(fontSize: 55, fontWeight: FontWeight.w900, color: Color(0xFF1A237E), letterSpacing: 5)),
            const SizedBox(height: 10),
            Container(height: 3, width: 80, color: Colors.orangeAccent),
            const SizedBox(height: 20),
            const Text("POWERED BY ABHIMANIU", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 3)),
          ],
        ),
      ),
    );
  }
}

// --- PREMIUM ROLE SELECTION ---
class RoleSelectionPage extends StatelessWidget {
  const RoleSelectionPage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(colors: [Color(0xFF1A237E), Color(0xFF3949AB)], begin: Alignment.topCenter)
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("Welcome to the Trinity", style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
            const SizedBox(height: 50),
            _roleTile(context, "Shopkeeper", Icons.store_rounded, Colors.indigoAccent),
            _roleTile(context, "Professional", Icons.handyman_rounded, Colors.orangeAccent),
            _roleTile(context, "Customer", Icons.shopping_basket_rounded, Colors.tealAccent),
          ],
        ),
      ),
    );
  }
  Widget _roleTile(context, title, icon, color) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 45, vertical: 12),
    child: InkWell(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => LoginPage(role: title))),
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(25), boxShadow: [const BoxShadow(color: Colors.black45, blurRadius: 15)]),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF1A237E), size: 35),
            const SizedBox(width: 25),
            Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1A237E))),
            const Spacer(),
            const Icon(Icons.arrow_forward_ios, size: 18, color: Colors.grey),
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
      appBar: AppBar(title: Text("$role Login"), backgroundColor: const Color(0xFF1A237E), foregroundColor: Colors.white),
      body: Padding(
        padding: const EdgeInsets.all(35),
        child: Column(children: [
          TextField(controller: _phone, decoration: const InputDecoration(labelText: "Phone Number", prefixIcon: Icon(Icons.phone), border: OutlineInputBorder())),
          const SizedBox(height: 20),
          TextField(controller: _otp, decoration: const InputDecoration(labelText: "OTP (123456)", prefixIcon: Icon(Icons.lock), border: OutlineInputBorder())),
          const SizedBox(height: 40),
          ElevatedButton(
            onPressed: () async {
              if (_otp.text == "123456") {
                SharedPreferences prefs = await SharedPreferences.getInstance();
                await prefs.setString('userRole', role);
                await prefs.setString('myPhone', _phone.text);
                Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => _getRoute(role)), (r)=>false);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A237E), foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 60), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
            child: const Text("LOGIN", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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

// --- SHOPKEEPER DASHBOARD ---
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
      appBar: AppBar(title: const Text("Inventory Manager"), backgroundColor: const Color(0xFF1A237E), foregroundColor: Colors.white, actions: [IconButton(icon: const Icon(Icons.logout), onPressed: () => handleLogout(context))]),
      floatingActionButton: FloatingActionButton(onPressed: () => _showAIChat(context), child: const Icon(Icons.auto_awesome)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(children: [
          GestureDetector(
            onTap: () async {
              final p = await ImagePicker().pickImage(source: ImageSource.gallery);
              if (p != null) setState(() => _img = File(p.path));
            },
            child: Container(
              height: 180, width: double.infinity, margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(25), border: Border.all(color: Colors.indigo)),
              child: _img == null ? const Icon(Icons.add_a_photo, size: 50, color: Colors.indigo) : ClipRRect(borderRadius: BorderRadius.circular(25), child: Image.file(_img!, fit: BoxFit.cover)),
            ),
          ),
          TextField(controller: _n, decoration: const InputDecoration(labelText: "Product Name", border: OutlineInputBorder())),
          const SizedBox(height: 15),
          TextField(controller: _p, decoration: const InputDecoration(labelText: "Price (₹)", border: OutlineInputBorder())),
          const SizedBox(height: 20),
          ElevatedButton(onPressed: _save, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A237E), foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 50)), child: const Text("ADD PRODUCT")),
          const Divider(height: 50),
          ...products.asMap().entries.map((e) => Card(
            child: ListTile(
              leading: e.value['img'] != "" ? ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.file(File(e.value['img']), width: 55, height: 55, fit: BoxFit.cover)) : const Icon(Icons.image, size: 30),
              title: Text(e.value['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text("Price: ₹${e.value['price']}"),
              trailing: IconButton(icon: const Icon(Icons.delete_forever, color: Colors.redAccent), onPressed: () {
                setState(() => products.removeAt(e.key));
                _save();
              }),
            ),
          )).toList(),
        ]),
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
  File? _proImg;
  String name = "", job = "", phone = "";
  bool online = false, hasHired = false;

  @override
  void initState() { super.initState(); _load(); }
  _load() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      name = prefs.getString('pro_name') ?? "";
      job = prefs.getString('pro_job') ?? "";
      phone = prefs.getString('myPhone') ?? "";
      if (prefs.getString('pro_img') != null) _proImg = File(prefs.getString('pro_img')!);
      online = prefs.getBool('pro_status') ?? false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Professional Partner"), backgroundColor: const Color(0xFF1A237E), foregroundColor: Colors.white, actions: [IconButton(icon: const Icon(Icons.logout), onPressed: () => handleLogout(context))]),
      floatingActionButton: FloatingActionButton(onPressed: () => _showAIChat(context), child: const Icon(Icons.auto_awesome)),
      body: name == "" ? _createProfile() : _mainView(),
    );
  }

  Widget _createProfile() => SingleChildScrollView(
    padding: const EdgeInsets.all(40),
    child: Column(children: [
      GestureDetector(
        onTap: () async {
          final p = await ImagePicker().pickImage(source: ImageSource.camera);
          if (p != null) setState(() => _proImg = File(p.path));
        },
        child: CircleAvatar(radius: 70, backgroundColor: Colors.grey[200], backgroundImage: _proImg != null ? FileImage(_proImg!) : null, child: _proImg == null ? const Icon(Icons.add_a_photo, size: 40) : null),
      ),
      const SizedBox(height: 30),
      const TextField(decoration: InputDecoration(labelText: "Full Name", border: OutlineInputBorder())),
      const SizedBox(height: 15),
      const TextField(decoration: InputDecoration(labelText: "Job Title (e.g. Electrician)", border: OutlineInputBorder())),
      const SizedBox(height: 30),
      ElevatedButton(onPressed: () async {
        if (_proImg == null) return;
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('pro_name', "ABHIMANIU");
        await prefs.setString('pro_job', "Plumber");
        await prefs.setString('pro_img', _proImg!.path);
        _load();
      }, child: const Text("GO LIVE"))
    ]),
  );

  Widget _mainView() => Padding(
    padding: const EdgeInsets.all(20),
    child: Column(children: [
      Container(
        padding: const EdgeInsets.all(25),
        decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF1A237E), Colors.blue]), borderRadius: BorderRadius.circular(30)),
        child: Column(children: [
          CircleAvatar(radius: 50, backgroundImage: _proImg != null ? FileImage(_proImg!) : null),
          const SizedBox(height: 15),
          Text(name, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
          Text(job, style: const TextStyle(color: Colors.white70, fontSize: 18)),
          const Divider(color: Colors.white24, height: 40),
          const Text("OFFICIAL ID: TRIN-853", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ]),
      ),
      SwitchListTile(
        title: Text(online ? "YOU ARE ONLINE" : "YOU ARE OFFLINE", style: TextStyle(fontWeight: FontWeight.bold, color: online ? Colors.green : Colors.red)),
        value: online,
        onChanged: (v) async {
          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setBool('pro_status', v);
          setState(() => online = v);
        },
      ),
    ]),
  );
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
    if (prefs.getBool('pro_status') ?? false) {
      setState(() {
        pro = {'name': prefs.getString('pro_name'), 'job': prefs.getString('pro_job'), 'img': prefs.getString('pro_img'), 'phone': prefs.getString('myPhone')};
      });
    } else { setState(() => pro = null); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Trinity Marketplace"), backgroundColor: const Color(0xFF1A237E), foregroundColor: Colors.white,
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _fetch), IconButton(icon: const Icon(Icons.logout), onPressed: () => handleLogout(context))],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(110),
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: TextField(
                onChanged: (v) => setState(() => query = v.toLowerCase()),
                decoration: InputDecoration(hintText: "Search anything...", prefixIcon: const Icon(Icons.search), filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(30))),
              ),
            ),
            TabBar(controller: _tab, indicatorColor: Colors.orangeAccent, labelColor: Colors.white, unselectedLabelColor: Colors.white70, tabs: const [Tab(text: "Products"), Tab(text: "Hire Pros")]),
          ]),
        ),
      ),
      floatingActionButton: FloatingActionButton(onPressed: () => _showAIChat(context), child: const Icon(Icons.auto_awesome)),
      body: TabBarView(controller: _tab, children: [
        // Tab 1: Products (Search Fixed)
        ListView(children: products.where((p) => p['name'].toString().toLowerCase().contains(query)).map((p) => Card(
          child: ListTile(
            leading: p['img'] != "" ? ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.file(File(p['img']), width: 50, height: 50, fit: BoxFit.cover)) : const Icon(Icons.image),
            title: Text(p['name']),
            trailing: Text("₹${p['price']} BUY", style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
          ),
        )).toList()),
        // Tab 2: Professionals (Search Fixed)
        ListView(children: [
          if (pro != null && pro!['job'].toString().toLowerCase().contains(query))
            Card(
              child: ListTile(
                leading: pro!['img'] != null ? CircleAvatar(backgroundImage: FileImage(File(pro!['img']))) : const CircleAvatar(child: Icon(Icons.person)),
                title: Text(pro!['name']),
                subtitle: Text(pro!['job']),
                trailing: isHired 
                  ? IconButton(icon: const Icon(Icons.call, color: Colors.green), onPressed: () => startSecureCall(pro!['phone']))
                  : ElevatedButton(onPressed: () => setState(() => isHired = true), child: const Text("HIRE")),
              ),
            ),
          if (pro == null) const Center(child: Padding(padding: EdgeInsets.all(40), child: Text("No Professionals Online"))),
        ]),
      ]),
    );
  }
}

// --- AI CHATBOT ---
void _showAIChat(BuildContext context) {
  showModalBottomSheet(
    context: context, isScrollControlled: true, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
    builder: (context) => Container(
      padding: const EdgeInsets.all(25), height: 500,
      child: Column(children: [
        const Text("Trinity AI Assistant", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1A237E))),
        const Divider(),
        const Expanded(child: Center(child: Text("Hello! I am your Luxury Support AI. How can I help you today?", textAlign: TextAlign.center, style: TextStyle(fontSize: 16)))),
        TextField(decoration: InputDecoration(hintText: "Ask anything...", suffixIcon: const Icon(Icons.send), border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)))),
      ]),
    ),
  );
}
