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
        // FIXED: Using standard CardTheme to avoid build errors
        cardTheme: CardTheme(
          elevation: 5,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
      ),
      // FIXED: Removed 'const' because SplashScreen has logic
      home: SplashScreen(),
    );
  }
}

// --- GLOBAL FUNCTIONS ---
Future<void> handleLogout(BuildContext context) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.remove('userRole'); 
  if (context.mounted) {
    Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => RoleSelectionPage()), (route) => false);
  }
}

// --- SPLASH SCREEN ---
class SplashScreen extends StatefulWidget {
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
      else Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => RoleSelectionPage()));
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
            const Text("THE TRINITY", style: TextStyle(fontSize: 50, fontWeight: FontWeight.w900, color: Color(0xFF1A237E), letterSpacing: 3)),
            const SizedBox(height: 10),
            Text("Powered by ABHIMANIU".toUpperCase(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.indigo)),
          ],
        ),
      ),
    );
  }
}

// --- ROLE SELECTION (Luxury Look) ---
class RoleSelectionPage extends StatelessWidget {
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
            const Text("Welcome to Trinity", style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
            const SizedBox(height: 40),
            _roleBtn(context, "Shopkeeper", Icons.store_rounded),
            _roleBtn(context, "Professional", Icons.handyman_rounded),
            _roleBtn(context, "Customer", Icons.person_search_rounded),
            const SizedBox(height: 50),
            const Text("Powered by ABHIMANIU", style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
  Widget _roleBtn(context, title, icon) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 45, vertical: 10),
    child: Card(
      child: ListTile(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => LoginPage(role: title))),
        leading: Icon(icon, color: const Color(0xFF1A237E)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 14),
      ),
    ),
  );
}

// --- LOGIN PAGE ---
class LoginPage extends StatelessWidget {
  final String role;
  LoginPage({required this.role});
  final _phone = TextEditingController();
  final _otp = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("$role Access")),
      body: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(children: [
          TextField(controller: _phone, decoration: const InputDecoration(labelText: "Phone Number", prefixIcon: Icon(Icons.phone), border: OutlineInputBorder())),
          const SizedBox(height: 15),
          TextField(controller: _otp, decoration: const InputDecoration(labelText: "OTP (123456)", prefixIcon: Icon(Icons.lock), border: OutlineInputBorder())),
          const SizedBox(height: 30),
          ElevatedButton(
            onPressed: () async {
              if (_otp.text == "123456") {
                SharedPreferences prefs = await SharedPreferences.getInstance();
                await prefs.setString('userRole', role);
                Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => _getRoute(role)), (r)=>false);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A237E), foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 55)),
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

// --- SHOPKEEPER DASHBOARD (With Multi-Images) ---
class ShopDashboard extends StatefulWidget {
  const ShopDashboard({super.key});
  @override
  State<ShopDashboard> createState() => _ShopDashboardState();
}

class _ShopDashboardState extends State<ShopDashboard> {
  final _n = TextEditingController();
  final _p = TextEditingController();
  List<String> _imgs = [];
  List products = [];

