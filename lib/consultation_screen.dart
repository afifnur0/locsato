// lib/consultation_screen.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'models.dart'; 
import 'booking_screen.dart'; 
import 'history_screen.dart'; 
import 'upcoming_schedule_screen.dart'; 
import 'config.dart'; 

class ConsultationScreen extends StatefulWidget {
  const ConsultationScreen({super.key});

  @override
  State<ConsultationScreen> createState() => _ConsultationScreenState();
}

class _ConsultationScreenState extends State<ConsultationScreen> {
  List<DoctorModel> _doctors = [];
  bool _isLoading = true;
  String _searchQuery = "";
  
  // 1. TAMBAH VARIABEL STATE KATEGORI
  String _selectedCategory = "Semua";

  @override
  void initState() {
    super.initState();
    _fetchDoctors();
  }

  Future<void> _fetchDoctors() async {
    try {
      final urlDoctors = Uri.parse('${AppConfig.baseUrl}/api/doctors');
      final responseDocs = await http.get(urlDoctors);

      if (responseDocs.statusCode == 200) {
        final data = jsonDecode(responseDocs.body);
        final List<dynamic> doctorsJson = data['data'];
        
        setState(() {
          _doctors = doctorsJson.map((json) => DoctorModel.fromJson(json)).toList();
          _isLoading = false;
        });
      } else {
        throw Exception("Gagal load dokter: ${responseDocs.statusCode}");
      }
    } catch (e) {
      if(mounted) setState(() => _isLoading = false);
      print("Error fetch data: $e");
    }
  }

  String _getDoctorImageUrl(String? fotoPath, String namaDokter) {
    if (fotoPath == null || fotoPath.isEmpty) {
      return 'https://ui-avatars.com/api/?name=${Uri.encodeComponent(namaDokter)}&background=random&color=fff';
    }
    String cleanPath = fotoPath;
    if (cleanPath.startsWith('public/')) {
      cleanPath = cleanPath.replaceFirst('public/', '');
    }
    if (cleanPath.startsWith('storage/')) {
      cleanPath = cleanPath.replaceFirst('storage/', '');
    }
    if (cleanPath.startsWith('/')) {
      cleanPath = cleanPath.substring(1);
    }
    return '${AppConfig.baseUrl}/storage/$cleanPath';
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF3C8085); 
    const secondaryColor = Color(0xFF2A9D8F);

