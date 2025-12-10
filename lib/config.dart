// lib/config.dart
import 'package:flutter/foundation.dart'; // Untuk kIsWeb

class AppConfig {
  // -------------------------------------------------------------
  // GANTI BAGIAN INI DENGAN IP LAPTOP KAMU YANG SEKARANG
  // Cara cek IP: Buka CMD -> ketik 'ipconfig' -> Cari IPv4 Address
  // -------------------------------------------------------------
  static const String _ipLaptop = "192.168.1.157"; 
  
  // Logika otomatis: Kalau Web pakai localhost, kalau HP pakai IP Laptop
  static String get baseUrl {
    if (kIsWeb) {
      return "http://127.0.0.1:8000"; 
    } else {
      return "http://$_ipLaptop:8000";
    }
  }
}