  @override
  void initState() { super.initState(); _load(); }
  _load() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? data = prefs.getString('trinity_products');
    if (data != null) setState(() => products = json.decode(data));
  }
  _pick() async {
    final p = await ImagePicker().pickMultiImage();
    if (p.isNotEmpty) setState(() => _imgs = p.map((f) => f.path).toList());
  }
  _save() async {
    if (_n.text.isEmpty) return;
    products.add({'name': _n.text, 'price': _p.text, 'imgs': _imgs});
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('trinity_products', json.encode(products));
    setState(() { _n.clear(); _p.clear(); _imgs = []; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Store Manager"), actions: [IconButton(icon: const Icon(Icons.logout), onPressed: () => handleLogout(context))]),
      floatingActionButton: FloatingActionButton(onPressed: () => _openAI(context), child: const Icon(Icons.auto_awesome)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(children: [
          GestureDetector(
            onTap: _pick,
            child: Container(
              height: 120, width: double.infinity,
              decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(20)),
              child: _imgs.isEmpty ? const Icon(Icons.add_a_photo) : ListView(scrollDirection: Axis.horizontal, children: _imgs.map((path) => Image.file(File(path))).toList()),
            ),
          ),
          TextField(controller: _n, decoration: const InputDecoration(labelText: "Product Name")),
          TextField(controller: _p, decoration: const InputDecoration(labelText: "Price")),
          const SizedBox(height: 10),
          ElevatedButton(onPressed: _save, child: const Text("LIST PRODUCT")),
          const Divider(height: 40),
          ...products.asMap().entries.map((e) => Card(
            child: ListTile(
              leading: e.value['imgs'].isNotEmpty ? Image.file(File(e.value['imgs'][0]), width: 50) : const Icon(Icons.image),
              title: Text(e.value['name']),
              trailing: IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () {
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
  File? _photo;
  String name = "", job = "";

  @override
  void initState() { super.initState(); _load(); }
  _load() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      name = prefs.getString('pro_name') ?? "";
      job = prefs.getString('pro_job') ?? "";
      if (prefs.getString('pro_photo') != null) _photo = File(prefs.getString('pro_photo')!);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Partner Panel"), actions: [IconButton(icon: const Icon(Icons.logout), onPressed: () => handleLogout(context))]),
      floatingActionButton: FloatingActionButton(onPressed: () => _openAI(context), child: const Icon(Icons.auto_awesome)),
      body: name == "" ? _createUI() : _cardUI(),
    );
  }
  Widget _createUI() => Padding(
    padding: const EdgeInsets.all(40),
    child: Column(children: [
      GestureDetector(
        onTap: () async {
          final p = await ImagePicker().pickImage(source: ImageSource.camera);
          if (p != null) setState(() => _photo = File(p.path));
        },
        child: CircleAvatar(radius: 60, backgroundImage: _photo != null ? FileImage(_photo!) : null, child: _photo == null ? const Icon(Icons.camera_alt) : null),
      ),
      const TextField(decoration: InputDecoration(labelText: "Job Title")),
      ElevatedButton(onPressed: () async {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('pro_name', "PRO PARTNER");
        await prefs.setString('pro_job', "Technician");
        if (_photo != null) await prefs.setString('pro_photo', _photo!.path);
        _load();
      }, child: const Text("GO LIVE")),
    ]),
  );
  Widget _cardUI() => Center(
    child: Card(
      color: Colors.indigo,
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          CircleAvatar(radius: 40, backgroundImage: _photo != null ? FileImage(_photo!) : null),
          Text(name, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
          Text(job, style: const TextStyle(color: Colors.white70)),
          const Divider(),
          const Text("ID: TRIN-853", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ]),
      ),
    ),
  );
}

// --- CUSTOMER DASHBOARD (Search Fixed) ---
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
    if (prefs.getString('pro_name') != null) {
      setState(() => pro = {'name': prefs.getString('pro_name'), 'job': prefs.getString('pro_job'), 'img': prefs.getString('pro_photo')});
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredProducts = products.where((p) => p['name'].toString().toLowerCase().contains(query)).toList();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text("Trinity Marketplace"),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(110),
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.all(10),
              child: TextField(
                onChanged: (v) => setState(() => query = v.toLowerCase()),
                decoration: InputDecoration(hintText: "Search...", prefixIcon: const Icon(Icons.search), filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(30))),
              ),
            ),
            TabBar(controller: _tab, tabs: const [Tab(text: "Products"), Tab(text: "Experts")]),
          ]),
        ),
      ),
      floatingActionButton: FloatingActionButton(onPressed: () => _openAI(context), child: const Icon(Icons.auto_awesome)),
      body: TabBarView(controller: _tab, children: [
        ListView.builder(
          itemCount: filteredProducts.length,
          itemBuilder: (context, i) => Card(
            child: ListTile(
              leading: filteredProducts[i]['imgs'].isNotEmpty ? Image.file(File(filteredProducts[i]['imgs'][0]), width: 50) : const Icon(Icons.image),
              title: Text(filteredProducts[i]['name']),
              trailing: ElevatedButton(onPressed: () {}, child: const Text("BUY")),
              onTap: () => _showProduct(filteredProducts[i]),
            ),
          ),
        ),
        ListView(children: [
          if (pro != null && pro!['job'].toString().toLowerCase().contains(query))
            Card(child: ListTile(
              leading: pro!['img'] != null ? CircleAvatar(backgroundImage: FileImage(File(pro!['img']))) : null,
              title: Text(pro!['name']),
              subtitle: Text(pro!['job']),
              trailing: ElevatedButton(onPressed: () => launchUrl(Uri.parse("tel:9999999999")), child: const Text("HIRE")),
            )),
        ]),
      ]),
    );
  }
  void _showProduct(Map p) {
    showDialog(context: context, builder: (c) => AlertDialog(
      title: Text(p['name']),
      content: SizedBox(height: 200, child: ListView(scrollDirection: Axis.horizontal, children: (p['imgs'] as List).map((path) => Image.file(File(path))).toList())),
    ));
  }
}

// --- AI CHATBOT ---
void _openAI(BuildContext context) {
  showModalBottomSheet(
    context: context, isScrollControlled: true,
    builder: (context) => Container(
      padding: const EdgeInsets.all(20), height: 400,
      child: Column(children: [
        const Text("Trinity AI Support", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const Divider(),
        const Expanded(child: Center(child: Text("AI: Hello! How can I help you manage orders?"))),
        TextField(decoration: InputDecoration(hintText: "Type message...", suffixIcon: IconButton(icon: const Icon(Icons.send), onPressed: (){}))),
      ]),
    ),
  );
}
