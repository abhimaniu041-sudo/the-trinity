import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart'; // Standard package
import 'dart:io';
import 'dart:convert';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const TrinityApp());
}

// --- PREMIMUM THEME ---
class TrinityApp extends StatelessWidget {
  const TrinityApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo, brightness: Brightness.light),
        cardTheme: CardTheme(
          elevation: 5, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          color: Colors.white,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.indigo, foregroundColor: Colors.white, centerTitle: true,
          elevation: 10, shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(bottom: Radius.circular(15))),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(backgroundColor: Colors.orangeAccent, foregroundColor: Colors.white),
      ),
      home: const SplashScreen(),
    );
  }
}

// --- GLOBAL UTILS ---
Future<void> handleLogout(BuildContext context) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.remove('userRole'); // Only remove session, not data
  if (context.mounted) {
    Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const RoleSelectionPage()), (route) => false);
  }
}

// Fixed Call Function (Local Dialer - Server side required for real hidden numbers)
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
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("THE TRINITY", style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.indigo, letterSpacing: 3)),
            const SizedBox(height: 10),
            Container(padding: const EdgeInsets.all(5), decoration: BoxDecoration(border: Border.all(color: Colors.indigo), borderRadius: BorderRadius.circular(10)),
            child: Text("Powered by ABHIMANIU".toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.indigo, letterSpacing: 1.5))),
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
      body: Stack(
        children: [
          Container(decoration: const BoxDecoration(gradient: LinearGradient(colors: [Colors.indigo, Colors.indigoAccent], begin: Alignment.topCenter))),
          Positioned(bottom: 20, right: 20, child: Text("© ABHIMANIU", style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 10))),
          Center(
            child: Padding(
              padding: const EdgeInsets.all(25),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("SELECT PROFILE", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 40),
                  _roleCard(context, "Shopkeeper", Icons.storefront_rounded, Colors.white, Colors.indigo),
                  _roleCard(context, "Professional", Icons.engineering_rounded, Colors.white, Colors.orangeAccent),
                  _roleCard(context, "Customer", Icons.local_mall_rounded, Colors.white, Colors.greenAccent),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  Widget _roleCard(context, title, icon, bgColor, iconColor) => Card(
    margin: const EdgeInsets.only(bottom: 18), color: bgColor,
    child: ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => LoginPage(role: title))),
      leading: CircleAvatar(backgroundColor: iconColor.withOpacity(0.1), child: Icon(icon, color: iconColor, size: 28)),
      title: Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.indigo[900])),
      trailing: Icon(Icons.arrow_forward_ios_rounded, size: 16, color: iconColor),
    ),
  );
}

// --- LOGIN PAGE ---
class LoginPage extends StatefulWidget {
  final String role;
  const LoginPage({super.key, required this.role});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _phone = TextEditingController();
  final _otp = TextEditingController();
  bool obscure = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("${widget.role} Login")),
      body: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(children: [
          TextField(controller: _phone, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: "Mobile Number", border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(15))), prefixIcon: Icon(Icons.phone_android_rounded))),
          const SizedBox(height: 15),
          TextField(controller: _otp, keyboardType: TextInputType.number, obscureText: obscure, decoration: InputDecoration(labelText: "OTP (Demo: 123456)", border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(15))), prefixIcon: const Icon(Icons.lock_person_rounded), suffixIcon: IconButton(icon: Icon(obscure ? Icons.visibility : Icons.visibility_off), onPressed: () => setState(() => obscure = !obscure)))),
          const SizedBox(height: 30),
          SizedBox(
            width: double.infinity, height: 55,
            child: ElevatedButton(
              onPressed: () async {
                if (_otp.text == "123456") {
                  SharedPreferences prefs = await SharedPreferences.getInstance();
                  await prefs.setString('userRole', widget.role);
                  await prefs.setString('myPhone', _phone.text); // Save my number for anonymous call simulation
                  if (context.mounted) {
                    if (widget.role == 'Shopkeeper') Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const ShopDashboard()), (r)=>false);
                    else if (widget.role == 'Customer') Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const CustomerDashboard()), (r)=>false);
                    else Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const ProfessionalDashboard()), (r)=>false);
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Wrong OTP! Use 123456")));
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white, elevation: 10, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
              child: const Text("AUTHENTICATE", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
            ),
          )
        ]),
      ),
    );
  }
}

