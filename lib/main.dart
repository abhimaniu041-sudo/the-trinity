import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'dart:io';
import 'dart:convert';
import 'dart:math';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const TrinityApp());
}

// --- PREMIMUM THEME ENGINE ---
class TrinityApp extends StatelessWidget {
  const TrinityApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1A237E)),
        inputDecorationTheme: InputDecorationTheme(border: OutlineInputBorder(borderRadius: BorderRadius.circular(15))),
        cardTheme: CardTheme(elevation: 5, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), color: Colors.white),
        appBarTheme: const AppBarTheme(centerTitle: true, elevation: 5, backgroundColor: Colors.indigo, foregroundColor: Colors.white),
      ),
      home: const SplashScreen(),
    );
  }
}

// --- GLOBAL UTILS ---
Future<void> handleLogout(BuildContext context) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.remove('userRole'); 
  // Inventory, Leads and Profile data remains safe in local storage.
  if (context.mounted) {
    Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const RoleSelectionPage()), (route) => false);
  }
}

// Secured calling between Customer & Pro simulation
Future<void> launchCaller(String number) async {
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
  void initState() { super.initState(); _checkStatus(); }
  _checkStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? role = prefs.getString('userRole');
    await Future.delayed(const Duration(seconds: 3));
    if (mounted) {
      if (role != null) {
        if (role == 'Shopkeeper') Navigator.pushReplacement(context, MaterialPageRoute(builder: (c) => const ShopDashboard()));
        if (role == 'Customer') Navigator.pushReplacement(context, MaterialPageRoute(builder: (c) => const CustomerDashboard()));
        if (role == 'Professional') Navigator.pushReplacement(context, MaterialPageRoute(builder: (c) => const ProfessionalDashboard()));
      } else {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (c) => const RoleSelectionPage()));
      }
    }
  }
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text("THE TRINITY", style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.indigo)),
          SizedBox(height: 10),
          Text("Hyperlocal Superhub", style: TextStyle(color: Colors.grey)),
        ]),
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
        decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF1A237E), Color(0xFF3949AB)], begin: Alignment.topCenter)),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Text("Welcome to Trinity", style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
          const SizedBox(height: 50),
          _roleBtn(context, "Shopkeeper", Icons.storefront, Colors.indigo),
          _roleBtn(context, "Customer", Icons.shopping_bag_rounded, Colors.green),
          _roleBtn(context, "Professional", Icons.engineering_rounded, Colors.orange),
        ]),
      ),
    );
  }
  Widget _roleBtn(context, title, icon, color) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 10),
    child: Card(
      child: ListTile(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => LoginPage(role: title))),
        leading: CircleAvatar(backgroundColor: Colors.indigo.withOpacity(0.1), child: Icon(icon, color: Colors.indigo)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        trailing: const Icon(Icons.arrow_forward_ios),
      ),
    ),
  );
}

// --- LOGIN PAGE ---
class LoginPage extends StatelessWidget {
  final String role;
  LoginPage({super.key, required this.role});
  final _nC = TextEditingController();
  final _oC = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("$role Login")),
      body: Padding(padding: const EdgeInsets.all(25), child: Column(children: [
        const Text("Enter Email/Mobile and OTP", style: TextStyle(fontSize: 16)),
        const SizedBox(height: 30),
        TextField(controller: _nC, decoration: const InputDecoration(labelText: "Mobile or Email")),
        const SizedBox(height: 15),
        TextField(controller: _oC, decoration: const InputDecoration(labelText: "OTP (Demo: 123456)")),
        const SizedBox(height: 30),
        SizedBox(width: double.infinity, height: 50, child: ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white),
          onPressed: () async {
            if (_oC.text == "123456") {
              SharedPreferences prefs = await SharedPreferences.getInstance();
              await prefs.setString('userRole', role);
              await prefs.setString('user_id', _nC.text);
              if (context.mounted) {
                if (role == 'Shopkeeper') Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (c) => const ShopDashboard()), (r) => false);
                if (role == 'Customer') Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (c) => const CustomerDashboard()), (r) => false);
                if (role == 'Professional') Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (c) => const ProfessionalDashboard()), (r) => false);
              }
            }
          }, child: const Text("AUTHENTICATE"))),
      ])),
    );
  }
}

