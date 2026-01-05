// lib/main.dart
import 'package:flutter/material.dart';
import 'login_screen.dart'; 
import 'home_screen.dart';  
import 'shop_screen.dart'; 
import 'consultation_screen.dart'; 
import 'config.dart'; // <--- WAJIB IMPORT INI

void main() async {
  // 1. Pastikan binding Flutter siap sebelum menjalankan kode async
  WidgetsFlutterBinding.ensureInitialized();
  
  // 2. Load IP Address terakhir yang disimpan user (Supaya tidak perlu setting ulang tiap buka)
  await AppConfig.loadBaseUrl(); 
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LocSato',
      debugShowCheckedModeBanner: false,
      
      // KONFIGURASI TEMA
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFF4F7F6),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF3C8085),
        ).copyWith(
          primary: const Color(0xFF3C8085),
          secondary: const Color(0xFF2A5C5F),
        ),
        fontFamily: 'Roboto',
        useMaterial3: true,
      ),
      
      // --- SISTEM NAVIGASI (ROUTES) ---
      initialRoute: '/login', // Halaman pertama kali buka
      routes: {
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const HomeScreen(), 
        '/shop': (context) => const ShopScreen(),       
        '/consultation': (context) => const ConsultationScreen(),
      },
    );
  }
}