import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:photo_view/photo_view.dart';
import 'dart:io';
import 'dart:convert';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const TrinityApp());
}

class TrinityApp extends StatefulWidget {
  const TrinityApp({super.key});
  @override
  State<TrinityApp> createState() => _TrinityAppState();
}

class _TrinityAppState extends State<TrinityApp> {
  ThemeMode _themeMode = ThemeMode.light;

  void _toggleTheme() {
    setState(() {
      _themeMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'The Trinity',
      themeMode: _themeMode,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1A237E), brightness: Brightness.light),
        cardTheme: CardThemeData(elevation: 4, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo, brightness: Brightness.dark),
        cardTheme: CardThemeData(elevation: 4, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
      ),
      home: SplashScreen(toggleTheme: _toggleTheme, mode: _themeMode),
    );
  }
}

// --- NAVIGATION HELPER ---
Widget _navigate(String role, VoidCallback toggle, ThemeMode mode) {
  if (role == 'Shopkeeper') return ShopDashboard(onTheme: toggle, mode: mode);
  if (role == 'Professional') return ProDashboard(onTheme: toggle, mode: mode);
  return CustomerDashboard(onTheme: toggle, mode: mode);
}

// --- SPLASH SCREEN ---
class SplashScreen extends StatefulWidget {
  final VoidCallback toggleTheme;
  final ThemeMode mode;
  const SplashScreen({super.key, required this.toggleTheme, required this.mode});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() { super.initState(); _init(); }
  _init() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? role = prefs.getString('userRole');
    await Future.delayed(const Duration(seconds: 3));
    if (!mounted) return;
    if (role != null) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (c) => _navigate(role, widget.toggleTheme, widget.mode)));
    } else {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (c) => RoleSelectionPage(toggleTheme: widget.toggleTheme)));
    }
  }
  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: Text("THE TRINITY", style: TextStyle(fontSize: 40, fontWeight: FontWeight.w900, color: Color(0xFF1A237E)))));
  }
}

// --- ROLE SELECTION ---
class RoleSelectionPage extends StatelessWidget {
  final VoidCallback toggleTheme;
  const RoleSelectionPage({super.key, required this.toggleTheme});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF1A237E), Color(0xFF3949AB)], begin: Alignment.topCenter)),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Text("Welcome to Trinity", style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
          const SizedBox(height: 40),
          _btn(context, "Shopkeeper", Icons.storefront),
          _btn(context, "Customer", Icons.person_search),
          _btn(context, "Professional", Icons.engineering),
        ]),
      ),
    );
  }
  Widget _btn(context, String r, IconData i) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 10),
    child: Card(child: ListTile(
      leading: Icon(i, color: const Color(0xFF1A237E)),
      title: Text(r, style: const TextStyle(fontWeight: FontWeight.bold)),
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => LoginPage(role: r, toggleTheme: toggleTheme))),
    )),
  );
}

// --- LOGIN PAGE (Hybrid: Email/Phone) ---
class LoginPage extends StatefulWidget {
  final String role;
  final VoidCallback toggleTheme;
  const LoginPage({super.key, required this.role, required this.toggleTheme});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _idController = TextEditingController();
  final _otpController = TextEditingController();
  bool isOTPsent = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("${widget.role} Login")),
      body: Padding(padding: const EdgeInsets.all(30), child: Column(children: [
        TextField(controller: _idController, decoration: const InputDecoration(labelText: "Email ID or Phone Number", border: OutlineInputBorder(), prefixIcon: Icon(Icons.person))),
        const SizedBox(height: 20),
        if (isOTPsent) TextField(controller: _otpController, decoration: const InputDecoration(labelText: "OTP (Enter 123456)", border: OutlineInputBorder(), prefixIcon: Icon(Icons.lock))),
        const SizedBox(height: 30),
        ElevatedButton(
          style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 55)),
          onPressed: () async {
            if (!isOTPsent) {
              if (_idController.text.isNotEmpty) setState(() => isOTPsent = true);
            } else {
              if (_otpController.text == "123456") {
                SharedPreferences prefs = await SharedPreferences.getInstance();
                await prefs.setString('userRole', widget.role);
                await prefs.setString('user_id', _idController.text);
                if (mounted) Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (c) => SplashScreen(toggleTheme: widget.toggleTheme, mode: ThemeMode.light)), (r) => false);
              }
            }
          }, 
          child: Text(isOTPsent ? "VERIFY & LOGIN" : "GET OTP")
        )
      ])),
    );
  }
}

