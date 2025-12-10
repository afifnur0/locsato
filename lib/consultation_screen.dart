// lib/consultation_screen.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'models.dart'; 
import 'booking_screen.dart'; 
import 'history_screen.dart'; 
import 'upcoming_schedule_screen.dart'; // Pastikan file ini ada
import 'config.dart'; 

class ConsultationScreen extends StatefulWidget {
  const ConsultationScreen({super.key});

  @override
  State<ConsultationScreen> createState() => _ConsultationScreenState();
}

class _ConsultationScreenState extends State<ConsultationScreen> {
  // Hanya simpan data dokter, data jadwal ada di halaman sebelah
  List<DoctorModel> _doctors = [];
  bool _isLoading = true;
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    _fetchDoctors();
  }

  // --- AMBIL DATA DOKTER SAJA ---
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

  // --- FUNGSI PEMBERSIH URL GAMBAR ---
  String _getDoctorImageUrl(String? fotoPath, String namaDokter) {
    if (fotoPath == null || fotoPath.isEmpty) {
      return 'https://ui-avatars.com/api/?name=${Uri.encodeComponent(namaDokter)}&background=random&color=fff';
    }
    String cleanPath = fotoPath.replaceAll('public/', '');
    return '${AppConfig.baseUrl}/storage/$cleanPath';
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF3C8085); 

    // Filter dokter berdasarkan pencarian
    final filteredDoctors = _doctors.where((doc) {
      return doc.nama.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F6),
      appBar: AppBar(
        title: const Text("Konsultasi", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: primaryColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. HERO SECTION
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
              decoration: BoxDecoration(
                color: primaryColor,
                image: const DecorationImage(
                  image: NetworkImage('https://images.unsplash.com/photo-1576201836106-db1758fd1c97?auto=format&fit=crop&w=1200&q=80'),
                  fit: BoxFit.cover,
                  colorFilter: ColorFilter.mode(Colors.black45, BlendMode.darken),
                ),
              ),
              child: Column(
                children: [
                  const Text(
                    "Peduli Kesehatan\nHewan Peliharaan Anda",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 10),
                  const Text("Temukan Dokter Spesialis Hewan Terbaik", style: TextStyle(color: Colors.white70)),
                  const SizedBox(height: 20),

                  // --- MENU NAVIGASI (JADWAL & RIWAYAT) ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Tombol ke Halaman Jadwal Mendatang
                      _buildHeaderButton(
                        icon: Icons.calendar_today,
                        label: "Jadwal Saya",
                        color: Colors.orange,
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const UpcomingScheduleScreen())),
                      ),
                      // Tombol ke Halaman Riwayat Selesai
                      _buildHeaderButton(
                        icon: Icons.history,
                        label: "Riwayat Selesai",
                        color: Colors.blue,
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const HistoryScreen())),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Search Box
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(30)),
                    child: TextField(
                      onChanged: (value) => setState(() => _searchQuery = value),
                      decoration: const InputDecoration(
                        hintText: "Cari Dokter...",
                        border: InputBorder.none,
                        icon: Icon(Icons.search, color: Colors.grey),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 2. KATEGORI
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 20, 20, 10),
              child: Text("Kategori Spesialis", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  _buildCategoryCard("Kucing", Icons.pets, Colors.orange),
                  _buildCategoryCard("Anjing", Icons.flutter_dash, Colors.blue), 
                  _buildCategoryCard("Burung", Icons.flutter_dash, Colors.green),
                  _buildCategoryCard("Reptil", Icons.bug_report, Colors.brown),
                ],
              ),
            ),

            // 3. DAFTAR DOKTER
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 20, 20, 10),
              child: Text("Rekomendasi Dokter", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ),
            
            _isLoading 
              ? const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()))
              : filteredDoctors.isEmpty
                  ? const Center(child: Padding(padding: EdgeInsets.all(20), child: Text("Dokter tidak ditemukan")))
                  : GridView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      shrinkWrap: true, 
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2, 
                        childAspectRatio: 0.75, 
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                      ),
                      itemCount: filteredDoctors.length,
                      itemBuilder: (context, index) {
                        return _buildDoctorCard(filteredDoctors[index], primaryColor);
                      },
                    ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // Widget Tombol Header Kecil
  Widget _buildHeaderButton({required IconData icon, required String label, required Color color, required VoidCallback onTap}) {
    return ElevatedButton.icon(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: color,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      ),
      icon: Icon(icon, size: 18),
      label: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildCategoryCard(String label, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 5)],
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildDoctorCard(DoctorModel doctor, Color primaryColor) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // FOTO DOKTER
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: Image.network(
                _getDoctorImageUrl(doctor.foto, doctor.nama),
                fit: BoxFit.cover,
                errorBuilder: (ctx, err, stack) {
                  return Container(
                    color: Colors.grey[200], 
                    child: const Icon(Icons.person, size: 50, color: Colors.grey)
                  );
                },
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(child: CircularProgressIndicator(value: loadingProgress.expectedTotalBytes != null ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes! : null));
                },
              ),
            ),
          ),
          
          // Info Dokter
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Text("Dr. ${doctor.nama}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(doctor.spesialisasi, style: TextStyle(color: primaryColor, fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                
                // Status
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: doctor.aktif ? Colors.green[50] : Colors.red[50],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    doctor.aktif ? "Online" : "Offline",
                    style: TextStyle(color: doctor.aktif ? Colors.green : Colors.red, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 8),
                
                // Tombol Janji Temu
                SizedBox(
                  width: double.infinity,
                  height: 30,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: doctor.aktif ? primaryColor : Colors.grey[300],
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                    onPressed: doctor.aktif ? () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => BookingScreen(doctor: doctor)));
                    } : null,
                    child: Text("Janji Temu", style: TextStyle(color: doctor.aktif ? Colors.white : Colors.grey[600], fontSize: 11)),
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}