    // 2. UPDATE LOGIKA FILTER
    final filteredDoctors = _doctors.where((doc) {
      // Filter Nama
      final matchesSearch = doc.nama.toLowerCase().contains(_searchQuery.toLowerCase());
      
      // Filter Kategori (Spesialisasi)
      final matchesCategory = _selectedCategory == "Semua" || 
                              doc.spesialisasi.toLowerCase().contains(_selectedCategory.toLowerCase());
                              
      return matchesSearch && matchesCategory;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text("Konsultasi", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87, fontSize: 20)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: Colors.black87),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.history, color: Colors.black87, size: 20),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const HistoryScreen())),
              tooltip: 'Riwayat Konsultasi',
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search Bar
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: TextField(
                  onChanged: (value) => setState(() => _searchQuery = value),
                  decoration: const InputDecoration(
                    hintText: "Cari dokter spesialis...",
                    hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
                    border: InputBorder.none,
                    prefixIcon: Icon(Icons.search, color: Colors.grey),
                    contentPadding: EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Kategori Spesialis
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Kategori Spesialis", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E293B))),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _buildCategoryCard("Semua", Icons.apps, primaryColor),
                  _buildCategoryCard("Kucing", Icons.pets, Colors.orange),
                  _buildCategoryCard("Anjing", Icons.flutter_dash, Colors.blue), 
                  _buildCategoryCard("Burung", Icons.emoji_nature, Colors.green),
                  _buildCategoryCard("Reptil", Icons.bug_report, Colors.brown),
                  _buildCategoryCard("Umum", Icons.medical_services, secondaryColor),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Daftar Dokter
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Rekomendasi Dokter", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E293B))),
                  if (_searchQuery.isNotEmpty || _selectedCategory != "Semua") 
                    GestureDetector(
                      onTap: () => setState(() { _searchQuery = ""; _selectedCategory = "Semua"; }), 
                      child: const Text("Reset", style: TextStyle(color: primaryColor, fontSize: 13, fontWeight: FontWeight.bold))
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            
            _isLoading 
              ? const Center(child: Padding(padding: EdgeInsets.all(30), child: CircularProgressIndicator()))
              : filteredDoctors.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(40), 
                        child: Column(
                          children: [
                            Icon(Icons.search_off, size: 50, color: Colors.grey[300]),
                            const SizedBox(height: 12),
                            Text("Dokter tidak ditemukan", style: TextStyle(color: Colors.grey[500], fontWeight: FontWeight.w500)),
                          ],
                        )
                      )
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      shrinkWrap: true, 
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: filteredDoctors.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        return _buildDoctorCard(context, filteredDoctors[index], primaryColor, secondaryColor);
                      },
                    ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // --- WIDGET HELPER ---

  Widget _buildCategoryCard(String label, IconData icon, Color baseColor) {
    bool isActive = _selectedCategory == label;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedCategory = label;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? baseColor : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: isActive ? [
            BoxShadow(color: baseColor.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))
          ] : [
            BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 4, offset: const Offset(0, 2))
          ],
          border: Border.all(color: isActive ? baseColor : Colors.grey.shade200, width: 1),
        ),
        child: Row(
          children: [
            Icon(icon, color: isActive ? Colors.white : baseColor, size: 18),
            if (isActive) ...[
              const SizedBox(width: 8),
              Text(
                label, 
                style: const TextStyle(
                  fontWeight: FontWeight.w600, 
                  fontSize: 13, 
                  color: Colors.white
                )
              ),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildDoctorCard(BuildContext context, DoctorModel doctor, Color primaryColor, Color secondaryColor) {
    return GestureDetector(
      onTap: () => _showDoctorModal(context, doctor, primaryColor, secondaryColor),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Doctor Image
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(
                    _getDoctorImageUrl(doctor.foto, doctor.nama),
                    width: 65, height: 65, fit: BoxFit.cover,
                    errorBuilder: (ctx, err, stack) => Container(width: 65, height: 65, color: Colors.grey[100], child: const Icon(Icons.person, color: Colors.grey, size: 30)),
                  ),
                ),
                Positioned(
                  bottom: -2,
                  right: -2,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: doctor.aktif ? Colors.green : Colors.grey,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                )
              ],
            ),
            const SizedBox(width: 14),
            
            // Doctor Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Dr. ${doctor.nama}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1E293B))),
                  const SizedBox(height: 4),
                  Text(doctor.spesialisasi, style: TextStyle(fontSize: 12, color: primaryColor, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),
                  
                  // Action / Next Available
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.star, size: 14, color: Colors.amber.shade500),
                          const SizedBox(width: 4),
                          const Text("4.8", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87)),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: doctor.aktif ? primaryColor : Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          doctor.aktif ? "Buat Janji" : "Tutup", 
                          style: TextStyle(
                            color: doctor.aktif ? Colors.white : Colors.grey.shade600, 
                            fontSize: 11, 
                            fontWeight: FontWeight.bold
                          )
                        ),
                      )
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }


  // --- MODAL POPUP PROFIL DOKTER ---
  void _showDoctorModal(BuildContext context, DoctorModel doctor, Color primaryColor, Color secondaryColor) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
          ),
          child: Column(
            children: [
              // Header Image
              SizedBox(
                height: 250,
                width: double.infinity,
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
                      child: Image.network(
                        _getDoctorImageUrl(doctor.foto, doctor.nama),
                        width: double.infinity, height: double.infinity, fit: BoxFit.cover,
                        errorBuilder: (ctx, err, stack) => Container(color: Colors.grey[200], child: const Center(child: Icon(Icons.person, size: 80, color: Colors.grey))),
                      ),
                    ),
                    Positioned(
                      top: 15, right: 15,
                      child: InkWell(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                          child: const Icon(Icons.close, size: 20, color: Colors.black87),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 15, left: 15,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: doctor.aktif ? Colors.green : Colors.grey.shade600,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 5)],
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.circle, size: 8, color: Colors.white),
                            const SizedBox(width: 6),
                            Text(doctor.aktif ? "Online" : "Offline", style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    )
                  ],
                ),
              ),

              // Body Info
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Dr. ${doctor.nama}", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF264653))),
                      const SizedBox(height: 5),
                      Text(doctor.spesialisasi, style: const TextStyle(fontSize: 14, color: Colors.grey)),
                      const SizedBox(height: 15),

                      // Rating & Experience
                      Row(
                        children: [
                          _buildInfoChip(Icons.work, "5 Tahun", Colors.grey.shade200),
                          const SizedBox(width: 10),
                          _buildInfoChip(Icons.thumb_up, "95%", Colors.grey.shade200),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Harga Box
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
                        decoration: BoxDecoration(color: secondaryColor.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("Biaya Konsultasi", style: TextStyle(fontWeight: FontWeight.w600)),
                            Text("Rp 50.000", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF264653))),
                          ],
                        ),
                      ),
                      const SizedBox(height: 25),

                      // Jadwal Praktik
                      const Text("Jadwal Praktik", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 12)),
                      const SizedBox(height: 10),
                      doctor.jadwals.isEmpty
                        ? const Padding(padding: EdgeInsets.only(bottom: 15), child: Text("Belum ada jadwal yang diatur.", style: TextStyle(color: Colors.grey, fontSize: 13)))
                        : Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: doctor.jadwals.map<Widget>((jdwl) {
                              final bool isLibur = jdwl['is_libur'] == 1 || jdwl['is_libur'] == true;
                              final String hari = jdwl['hari'] ?? '';
                              
                              String jamMulai = jdwl['jam_mulai'] ?? '';
                              String jamSelesai = jdwl['jam_selesai'] ?? '';
                              if (jamMulai.length >= 5) jamMulai = jamMulai.substring(0, 5);
                              if (jamSelesai.length >= 5) jamSelesai = jamSelesai.substring(0, 5);

                              if (isLibur) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.red.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: Colors.red.withOpacity(0.3))
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.close, size: 14, color: Colors.red),
                                      const SizedBox(width: 6),
                                      Text("$hari (Cuti)", style: const TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                );
                              } else {
                                return Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: primaryColor.withOpacity(0.08),
                                    border: Border.all(color: primaryColor.withOpacity(0.2)),
                                    borderRadius: BorderRadius.circular(12)
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(hari, style: TextStyle(color: primaryColor, fontSize: 11, fontWeight: FontWeight.bold)),
                                      const SizedBox(height: 4),
                                      Text("$jamMulai - $jamSelesai", style: const TextStyle(color: Color(0xFF1E293B), fontSize: 12, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                );
                              }
                            }).toList(),
                          ),
                      const SizedBox(height: 25),

                      // Bidang Keahlian
                      const Text("Bidang Keahlian", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 12)),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8, runSpacing: 8,
                        children: [
                          _buildKeahlianChip("Penyakit Dalam", primaryColor),
                          _buildKeahlianChip("Vaksinasi & Imunisasi", primaryColor),
                          _buildKeahlianChip("Perkembangan Hewan", primaryColor),
                        ],
                      ),
                      const SizedBox(height: 25),

                      // Detail Latar Belakang
                      _buildListTileInfo(Icons.school, "Alumnus", "Universitas Kedokteran Hewan, 2015"),
                      _buildListTileInfo(Icons.location_on, "Praktik di", "LocSato Clinic, Bandung"),
                      _buildListTileInfo(Icons.verified_user, "Nomor STR", "7111201423063624"),
                    ],
                  ),
                ),
              ),

              // Bottom Booking Button
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))]),
                child: SizedBox(
                  width: double.infinity, height: 50,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: doctor.aktif ? const Color(0xFF264653) : Colors.grey,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: doctor.aktif ? () {
                      Navigator.pop(context); // Tutup modal
                      Navigator.push(context, MaterialPageRoute(builder: (context) => BookingScreen(doctor: doctor)));
                    } : null,
                    icon: const Icon(Icons.calendar_month, color: Colors.white),
                    label: Text(doctor.aktif ? "Lanjut Booking" : "Sedang Istirahat", style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              )
            ],
          ),
        );
      }
    );
  }

  Widget _buildInfoChip(IconData icon, String text, Color bgColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade300)),
      child: Row(
        children: [
          Icon(icon, size: 14, color: Colors.grey.shade700),
          const SizedBox(width: 5),
          Text(text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildKeahlianChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(border: Border.all(color: color.withOpacity(0.5)), borderRadius: BorderRadius.circular(20)),
      child: Text(text, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }

  Widget _buildListTileInfo(IconData icon, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.grey.shade400, size: 24),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF264653))),
                const SizedBox(height: 2),
                Text(subtitle, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
              ],
            ),
          )
        ],
      ),
    );
  }
}