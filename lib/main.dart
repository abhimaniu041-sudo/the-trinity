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

  void toggleTheme() {
    setState(() {
      _themeMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.dark;
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
        appBarTheme: const AppBarTheme(centerTitle: true, elevation: 2),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo, brightness: Brightness.dark),
      ),
      home: SplashScreen(toggleTheme: toggleTheme),
    );
  }
}

// --- GLOBAL MODELS ---
class Product {
  final String id, name, price, disc, shopName;
  final List<String> imgs;
  Product({required this.id, required this.name, required this.price, required this.disc, required this.imgs, required this.shopName});

  Map<String, dynamic> toMap() => {'id': id, 'name': name, 'price': price, 'disc': disc, 'imgs': imgs, 'shopName': shopName};
  factory Product.fromMap(Map<String, dynamic> map) => Product(id: map['id'], name: map['name'], price: map['price'], disc: map['disc'], imgs: List<String>.from(map['imgs']), shopName: map['shopName']);
}

// --- SPLASH SCREEN ---
class SplashScreen extends StatefulWidget {
  final VoidCallback toggleTheme;
  const SplashScreen({super.key, required this.toggleTheme});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() { super.initState(); _checkAuth(); }
  _checkStatus() async {} // Compatibility stub

  _checkAuth() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? role = prefs.getString('userRole');
    await Future.delayed(const Duration(seconds: 3));
    if (!mounted) return;
    if (role != null) {
      Widget next;
      if (role == 'Shopkeeper') next = ShopDashboard(toggleTheme: widget.toggleTheme);
      else if (role == 'Professional') next = ProDashboard(toggleTheme: widget.toggleTheme);
      else next = CustomerDashboard(toggleTheme: widget.toggleTheme);
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (c) => next));
    } else {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (c) => RoleSelectionPage(toggleTheme: widget.toggleTheme)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("THE TRINITY", style: TextStyle(fontSize: 42, fontWeight: FontWeight.w900, color: Color(0xFF1A237E), letterSpacing: 4)),
            const SizedBox(height: 10),
            Text("Powered by ABHIMANIU".toUpperCase(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}

// --- SHARED ROLE SELECTION ---
class RoleSelectionPage extends StatelessWidget {
  final VoidCallback toggleTheme;
  const RoleSelectionPage({super.key, required this.toggleTheme});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF1A237E), Color(0xFF3949AB)], begin: Alignment.topCenter)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("Welcome to Trinity", style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
            const SizedBox(height: 50),
            _roleCard(context, "Shopkeeper", Icons.storefront, Colors.indigo),
            _roleCard(context, "Customer", Icons.person_search, Colors.green),
            _roleCard(context, "Professional", Icons.engineering, Colors.orange),
          ],
        ),
      ),
    );
  }

  Widget _roleCard(context, String role, IconData icon, Color col) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 10),
    child: Card(
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFF1A237E)),
        title: Text(role, style: const TextStyle(fontWeight: FontWeight.bold)),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => LoginPage(role: role, toggleTheme: toggleTheme))),
      ),
    ),
  );
}

// --- LOGIN PAGE ---
class LoginPage extends StatelessWidget {
  final String role;
  final VoidCallback toggleTheme;
  LoginPage({super.key, required this.role, required this.toggleTheme});
  final _otp = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("$role Login")),
      body: Padding(padding: const EdgeInsets.all(30), child: Column(children: [
        TextField(controller: _otp, decoration: const InputDecoration(labelText: "OTP (123456)", border: OutlineInputBorder())),
        const SizedBox(height: 30),
        ElevatedButton(
          style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 55)),
          onPressed: () async {
            if (_otp.text == "123456") {
              SharedPreferences prefs = await SharedPreferences.getInstance();
              await prefs.setString('userRole', role);
              Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (c) => SplashScreen(toggleTheme: toggleTheme)), (r) => false);
            }
          }, child: const Text("AUTHENTICATE")
        )
      ])),
    );
  }
}

// --- 1. SHOPKEEPER DASHBOARD (PROFILE + DISCOUNT + NOTIFICATION) ---
class ShopDashboard extends StatefulWidget {
  final VoidCallback toggleTheme;
  const ShopDashboard({super.key, required this.toggleTheme});
  @override
  State<ShopDashboard> createState() => _ShopDashboardState();
}

