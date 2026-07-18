import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'login_screen.dart';
import 'config.dart';

class DoctorDashboardScreen extends StatefulWidget {
  const DoctorDashboardScreen({super.key});

  @override
  State<DoctorDashboardScreen> createState() => _DoctorDashboardScreenState();
}

class _DoctorDashboardScreenState extends State<DoctorDashboardScreen> {
  final Color primaryColor = const Color(0xFF0F766E);
  final Color primaryHover = const Color(0xFF115E59);
  final Color bgColor = const Color(0xFFF8F9FA);

  bool _isOnline = true;
  late Timer _timer;
  DateTime _currentTime = DateTime.now();

  // Variabel State API
  bool _isLoading = true;
  String _namaDokter = "Memuat...";
  int _totalPasien = 0;
  List<dynamic> _antreanList = [];
  List<dynamic> _obatList = []; // Daftar obat untuk dropdown

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('id_ID', null);
    _loadDoctorData();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _currentTime = DateTime.now();
        });
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  // --- AMBIL DATA DARI API ---
  Future<void> _loadDoctorData() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) return;

    try {
      final url = Uri.parse('${AppConfig.baseUrl}/api/dokter/dashboard');
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final jsonResp = jsonDecode(response.body);
        if (jsonResp['status'] == 'success') {
          final data = jsonResp['data'];
          if (mounted) {
            setState(() {
              _namaDokter = data['nama_dokter'] ?? "Dokter";
              _isOnline = data['is_online'] ?? false;
              _totalPasien = data['total_pasien'] ?? 0;
              _antreanList = data['antrean'] ?? [];
              _obatList = data['obat_list'] ?? [];
              _isLoading = false;
            });
          }
        }
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print("Error fetch doctor data: $e");
      setState(() => _isLoading = false);
    }
  }

  // --- UPDATE STATUS ONLINE/OFFLINE ---
  Future<void> _updateOnlineStatus(bool isOnline) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) return;

    try {
      final url = Uri.parse('${AppConfig.baseUrl}/api/dokter/update-status');
      await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'is_online': isOnline}),
      );
    } catch (e) {
      print("Error update online status: $e");
    }
  }

  void _logout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Keluar"),
        content: const Text("Apakah Anda yakin ingin keluar dari Panel Dokter?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Batal")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.clear();
              if (mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
            child: const Text("Keluar", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text("Dashboard Dokter", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 18)),
        backgroundColor: primaryColor,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.logout, color: Colors.white), onPressed: _logout),
        ],
      ),
      body: _isLoading 
        ? Center(child: CircularProgressIndicator(color: primaryColor))
        : SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeroHeader(),
                
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 25, 20, 15),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Antrean Konsultasi", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2D3436))),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)),
                        child: Text("${_antreanList.length} Pasien", style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black87)),
                      )
                    ],
                  ),
                ),

                _antreanList.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _antreanList.length,
                      itemBuilder: (context, index) {
                        return _buildPatientCard(_antreanList[index]);
                      },
                    ),
                const SizedBox(height: 40),
              ],
            ),
          ),
    );
  }

  // --- WIDGET HELPER ---

  Widget _buildHeroHeader() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [primaryColor, primaryHover], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: primaryColor.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("👋 Halo, Dr. $_namaDokter", style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 5),
                    const Text("Selamat bertugas! Pantau antrean dan pesan pasien Anda hari ini.", style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.4)),
                  ],
                ),
              ),
              const SizedBox(width: 15),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(DateFormat('HH:mm:ss', 'id_ID').format(_currentTime) + " WIB", style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  Text(DateFormat('EEEE, d MMM yyyy', 'id_ID').format(_currentTime), style: const TextStyle(color: Colors.white70, fontSize: 10)),
                ],
              )
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(50)),
                child: Row(
                  children: [
                    const Icon(Icons.people_alt, color: Colors.white, size: 16),
                    const SizedBox(width: 8),
                    Text("Total Pasien Ditangani: $_totalPasien", style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              Row(
                children: [
                  const Text("Online", style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(width: 5),
                  SizedBox(
                    height: 24,
                    child: Switch(
                      value: _isOnline,
                      activeColor: Colors.white,
                      activeTrackColor: Colors.green,
                      inactiveTrackColor: Colors.grey.withOpacity(0.5),
                      onChanged: (val) {
                        setState(() => _isOnline = val);
                        _updateOnlineStatus(val);
                      },
                    ),
                  ),
                ],
              )
            ],
          )
        ],
      ),
    );
  }

  Widget _buildPatientCard(Map<String, dynamic> data) {
    // Dropdown Items List
    List<DropdownMenuItem<String>> medicineItems = _obatList.map((obat) {
      return DropdownMenuItem<String>(
        value: obat['id'].toString(),
        child: Text(obat['nama'], style: const TextStyle(fontSize: 12, overflow: TextOverflow.ellipsis)),
      );
    }).toList();

    return Card(
      elevation: 3,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.only(bottom: 20),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Badge Jadwal & Status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(color: const Color(0xFFE0F2F1), borderRadius: BorderRadius.circular(8)),
                  child: Row(
                    children: [
                      Icon(Icons.schedule, size: 12, color: primaryColor),
                      const SizedBox(width: 5),
                      Text(data['jadwal'], style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: primaryColor)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(50)),
                  child: Text(data['status'], style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.green.shade700)),
                )
              ],
            ),
            const SizedBox(height: 15),

            // Info Pasien
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.grey.shade100,
                  child: Text(data['pemilik'].toString().substring(0, 1).toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Nama Pemilik", style: TextStyle(fontSize: 10, color: Colors.grey)),
                      Text(data['pemilik'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Pasien (Hewan)", style: TextStyle(fontSize: 10, color: Colors.grey)),
                      Row(
                        children: [
                          Icon(Icons.pets, size: 12, color: primaryColor),
                          const SizedBox(width: 4),
                          Text(data['hewan'], style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: primaryColor)),
                        ],
                      ),
                      Text("Jenis: ${data['jenis_hewan']}", style: const TextStyle(fontSize: 10, color: Colors.grey)),
                    ],
                  ),
                )
              ],
            ),
            const SizedBox(height: 15),

            // Keluhan Awal
            const Text("Keluhan Awal Pasien:", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
            const SizedBox(height: 5),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
              child: Text('"${data['keluhan']}"', style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.black87, fontSize: 12)),
            ),
            const SizedBox(height: 15),

            // Tombol Aksi
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {},
                    icon: Icon(Icons.chat_bubble_outline, size: 16, color: primaryColor),
                    label: Text("Chat", style: TextStyle(color: primaryColor, fontSize: 12)),
                    style: OutlinedButton.styleFrom(side: BorderSide(color: primaryColor), padding: const EdgeInsets.symmetric(vertical: 10)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.history_edu, size: 16, color: Colors.blue),
                    label: const Text("Medis", style: TextStyle(color: Colors.blue, fontSize: 12)),
                    style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.blue), padding: const EdgeInsets.symmetric(vertical: 10)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.cancel_outlined, size: 16, color: Colors.red),
                    label: const Text("Batal", style: TextStyle(color: Colors.red, fontSize: 12)),
                    style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.red), padding: const EdgeInsets.symmetric(vertical: 10)),
                  ),
                ),
              ],
            ),
            
            const Padding(padding: EdgeInsets.symmetric(vertical: 15), child: Divider()),

            // Form Diagnosa
            const Text("Catatan Medis / Diagnosa Akhir", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextFormField(
              maxLines: 3,
              decoration: InputDecoration(
                hintText: "Ketik hasil diagnosa atau tindakan di sini...",
                hintStyle: const TextStyle(fontSize: 12, color: Colors.grey),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.all(12)
              ),
            ),
            const SizedBox(height: 15),

            // E-Prescription (Dropdown Obat dari API)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade200)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.vaccines, size: 14, color: primaryColor),
                      const SizedBox(width: 5),
                      const Text("E-Prescription (Pilih Obat Klinik)", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(color: Colors.white, border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        hint: const Text("Ketik nama obat untuk mencari...", style: TextStyle(fontSize: 12)),
                        items: medicineItems,
                        onChanged: (val) {
                          // Handle Pilihan Obat
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 15),

            // Biaya Layanan & Submit
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  flex: 1,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Biaya Layanan (Rp)", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 5),
                      TextFormField(
                        initialValue: data['biaya_default'].toString(),
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          prefixText: "Rp ",
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0)
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  flex: 1,
                  child: SizedBox(
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Fitur penyelesaian konsultasi segera hadir.")));
                      },
                      icon: const Icon(Icons.check, size: 18, color: Colors.white),
                      label: const Text("Selesaikan Sesi", style: TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(backgroundColor: primaryColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                    ),
                  ),
                )
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.all(40.0),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.event_available, size: 60, color: Colors.grey.shade300),
            const SizedBox(height: 15),
            const Text("Belum Ada Jadwal", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black54)),
            const SizedBox(height: 5),
            const Text("Belum ada antrean pasien untuk hari ini.", style: TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}