// --- SHOPKEEPER DASHBOARD (DISCOUNT + MULTI-IMAGE + STOCK + LEADS) ---
class ShopDashboard extends StatefulWidget {
  const ShopDashboard({super.key});
  @override
  State<ShopDashboard> createState() => _ShopDashboardState();
}

class _ShopDashboardState extends State<ShopDashboard> {
  final _dukaanC = TextEditingController(), _sLocC = TextEditingController(), _pNC = TextEditingController(), _pPC = TextEditingController(), _pDC = TextEditingController(), _pQC = TextEditingController();
  final picker = ImagePicker();
  File? _dukaanPhoto;
  List<String> _productImages = [];
  List products = [], leads = [];
  bool hasProfile = false;

  @override
  void initState() { super.initState(); _load(); }
  _load() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _dukaanC.text = prefs.getString('shop_name') ?? "";
      if (prefs.getString('shop_photo') != null) _dukaanPhoto = File(prefs.getString('shop_photo')!);
      if (_dukaanC.text.isNotEmpty) hasProfile = true;
      String? data = prefs.getString('shop_products');
      if (data != null) products = json.decode(data);
      String? lData = prefs.getString('shop_leads');
      if (lData != null) leads = json.decode(lData);
    });
  }

  _pickDukaanPhoto() async {
    final p = await picker.pickImage(source: ImageSource.gallery);
    if (p != null) setState(() => _dukaanPhoto = File(p.path));
  }
  _pickProductsImages() async {
    final p = await picker.pickMultiImage();
    if (p.isNotEmpty) setState(() => _productImages = p.map((f)=>f.path).toList());
  }

  _saveProfile() async {
    if (_dukaanPhoto == null) return;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('shop_name', _dukaanC.text);
    await prefs.setString('shop_loc', _sLocC.text);
    await prefs.setString('shop_photo', _dukaanPhoto!.path);
    _load();
  }

  _saveProduct() async {
    int disc = int.tryParse(_pDC.text) ?? 0;
    products.add({'name': _pNC.text, 'price': _pPC.text, 'disc': disc, 'stock': _pQC.text, 'imgs': _productImages});
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('shop_products', json.encode(products));
    setState(() { _pNC.clear(); _pPC.clear(); _pDC.clear(); _pQC.clear(); _productImages = []; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Trinity Store"), actions: [IconButton(icon: const Icon(Icons.logout), onPressed: () => handleLogout(context))]),
      floatingActionButton: FloatingActionButton(onPressed: () => _openAI(context), child: const Icon(Icons.auto_awesome)),
      body: SingleChildScrollView(padding: const EdgeInsets.all(15), child: !hasProfile ? _profileSetup() : _mainView()),
    );
  }

  Widget _profileSetup() => Column(children: [
    const Text("Register Your Shop", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
    GestureDetector(onTap: _pickDukaanPhoto, child: CircleAvatar(radius: 60, backgroundImage: _dukaanPhoto != null ? FileImage(_dukaanPhoto!) : null, child: _dukaanPhoto == null ? const Icon(Icons.add_a_photo) : null)),
    TextField(controller: _dukaanC, decoration: const InputDecoration(hintText: "Dukaan Name")),
    TextField(controller: _sLocC, decoration: const InputDecoration(hintText: "Full Location")),
    ElevatedButton(onPressed: _saveProfile, child: const Text("Create Profile"))
  ]);

  Widget _mainView() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Container(padding: const EdgeInsets.all(15), decoration: BoxDecoration(color: Colors.indigo[50], borderRadius: BorderRadius.circular(15)), child: Row(children: [
      CircleAvatar(backgroundImage: _dukaanPhoto != null ? FileImage(_dukaanPhoto!) : null),
      const SizedBox(width: 10), Text(_dukaanC.text, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18))
    ])),
    const SizedBox(height: 20),
    const Text("Add New Inventory", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
    const SizedBox(height: 10),
    GestureDetector(onTap: _pickProductsImages, child: Container(height: 80, width: double.infinity, color: Colors.grey[200], child: _productImages.isEmpty ? const Icon(Icons.add_photo_alternate) : ListView(scrollDirection: Axis.horizontal, children: _productImages.map((f)=>Image.file(File(f))).toList()))),
    TextField(controller: _pNC, decoration: const InputDecoration(hintText: "Item Name")),
    Row(children: [
      Expanded(child: TextField(controller: _pPC, decoration: const InputDecoration(hintText: "Price"))),
      Expanded(child: TextField(controller: _pDC, decoration: const InputDecoration(hintText: "Discount %"))),
      Expanded(child: TextField(controller: _pQC, decoration: const InputDecoration(hintText: "Stock Qty"))),
    ]),
    ElevatedButton(onPressed: _saveProduct, child: const Text("Save Product")),
    const Divider(),
    const Text("Active Inventory:", style: TextStyle(fontWeight: FontWeight.bold)),
    ...products.asMap().entries.map((e) => Card(child: ListTile(leading: Image.file(File(e.value['imgs'][0]), width: 40, fit: BoxFit.cover), title: Text("${e.value['name']} (Qty: ${e.value['stock']})"), trailing: Text("₹${e.value['price']}")))).toList(),
    const Divider(),
    const Text("New Orders/Leads:", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
    ...leads.map((l) => Card(color: Colors.green[50], child: ListTile(title: Text("Item: ${l['item']}"), subtitle: Text("Customer: ${l['cust']}\nAddr: ${l['addr']}")))).toList()
  ]);
}