// --- 1. SHOPKEEPER DASHBOARD (IMAGES & REMOVE) ---
class ShopDashboard extends StatefulWidget {
  const ShopDashboard({super.key});
  @override
  State<ShopDashboard> createState() => _ShopDashboardState();
}

class _ShopDashboardState extends State<ShopDashboard> {
  final _name = TextEditingController();
  final _price = TextEditingController();
  File? _productImg;
  List products = [];

  @override
  void initState() { super.initState(); _loadProducts(); }
  _loadProducts() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? data = prefs.getString('trinity_products');
    if (data != null) setState(() => products = json.decode(data));
  }
  _pickImg() async {
    final p = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (p != null) setState(() => _productImg = File(p.path));
  }
  _saveProduct() async {
    if (_name.text.isEmpty || _price.text.isEmpty) return;
    products.add({'name': _name.text, 'price': _price.text, 'img': _productImg?.path ?? ""});
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('trinity_products', json.encode(products));
    setState(() { _name.clear(); _price.clear(); _productImg = null; });
  }
  // NEW: Remove functionality
  _removeProduct(int index) async {
    showDialog(context: context, builder: (c) => AlertDialog(
      title: const Text("Delete Product?"), content: Text("Are you sure you want to remove '${products[index]['name']}'?"),
      actions: [
        TextButton(onPressed: () => Navigator.pop(c), child: const Text("Cancel")),
        ElevatedButton(onPressed: () async {
          products.removeAt(index);
          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setString('trinity_products', json.encode(products));
          setState(() {}); Navigator.pop(c);
        }, style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white), child: const Text("Delete")),
      ],
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Store Management"), actions: [IconButton(icon: const Icon(Icons.logout_rounded), onPressed: () => handleLogout(context))]),
      floatingActionButton: FloatingActionButton(onPressed: () => _openAI(context), child: const Icon(Icons.support_agent_rounded, size: 30)),
      body: ListView(
        padding: const EdgeInsets.all(15),
        children: [
          Card(
            color: Colors.indigo[50],
            child: Padding(
              padding: const EdgeInsets.all(15),
              child: Column(children: [
                GestureDetector(
                  onTap: _pickImg,
                  child: Container(
                    height: 120, width: double.infinity,
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.indigoAccent)),
                    child: _productImg == null ? const Icon(Icons.add_photo_alternate_rounded, size: 40, color: Colors.indigo) : ClipRRect(borderRadius: BorderRadius.circular(15), child: Image.file(_productImg!, fit: BoxFit.cover)),
                  ),
                ),
                const SizedBox(height: 15),
                TextField(controller: _name, decoration: const InputDecoration(labelText: "Product Name", border: OutlineInputBorder(), prefixIcon: Icon(Icons.shopping_bag_outlined))),
                const SizedBox(height: 10),
                TextField(controller: _price, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Price (₹)", border: OutlineInputBorder(), prefixIcon: Icon(Icons.currency_rupee_rounded))),
                const SizedBox(height: 15),
                ElevatedButton.icon(onPressed: _saveProduct, icon: const Icon(Icons.add), label: const Text("List Product")),
              ]),
            ),
          ),
          const Divider(height: 30),
          const Text("Listed Products (Hold to Delete)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 10),
          ...products.asMap().entries.map((entry) => Card(
            child: ListTile(
              onLongPress: () => _removeProduct(entry.key), // Remove on hold
              leading: entry.value['img'] != "" ? ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.file(File(entry.value['img']), width: 50, height: 50, fit: BoxFit.cover)) : const Icon(Icons.image),
              title: Text(entry.value['name']),
              trailing: Text("₹${entry.value['price']}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
            ),
          )).toList()
        ],
      ),
    );
  }
}

// --- 2. PROFESSIONAL DASHBOARD (PHOTO + ACCEPT CALL) ---
class ProfessionalDashboard extends StatefulWidget {
  const ProfessionalDashboard({super.key});
  @override
  State<ProfessionalDashboard> createState() => _ProfessionalDashboardState();
}

