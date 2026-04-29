import 'package:flutter/material.dart';

void main() {
  runApp(const TrinityApp());
}

class TrinityApp extends StatelessWidget {
  const TrinityApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        scaffoldBackgroundColor: Colors.white,
      ),
      home: const LoginPage(),
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(30.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('assets/icon.png', width: 120), // Aapka Assembly worker logo
              const SizedBox(height: 30),
              const Text(
                "THE TRINITY",
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.indigo),
              ),
              const Text(
                "Shopkeeper & Assembly Login",
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
              const SizedBox(height: 50),
              
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'Phone Number',
                  prefixIcon: const Icon(Icons.phone),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: const Icon(Icons.lock),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    // Yahan hum dashboard par navigate karenge
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => const ShopDashboard()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text("LOGIN", style: TextStyle(fontSize: 18)),
                ),
              ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: () {},
                child: const Text("Forgot Password?"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ShopDashboard extends StatelessWidget {
  const ShopDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Trinity Shop Dashboard")),
      body: Center(
        child: const Text("Dashboard will have product upload & order tracking"),
      ),
    );
  }
}
