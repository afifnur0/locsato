// lib/home_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'config.dart';
import 'shop_screen.dart';      
import 'profile_screen.dart';   
import 'consultation_screen.dart'; 
import 'pet_care_screen.dart';
import 'home_visit_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  Map<String, dynamic>? _userData;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final String? userString = prefs.getString('user_data'); 
    
    if (userString != null) {
      setState(() {
        _userData = jsonDecode(userString);
      });
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    if (index == 0 || index == 2) {
      _loadCurrentUser();
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF3C8085);

    // List of pages rebuilt to pass userData dynamically
    final List<Widget> pages = [
      HomeContent(userData: _userData),  
      const ShopScreen(),   
      const ProfileScreen(), 
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), 
      body: pages[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, -5))],
        ),
        child: BottomNavigationBar(
          backgroundColor: Colors.white,
          selectedItemColor: primaryColor,
          unselectedItemColor: Colors.grey.shade400,
          showUnselectedLabels: true,
          currentIndex: _selectedIndex, 
          onTap: _onItemTapped,        
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Beranda',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.shopping_bag_outlined),
              activeIcon: Icon(Icons.shopping_bag),
              label: 'Belanja',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Profil',
            ),
          ],
        ),
      ),
    );
  }
}

class HomeContent extends StatelessWidget {
  final Map<String, dynamic>? userData;
  const HomeContent({super.key, this.userData});

  String _getUserPhotoUrl() {
    if (userData == null || userData!['profile_pic'] == null) return "";
    String rawPath = userData!['profile_pic'];
    String cleanPath = rawPath.replaceAll('public/', '').replaceAll('public\\', '').replaceAll('\\', '/');
    if (cleanPath.startsWith('/')) cleanPath = cleanPath.substring(1);
    if (cleanPath.startsWith('http')) return cleanPath;
    return '${AppConfig.baseUrl}/storage/$cleanPath';
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF3C8085);
    String userName = userData != null ? (userData!['nama'] ?? 'Pengguna') : 'Memuat...';
    int userPoints = userData != null ? (userData!['points'] ?? 0) : 0;
    int userLevel = userData != null ? (userData!['level'] ?? 1) : 1;
    int userXp = userData != null ? (userData!['current_xp'] ?? 0) : 0;

    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // COMPACT HEADER
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Halo, $userName! 👋", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                        const SizedBox(height: 4),
                        const Text("Siap merawat anabul hari ini?", style: TextStyle(fontSize: 13, color: Colors.grey)),
                      ],
                    ),
                  ),
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: Colors.grey.shade200,
                    backgroundImage: _getUserPhotoUrl().isNotEmpty ? NetworkImage(_getUserPhotoUrl()) : null,
                    child: _getUserPhotoUrl().isEmpty ? const Icon(Icons.person, color: Colors.grey, size: 24) : null,
                  ),
                ],
              ),
            ),

            // GAMIFICATION CARD (Standard Flow, Not Floating)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2A5C5F), Color(0xFF3C8085)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(color: primaryColor.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4)),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildGamificationStat("Poin LocSato", userPoints.toString(), Icons.stars, Colors.amber),
                    Container(height: 35, width: 1, color: Colors.white.withOpacity(0.3)),
                    _buildGamificationStat("Level", userLevel.toString(), Icons.military_tech, Colors.white),
                    Container(height: 35, width: 1, color: Colors.white.withOpacity(0.3)),
                    _buildGamificationStat("XP", userXp.toString(), Icons.trending_up, Colors.lightBlueAccent),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // SERVICES SECTION
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Layanan Kami", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                  const SizedBox(height: 12),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.5, // Lebar persegi panjang, khas aplikasi mobile native
                    children: [
                      _buildModernServiceCard(context, Icons.chat_bubble_outline, "Konsultasi", "Tanya Dokter", Colors.blue, () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const ConsultationScreen()));
                      }),
                      _buildModernServiceCard(context, Icons.home_outlined, "Home Visit", "Panggil ke Rumah", Colors.green, () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const HomeVisitScreen()));
                      }),
                      _buildModernServiceCard(context, Icons.shopping_bag_outlined, "Pet Shop", "Belanja Kebutuhan", Colors.orange, () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const ShopScreen()));
                      }),
                      _buildModernServiceCard(context, Icons.menu_book_outlined, "Pet Care", "Artikel & Tips", Colors.purple, () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const PetCareScreen()));
                      }),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // WHY US SECTION
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Kenapa LocSato?", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      children: [
                        _buildCheckPoint("Dokter Terverifikasi", "Semua mitra dokter memiliki SIP resmi."),
                        const SizedBox(height: 10),
                        _buildCheckPoint("Respon Cepat 24/7", "Sistem kami siap membantu kapanpun."),
                        const SizedBox(height: 10),
                        _buildCheckPoint("Produk 100% Original", "Jaminan uang kembali jika palsu."),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGamificationStat(String label, String value, IconData icon, Color iconColor) {
    return Column(
      children: [
        Icon(icon, color: iconColor, size: 24),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
        Text(label, style: TextStyle(fontSize: 10, color: Colors.white.withOpacity(0.8))),
      ],
    );
  }

  Widget _buildModernServiceCard(BuildContext context, IconData icon, String title, String subtitle, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.grey.shade100),
          boxShadow: [
            BoxShadow(color: color.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 5)),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const Spacer(),
            Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
            const SizedBox(height: 4),
            Text(subtitle, style: const TextStyle(fontSize: 11, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckPoint(String title, String subtitle) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: const BoxDecoration(
            color: Color(0xFFDCFCE7),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check, color: Color(0xFF16A34A), size: 12),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E293B))),
              const SizedBox(height: 2),
              Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 11)),
            ],
          ),
        ),
      ],
    );
  }
}