class _ProfessionalDashboardState extends State<ProfessionalDashboard> {
  bool isOnline = false;
  File? _proPhoto;
  String name = "", job = "";
  final _n = TextEditingController();
  final _j = TextEditingController();

  @override
  void initState() { super.initState(); _loadProfile(); }
  _loadProfile() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      name = prefs.getString('pro_name') ?? "";
      job = prefs.getString('pro_job') ?? "";
      if (prefs.getString('pro_photo') != null) _proPhoto = File(prefs.getString('pro_photo')!);
      isOnline = prefs.getBool('pro_online') ?? false;
    });
  }
  _pickProPhoto() async {
    final p = await ImagePicker().pickImage(source: ImageSource.camera); // Prefer Camera
    if (p != null) setState(() => _proPhoto = File(p.path));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Partner Panel"), actions: [IconButton(icon: const Icon(Icons.logout_rounded), onPressed: () => handleLogout(context))]),
      floatingActionButton: FloatingActionButton(onPressed: () => _openAI(context), child: const Icon(Icons.support_agent_rounded, size: 30)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: name == "" ? Column(children: [
          const Text("Complete Your Profile", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 15),
          GestureDetector(
            onTap: _pickProPhoto,
            child: CircleAvatar(radius: 60, backgroundColor: Colors.indigo[100], backgroundImage: _proPhoto != null ? FileImage(_proPhoto!) : null, child: _proPhoto == null ? const Icon(Icons.add_a_photo, size: 40, color: Colors.indigo) : null),
          ),
          const SizedBox(height: 15),
          TextField(controller: _n, decoration: const InputDecoration(labelText: "Full Name", border: OutlineInputBorder())),
          const SizedBox(height: 10),
          TextField(controller: _j, decoration: const InputDecoration(labelText: "Expertise (e.g. Electrician)", border: OutlineInputBorder())),
          ElevatedButton(onPressed: () async {
            if (_proPhoto == null) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please upload profile photo"))); return;
            }
            SharedPreferences prefs = await SharedPreferences.getInstance();
            await prefs.setString('pro_name', _n.text); await prefs.setString('pro_job', _j.text); await prefs.setString('pro_photo', _proPhoto!.path);
            _loadProfile();
          }, child: const Text("Go Online"))
        ]) : Column(children: [
          // PREMIUM PARTNER CARD
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(gradient: const LinearGradient(colors: [Colors.indigo, Colors.blueAccent]), borderRadius: BorderRadius.circular(20), boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10)]),
            child: Column(children: [
              CircleAvatar(radius: 40, backgroundImage: _proPhoto != null ? FileImage(_proPhoto!) : null),
              Text(name, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
              Text(job, style: const TextStyle(color: Colors.white70)),
            ]),
          ),
          SwitchListTile(
            title: const Text("Status (Get Requests)"),
            value: isOnline,
            onChanged: (v) async {
              SharedPreferences prefs = await SharedPreferences.getInstance();
              await prefs.setBool('pro_online', v);
              setState(() => isOnline = v);
            },
          ),
          const Divider(height: 30),
          const Text("Incoming Leads", style: TextStyle(fontWeight: FontWeight.bold)),
          Card(color: Colors.orange[50], child: ListTile(
            title: const Text("Urgent Requirement"), subtitle: const Text("Tap Fitting | Sector 22"),
            trailing: Row(mainAxisSize: MainAxisSize.min, children: [
              IconButton(icon: const Icon(Icons.check, color: Colors.green), onPressed: () {}),
              // NEW CALL LOGIC: Standard practice to use local dialer. Server Required for full hide.
              IconButton(icon: const Icon(Icons.call, color: Colors.green), onPressed: () => makeSecureCall("7777777777")), 
            ]),
          ))
        ]),
      ),
    );
  }
}

// --- 3. CUSTOMER DASHBOARD (SEARCH FIX & AI) ---
class CustomerDashboard extends StatefulWidget {
  const CustomerDashboard({super.key});
  @override
  State<CustomerDashboard> createState() => _CustomerDashboardState();
}