// --- SHARED HEADER ---
class DashboardHeader extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final VoidCallback onTheme, onProfile;
  final ThemeMode mode;
  const DashboardHeader({super.key, required this.title, required this.onTheme, required this.onProfile, required this.mode});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      actions: [
        IconButton(icon: Icon(mode == ThemeMode.light ? Icons.dark_mode : Icons.light_mode), onPressed: onTheme),
        IconButton(icon: const Icon(Icons.account_circle_outlined), onPressed: onProfile),
        IconButton(icon: const Icon(Icons.logout, color: Colors.red), onPressed: () async {
          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.remove('userRole');
          Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (c) => RoleSelectionPage(toggleTheme: onTheme)), (r) => false);
        }),
      ],
    );
  }
  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

// --- 1. CUSTOMER DASHBOARD ---
class CustomerDashboard extends StatefulWidget {
  final VoidCallback onTheme;
  final ThemeMode mode;
  const CustomerDashboard({super.key, required this.onTheme, required this.mode});
  @override
  State<CustomerDashboard> createState() => _CustomerDashboardState();
}

class _CustomerDashboardState extends State<CustomerDashboard> with SingleTickerProviderStateMixin {
  late TabController _tab;
  String query = "", cName = "", cAddr = "";
  List products = [];
  Map? pro;
  bool hasProfile = false;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _load();
  }

  _load() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      cName = prefs.getString('cust_name') ?? "";
      cAddr = prefs.getString('cust_addr') ?? "";
      hasProfile = cName.isNotEmpty;
      String? data = prefs.getString('shop_products');
      if (data != null) products = json.decode(data);
      if (prefs.getBool('pro_status') ?? false) {
        pro = {'name': prefs.getString('pro_name'), 'job': prefs.getString('pro_job'), 'img': prefs.getString('pro_photo')};
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final filtered = products.where((p) => p['name'].toString().toLowerCase().contains(query.toLowerCase())).toList();
    return Scaffold(
      appBar: DashboardHeader(title: "Trinity Market", onTheme: widget.onTheme, mode: widget.mode, onProfile: _showProfile),
      floatingActionButton: FloatingActionButton(onPressed: () => _openAI(context), child: const Icon(Icons.auto_awesome)),
      body: !hasProfile ? _setup() : Column(children: [
        Padding(padding: const EdgeInsets.all(15), child: TextField(onChanged: (v) => setState(() => query = v), decoration: InputDecoration(hintText: "Search products/experts...", prefixIcon: const Icon(Icons.search), border: OutlineInputBorder(borderRadius: BorderRadius.circular(30))))),
        TabBar(controller: _tab, labelColor: Colors.indigo, tabs: const [Tab(text: "Products"), Tab(text: "Experts")]),
        Expanded(child: TabBarView(controller: _tab, children: [
          ListView.builder(itemCount: filtered.length, itemBuilder: (c, i) => _productTile(filtered[i])),
          _proSection()
        ]))
      ]),
    );
  }

  Widget _setup() => Padding(padding: const EdgeInsets.all(40), child: Column(children: [
    const Text("Setup Your Profile", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
    TextField(onChanged: (v) => cName = v, decoration: const InputDecoration(labelText: "Full Name")),
    TextField(onChanged: (v) => cAddr = v, decoration: const InputDecoration(labelText: "Address")),
    ElevatedButton(onPressed: () async {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('cust_name', cName); await prefs.setString('cust_addr', cAddr); _load();
    }, child: const Text("Save"))
  ]));

  Widget _productTile(Map p) => Card(child: ListTile(
    onTap: () => _zoom(p['imgs']),
    leading: Image.file(File(p['imgs'][0]), width: 50, fit: BoxFit.cover),
    title: Text(p['name']),
    trailing: ElevatedButton(onPressed: () => _buy(p), child: const Text("BUY")),
  ));

  Widget _proSection() => ListView(children: [
    if (pro != null && pro!['name'].toLowerCase().contains(query.toLowerCase()))
      Card(child: ListTile(
        leading: CircleAvatar(backgroundImage: pro!['img'] != null ? FileImage(File(pro!['img'])) : null),
        title: Text(pro!['name']), subtitle: Text(pro!['job']),
        trailing: ElevatedButton(onPressed: _hire, child: const Text("HIRE")),
      ))
  ]);

  void _showProfile() => _setup(); // Simplified for demo
  void _hire() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hired_msg', true);
    await prefs.setString('hired_details', "Customer: $cName\nAddress: $cAddr");
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Hiring Details sent to Professional!")));
  }
  void _buy(Map p) {
     ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Order Success! Details shared with Shopkeeper.")));
  }
  void _zoom(List imgs) {
    showDialog(context: context, builder: (c) => Dialog.fullscreen(child: Stack(children: [
      PhotoView(imageProvider: FileImage(File(imgs[0]))),
      Positioned(top: 40, right: 20, child: IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => Navigator.pop(c)))
    ])));
  }
}