class _ShopDashboardState extends State<ShopDashboard> {
  List<Product> products = [];
  bool hasProfile = false;
  String shopName = "", shopAddr = "";
  File? shopImg;
  
  final _nameC = TextEditingController(), _priceC = TextEditingController(), _discC = TextEditingController();

  @override
  void initState() { super.initState(); _loadData(); }

  _loadData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      shopName = prefs.getString('shop_name') ?? "";
      hasProfile = shopName.isNotEmpty;
      String? pData = prefs.getString('shop_products');
      if (pData != null) {
        products = (json.decode(pData) as List).map((x) => Product.fromMap(x)).toList();
      }
    });
  }

  void _setupProfile() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('shop_name', shopName);
    setState(() => hasProfile = true);
  }

  void _addProduct() async {
    final picker = ImagePicker();
    final List<XFile> picked = await picker.pickMultiImage();
    if (picked.isEmpty) return;

    final newP = Product(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameC.text, price: _priceC.text, disc: _discC.text,
      imgs: picked.map((e) => e.path).toList(), shopName: shopName
    );

    products.add(newP);
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('shop_products', json.encode(products.map((e) => e.toMap()).toList()));
    setState(() { _nameC.clear(); _priceC.clear(); _discC.clear(); });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Trinity Shop"),
        actions: [
          IconButton(icon: const Icon(Icons.settings), onPressed: () => _showSettings(context)),
        ],
      ),
      floatingActionButton: FloatingActionButton(onPressed: () => _openAI(context), child: const Icon(Icons.auto_awesome)),
      body: !hasProfile ? _profileSetupUI() : _inventoryUI(),
    );
  }

  Widget _profileSetupUI() => Padding(
    padding: const EdgeInsets.all(30),
    child: Column(children: [
      const Text("Setup Your Store", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
      TextField(onChanged: (v) => shopName = v, decoration: const InputDecoration(labelText: "Shop Name")),
      const SizedBox(height: 20),
      ElevatedButton(onPressed: _setupProfile, child: const Text("Open Shop"))
    ]),
  );

  Widget _inventoryUI() => SingleChildScrollView(
    padding: const EdgeInsets.all(20),
    child: Column(children: [
      TextField(controller: _nameC, decoration: const InputDecoration(labelText: "Product Name")),
      Row(children: [
        Expanded(child: TextField(controller: _priceC, decoration: const InputDecoration(labelText: "Price"))),
        const SizedBox(width: 10),
        Expanded(child: TextField(controller: _discC, decoration: const InputDecoration(labelText: "Discount %"))),
      ]),
      const SizedBox(height: 10),
      ElevatedButton.icon(onPressed: _addProduct, icon: const Icon(Icons.add_a_photo), label: const Text("Select Images & Save")),
      const Divider(height: 40),
      const Text("Listed Inventory", style: TextStyle(fontWeight: FontWeight.bold)),
      ...products.map((p) => Card(child: ListTile(
        leading: Image.file(File(p.imgs[0]), width: 50, fit: BoxFit.cover),
        title: Text(p.name),
        subtitle: Text("₹${p.price} (${p.disc}% Off)"),
        trailing: IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () {
          setState(() => products.remove(p));
          _setupProfile(); // Re-save logic
        }),
      ))).toList()
    ]),
  );

  void _showSettings(BuildContext context) {
    showModalBottomSheet(context: context, builder: (c) => Column(mainAxisSize: MainAxisSize.min, children: [
      ListTile(leading: const Icon(Icons.brightness_6), title: const Text("Toggle Dark/Light"), onTap: widget.toggleTheme),
      ListTile(leading: const Icon(Icons.logout, color: Colors.red), title: const Text("Logout"), onTap: () async {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.remove('userRole');
        Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (c) => const RoleSelectionPage(toggleTheme: null as dynamic)), (r) => false);
      }),
    ]));
  }
}

// --- 2. CUSTOMER DASHBOARD (SEARCH + ZOOM + PRIVACY) ---
class CustomerDashboard extends StatefulWidget {
  final VoidCallback toggleTheme;
  const CustomerDashboard({super.key, required this.toggleTheme});
  @override
  State<CustomerDashboard> createState() => _CustomerDashboardState();
}

