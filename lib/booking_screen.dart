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
      backgroundColor: const Color(0xFFF4F7F6),
      appBar: AppBar(
        title: const Text("Buat Janji Temu", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
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
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 10)],
                  ),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundImage: NetworkImage(
                          widget.doctor.foto != null 
                            // Pastikan URL gambar bersih dari 'public/' dan pakai AppConfig
                            ? '${AppConfig.baseUrl}/storage/${widget.doctor.foto!.replaceAll('public/', '')}' 
                            : 'https://ui-avatars.com/api/?name=${Uri.encodeComponent(widget.doctor.nama)}'
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text("Dr. ${widget.doctor.nama}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      Text(widget.doctor.spesialisasi, style: TextStyle(color: Colors.grey[600])),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(20)),
                        child: Text(
                          "Biaya: Rp ${widget.doctor.harga}", 
                          style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)
                        ),
                      )
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // --- 2. PILIH JADWAL ---
                const Text("1. Pilih Jadwal Praktik", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 12),
                _schedules.isEmpty 
                  ? Container(
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(color: Colors.orange[50], borderRadius: BorderRadius.circular(10)),
                      child: const Text("Dokter ini belum memiliki jadwal praktik.", style: TextStyle(color: Colors.orange)),
                    )
                  : GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 2.5,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                      ),
                      itemCount: _schedules.length,
                      itemBuilder: (context, index) {
                        final jadwal = _schedules[index];
                        
                        // FIX: Logic ID jadwal yang fleksibel
                        final int scheduleId = jadwal['id'] ?? jadwal['id_jadwal']; 
                        final isSelected = _selectedScheduleId == scheduleId;
                        
                        return GestureDetector(
                          onTap: () => setState(() => _selectedScheduleId = scheduleId),
                          child: Container(
                            decoration: BoxDecoration(
                              color: isSelected ? primaryColor : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected ? primaryColor : Colors.grey.shade300, 
                                width: isSelected ? 2 : 1
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  jadwal['hari'] ?? 'Hari', 
                                  style: TextStyle(fontWeight: FontWeight.bold, color: isSelected ? Colors.white : Colors.black)
                                ),
                                Text(
                                  "${jadwal['jam_mulai']} - ${jadwal['jam_selesai']}", 
                                  style: TextStyle(fontSize: 12, color: isSelected ? Colors.white70 : Colors.grey)
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),

                const SizedBox(height: 24),

                // --- 3. DETAIL KONSULTASI ---
                const Text("2. Detail Konsultasi", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 10)],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Dropdown Hewan
                      const Text("Pilih Pasien (Hewan)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(10)),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<int>(
                            value: _selectedPetId,
                            hint: const Text("Pilih Hewan Peliharaan..."),
                            isExpanded: true,
                            items: _myPets.map<DropdownMenuItem<int>>((pet) {
                              return DropdownMenuItem<int>(
                                value: pet['id_hewan'] ?? pet['id'], // Handle beda nama kolom
                                child: Text("${pet['nama']} (${pet['spesies']})"),
                              );
                            }).toList(),
                            onChanged: (val) => setState(() => _selectedPetId = val),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 16),

                      // Input Keluhan
                      const Text("Keluhan / Catatan", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _noteController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          hintText: "Jelaskan gejala atau kondisi hewan...",
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                // --- TOMBOL SUBMIT ---
                ElevatedButton(
                  onPressed: (_isSubmitting || _schedules.isEmpty) 
                    ? null 
                    : _submitBooking,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    elevation: 5,
                  ),
                  child: _isSubmitting 
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text("BUAT JANJI TEMU", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
    );
  }
}