class _CustomerDashboardState extends State<CustomerDashboard> with SingleTickerProviderStateMixin {
  late TabController _tab;
  String query = "";
  List allProducts = [];
  Map? onlineProData;
  File? _proP;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _fetchMarketData();
  }

  _fetchMarketData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    // Products
    String? pData = prefs.getString('trinity_products');
    if (pData != null) allProducts = json.decode(pData);
    
    // Professionals
    if (prefs.getBool('pro_online') ?? false) {
      if (prefs.getString('pro_photo') != null) _proP = File(prefs.getString('pro_photo')!);
      setState(() {
        onlineProData = {'name': prefs.getString('pro_name'), 'job': prefs.getString('pro_job'), 'phone': prefs.getString('myPhone')};
      });
    } else {
      setState(() { onlineProData = null; });
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Trinity Marketplace"),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchMarketData), IconButton(icon: const Icon(Icons.logout), onPressed: () => handleLogout(context))],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(100),
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
              child: TextField(
                onChanged: (v) => setState(() => query = v.toLowerCase()),
                decoration: InputDecoration(hintText: "Search anything...", prefixIcon: const Icon(Icons.search), filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none)),
              ),
            ),
            TabBar(controller: _tab, indicatorColor: Colors.white, labelColor: Colors.white, unselectedLabelColor: Colors.white70, tabs: const [Tab(text: "Products"), Tab(text: "Hire Pros")]),
          ]),
        ),
      ),
      floatingActionButton: FloatingActionButton(onPressed: () => _openAI(context), child: const Icon(Icons.auto_awesome_rounded, size: 30)),
      body: TabBarView(controller: _tab, children: [
        // Tab 1: Products with image
        ListView(padding: const EdgeInsets.symmetric(vertical: 10), children: allProducts.where((p) => p['name'].toString().toLowerCase().contains(query)).map((p) => Card(
          child: ListTile(
            leading: p['img'] != "" ? ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.file(File(p['img']), width: 50, height: 50, fit: BoxFit.cover)) : const Icon(Icons.image, color: Colors.indigo),
            title: Text(p['name']),
            trailing: ElevatedButton(onPressed: (){}, child: Text("₹${p['price']} BUY")),
          ),
        )).toList()),
        
        // Tab 2: Professionals (Only Online & Hired Logic)
        ListView(padding: const EdgeInsets.all(10), children: [
          if (onlineProData != null && (onlineProData!['job'].toString().toLowerCase().contains(query) || onlineProData!['name'].toString().toLowerCase().contains(query)))
            Card(
              color: Colors.green[50],
              child: ListTile(
                leading: CircleAvatar(backgroundImage: _proP != null ? FileImage(_proP!) : null),
                title: Text(onlineProData!['name']),
                subtitle: Text(onlineProData!['job']),
                trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                  ElevatedButton(onPressed: () {}, child: const Text("HIRE")), // Hiring confirm required
                  const SizedBox(width: 5),
                  // CALL Logic: In current local standard, opens dialer. Need backend for masking.
                  IconButton(icon: const Icon(Icons.call_rounded, color: Colors.green), onPressed: () => makeSecureCall(onlineProData!['phone'])), 
                ]),
              ),
            ),
          if (onlineProData == null) const Center(child: Padding(padding: EdgeInsets.all(30), child: Text("No Professionals Online right now")))
        ]),
      ]),
    );
  }
}

// --- AI SUPPORT CHAT ---
void _openAI(BuildContext context) {
  showModalBottomSheet(
    context: context, isScrollControlled: true, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
    builder: (context) => Container(
      padding: const EdgeInsets.all(20), height: MediaQuery.of(context).size.height * 0.7,
      child: Column(children: [
        const Text("Trinity AI Assistant", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.indigo)),
        const Divider(),
        const Expanded(child: Center(child: Text("How can I help you with Trinity Services?\n(Type 'Product' or 'Hire')", textAlign: TextAlign.center))),
        TextField(decoration: InputDecoration(hintText: "Ask something...", suffixIcon: const Icon(Icons.send), border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)))),
      ]),
    ),
  );
}
