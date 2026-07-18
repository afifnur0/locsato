// lib/register_screen.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'config.dart'; // <--- 1. WAJIB IMPORT CONFIG INI

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _register() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // 2. GUNAKAN BASE URL DARI CONFIG (Agar sinkron dengan Login & Checkout)
      final url = Uri.parse('${AppConfig.baseUrl}/api/register');

      final response = await http.post(
        url,
        body: {
          'nama': _nameController.text, // Pastikan backend Laravel menerima 'nama' (bukan 'name')
          'email': _emailController.text,
          'password': _passwordController.text,
        },
        headers: {'Accept': 'application/json'},
      );

      print("Register URL: $url");
      print("Response: ${response.body}");

      final data = jsonDecode(response.body);

      if (response.statusCode == 201 && data['status'] == 'success') {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Registrasi Berhasil! Silakan Login."), backgroundColor: Colors.green),
          );
          Navigator.pop(context); // Kembali ke halaman Login
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(data['message'] ?? "Registrasi Gagal"),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            // Tampilkan error URL agar mudah dicek
            content: Text("Gagal terhubung ke ${AppConfig.baseUrl}.\nError: $e"), 
            backgroundColor: Colors.red
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
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: primaryColor), // Panah back warna hijau
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                "Daftar Akun",
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: primaryColor),
              ),
              const Text(
                "Lengkapi data diri Anda",
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 30),

              // INPUT NAMA
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: "Nama Lengkap",
                  prefixIcon: Icon(Icons.person_outline, color: primaryColor),
                ),
              ),
              const SizedBox(height: 16),

              // INPUT EMAIL
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: "Email Address",
                  prefixIcon: Icon(Icons.email_outlined, color: primaryColor),
                ),
              ),
              const SizedBox(height: 16),

              // INPUT PASSWORD
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: "Password",
                  prefixIcon: Icon(Icons.lock_outline, color: primaryColor),
                ),
              ),
              const SizedBox(height: 30),

              // TOMBOL DAFTAR
              ElevatedButton(
                onPressed: _isLoading ? null : _register,
                child: _isLoading
                    ? const SizedBox(
                        height: 20, width: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text("DAFTAR SEKARANG", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}