// --- 2. SHOPKEEPER DASHBOARD ---
class ShopDashboard extends StatefulWidget {
  final VoidCallback onTheme;
  final ThemeMode mode;
  const ShopDashboard({super.key, required this.onTheme, required this.mode});
  @override
  State<ShopDashboard> createState() => _ShopDashboardState();
}

class _ShopDashboardState extends State<ShopDashboard> {
  String sName = "";
  List products = [];
  @override
  void initState() { super.initState(); _load(); }
  _load() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      sName = prefs.getString('shop_name') ?? "";
      String? data = prefs.getString('shop_products');
      if (data != null) products = json.decode(data);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: DashboardHeader(title: "Trinity Store", onTheme: widget.onTheme, mode: widget.mode, onProfile: (){}),
      body: sName.isEmpty ? _setup() : _main(),
    );
  }

  Widget _setup() => Padding(padding: const EdgeInsets.all(40), child: Column(children: [
    TextField(onChanged: (v) => sName = v, decoration: const InputDecoration(labelText: "Shop Name")),
    ElevatedButton(onPressed: () async {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('shop_name', sName); _load();
    }, child: const Text("Create Shop"))
  ]));

  Widget _main() => ListView(padding: const EdgeInsets.all(20), children: [
    Text("Welcome, $sName", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
    const Divider(),
    const Text("Stock Inventory:"),
    ...products.map((p) => Card(child: ListTile(title: Text(p['name']), subtitle: Text("₹${p['price']}")))).toList()
  ]);
}

// --- 3. PROFESSIONAL DASHBOARD ---
class ProDashboard extends StatefulWidget {
  final VoidCallback onTheme;
  final ThemeMode mode;
  const ProDashboard({super.key, required this.onTheme, required this.mode});
  @override
  State<ProDashboard> createState() => _ProDashboardState();
}

class _ProDashboardState extends State<ProDashboard> {
  String name = "", lead = "";
  bool hasLead = false;
  @override
  void initState() { super.initState(); _load(); }
  _load() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      name = prefs.getString('pro_name') ?? "";
      hasLead = prefs.getBool('hired_msg') ?? false;
      lead = prefs.getString('hired_details') ?? "";
    });
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: DashboardHeader(title: "Partner Hub", onTheme: widget.onTheme, mode: widget.mode, onProfile: (){}),
      body: name.isEmpty ? _setup() : _main(),
    );
  }

  Widget _setup() => Center(child: ElevatedButton(onPressed: () async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('pro_name', "Verified Partner"); _load();
  }, child: const Text("Setup Pro Account")));

  Widget _main() => Column(children: [
    const SizedBox(height: 20),
    if (hasLead) Card(color: Colors.orange.shade100, margin: const EdgeInsets.all(20), child: Padding(padding: const EdgeInsets.all(20), child: Column(children: [
      const Text("NEW SERVICE REQUEST", style: TextStyle(fontWeight: FontWeight.bold)),
      Text(lead),
      ElevatedButton(onPressed: () => launchUrl(Uri.parse("tel:999")), child: const Text("Accept & Call"))
    ]))) else const Center(child: Text("No Requests")),
  ]);
}

// --- AI CHAT SYSTEM ---
void _openAI(BuildContext context) {
  final ctrl = TextEditingController();
  List<Map<String, String>> chat = [{'r': 'ai', 'm': 'Hello! How can I help you today?'}];
  showModalBottomSheet(context: context, isScrollControlled: true, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
    builder: (c) => StatefulBuilder(builder: (c, setS) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(c).viewInsets.bottom),
      child: Container(height: 400, padding: const EdgeInsets.all(20), child: Column(children: [
        const Text("Trinity AI Assistant", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
        Expanded(child: ListView.builder(itemCount: chat.length, itemBuilder: (c, i) => Align(
          alignment: chat[i]['r'] == 'u' ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(padding: const EdgeInsets.all(10), margin: const EdgeInsets.symmetric(vertical: 5), decoration: BoxDecoration(color: chat[i]['r'] == 'u' ? Colors.blue.shade100 : Colors.grey.shade200, borderRadius: BorderRadius.circular(15)), child: Text(chat[i]['m']!)),
        ))),
        TextField(controller: ctrl, decoration: InputDecoration(hintText: "Ask...", suffixIcon: IconButton(icon: const Icon(Icons.send), onPressed: () {
          setS(() {
            chat.add({'r': 'u', 'm': ctrl.text});
            String bot = "I am checking that for you...";
            if (ctrl.text.toLowerCase().contains("hire")) bot = "Search in Experts tab and click HIRE.";
            chat.add({'r': 'ai', 'm': bot});
            ctrl.clear();
          });
        })))
      ])),
    )),
  );
}
