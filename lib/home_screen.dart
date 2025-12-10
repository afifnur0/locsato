// lib/home_screen.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'models.dart'; 
import 'config.dart';
import 'shop_screen.dart';      // Halaman Belanja
import 'profile_screen.dart';   // Halaman Profile
import 'consultation_screen.dart'; // Halaman Konsultasi

// Kita ubah jadi StatefulWidget agar bisa pindah-pindah halaman
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // 1. INDEX HALAMAN AKTIF
  int _selectedIndex = 0;

  // 2. DAFTAR HALAMAN UTAMA (Menu Bawah)
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      const HomeContent(),  // Konten Home (Widget terpisah di bawah)
      const ShopScreen(),   // Halaman Belanja
      const ProfileScreen(), // Halaman Profil
    ];
  }

  // 3. FUNGSI GANTI HALAMAN
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF0F766E);

    return Scaffold(
      // --- APP BAR DINAMIS (Hanya muncul di Home) ---
      appBar: _selectedIndex == 0 
        ? AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            title: RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, fontFamily: 'Roboto'),
                children: [
                  TextSpan(text: 'Loc', style: TextStyle(color: Colors.grey[800])),
                  TextSpan(text: 'Sato', style: TextStyle(color: primaryColor)),
                ],
              ),
            ),
            actions: [
              IconButton(
                icon: Icon(Icons.notifications_outlined, color: Colors.grey[800]),
                onPressed: () {},
              ),
              Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: GestureDetector(
                  onTap: () => _onItemTapped(2), // Klik Foto -> Pindah ke tab Profil
                  child: const CircleAvatar(
                    radius: 18,
                    backgroundColor: Color(0xFF3C8085),
                    child: Icon(Icons.person, color: Colors.white, size: 20),
                  ),
                ),
              ),
            ],
          )
        : null, // Halaman Shop & Profile punya AppBar sendiri

      // --- BODY UTAMA ---
      body: _pages[_selectedIndex],

      // --- MENU BAWAH (BOTTOM NAVIGATION) ---
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, -5))],
        ),
        child: BottomNavigationBar(
          backgroundColor: Colors.white,
          selectedItemColor: primaryColor,
          unselectedItemColor: Colors.grey,
          showUnselectedLabels: true,
          currentIndex: _selectedIndex, // Menandai menu aktif
          onTap: _onItemTapped,         // Mengubah halaman saat diklik
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
// KONTEN BERANDA (Dipisah agar rapi & Punya State sendiri untuk Load API)
// ==========================================
class HomeContent extends StatefulWidget {
  const HomeContent({super.key});

  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  List<DoctorModel> _availableDoctors = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchDoctors();
  }

  // --- AMBIL DATA DOKTER DARI API (BUKAN DUMMY) ---
  Future<void> _fetchDoctors() async {
    try {
      final url = Uri.parse('${AppConfig.baseUrl}/api/doctors');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> doctorsJson = data['data'];
        
        setState(() {
          // Ambil maksimal 5 dokter untuk ditampilkan di Home
          _availableDoctors = doctorsJson.map((json) => DoctorModel.fromJson(json)).toList();
          if (_availableDoctors.length > 5) {
            _availableDoctors = _availableDoctors.sublist(0, 5);
          }
          _isLoading = false;
        });
      } else {
        throw Exception("Gagal load dokter");
      }
    } catch (e) {
      if(mounted) setState(() => _isLoading = false);
      print("Error fetch doctors: $e");
    }
  }

  // Helper untuk membersihkan URL Gambar
  String _getDoctorImageUrl(String? fotoPath, String namaDokter) {
    if (fotoPath == null || fotoPath.isEmpty) {
      return 'https://ui-avatars.com/api/?name=${Uri.encodeComponent(namaDokter)}&background=random&color=fff';
    }
    String cleanPath = fotoPath.replaceAll('public/', '');
    return '${AppConfig.baseUrl}/storage/$cleanPath';
  }

  @override
  Widget build(BuildContext context) {
    // Akses context Home Screen untuk pindah tab
    void navigateToShop() {
      final homeState = context.findAncestorStateOfType<State<HomeScreen>>();
      // Panggil method _onItemTapped via reflection (agak tricky) atau
      // cara paling aman: kita biarkan navigation bar yang handle,
      // tapi untuk simplisitas di sini kita push halaman baru atau biarkan user klik manual.
      // NOTE: Context ancestor ini agak kompleks di Flutter jika class _HomeScreenState private.
      // Solusi simpel: Kita asumsikan user klik navbar bawah untuk belanja.
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. HERO BANNER
          Container(
            margin: const EdgeInsets.all(16),
            width: double.infinity,
            height: 180,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              image: const DecorationImage(
                image: NetworkImage("https://images.unsplash.com/photo-1548767797-d8c844163c4c?auto=format&fit=crop&w=800&q=80"),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(Colors.black38, BlendMode.darken),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Selamat Datang di\nLocSato",
                    style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold, height: 1.2),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Solusi Kesehatan Hewan Peliharaan.",
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F766E),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    ),
                    onPressed: () {
                      // Navigasi ke Halaman Konsultasi
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const ConsultationScreen()));
                    }, 
                    child: const Text("Mulai Konsultasi"),
                  )
                ],
              ),
            ),
          ),

          // 2. LAYANAN KAMI (MENU GRID)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: const Text("Layanan Kami", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ),
          const SizedBox(height: 16),
          
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildServiceItem(
                  icon: Icons.chat_bubble_outline, 
                  label: "Konsultasi", 
                  color: const Color(0xFF0F766E),
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const ConsultationScreen()));
                  },
                ),
                _buildServiceItem(icon: Icons.pets, label: "PetCare", color: Colors.orange, onTap: (){}),
                _buildServiceItem(icon: Icons.medical_services_outlined, label: "HomVisit", color: Colors.blue, onTap: (){}),
                
                // TOMBOL PET MEDIC
                _buildServiceItem(
                  icon: Icons.shopping_bag_outlined, 
                  label: "PetMedic", 
                  color: Colors.redAccent, 
                  onTap: () {
                    // Navigasi manual ke ShopScreen jika state management kompleks
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const ShopScreen()));
                  }
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // 3. DOKTER TERSEDIA (DATA ASLI DARI API)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Dokter Tersedia", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                TextButton(
                  onPressed: (){
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const ConsultationScreen()));
                  }, 
                  child: const Text("Lihat Semua", style: TextStyle(color: Color(0xFF0F766E)))
                ),
              ],
            ),
          ),
          
          // LIST VIEW DOKTER (Dynamic)
          _isLoading 
            ? const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator())) 
            : _availableDoctors.isEmpty 
                ? const Center(child: Padding(padding: EdgeInsets.all(20), child: Text("Belum ada dokter tersedia.")))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _availableDoctors.length,
                    itemBuilder: (context, index) {
                      final doctor = _availableDoctors[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(color: Colors.grey.withOpacity(0.05), spreadRadius: 2, blurRadius: 10, offset: const Offset(0, 4)),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Row(
                            children: [
                              // Foto Dokter
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(
                                  _getDoctorImageUrl(doctor.foto, doctor.nama),
                                  width: 70, height: 70, fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => Container(width: 70, height: 70, color: Colors.grey[300], child: const Icon(Icons.person)),
                                ),
                              ),
                              const SizedBox(width: 16),
                              // Info Dokter
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(doctor.nama, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                    const SizedBox(height: 4),
                                    Text(doctor.spesialisasi, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        // Status Online/Offline
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: doctor.aktif ? Colors.green[50] : Colors.red[50],
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            doctor.aktif ? "Online" : "Offline",
                                            style: TextStyle(color: doctor.aktif ? Colors.green : Colors.red, fontSize: 10, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                        const Spacer(),
                                        Text(doctor.harga, style: const TextStyle(color: Color(0xFF0F766E), fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildServiceItem({required IconData icon, required String label, required Color color, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 60, height: 60,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey.shade200, width: 1),
              boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5))],
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black87)),
        ],
      ),
    );
  }
}