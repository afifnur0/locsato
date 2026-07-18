// lib/upcoming_schedule_screen.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'config.dart';
import 'models.dart'; 
import 'booking_screen.dart'; 

class UpcomingScheduleScreen extends StatefulWidget {
  const UpcomingScheduleScreen({super.key});

  @override
  State<UpcomingScheduleScreen> createState() => _UpcomingScheduleScreenState();
}

class _UpcomingScheduleScreenState extends State<UpcomingScheduleScreen> {
  // Menyimpan raw JSON data agar lebih fleksibel memetakan relasi 'jadwals'
  List<dynamic> _doctors = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchSchedules();
  }

  // Mengambil data seluruh dokter beserta jadwal praktiknya
  Future<void> _fetchSchedules() async {
    try {
      final url = Uri.parse('${AppConfig.baseUrl}/api/doctors');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _doctors = data['data'];
          _isLoading = false;
        });
      } else {
        throw Exception("Gagal load data jadwal");
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      print("Error fetch schedules: $e");
    }
  }

  // Fungsi pembersih URL foto
  String _getDoctorImageUrl(String? fotoPath, String namaDokter) {
    if (fotoPath == null || fotoPath.isEmpty) {
      return 'https://ui-avatars.com/api/?name=${Uri.encodeComponent(namaDokter)}&background=random&color=fff';
    }
    String cleanPath = fotoPath;
    if (cleanPath.startsWith('public/')) cleanPath = cleanPath.replaceFirst('public/', '');
    if (cleanPath.startsWith('storage/')) cleanPath = cleanPath.replaceFirst('storage/', '');
    if (cleanPath.startsWith('/')) cleanPath = cleanPath.substring(1);
    return '${AppConfig.baseUrl}/storage/$cleanPath';
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF3C8085);
    const bgColor = Color(0xFFF8F9FA);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text("Jadwal Praktik", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 18)),
        backgroundColor: primaryColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: primaryColor))
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Ringkas
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                color: Colors.white,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Ketersediaan Dokter",
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "Temukan jadwal praktik yang sesuai dengan waktu Anda.",
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // 2. LIST DOKTER & JADWAL
              Expanded(
                child: _doctors.isEmpty
                    ? const Center(child: Text("Belum ada data jadwal dokter tersedia.", style: TextStyle(color: Colors.grey)))
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: _doctors.length,
                        itemBuilder: (context, index) {
                          return _buildJadwalCard(context, _doctors[index]);
                        },
                      ),
              ),
            ],
          ),
    );
  }

  // --- WIDGET KARTU JADWAL DOKTER ---
  Widget _buildJadwalCard(BuildContext context, Map<String, dynamic> docJson) {
    final String nama = docJson['nama'] ?? 'Unknown';
    final String spesialisasi = docJson['spesialisasi'] ?? 'Umum';
    final String? foto = docJson['fotodokter'] ?? docJson['foto'];
    final List<dynamic> jadwals = docJson['jadwals'] ?? docJson['jadwal'] ?? [];
    final bool isAktif = docJson['aktif'] == 1 || docJson['aktif'] == true;
    const primaryColor = Color(0xFF3C8085);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // HEADER KARTU (Foto, Nama, Spesialis)
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  _getDoctorImageUrl(foto, nama),
                  width: 50, height: 50, fit: BoxFit.cover,
                  errorBuilder: (ctx, err, stack) => Container(width: 50, height: 50, color: Colors.grey[200], child: const Icon(Icons.person, color: Colors.grey)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Dr. $nama", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1E293B))),
                    const SizedBox(height: 4),
                    Text(spesialisasi, style: const TextStyle(fontSize: 12, color: primaryColor, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              if (!isAktif)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                  child: const Text("Tutup", style: TextStyle(color: Colors.red, fontSize: 10, fontWeight: FontWeight.bold)),
                )
            ],
          ),
          
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, color: Color(0xFFEEEEEE)),
          ),

          // BODY KARTU (List Jadwal - Wrap Chips Native Mobile)
          jadwals.isEmpty
            ? const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Text("Belum ada jadwal yang diatur.", style: TextStyle(color: Colors.grey, fontSize: 12)))
            : Wrap(
                spacing: 8,
                runSpacing: 8,
                children: jadwals.map<Widget>((jdwl) {
                  final bool isLibur = jdwl['is_libur'] == 1 || jdwl['is_libur'] == true;
                  final String hari = jdwl['hari'] ?? '';
                  
                  // Format Jam
                  String jamMulai = jdwl['jam_mulai'] ?? '';
                  String jamSelesai = jdwl['jam_selesai'] ?? '';
                  if (jamMulai.length >= 5) jamMulai = jamMulai.substring(0, 5);
                  if (jamSelesai.length >= 5) jamSelesai = jamSelesai.substring(0, 5);

                  if (isLibur) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20)
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.close, size: 12, color: Colors.red),
                          const SizedBox(width: 4),
                          Text("$hari (Cuti)", style: const TextStyle(color: Colors.red, fontSize: 11, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    );
                  } else {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.08),
                        border: Border.all(color: primaryColor.withOpacity(0.2)),
                        borderRadius: BorderRadius.circular(8)
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(hari, style: const TextStyle(color: primaryColor, fontSize: 10, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 2),
                          Text("$jamMulai - $jamSelesai", style: const TextStyle(color: Color(0xFF1E293B), fontSize: 11, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    );
                  }
                }).toList(),
              ),
          
          const SizedBox(height: 16),

          // FOOTER KARTU (Tombol Booking)
          SizedBox(
            width: double.infinity,
            height: 36,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: isAktif ? primaryColor : Colors.grey[300],
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: isAktif ? () {
                DoctorModel selectedDoctor = DoctorModel.fromJson(docJson);
                Navigator.push(context, MaterialPageRoute(builder: (context) => BookingScreen(doctor: selectedDoctor)));
              } : null,
              child: Text(isAktif ? "Buat Janji Temu" : "Dokter Tidak Aktif", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: isAktif ? Colors.white : Colors.grey[600])),
            ),
          )
        ],
      ),
    );
  }
}