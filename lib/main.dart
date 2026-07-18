// lib/main.dart
import 'package:flutter/material.dart';
import 'login_screen.dart'; 
import 'home_screen.dart';  
import 'shop_screen.dart'; 
import 'consultation_screen.dart'; 
import 'config.dart'; // <--- WAJIB IMPORT INI

import 'package:google_fonts/google_fonts.dart';

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
    const primaryColor = Color(0xFF3C8085);
    const bgColor = Color(0xFFF8FAFC);

    return MaterialApp(
      title: 'LocSato',
      debugShowCheckedModeBanner: false,
      
      // KONFIGURASI TEMA MODERN
      theme: ThemeData(
        scaffoldBackgroundColor: bgColor,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryColor,
        ).copyWith(
          primary: primaryColor,
          secondary: const Color(0xFF2A5C5F),
          surface: Colors.white,
        ),
        textTheme: GoogleFonts.poppinsTextTheme(
          Theme.of(context).textTheme,
        ),
        useMaterial3: true,
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade200)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade200)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: primaryColor, width: 2)),
          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
        ),
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