// --- PROFESSIONAL DASHBOARD (ID CARD, AVAILABILITY, LEADS) ---
class ProfessionalDashboard extends StatefulWidget {
  const ProfessionalDashboard({super.key});
  @override
  State<ProfessionalDashboard> createState() => _ProfessionalDashboardState();
}

class _ProfessionalDashboardState extends State<ProfessionalDashboard> {
  final _nameC = TextEditingController(), _jtC = TextEditingController();
  File? _photo; String name = "", job = "", id = "";
  bool hasProfile = false, online = false, leadAccept = false;

  @override
  void initState() { super.initState(); _load(); }
  _load() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      name = prefs.getString('pro_name') ?? ""; job = prefs.getString('pro_job') ?? "";
      id = prefs.getString('user_id') ?? ""; online = prefs.getBool('pro_status') ?? false;
      if (prefs.getString('pro_photo') != null) _photo = File(prefs.getString('pro_photo')!);
      if (name.isNotEmpty) hasProfile = true;
    });
  }

  _saveProfile() async {
    if (_nameC.text.isEmpty || _jtC.text.isEmpty) return;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('pro_name', _nameC.text);
    await prefs.setString('pro_job', _jtC.text);
    if (_photo != null) await prefs.setString('pro_photo', _photo!.path);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Partner Panel"), actions: [IconButton(icon: const Icon(Icons.logout), onPressed: () => handleLogout(context))]),
      floatingActionButton: FloatingActionButton(onPressed: () => _openAI(context), child: const Icon(Icons.auto_awesome)),
      body: SingleChildScrollView(padding: const EdgeInsets.all(15), child: !hasProfile ? _profileSetup() : _mainProView()),
    );
  }

  Widget _profileSetup() => Column(children: [
    const Text("Expert Profile Setup", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
    GestureDetector(onTap: () async {
      final p = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (p != null) setState(() => _photo = File(p.path));
    }, child: CircleAvatar(radius: 60, backgroundImage: _photo != null ? FileImage(_photo!) : null, child: _photo == null ? const Icon(Icons.add_a_photo) : null)),
    TextField(controller: _nameC, decoration: const InputDecoration(hintText: "Full Name")),
    TextField(controller: _jtC, decoration: const InputDecoration(hintText: "Job Title (Plumber, Electrician)")),
    ElevatedButton(onPressed: _saveProfile, child: const Text("Go Live"))
  ]);

  Widget _mainProView() => Column(children: [
    Card(color: Colors.indigo, child: Padding(padding: const EdgeInsets.all(20), child: Column(children: [
      CircleAvatar(radius: 40, backgroundImage: _photo != null ? FileImage(_photo!) : null),
      Text(name, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
      Text(job.toUpperCase(), style: const TextStyle(color: Colors.white70)),
      const Divider(color: Colors.white24),
      Text("ID: $id", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
    ]))),
    SwitchListTile(title: Text(online ? "YOU ARE ONLINE (Lead Mode)" : "YOU ARE OFFLINE", style: TextStyle(color: online ? Colors.green : Colors.red, fontWeight: FontWeight.bold)), value: online, onChanged: (v) async {
       SharedPreferences prefs = await SharedPreferences.getInstance();
       await prefs.setBool('pro_status', v); setState(() => online = v);
    }),
    Card(color: Colors.green[50], child: ListTile(title: const Text("New Service Request"), subtitle: const Text("Sector 22 Chandigarh | Tap Fitting"), trailing: leadAccept 
      ? IconButton(icon: const Icon(Icons.call, color: Colors.green), onPressed: () => launchCaller("8888888888"))
      : TextButton(onPressed: () => setState(() => leadAccept = true), child: const Text("ACCEPT"))))
  ]);
}

// --- CUSTOMER DASHBOARD (PROFILE, AMAZON STYLE SEARCH, HIRING) ---
class CustomerDashboard extends StatefulWidget {
  const CustomerDashboard({super.key});
  @override
  State<CustomerDashboard> createState() => _CustomerDashboardState();
}

class _CustomerDashboardState extends State<CustomerDashboard> with SingleTickerProviderStateMixin {
  late TabController _tab;
  String query = "", cName = "", cAddr = "";
  List products = []; Map? pro;
  bool isHired = false, hasProfile = false;

  @override
  void initState() { super.initState(); _tab = TabController(length: 2, vsync: this); _load(); }
  _load() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      cName = prefs.getString('cust_name') ?? "";
      cAddr = prefs.getString('cust_addr') ?? "";
      if (cName.isNotEmpty) hasProfile = true;
      String? data = prefs.getString('shop_products');
      if (data != null) products = json.decode(data);
      if (prefs.getBool('pro_status') ?? false) {
        pro = {'name': prefs.getString('pro_name'), 'job': prefs.getString('pro_job'), 'img': prefs.getString('pro_photo'), 'phone': prefs.getString('user_id')};
      } else { pro = null; }
    });
  }

  @override
  Widget build(BuildContext context) {
    final filteredProducts = products.where((p) => p['name'].toString().toLowerCase().contains(query.toLowerCase())).toList();
    final proMatch = pro != null && (pro!['job'].toString().toLowerCase().contains(query.toLowerCase()) || pro!['name'].toString().toLowerCase().contains(query.toLowerCase()));

    return Scaffold(
      appBar: AppBar(title: const Text("Trinity Marketplace"), bottom: PreferredSize(preferredSize: const Size.fromHeight(110), child: Column(children: [
        Padding(padding: const EdgeInsets.symmetric(horizontal: 15), child: TextField(onChanged: (v) => setState(() => query = v.toLowerCase()), decoration: InputDecoration(hintText: "Search Plumber, Tap, or Name...", filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(30))))),
        TabBar(controller: _tab, labelColor: Colors.orangeAccent, tabs: const [Tab(text: "Inventory"), Tab(text: "Hire Pros")]),
      ]))),
      floatingActionButton: FloatingActionButton(onPressed: () => _openAI(context), child: const Icon(Icons.auto_awesome)),
      body: !hasProfile ? _profileSetupUI() : TabBarView(controller: _tab, children: [
        _buildProductList(filteredProducts),
        _buildProHireList(proMatch),
      ]),
    );
  }

  Widget _profileSetupUI() => Padding(padding: const EdgeInsets.all(40), child: Column(children: [
    const Text("Setup Your Profile", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
    const CircleAvatar(radius: 50, child: Icon(Icons.person, size: 40)),
    TextField(onChanged: (v) => cName = v, decoration: const InputDecoration(hintText: "Full Name")),
    TextField(onChanged: (v) => cAddr = v, decoration: const InputDecoration(hintText: "Complete Address")),
    ElevatedButton(onPressed: () async {
      if (cName.isEmpty) return;
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('cust_name', cName); await prefs.setString('cust_addr', cAddr); _load();
    }, child: const Text("Begin Shopping"))
  ]));

  Widget _buildProductList(List items) => ListView.separated(
    padding: const EdgeInsets.all(15),
    itemCount: items.length, separatorBuilder: (c,i) => const SizedBox(height: 10),
    itemBuilder: (context, index) {
      final p = items[index];
      int finalPrice = int.parse(p['price']) - (int.parse(p['price']) * int.parse(p['disc']) / 100).round();
      return GestureDetector(
        onTap: () => _viewDetails(p),
        child: Container(decoration: BoxDecoration(border: Border.all(color: Colors.grey[300]), borderRadius: BorderRadius.circular(15)), child: Row(children: [
          Image.file(File(p['imgs'][0]), width: 100, height: 100, fit: BoxFit.cover),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(p['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            Text("${p['disc']}% OFF", style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            Text("₹$finalPrice", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            Text("M.R.P: ₹${p['price']}", style: const TextStyle(decoration: TextDecoration.lineThrough, color: Colors.grey, fontSize: 12)),
          ]))
        ]))
      );
    }
  );

  Widget _buildProHireList(bool isMatch) => ListView(padding: const EdgeInsets.all(15), children: [
    if (pro != null && isMatch) Card(child: ListTile(
      leading: CircleAvatar(backgroundImage: FileImage(File(pro!['img']))),
      title: Text(pro!['name']), subtitle: Text(pro!['job'].toUpperCase()),
      trailing: ElevatedButton(onPressed: () async {
        if (isHired) { launchCaller("7777777777"); return; }
        // Simulate sending customer data to Shop (backend logic required)
        SharedPreferences prefs = await SharedPreferences.getInstance();
        String? leads = prefs.getString('shop_leads');
        List l = leads != null ? json.decode(leads) : [];
        l.add({'cust': cName, 'addr': cAddr, 'item': 'Plumber Lead'});
        await prefs.setString('shop_leads', json.encode(l));
        setState(() => isHired = true);
      }, child: Text(isHired ? "CALL" : "HIRE")),
    )),
    if (pro == null || !isMatch) const Center(child: Text("No Experts Online"))
  ]);

  void _viewDetails(Map p) {
    int dp = int.parse(p['price']) - (int.parse(p['price']) * int.parse(p['disc']) / 100).round();
    showModalBottomSheet(context: context, isScrollControlled: true, builder: (context) => SingleChildScrollView(child: Column(children: [
      SizedBox(height: 300, child: PhotoViewGallery.builder(itemCount: (p['imgs'] as List).length, builder: (context, index) => PhotoViewGalleryPageOptions(imageProvider: FileImage(File(p['imgs'][index]))))),
      Container(padding: const EdgeInsets.all(20), width: double.infinity, color: Colors.white, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(p['name'], style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        Text("${p['disc']}% OFF", style: const TextStyle(color: Colors.red, fontSize: 18, fontWeight: FontWeight.bold)),
        Text("₹$dp", style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
        const Text("In Stock", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
        const Divider(),
        SizedBox(width: double.infinity, height: 50, child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white), onPressed: () async {
          // Send customer data to Shop
          SharedPreferences prefs = await SharedPreferences.getInstance();
          String? leads = prefs.getString('shop_leads');
          List l = leads != null ? json.decode(leads) : [];
          l.add({'cust': cName, 'addr': cAddr, 'item': p['name']});
          await prefs.setString('shop_leads', json.encode(l));
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("BUY Details sent to Shopkeeper!")));
        }, child: const Text("PROCEED TO BUY")))
      ]))
    ])));
  }
}

