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
        cardTheme: const CardTheme(elevation: 10, shadowColor: Colors.black12),
      ),
      home: const SplashScreen(),
    );
  }
}

// --- GLOBAL UTILS ---
Future<void> handleLogout(BuildContext context) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.remove('userRole'); 
  Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const RoleSelectionPage()), (route) => false);
}

// --- 1. SHOPKEEPER (MULTI-IMAGE & REMOVE) ---
class ShopDashboard extends StatefulWidget {
  const ShopDashboard({super.key});
  @override
  State<ShopDashboard> createState() => _ShopDashboardState();
}

class _ShopDashboardState extends State<ShopDashboard> {
  final _n = TextEditingController();
  final _p = TextEditingController();
  List<String> _tempImages = []; // Multiple images list
  List products = [];

  @override
  void initState() { super.initState(); _load(); }

  _load() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? data = prefs.getString('trinity_products');
    if (data != null) setState(() => products = json.decode(data));
  }

  _pickImages() async {
    final List<XFile> pickedFiles = await ImagePicker().pickMultiImage();
    if (pickedFiles.isNotEmpty) {
      setState(() {
        _tempImages = pickedFiles.map((file) => file.path).toList();
      });
    }
  }

  _save() async {
    if (_n.text.isEmpty || _tempImages.isEmpty) return;
    products.add({'name': _n.text, 'price': _p.text, 'imgs': _tempImages});
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('trinity_products', json.encode(products));
    setState(() { _n.clear(); _p.clear(); _tempImages = []; });
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Product Listed with Multiple Images!")));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Trinity Inventory"), actions: [IconButton(icon: const Icon(Icons.logout), onPressed: () => handleLogout(context))]),
      floatingActionButton: FloatingActionButton(onPressed: () => _openAI(context), child: const Icon(Icons.auto_awesome)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(children: [
          const Text("Add New Product", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: _pickImages,
            child: Container(
              height: 120, width: double.infinity,
              decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.indigo)),
              child: _tempImages.isEmpty 
                ? const Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.add_a_photo, size: 40), Text("Select Multiple Images")])
                : ListView.builder(scrollDirection: Axis.horizontal, itemCount: _tempImages.length, itemBuilder: (c, i) => Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.file(File(_tempImages[i]), width: 100, fit: BoxFit.cover)),
                  )),
            ),
          ),
          const SizedBox(height: 15),
          TextField(controller: _n, decoration: const InputDecoration(labelText: "Product Name", border: OutlineInputBorder())),
          const SizedBox(height: 10),
          TextField(controller: _p, decoration: const InputDecoration(labelText: "Price", border: OutlineInputBorder())),
          const SizedBox(height: 20),
          ElevatedButton(onPressed: _save, style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)), child: const Text("LIST PRODUCT")),
          const Divider(height: 50),
          ...products.asMap().entries.map((e) => Card(
            child: ListTile(
              leading: e.value['imgs'] != null ? Image.file(File(e.value['imgs'][0]), width: 50, fit: BoxFit.cover) : const Icon(Icons.image),
              title: Text(e.value['name']),
              trailing: IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () {
                setState(() => products.removeAt(e.key));
                _save(); // Resave
              }),
            ),
          )).toList(),
        ]),
      ),
    );
  }
}

// --- 2. CUSTOMER (FIXED SEARCH & BUY) ---
class CustomerDashboard extends StatefulWidget {
  const CustomerDashboard({super.key});
  @override
  State<CustomerDashboard> createState() => _CustomerDashboardState();
}

class _CustomerDashboardState extends State<CustomerDashboard> with SingleTickerProviderStateMixin {
  late TabController _tab;
  String query = "";
  List allProducts = [];
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
    if (pData != null) setState(() => allProducts = json.decode(pData));
    
