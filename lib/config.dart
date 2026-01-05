// lib/config.dart
import 'package:flutter/foundation.dart'; // Untuk kIsWeb
import 'package:shared_preferences/shared_preferences.dart'; // WAJIB: Untuk simpan IP

class AppConfig {
  // -------------------------------------------------------------
  // IP Default (Cadangan jika belum disetting di menu Login)
  // -------------------------------------------------------------
  static String _defaultIp = "192.168.1.12"; 

  // Variable private untuk menampung URL yang aktif saat ini
  static String _activeUrl = "";

  // GETTER: Untuk mengambil URL di seluruh aplikasi
  static String get baseUrl {
    // 1. Jika sudah ada URL aktif (dari settingan), pakai itu
    if (_activeUrl.isNotEmpty) {
      return _activeUrl;
    }

    // 2. Jika belum ada, gunakan logika default (Web vs Mobile)
    if (kIsWeb) {
      return "http://127.0.0.1:8000"; 
    } else {
      return "http://$_defaultIp:8000";
    }
  }

  // --- FUNGSI 1: LOAD IP (Dipanggil di main.dart) ---
  // Mengecek apakah user pernah menyimpan IP khusus sebelumnya
  static Future<void> loadBaseUrl() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedIp = prefs.getString('server_ip');
      
      if (savedIp != null && savedIp.isNotEmpty) {
        _activeUrl = "http://$savedIp:8000";
        print("Config Loaded from Storage: $_activeUrl");
      } else {
        // Jika tidak ada simpanan, inisialisasi default
        _activeUrl = kIsWeb ? "http://127.0.0.1:8000" : "http://$_defaultIp:8000";
      }
    } catch (e) {
      print("Gagal load config: $e");
    }
  }

  // --- FUNGSI 2: SET IP (Dipanggil di Login Screen) ---
  // Menyimpan IP baru yang diinput user
  static Future<void> setBaseUrl(String newIp) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Simpan hanya angkanya saja, misal: 192.168.1.50
      await prefs.setString('server_ip', newIp); 
      
      // Update variable aktif agar aplikasi langsung berubah arah tanpa restart
      _activeUrl = "http://$newIp:8000";
      print("Config Updated manually: $_activeUrl");
    } catch (e) {
      print("Gagal simpan config: $e");
    }
  }
}