// --- AI SUPPORT SYSTEM ---
void _openAI(BuildContext context) {
  final List<String> chat = ["AI: Hello! How can I help you manage marketplace today? Ask about hire, price or products."];
  final ctrl = TextEditingController();
  showModalBottomSheet(context: context, isScrollControlled: true, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(30))), builder: (c) => StatefulBuilder(builder: (c, setS) => Padding(
    padding: EdgeInsets.only(bottom: MediaQuery.of(c).viewInsets.bottom),
    child: Container(height: 400, padding: const EdgeInsets.all(20), child: Column(children: [
      const Text("Trinity Luxury AI", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
      Expanded(child: ListView.builder(itemCount: chat.length, itemBuilder: (c, i) => ListTile(title: Text(chat[i])))),
      TextField(controller: ctrl, decoration: InputDecoration(hintText: "Ask about hire, price...", suffixIcon: IconButton(icon: const Icon(Icons.send), onPressed: () {
        setS(() {
          chat.add("You: ${ctrl.text}");
          String bot = "Searching database for '${ctrl.text}'...";
          if (ctrl.text.toLowerCase().contains("hire")) bot = "Go to Experts tab and click HIRE to notify a pro.";
          chat.add("AI: $bot"); ctrl.clear();
        });
      })))
    ])),
  )));
}