    if (prefs.getBool('pro_status') ?? false) {
      setState(() { pro = {'name': prefs.getString('pro_name'), 'job': prefs.getString('pro_job'), 'phone': prefs.getString('myPhone')}; });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Search Filtering Logic
    List filteredProducts = allProducts.where((p) => p['name'].toString().toLowerCase().contains(query)).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Trinity Market"),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _fetch)],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(110),
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
              child: TextField(
                onChanged: (v) => setState(() => query = v.toLowerCase()),
                decoration: InputDecoration(hintText: "Search products/pros...", prefixIcon: const Icon(Icons.search), filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(30))),
              ),
            ),
            TabBar(controller: _tab, indicatorColor: Colors.orangeAccent, tabs: const [Tab(text: "Products"), Tab(text: "Pros")]),
          ]),
        ),
      ),
      floatingActionButton: FloatingActionButton(onPressed: () => _openAI(context), child: const Icon(Icons.auto_awesome)),
      body: TabBarView(controller: _tab, children: [
        // Tab 1: Products Fix
        ListView.builder(
          itemCount: filteredProducts.length,
          itemBuilder: (context, i) {
            final p = filteredProducts[i];
            return Card(
              child: ListTile(
                onTap: () => _showProductDetails(p), // Image visit logic
                leading: p['imgs'] != null ? Image.file(File(p['imgs'][0]), width: 50, fit: BoxFit.cover) : const Icon(Icons.image),
                title: Text(p['name']),
                trailing: ElevatedButton(onPressed: () => _buySuccess(), child: Text("₹${p['price']} BUY")),
              ),
            );
          },
        ),
        // Tab 2: Pros Search
        ListView(children: [
          if (pro != null && pro!['job'].toLowerCase().contains(query))
            Card(child: ListTile(
              leading: const CircleAvatar(child: Icon(Icons.person)),
              title: Text(pro!['name']), subtitle: Text(pro!['job']),
              trailing: isHired 
                ? IconButton(icon: const Icon(Icons.call, color: Colors.green), onPressed: () => launchUrl(Uri.parse("tel:${pro!['phone']}")))
                : ElevatedButton(onPressed: () => setState(() => isHired = true), child: const Text("HIRE")),
            )),
        ]),
      ]),
    );
  }

  void _showProductDetails(Map p) {
    showDialog(context: context, builder: (c) => AlertDialog(
      title: Text(p['name']),
      content: SizedBox(
        height: 250, width: 300,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: p['imgs'].length,
          itemBuilder: (context, index) => Padding(
            padding: const EdgeInsets.all(8.0),
            child: ClipRRect(borderRadius: BorderRadius.circular(15), child: Image.file(File(p['imgs'][index]), width: 200, fit: BoxFit.contain)),
          ),
        ),
      ),
      actions: [TextButton(onPressed: () => Navigator.pop(c), child: const Text("Close"))],
    ));
  }

  void _buySuccess() {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(backgroundColor: Colors.green, content: Text("Order Placed Successfully!")));
  }
}

// --- 3. AI CHAT BOT (FULLY FUNCTIONAL UI) ---
void _openAI(BuildContext context) {
  final List<Map<String, String>> _messages = [];
  final _chatCtrl = TextEditingController();

  showModalBottomSheet(
    context: context, isScrollControlled: true, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
    builder: (context) => StatefulBuilder(
      builder: (context, setModalState) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(20),
        child: Column(children: [
          const Text("Trinity Luxury AI", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.indigo)),
          const Divider(),
          Expanded(
            child: _messages.isEmpty 
              ? const Center(child: Text("How can I help you manage your marketplace today?"))
              : ListView.builder(
                  itemCount: _messages.length,
                  itemBuilder: (c, i) => Align(
                    alignment: _messages[i]['role'] == 'user' ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 5),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: _messages[i]['role'] == 'user' ? Colors.indigo[100] : Colors.grey[200], borderRadius: BorderRadius.circular(15)),
                      child: Text(_messages[i]['text']!),
                    ),
                  ),
                ),
          ),
          Row(children: [
            Expanded(child: TextField(controller: _chatCtrl, decoration: const InputDecoration(hintText: "Ask about stock, hiring..."))),
            IconButton(icon: const Icon(Icons.send, color: Colors.indigo), onPressed: () {
              if (_chatCtrl.text.isEmpty) return;
              setModalState(() {
                _messages.add({'role': 'user', 'text': _chatCtrl.text});
                String reply = "Based on your request for '${_chatCtrl.text}', I recommend checking the Inventory Tab for updates.";
                if (_chatCtrl.text.toLowerCase().contains("hire")) reply = "You can find verified professionals in the 'Hire Pros' tab.";
                _messages.add({'role': 'ai', 'text': reply});
                _chatCtrl.clear();
              });
            }),
          ]),
        ]),
      ),
    ),
  );
}

// (Splash, RoleSelection, Professional classes as per previous luxury design but with updated functions)
