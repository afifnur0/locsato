import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppConfig {
  // =========================================================
  // GANTI BAGIAN INI SESUAI PERANGKAT ANDA
  // =========================================================
  
  // OPSI A: Jika pakai Emulator Android Studio
  static String _defaultIp = "10.0.2.2"; 
  
  // OPSI B: Jika pakai HP Fisik (Cek IP Laptop, misal 192.168.1.12)
  // static String _defaultIp = "192.168.1.12"; 

  // =========================================================
  
  static String _activeUrl = "";

  static String get baseUrl {
    // 1. Prioritaskan URL yang sudah di-load/aktif
    if (_activeUrl.isNotEmpty) return _activeUrl;
    
    // 2. Jika Web, pakai localhost biasa
    if (kIsWeb) return "http://127.0.0.1:8000";
    
    // 3. Jika Android/iOS, pakai IP Default di atas
    return "http://$_defaultIp:8000";
  }

  // Dipanggil oleh main.dart (Baris 13 kode Anda)
  static Future<void> loadBaseUrl() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedIp = prefs.getString('server_ip');
      
      if (savedIp != null && savedIp.isNotEmpty) {
        _activeUrl = "http://$savedIp:8000";
        if (kDebugMode) print("Config Loaded: $_activeUrl");
      }
    } catch (e) {
      if (kDebugMode) print("Config Error: $e");
    }
  }

  // Opsional: Untuk fitur ganti IP di halaman Login
  static Future<void> setBaseUrl(String newIp) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('server_ip', newIp);
    _activeUrl = "http://$newIp:8000";
  }
}