class _CustomerDashboardState extends State<CustomerDashboard> with SingleTickerProviderStateMixin {
  late TabController _tab;
  String query = "";
  List<Product> products = [];
  Map? pro;
  bool isHired = false, hasProfile = false;
  String custName = "", custAddr = "";

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _load();
  }

  _load() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      custName = prefs.getString('cust_name') ?? "";
      hasProfile = custName.isNotEmpty;
      String? pData = prefs.getString('shop_products');
      if (pData != null) {
        products = (json.decode(pData) as List).map((x) => Product.fromMap(x)).toList();
      }
      if (prefs.getBool('pro_status') ?? false) {
        pro = {'name': prefs.getString('pro_name'), 'job': prefs.getString('pro_job'), 'img': prefs.getString('pro_photo')};
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final filtered = products.where((p) => p.name.toLowerCase().contains(query.toLowerCase())).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Trinity Market"),
        actions: [IconButton(icon: const Icon(Icons.person), onPressed: _editProfile)],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(100),
          child: Column(children: [
            Padding(padding: const EdgeInsets.symmetric(horizontal: 15), child: TextField(
              onChanged: (v) => setState(() => query = v),
              decoration: InputDecoration(hintText: "Search Plumber, Taps...", prefixIcon: const Icon(Icons.search), border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none), filled: true, fillColor: Colors.white24),
            )),
            TabBar(controller: _tab, tabs: const [Tab(text: "Products"), Tab(text: "Experts")]),
          ]),
        ),
      ),
      floatingActionButton: FloatingActionButton(onPressed: () => _openAI(context), child: const Icon(Icons.auto_awesome)),
      body: !hasProfile ? _custSetupUI() : TabBarView(controller: _tab, children: [
        _buildProductList(filtered),
        _buildProList(),
      ]),
    );
  }

  Widget _custSetupUI() => Padding(padding: const EdgeInsets.all(40), child: Column(children: [
    TextField(onChanged: (v) => custName = v, decoration: const InputDecoration(labelText: "Full Name")),
    TextField(onChanged: (v) => custAddr = v, decoration: const InputDecoration(labelText: "Full Address")),
    ElevatedButton(onPressed: () async {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('cust_name', custName); await prefs.setString('cust_addr', custAddr);
      _load();
    }, child: const Text("Complete Setup"))
  ]));

  Widget _buildProductList(List<Product> list) => ListView.builder(
    itemCount: list.length,
    itemBuilder: (c, i) => Card(child: ListTile(
      onTap: () => _showZoom(list[i].imgs),
      leading: Image.file(File(list[i].imgs[0]), width: 50, fit: BoxFit.cover),
      title: Text(list[i].name),
      subtitle: Text("${list[i].disc}% Off | Shop: ${list[i].shopName}"),
      trailing: ElevatedButton(onPressed: () => _confirmOrder(list[i]), child: const Text("BUY")),
    )),
  );

  Widget _buildProList() => ListView(children: [
    if (pro != null && pro!['job'].toLowerCase().contains(query.toLowerCase()))
      Card(child: ListTile(
        leading: CircleAvatar(backgroundImage: FileImage(File(pro!['img']))),
        title: Text(pro!['name']),
        subtitle: Text(pro!['job']),
        trailing: ElevatedButton(onPressed: _confirmHire, child: Text(isHired ? "CALL" : "HIRE")),
      ))
  ]);

  void _editProfile() {
    showDialog(context: context, builder: (c) => AlertDialog(
      title: const Text("Edit Details"),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(decoration: const InputDecoration(labelText: "Update Name")),
        TextField(decoration: const InputDecoration(labelText: "Update Address")),
      ]),
      actions: [TextButton(onPressed: () => Navigator.pop(c), child: const Text("Save"))],
    ));
  }

  void _confirmOrder(Product p) {
    showDialog(context: context, builder: (c) => AlertDialog(
      title: const Text("Confirm Order"),
      content: Text("Confirming will share your Name & Address with ${p.shopName}."),
      actions: [ElevatedButton(onPressed: () => Navigator.pop(c), child: const Text("Confirm & Send"))],
    ));
  }

  void _confirmHire() async {
    if (isHired) { launchUrl(Uri.parse("tel:123456789")); return; }
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hired_msg', true);
    await prefs.setString('hired_cust_details', "Name: $custName\nAddress: $custAddr");
    setState(() => isHired = true);
  }

  void _showZoom(List<String> imgs) {
    showDialog(context: context, builder: (c) => Dialog.fullscreen(
      child: Stack(children: [
        PhotoView(imageProvider: FileImage(File(imgs[0]))),
        Positioned(top: 40, right: 20, child: IconButton(icon: const Icon(Icons.close, color: Colors.white, size: 30), onPressed: () => Navigator.pop(c))),
      ]),
    ));
  }
}

