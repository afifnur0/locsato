// lib/login_screen.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'home_screen.dart'; 
import 'register_screen.dart'; 
import 'config.dart'; // <--- 1. WAJIB IMPORT FILE CONFIG.DART

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  // --- HAPUS CONFIG MANUAL DISINI ---
  // Kita tidak lagi menulis IP manual di setiap file.
  // Semua mengambil dari config.dart

  Future<void> _login() async {
    setState(() {
      _isLoading = true; 
    });

    try {
      // 2. GUNAKAN BASE URL DARI CONFIG
      // Ini menjamin IP Address sama persis dengan halaman Checkout
      final url = Uri.parse('${AppConfig.baseUrl}/api/login');

      final response = await http.post(
        url,
        body: {
          'email': _emailController.text,
          'password': _passwordController.text,
        },
        headers: {'Accept': 'application/json'},
      );

      print("Connecting to: $url");
      print("Response Status: ${response.statusCode}");
      print("Response Body: ${response.body}");

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['status'] == 'success') {
        // --- LOGIN SUKSES ---
        final prefs = await SharedPreferences.getInstance();
        
        // 3. SIMPAN TOKEN
        // Token ini sekarang valid untuk IP yang ada di config.dart
        await prefs.setString('token', data['data']['token']);
        
        // 4. Simpan Data User
        await prefs.setString('user_name', data['data']['user']['nama']);
        await prefs.setString('user_email', data['data']['user']['email']); 
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Login Berhasil!"), backgroundColor: Colors.green),
          );
          
          // Pindah ke Home (Hapus riwayat login agar tidak bisa back)
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomeScreen()),
          );
        }
      } else {
        // --- LOGIN GAGAL ---
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(data['message'] ?? "Email atau Password salah"),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            // Tampilkan pesan error yang jelas (mengambil URL dari config)
            content: Text("Gagal terhubung ke ${AppConfig.baseUrl}.\nError: $e"),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false; 
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF3C8085);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),
              const Icon(Icons.pets, size: 80, color: primaryColor),
              const SizedBox(height: 16),
              const Text(
                "LocSato",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
              ),
              const Text(
                "Masuk untuk konsultasi hewan kesayangan",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 50),

              // INPUT EMAIL
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: "Email Address",
                  prefixIcon: const Icon(Icons.email_outlined, color: primaryColor),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: primaryColor, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // INPUT PASSWORD
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: "Password",
                  prefixIcon: const Icon(Icons.lock_outline, color: primaryColor),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: primaryColor, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 30),

              // TOMBOL LOGIN
              ElevatedButton(
                onPressed: _isLoading ? null : _login,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 5,
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                      )
                    : const Text(
                        "MASUK",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),

              const SizedBox(height: 24),

              // LINK KE REGISTER
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Belum punya akun?"),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const RegisterScreen()),
                      );
                    },
                    child: const Text(
                      "Daftar di sini",
                      style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}