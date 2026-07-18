// lib/booking_screen.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'models.dart'; 
import 'config.dart'; // <--- WAJIB IMPORT CONFIG

class BookingScreen extends StatefulWidget {
  final DoctorModel doctor; // Data dokter yang dipilih

  const BookingScreen({super.key, required this.doctor});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  // --- STATE DATA ---
  List<dynamic> _schedules = [];
  List<dynamic> _myPets = [];
  
  // --- USER INPUT ---
  int? _selectedScheduleId;
  int? _selectedPetId;
  final TextEditingController _noteController = TextEditingController();
  
  bool _isLoading = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  // --- 1. GET DATA (JADWAL & HEWAN) ---
  Future<void> _fetchData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final headers = {
        'Authorization': 'Bearer $token', 
        'Accept': 'application/json'
      };
      
      // Gunakan Base URL dari Config
      final baseUrl = AppConfig.baseUrl;

      // Request API secara paralel (Jadwal & Hewan)
      final responses = await Future.wait([
        http.get(Uri.parse('$baseUrl/api/doctors/${widget.doctor.id}/schedules'), headers: headers),
        http.get(Uri.parse('$baseUrl/api/pets'), headers: headers),
      ]);

      if (responses[0].statusCode == 200 && responses[1].statusCode == 200) {
        setState(() {
          // Parse Data Jadwal
          final scheduleData = jsonDecode(responses[0].body);
          _schedules = scheduleData['data'] ?? [];

          // Parse Data Hewan
          final petData = jsonDecode(responses[1].body);
          _myPets = petData['data'] ?? [];
          
          _isLoading = false;
        });
      } else {
        throw Exception("Gagal memuat data (Status: ${responses[0].statusCode})");
      }
    } catch (e) {
      if(mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
      }
    }
  }

  // --- 2. SUBMIT BOOKING (FIXED SESUAI DATABASE) ---
  Future<void> _submitBooking() async {
    // Validasi Input
    if (_selectedScheduleId == null || _selectedPetId == null || _noteController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Mohon lengkapi jadwal, hewan, dan keluhan!"), backgroundColor: Colors.red)
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      
      final url = Uri.parse('${AppConfig.baseUrl}/api/consultations');

      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token', 
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        // --- PERBAIKAN UTAMA DISINI ---
        // Menggunakan nama key bahasa Indonesia sesuai Database Laravel
        body: jsonEncode({
          'id_dokter': widget.doctor.id,      // Sesuai tabel: id_dokter
          'id_jadwal': _selectedScheduleId,   // Sesuai tabel: id_jadwal
          'id_hewan': _selectedPetId,         // Sesuai tabel: id_hewan
          'catatan': _noteController.text,    // Sesuai tabel: catatan
        }),
      );

      print("Booking Response: ${response.body}"); // Debugging

      if (response.statusCode == 201 || response.statusCode == 200) {
        // SUKSES
        if(mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Janji Temu Berhasil Dibuat!"), backgroundColor: Colors.green));
          Navigator.pop(context); // Kembali ke halaman sebelumnya
        }
      } else {
        // GAGAL - Baca pesan error dari server
        final responseData = jsonDecode(response.body);
        final msg = responseData['message'] ?? "Gagal melakukan booking";
        if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Gagal: $msg"), backgroundColor: Colors.red));
      }
    } catch (e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
    } finally {
      if(mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF3C8085);
    
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text("Buat Janji Temu", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87, fontSize: 18)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: primaryColor))
        : SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                
                // --- 1. KARTU DOKTER ---
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.network(
                          widget.doctor.foto != null 
                            ? '${AppConfig.baseUrl}/storage/${widget.doctor.foto!.replaceAll('public/', '')}' 
                            : 'https://ui-avatars.com/api/?name=${Uri.encodeComponent(widget.doctor.nama)}',
                          width: 80, height: 80, fit: BoxFit.cover,
                          errorBuilder: (ctx, err, stack) => Container(width: 80, height: 80, color: Colors.grey[100], child: const Icon(Icons.person, color: Colors.grey, size: 40)),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Dr. ${widget.doctor.nama}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF1E293B))),
                            const SizedBox(height: 4),
                            Text(widget.doctor.spesialisasi, style: TextStyle(color: primaryColor, fontSize: 14, fontWeight: FontWeight.w500)),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(color: primaryColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                              child: Text(
                                "Rp ${widget.doctor.harga}", 
                                style: const TextStyle(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 13)
                              ),
                            )
                          ],
                        ),
                      )
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // --- 2. PILIH JADWAL ---
                const Text("Pilih Jadwal Praktik", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E293B))),
                const SizedBox(height: 12),
                _schedules.isEmpty 
                  ? Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.orange.shade200)),
                      child: const Row(
                        children: [
                          Icon(Icons.warning_amber_rounded, color: Colors.orange),
                          SizedBox(width: 12),
                          Expanded(child: Text("Dokter ini belum memiliki jadwal praktik yang tersedia.", style: TextStyle(color: Colors.orange, fontSize: 14))),
                        ],
                      ),
                    )
                  : Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: _schedules.map<Widget>((jadwal) {
                        final int scheduleId = jadwal['id'] ?? jadwal['id_jadwal']; 
                        final isSelected = _selectedScheduleId == scheduleId;
                        
                        return GestureDetector(
                          onTap: () => setState(() => _selectedScheduleId = scheduleId),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: (MediaQuery.of(context).size.width - 40 - 12) / 2, // 2 columns with spacing
                            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                            decoration: BoxDecoration(
                              color: isSelected ? primaryColor : Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: isSelected ? [
                                BoxShadow(color: primaryColor.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))
                              ] : [
                                BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 4, offset: const Offset(0, 2))
                              ],
                              border: Border.all(
                                color: isSelected ? primaryColor : Colors.grey.shade200, 
                                width: 1
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  jadwal['hari'] ?? 'Hari', 
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: isSelected ? Colors.white : const Color(0xFF1E293B))
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "${jadwal['jam_mulai'].toString().substring(0,5)} - ${jadwal['jam_selesai'].toString().substring(0,5)}", 
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: isSelected ? Colors.white.withOpacity(0.9) : Colors.grey.shade600)
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                const SizedBox(height: 30),

                // --- 3. DETAIL KONSULTASI ---
                const Text("Detail Konsultasi", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E293B))),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Dropdown Hewan
                      const Text("Hewan Peliharaan", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Color(0xFF1E293B))),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          border: Border.all(color: Colors.grey.shade200), 
                          borderRadius: BorderRadius.circular(12)
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<int>(
                            value: _selectedPetId,
                            hint: const Text("Pilih pasien hewan...", style: TextStyle(color: Colors.grey, fontSize: 14)),
                            isExpanded: true,
                            icon: const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
                            items: _myPets.map<DropdownMenuItem<int>>((pet) {
                              return DropdownMenuItem<int>(
                                value: pet['id_hewan'] ?? pet['id'],
                                child: Text("${pet['nama']} (${pet['spesies']})", style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                              );
                            }).toList(),
                            onChanged: (val) => setState(() => _selectedPetId = val),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 20),

                      // Input Keluhan
                      const Text("Keluhan / Catatan", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Color(0xFF1E293B))),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _noteController,
                        maxLines: 4,
                        style: const TextStyle(fontSize: 14),
                        decoration: InputDecoration(
                          hintText: "Jelaskan gejala atau kondisi hewan peliharaan Anda...",
                          hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
                          fillColor: Colors.grey.shade50,
                          filled: true,
                          contentPadding: const EdgeInsets.all(16),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF3C8085))),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),

                // --- TOMBOL SUBMIT ---
                SizedBox(
                  height: 56, // Touch-friendly size (min 48px)
                  child: ElevatedButton(
                    onPressed: (_isSubmitting || _schedules.isEmpty) 
                      ? null 
                      : _submitBooking,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey.shade300,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: (_isSubmitting || _schedules.isEmpty) ? 0 : 4,
                      shadowColor: primaryColor.withOpacity(0.4),
                    ),
                    child: _isSubmitting 
                      ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                      : const Text("Buat Janji Temu", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
    );
  }
}