// --- 3. PROFESSIONAL DASHBOARD (NOTIFICATION Logic) ---
class ProDashboard extends StatefulWidget {
  final VoidCallback toggleTheme;
  const ProDashboard({super.key, required this.toggleTheme});
  @override
  State<ProDashboard> createState() => _ProDashboardState();
}

class _ProDashboardState extends State<ProDashboard> {
  bool hasReq = false, isOnline = false;
  String details = "", name = "";
  File? photo;

  @override
  void initState() { super.initState(); _load(); }
  _load() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      name = prefs.getString('pro_name') ?? "";
      hasReq = prefs.getBool('hired_msg') ?? false;
      details = prefs.getString('hired_cust_details') ?? "";
      isOnline = prefs.getBool('pro_status') ?? false;
      String? path = prefs.getString('pro_photo');
      if (path != null) photo = File(path);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Pro Portal"), actions: [IconButton(icon: const Icon(Icons.settings), onPressed: () {})]),
      floatingActionButton: FloatingActionButton(onPressed: () => _openAI(context), child: const Icon(Icons.auto_awesome)),
      body: name.isEmpty ? _setup() : Column(children: [
        const SizedBox(height: 20),
        CircleAvatar(radius: 50, backgroundImage: photo != null ? FileImage(photo!) : null),
        Text(name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        SwitchListTile(title: const Text("Online Status"), value: isOnline, onChanged: (v) async {
           SharedPreferences prefs = await SharedPreferences.getInstance();
           await prefs.setBool('pro_status', v); setState(() => isOnline = v);
        }),
        const Divider(),
        if (hasReq) Card(
          color: Colors.orangeAccent.withOpacity(0.3),
          margin: const EdgeInsets.all(20),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(children: [
              const Text("NEW WORK REQUEST", style: TextStyle(fontWeight: FontWeight.bold)),
              Text(details),
              ElevatedButton(onPressed: () => launchUrl(Uri.parse("tel:123")), child: const Text("Accept & Call"))
            ]),
          ),
        ) else const Center(child: Text("No new leads today")),
      ]),
    );
  }

  Widget _setup() => Padding(padding: const EdgeInsets.all(40), child: Column(children: [
    ElevatedButton(onPressed: () async {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('pro_name', "PRO PARTNER");
      await prefs.setString('pro_job', "Plumber");
      _load();
    }, child: const Text("Quick Setup Profile"))
  ]));
}

// --- AI CHATBOT SYSTEM ---
void _openAI(BuildContext context) {
  final msg = TextEditingController();
  List<Map<String, String>> chat = [{'r': 'ai', 'm': 'Hello! I am Trinity Assistant. How can I help?'}];

  showModalBottomSheet(
    context: context, isScrollControlled: true,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
    builder: (c) => StatefulBuilder(builder: (c, setS) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(c).viewInsets.bottom),
      child: Container(
        height: 450, padding: const EdgeInsets.all(20),
        child: Column(children: [
          const Text("Trinity AI", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          Expanded(child: ListView.builder(
            itemCount: chat.length,
            itemBuilder: (c, i) => Align(
              alignment: chat[i]['r'] == 'u' ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 5),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: chat[i]['r'] == 'u' ? Colors.blue[100] : Colors.grey[200], borderRadius: BorderRadius.circular(15)),
                child: Text(chat[i]['m']!),
              ),
            ),
          )),
          TextField(controller: msg, decoration: InputDecoration(hintText: "Ask about Price, Hire or Shop...", suffixIcon: IconButton(icon: const Icon(Icons.send), onPressed: () {
            setS(() {
              String u = msg.text.toLowerCase();
              chat.add({'r': 'u', 'm': msg.text});
              String bot = "I am not sure about that. Please check our guide.";
              if (u.contains("hire")) bot = "Go to Experts tab, search for a skill and click HIRE.";
              if (u.contains("plumber")) bot = "We have verified plumbers! Use the search bar to find one.";
              if (u.contains("price")) bot = "Shopkeepers set the price. You can see discounts in the inventory.";
              chat.add({'r': 'ai', 'm': bot});
              msg.clear();
            });
          })))
        ]),
      ),
    )),
  );
}
