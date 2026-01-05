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

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  Map<String, dynamic>? _userData;

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
    _pages = [
      const HomeContent(),  
      const ShopScreen(),   
      const ProfileScreen(), 
    ];
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

  String _getUserPhotoUrl() {
    if (_userData == null || _userData!['profile_pic'] == null) return "";
    String rawPath = _userData!['profile_pic'];
    String cleanPath = rawPath.replaceAll('public/', '').replaceAll('public\\', '').replaceAll('\\', '/');
    if (cleanPath.startsWith('/')) cleanPath = cleanPath.substring(1);
    if (cleanPath.startsWith('http')) return cleanPath;
    return '${AppConfig.baseUrl}/storage/$cleanPath';
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

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // Warna Background Body Web
      // Body langsung konten tanpa AppBar standar agar Hero Image full
      body: _selectedIndex == 0 
          ? const HomeContent() 
          : _pages[_selectedIndex],

      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, -5))],
        ),
        child: BottomNavigationBar(
          backgroundColor: Colors.white,
          selectedItemColor: primaryColor,
          unselectedItemColor: Colors.grey,
          showUnselectedLabels: true,
          currentIndex: _selectedIndex, 
          onTap: _onItemTapped,        
          type: BottomNavigationBarType.fixed,
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

// ==========================================
// KONTEN BERANDA (UI MODERN + FIXED READABILITY)
// ==========================================
class HomeContent extends StatefulWidget {
  const HomeContent({super.key});

  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  // Config Warna
  final Color primaryColor = const Color(0xFF3C8085);
  final Color primarySoft = const Color(0xFFE0F2F1);
  final Color accentColor = const Color(0xFFF59E0B);
  final Color textDark = const Color(0xFF1F2937);
  final Color textGrey = const Color(0xFF64748B);

  // Controller Carousel
  final PageController _pageController = PageController();
  int _currentCarouselIndex = 0;
  Timer? _carouselTimer;

  // Data Slider
  final List<Map<String, String>> _heroSlides = [
    {
      "image": "https://images.unsplash.com/photo-1548767797-d8c844163c4c?q=80&w=800",
      "badge": "Selamat Datang di LocSato",
      "title": "Kesehatan Hewan,\nKini Lebih Mudah.",
      "desc": "Platform sahabat anabul yang menghubungkan Anda dengan dokter hewan terbaik.",
      "btn": "Konsultasi Dokter"
    },
    {
      "image": "https://images.unsplash.com/photo-1576201836106-db1758fd1c97?q=80&w=800",
      "badge": "Layanan Home Visit",
      "title": "Dokter Datang\nke Rumah Anda.",
      "desc": "Anabul takut ke klinik? Panggil dokter kami ke rumah. Bebas stres.",
      "btn": "Booking Jadwal"
    },
    {
      "image": "https://images.unsplash.com/photo-1583337130417-3346a1be7dee?q=80&w=800",
      "badge": "Pet Shop Terlengkap",
      "title": "Belanja Kebutuhan\nHarian Anabul.",
      "desc": "Makanan & vitamin berkualitas. 100% Original dan pengiriman cepat.",
      "btn": "Belanja Sekarang"
    },
  ];

  @override
  void initState() {
    super.initState();
    // Auto Scroll
    _carouselTimer = Timer.periodic(const Duration(seconds: 5), (Timer timer) {
      if (_currentCarouselIndex < _heroSlides.length - 1) {
        _currentCarouselIndex++;
      } else {
        _currentCarouselIndex = 0;
      }
      if (_pageController.hasClients) {
        _pageController.animateToPage(
          _currentCarouselIndex,
          duration: const Duration(milliseconds: 800),
          curve: Curves.fastOutSlowIn,
        );
      }
    });
  }

  @override
  void dispose() {
    _carouselTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // 1. HERO CAROUSEL SECTION
          SizedBox(
            height: 520, // Tinggi area Hero
            child: Stack(
              children: [
                PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() => _currentCarouselIndex = index);
                  },
                  itemCount: _heroSlides.length,
                  itemBuilder: (context, index) {
                    final slide = _heroSlides[index];
                    return Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.network(
                          slide['image']!,
                          fit: BoxFit.cover,
                          errorBuilder: (ctx, err, stack) => Container(color: Colors.grey),
                        ),
                        // Gradient Overlay agar teks putih terbaca
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                const Color(0xFF1E293B).withOpacity(0.3),
                                const Color(0xFF0F172A).withOpacity(0.9),
                              ],
                            ),
                          ),
                        ),
                        // Konten Teks Hero
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 40),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const SizedBox(height: 20),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(50),
                                  border: Border.all(color: Colors.white.withOpacity(0.3)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.star, color: accentColor, size: 16),
                                    const SizedBox(width: 8),
                                    Text(
                                      slide['badge']!,
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 20),
                              Text(
                                slide['title']!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 28, 
                                  fontWeight: FontWeight.w800,
                                  height: 1.2,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                slide['desc']!,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 13,
                                  height: 1.5,
                                ),
                              ),
                              const SizedBox(height: 25),
                              ElevatedButton(
                                onPressed: () {
                                  if (index == 0) Navigator.push(context, MaterialPageRoute(builder: (_) => const ConsultationScreen()));
                                  if (index == 1) Navigator.push(context, MaterialPageRoute(builder: (_) => const ConsultationScreen()));
                                  if (index == 2) Navigator.push(context, MaterialPageRoute(builder: (_) => const ShopScreen()));
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primaryColor,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                                  elevation: 5,
                                ),
                                child: Text(slide['btn']!, style: const TextStyle(fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
                
                // Indikator Carousel
                Positioned(
                  bottom: 100, // Posisi titik-titik (di atas box putih)
                  left: 0, right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_heroSlides.length, (index) {
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: _currentCarouselIndex == index ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _currentCarouselIndex == index ? primaryColor : Colors.white.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),
                ),
              ],
            ),
          ),

          // 2. SERVICES SECTION (SOLUSI BACA: WRAPPER PUTIH)
          Transform.translate(
            offset: const Offset(0, -60), // Naik ke atas menutupi Hero
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 25, horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.white, // Background Putih agar teks jelas!
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Title Section di dalam Box Putih
                    Column(
                      children: [
                        Text(
                          "LAYANAN KAMI",
                          style: TextStyle(
                            color: primaryColor, 
                            fontWeight: FontWeight.bold, 
                            letterSpacing: 1.2,
                            fontSize: 12
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          "Apa yang Anabul\nAnda Butuhkan?",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: textDark, 
                            fontWeight: FontWeight.w800, 
                            fontSize: 20,
                            height: 1.2
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Grid Menu
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.9, 
                      children: [
                        _buildServiceCard(Icons.chat_bubble_outline, "Konsultasi", "Curhat masalah kesehatan.", () {
                           Navigator.push(context, MaterialPageRoute(builder: (_) => const ConsultationScreen()));
                        }),
                        _buildServiceCard(Icons.home_outlined, "Home Visit", "Panggil dokter ke rumah.", () {}),
                        _buildServiceCard(Icons.shopping_bag_outlined, "Pet Shop", "Belanja makanan & vitamin.", () {
                           Navigator.push(context, MaterialPageRoute(builder: (_) => const ShopScreen()));
                        }),
                        _buildServiceCard(Icons.menu_book_outlined, "Pet Care", "Artikel & tips merawat.", () {
                           Navigator.push(context, MaterialPageRoute(builder: (_) => const PetCareScreen()));}),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 3. WHY US SECTION
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Gambar
                ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Image.network(
                    "https://images.unsplash.com/photo-1514888286974-6c03e2ca1dba?q=80&w=800",
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 25),
                
                // Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: primarySoft, borderRadius: BorderRadius.circular(20)),
                  child: Text("TENTANG KAMI", style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 11)),
                ),
                const SizedBox(height: 15),
                
                // Teks Judul
                RichText(
                  text: TextSpan(
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: textDark, fontFamily: 'Roboto'),
                    children: [
                      const TextSpan(text: "Kenapa Memilih\n"),
                      TextSpan(text: "LocSato?", style: TextStyle(color: primaryColor)),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  "Kami hadir untuk memudahkan para Pet Lovers. Tidak perlu bingung lagi saat anabul sakit.",
                  style: TextStyle(color: textGrey, fontSize: 13, height: 1.6),
                ),
                const SizedBox(height: 20),

                // Poin-poin Checklist
                _buildCheckPoint("Dokter Terverifikasi", "Semua mitra dokter memiliki SIP resmi."),
                _buildCheckPoint("Respon Cepat 24/7", "Sistem kami siap membantu kapanpun."),
                _buildCheckPoint("Produk 100% Original", "Jaminan uang kembali jika palsu."),
                
                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // WIDGET KARTU LAYANAN (Disesuaikan agar lebih rapi di dalam box)
  Widget _buildServiceCard(IconData icon, String title, String desc, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC), // Warna agak abu dikit biar beda sama box putih
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 45, height: 45,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: primarySoft),
              ),
              child: Icon(icon, color: primaryColor, size: 22),
            ),
            const SizedBox(height: 10),
            Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textDark)),
            const SizedBox(height: 4),
            Text(
              desc,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 10, color: textGrey, height: 1.3),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // WIDGET CHECKLIST
  Widget _buildCheckPoint(String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: const BoxDecoration(
              color: Color(0xFFDCFCE7),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check, color: Color(0xFF16A34A), size: 14),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: textDark)),
                const SizedBox(height: 2),
                Text(subtitle, style: TextStyle(color: textGrey, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}