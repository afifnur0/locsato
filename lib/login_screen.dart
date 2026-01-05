// lib/login_screen.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'home_screen.dart';
import 'register_screen.dart';
import 'config.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  // --- FUNGSI GANTI IP ---
  void _showIpSettingDialog() {
    final ipController = TextEditingController();
    String currentIp = AppConfig.baseUrl.replaceAll("http://", "").replaceAll(":8000", "");
    ipController.text = currentIp;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Atur IP Server Laptop"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Masukkan IP Address Laptop kamu (Cek di cmd: ipconfig)."),
              const SizedBox(height: 10),
              TextField(
                controller: ipController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(hintText: "Contoh: 192.168.1.15", border: OutlineInputBorder()),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Batal")),
            ElevatedButton(
              onPressed: () async {
                if (ipController.text.isNotEmpty) {
                  await AppConfig.setBaseUrl(ipController.text);
                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Server berubah ke: ${AppConfig.baseUrl}")));
                  }
                }
              },
              child: const Text("Simpan"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _login() async {
    setState(() { _isLoading = true; });
    try {
      final url = Uri.parse('${AppConfig.baseUrl}/api/login');
      final response = await http.post(
        url,
        body: {'email': _emailController.text, 'password': _passwordController.text},
        headers: {'Accept': 'application/json'},
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['status'] == 'success') {
        final userData = data['data']['user'];
        final token = data['data']['token'];
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', token);
        await prefs.setString('user_data', jsonEncode(userData));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Login Berhasil!"), backgroundColor: Colors.green));
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const HomeScreen()));
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(data['message'] ?? "Email atau Password salah"), backgroundColor: Colors.red));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Gagal terhubung ke Server.\nCek IP Address!"), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF3C8085);
    const accentColor = Color(0xFFF59E0B);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // --- BAGIAN ATAS (HEADER MELENGKUNG) ---
            Stack(
              children: [
                // Shape Background
                Container(
                  height: 340, // Sedikit dipertinggi agar muat logo dan teks baru
                  decoration: const BoxDecoration(
                    color: primaryColor,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(60),
                      bottomRight: Radius.circular(60),
                    ),
                  ),
                ),
                // Dekorasi Lingkaran Transparan
                Positioned(
                  top: -50, right: -50,
                  child: Container(width: 200, height: 200, decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), shape: BoxShape.circle)),
                ),
                Positioned(
                  top: 80, left: -30,
                  child: Container(width: 100, height: 100, decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), shape: BoxShape.circle)),
                ),
                // Tombol Setting IP
                Positioned(
                  top: 40, right: 20,
                  child: IconButton(
                    icon: const Icon(Icons.settings, color: Colors.white70),
                    onPressed: _showIpSettingDialog,
                  ),
                ),
                
                // --- BAGIAN LOGO DAN TEKS (YANG DIUBAH) ---
                Center(
                  child: Column(
                    children: [
                      const SizedBox(height: 70),
                      // Container Logo LocSato
                      Container(
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20), // Bentuk kotak rounded
                          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 5))],
                        ),
                        // GUNAKAN IMAGE ASSET DI SINI
                        child: Image.asset(
                          "assets/images/logo_locsato.png", // <--- PASTIKAN PATH INI SESUAI DENGAN FILE ANDA
                          width: 90, // Sesuaikan ukuran logo
                          height: 90,
                          fit: BoxFit.contain,
                          // Fallback jika gambar belum disiapkan di pubspec.yaml
                          errorBuilder: (context, error, stackTrace) => const Icon(Icons.pets, size: 60, color: primaryColor),
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Teks Judul Baru
                      const Text(
                        "Selamat Datang di LocSato",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 24, // Ukuran sedikit disesuaikan agar muat
                          fontWeight: FontWeight.bold, 
                          color: Colors.white, 
                          letterSpacing: 1
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Masuk untuk merawat anabul kesayangan",
                        style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 14),
                      ),
                    ],
                  ),
                ),
                // -----------------------------------------
              ],
            ),

            const SizedBox(height: 30),

            // --- FORM LOGIN (INPUT) ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildTextField(controller: _emailController, hint: "Alamat Email", icon: Icons.email_outlined, color: primaryColor),
                  const SizedBox(height: 20),
                  _buildTextField(controller: _passwordController, hint: "Kata Sandi", icon: Icons.lock_outline, color: primaryColor, isPassword: true),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(onPressed: () {}, child: const Text("Lupa Kata Sandi?", style: TextStyle(color: Colors.grey))),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 8,
                      shadowColor: primaryColor.withOpacity(0.4),
                    ),
                    child: _isLoading
                        ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                        : const Text("MASUK", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1)),
                  ),
                  const SizedBox(height: 30),
                  Row(children: [
                    const Expanded(child: Divider(thickness: 1, color: Colors.grey)),
                    Padding(padding: const EdgeInsets.symmetric(horizontal: 10), child: Text("Atau masuk dengan", style: TextStyle(color: Colors.grey[600], fontSize: 12))),
                    const Expanded(child: Divider(thickness: 1, color: Colors.grey)),
                  ]),
                  const SizedBox(height: 20),
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    _buildSocialButton(Icons.g_mobiledata, Colors.red),
                    const SizedBox(width: 20),
                    _buildSocialButton(Icons.facebook, Colors.blue),
                  ]),
                  const SizedBox(height: 30),
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Text("Belum punya akun?", style: TextStyle(color: Colors.grey[700])),
                    TextButton(
                      onPressed: () { Navigator.push(context, MaterialPageRoute(builder: (context) => const RegisterScreen())); },
                      child: const Text("Daftar Sekarang", style: TextStyle(color: accentColor, fontWeight: FontWeight.bold)),
                    ),
                  ]),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // WIDGET HELPER
  Widget _buildTextField({required TextEditingController controller, required String hint, required IconData icon, required Color color, bool isPassword = false}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[100], borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5))],
      ),
      child: TextField(
        controller: controller, obscureText: isPassword ? _obscurePassword : false,
        keyboardType: isPassword ? TextInputType.text : TextInputType.emailAddress,
        style: const TextStyle(color: Colors.black87),
        decoration: InputDecoration(
          hintText: hint, hintStyle: const TextStyle(color: Colors.grey),
          prefixIcon: Icon(icon, color: color),
          suffixIcon: isPassword 
            ? IconButton(icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: Colors.grey), onPressed: () { setState(() { _obscurePassword = !_obscurePassword; }); })
            : null,
          border: InputBorder.none, contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildSocialButton(IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(border: Border.all(color: Colors.grey[300]!), borderRadius: BorderRadius.circular(12), color: Colors.white),
      child: Icon(icon, color: color, size: 30),
    );
  }
}