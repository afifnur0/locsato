// lib/home_visit_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'config.dart';
import 'package:url_launcher/url_launcher.dart'; // Tambahkan ini di pubspec.yaml jika belum ada
import 'package:intl/date_symbol_data_local.dart'; // <--- TAMBAHKAN BARIS INI

class HomeVisitScreen extends StatefulWidget {
  const HomeVisitScreen({super.key});

  @override
  State<HomeVisitScreen> createState() => _HomeVisitScreenState();
}

class _HomeVisitScreenState extends State<HomeVisitScreen> {
  // --- STATE VARIABEL ---
  bool _isLoading = false;
  
  // Data Dropdown (Dari API)
  List<dynamic> _pets = [];
  List<dynamic> _clinics = [];
  List<dynamic> _history = [];

  // Form Controllers
  final List<String> _selectedPets = [];
  String? _selectedClinic;
  final TextEditingController _alamatController = TextEditingController();
  final TextEditingController _keluhanController = TextEditingController();
  DateTime? _selectedDate;

  // Layanan & Biaya
  Map<String, dynamic> _layananHarga = {
    'Pemeriksaan Umum': 50000,
    'Vaksinasi': 100000,
    'Grooming': 75000,
    'Sterilisasi': 150000,
  };
  final List<String> _selectedServices = [];
  final int _biayaTransport = 25000;

  @override
  void initState() {
    super.initState();
    // Memuat kamus bahasa Indonesia untuk format tanggal
    initializeDateFormatting('id_ID', null).then((_) {
      _fetchDataAPI();
    });
  }
  // --- FUNGSI MENGAMBIL DATA API ASLI ---
  Future<void> _fetchDataAPI() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      
      final headers = {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json'
      };

      // 1. Ambil Data Init (Hewan & Klinik)
      final resInit = await http.get(Uri.parse('${AppConfig.baseUrl}/api/homvisit/init'), headers: headers);
      if (resInit.statusCode == 200) {
        final initData = jsonDecode(resInit.body)['data'];
        setState(() {
          _pets = initData['pets'] ?? [];
          _clinics = initData['clinics'] ?? [];
          if (initData['layanan_harga'] != null) {
             _layananHarga = initData['layanan_harga'];
          }
        });
      }

      // 2. Ambil Riwayat Kunjungan
      final resHistory = await http.get(Uri.parse('${AppConfig.baseUrl}/api/homvisit'), headers: headers);
      if (resHistory.statusCode == 200) {
        final historyData = jsonDecode(resHistory.body)['data'];
        setState(() {
          _history = historyData ?? [];
        });
      }

    } catch (e) {
      print("Error fetching API: $e");
    } finally {
      if(mounted) setState(() => _isLoading = false);
    }
  }

  // --- FUNGSI SUBMIT FORM PENDAFTARAN ---
  Future<void> _submitPendaftaran() async {
    if (_selectedPets.isEmpty || _selectedClinic == null || _selectedDate == null || _alamatController.text.isEmpty || _keluhanController.text.isEmpty || _selectedServices.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Harap lengkapi semua data formulir!'), backgroundColor: Colors.red));
      return;
    }

    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      
      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}/api/homvisit'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'pet_ids': _selectedPets,
          'id_klinik': _selectedClinic,
          'schedule': DateFormat('yyyy-MM-dd').format(_selectedDate!),
          'alamat': _alamatController.text,
          'keluhan': _keluhanController.text,
          'services': _selectedServices,
        }),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pesanan berhasil dibuat!'), backgroundColor: Colors.green));
        _fetchDataAPI(); // Refresh data riwayat
        
        // Buka URL Pembayaran Xendit jika ada
        if (responseData['payment_url'] != null) {
          final Uri url = Uri.parse(responseData['payment_url']);
          if (await canLaunchUrl(url)) {
            await launchUrl(url, mode: LaunchMode.externalApplication);
          }
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(responseData['message'] ?? 'Gagal membuat pesanan'), backgroundColor: Colors.red));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // --- LOGIKA PERHITUNGAN BIAYA ---
  int get _totalBiaya {
    int totalServices = 0;
    for (String service in _selectedServices) {
      totalServices += (_layananHarga[service] ?? 0) as int;
    }
    int jumlahHewan = _selectedPets.isEmpty ? 1 : _selectedPets.length;
    return _biayaTransport + (totalServices * jumlahHewan);
  }

  void _toggleService(String service) {
    setState(() {
      if (_selectedServices.contains(service)) {
        _selectedServices.remove(service);
      } else {
        _selectedServices.add(service);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // 1. Maintain brand identity: Warna existing #0F6E56
    const primaryColor = Color(0xFF0F6E56);
    const bgColor = Color(0xFFF9FAFB);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: bgColor,
        appBar: AppBar(
          title: const Text("Home Visit", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87, fontSize: 18)),
          backgroundColor: Colors.white,
          centerTitle: true,
          // 2. Navigation Back Button -> Expand to 44x44px. Flutter IconButton default is 48x48.
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
            color: Colors.black87,
            iconSize: 24,
            padding: const EdgeInsets.all(12), // Ensures large hit target
          ),
          // Header Section -> sticky or elevated
          elevation: 2,
          shadowColor: Colors.black12,
          bottom: const TabBar(
            indicatorColor: primaryColor,
            indicatorWeight: 3,
            labelColor: primaryColor,
            unselectedLabelColor: Colors.grey,
            labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            // Tab buttons -> 48px height minimum
            tabs: [
              Tab(height: 48, text: "Pesan Layanan"),
              Tab(height: 48, text: "Riwayat"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildFormTab(primaryColor),
            _buildHistoryTab(primaryColor),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // TAB 1: FORM PENDAFTARAN
  // ==========================================
  Widget _buildFormTab(Color primaryColor) {
    return Stack(
      children: [
        SingleChildScrollView(
          // Spacing & Layout: Horizontal padding 16px on mobile (we use 16 instead of 20 now)
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Banner Mini
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white, 
                  borderRadius: BorderRadius.circular(16), 
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))]
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: primaryColor.withOpacity(0.1), shape: BoxShape.circle),
                      child: Icon(Icons.home_repair_service_rounded, color: primaryColor, size: 28),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Typography & Readability: "Layanan Kunjungan" -> maintain 18px minimum
                          Text("Layanan Kunjungan", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                          SizedBox(height: 6),
                          // Subtitle -> verify 16px+ mobile, line height 1.5
                          Text(
                            "Dokter hewan akan datang langsung ke rumah Anda.", 
                            style: TextStyle(fontSize: 16, color: Colors.grey, height: 1.5)
                          ),
                        ],
                      ),
                    )
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 1. Pilih Hewan
              _buildInputLabel("Pasien (Hewan Peliharaan)"),
              _pets.isEmpty
                  ? Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(12)),
                      child: const Text("Belum ada data hewan. Tambahkan di profil terlebih dahulu.", style: TextStyle(color: Colors.orange, fontSize: 13)),
                    )
                  : Wrap(
                      // Spacing: Gap antar button pasien -> 8px minimum
                      spacing: 8.0,
                      runSpacing: 8.0,
                      children: _pets.map((p) {
                        String id = p['id_hewan'].toString();
                        bool isSelected = _selectedPets.contains(id);
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              if (isSelected) {
                                _selectedPets.remove(id);
                              } else {
                                _selectedPets.add(id);
                              }
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            // Button "asd" -> verify 44x48px minimum
                            constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: isSelected ? primaryColor : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: isSelected ? primaryColor : Colors.grey.shade300),
                              boxShadow: isSelected ? [BoxShadow(color: primaryColor.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))] : [],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.pets, size: 16, color: isSelected ? Colors.white : Colors.grey.shade600),
                                const SizedBox(width: 8),
                                Text(
                                  p['nama'] ?? 'Tanpa Nama', 
                                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: isSelected ? Colors.white : const Color(0xFF1E293B))
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
              const SizedBox(height: 24), // Section spacing 16px minimum

              // 2. Pilih Klinik
              _buildInputLabel("Klinik Penyedia Layanan"),
              _buildDropdown(
                hint: "Pilih Klinik Terdekat...",
                value: _selectedClinic,
                items: _clinics.map((c) {
                  bool isOpen = (c['is_open'] == 1 || c['is_open'] == true || c['is_open'] == null);
                  return DropdownMenuItem(
                    value: c['id'].toString(), 
                    child: Text(
                      "${c['nama'] ?? 'Klinik'} ${isOpen ? '' : '(Tutup)'}", 
                      style: TextStyle(color: isOpen ? const Color(0xFF1E293B) : Colors.grey, fontSize: 16, fontWeight: FontWeight.w500)
                    ),
                    enabled: isOpen,
                  );
                }).toList(),
                onChanged: (val) => setState(() => _selectedClinic = val),
              ),
              const SizedBox(height: 24),

              // 3. Alamat
              _buildInputLabel("Alamat Lengkap Kunjungan"),
              TextField(
                controller: _alamatController,
                maxLines: 3,
                style: const TextStyle(fontSize: 16, height: 1.5),
                decoration: _inputDecoration("Nama Jalan, Nomor Rumah, RT/RW, Patokan..."),
              ),
              const SizedBox(height: 24),

              // 4. Keluhan
              _buildInputLabel("Keluhan / Kondisi Hewan"),
              TextField(
                controller: _keluhanController,
                maxLines: 3,
                style: const TextStyle(fontSize: 16, height: 1.5),
                decoration: _inputDecoration("Contoh: Kucing lemas, tidak mau makan..."),
              ),
              const SizedBox(height: 24),

              // 5. Tanggal
              _buildInputLabel("Rencana Tanggal Kunjungan"),
              InkWell(
                onTap: () async {
                  DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 30)),
                  );
                  if (picked != null) setState(() => _selectedDate = picked);
                },
                child: Container(
                  // Date picker -> large calendar picker for touch, min height 48px
                  constraints: const BoxConstraints(minHeight: 48),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50, 
                    borderRadius: BorderRadius.circular(12), 
                    border: Border.all(color: Colors.grey.shade200)
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _selectedDate != null ? DateFormat('dd MMMM yyyy', 'id_ID').format(_selectedDate!) : "Pilih Tanggal Kunjungan",
                        style: TextStyle(color: _selectedDate != null ? const Color(0xFF1E293B) : Colors.grey, fontSize: 16, fontWeight: FontWeight.w500),
                      ),
                      const Icon(Icons.calendar_today, color: Colors.grey, size: 20),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // 6. Layanan
              _buildInputLabel("Layanan yang Dibutuhkan"),
              Wrap(
                spacing: 8, // Minimum 8px spacing
                runSpacing: 8,
                children: _layananHarga.keys.map((key) {
                  int price = _layananHarga[key]! as int;
                  bool isSelected = _selectedServices.contains(key);
                  return GestureDetector(
                    onTap: () => _toggleService(key),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: (MediaQuery.of(context).size.width - 32 - 8) / 2, // 2 columns responsive (padding 16*2=32)
                      constraints: const BoxConstraints(minHeight: 48), // Ensure minimum 48px touch target
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                      decoration: BoxDecoration(
                        color: isSelected ? primaryColor : Colors.white,
                        border: Border.all(color: isSelected ? primaryColor : Colors.grey.shade200, width: 1),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: isSelected ? [BoxShadow(color: primaryColor.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))] : [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2))],
                      ),
                      child: Row(
                        children: [
                          Icon(isSelected ? Icons.check_circle : Icons.radio_button_unchecked, color: isSelected ? Colors.white : Colors.grey, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(key, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: isSelected ? Colors.white : const Color(0xFF1E293B)), maxLines: 2, overflow: TextOverflow.ellipsis),
                                const SizedBox(height: 4),
                                Text("Rp ${price / 1000}k", style: TextStyle(fontSize: 13, color: isSelected ? Colors.white70 : Colors.grey)),
                              ],
                            ),
                          )
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 32),

              // Total Biaya Box
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white, 
                  border: Border.all(color: Colors.grey.shade200), 
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))]
                ),
                child: Column(
                  children: [
                    const Text("ESTIMASI TOTAL BIAYA", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1, color: Colors.grey)),
                    const SizedBox(height: 8),
                    Text(
                      NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0).format(_totalBiaya),
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: primaryColor),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
                      child: const Text("Sudah termasuk biaya transport Rp 25.000", style: TextStyle(fontSize: 12, color: Colors.black54)),
                    )
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Tombol Submit
              SizedBox(
                height: 56, // Touch friendly
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor, 
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), 
                    elevation: 4,
                    shadowColor: primaryColor.withOpacity(0.4)
                  ),
                  onPressed: _submitPendaftaran,
                  child: const Text("Jadwalkan Kunjungan", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
        if (_isLoading) const Center(child: CircularProgressIndicator())
      ],
    );
  }

  // ==========================================
  // TAB 2: RIWAYAT
  // ==========================================
  Widget _buildHistoryTab(Color primaryColor) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_history.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history_toggle_off, size: 60, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text("Belum ada riwayat Home Visit", style: TextStyle(color: Colors.grey.shade500, fontSize: 16, fontWeight: FontWeight.w500)),
          ],
        )
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _history.length,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final item = _history[index];
        
        final String status = (item['status'] ?? 'pending').toString().toLowerCase();
        final String namaKlinik = (item['klinik'] ?? 'Klinik').toString();
        final String tanggalStr = (item['tanggal'] ?? '').toString();
        final String namaHewan = (item['hewan'] ?? 'Hewan').toString();
        final String keluhan = (item['keluhan'] ?? '-').toString();
        final String paymentUrl = (item['payment_url'] ?? '').toString();

        Color badgeColor = Colors.blue;
        if (['dijadwalkan', 'sudah_dibayar', 'diperjalanan'].contains(status)) badgeColor = Colors.green;
        if (status == 'menunggu_pembayaran') badgeColor = Colors.orange;
        if (status == 'dibatalkan' || status == 'ditolak') badgeColor = Colors.red;

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey.shade100),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(child: Text(namaKlinik, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E293B)), maxLines: 1, overflow: TextOverflow.ellipsis)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(color: badgeColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                    child: Text(status.toUpperCase().replaceAll('_', ' '), style: TextStyle(color: badgeColor, fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                  const SizedBox(width: 6),
                  Text(tanggalStr, style: const TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.w500)),
                ],
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Divider(height: 1, color: Color(0xFFEEEEEE)),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.pets, size: 18, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(child: Text(namaHewan, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: Color(0xFF1E293B)))),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline, size: 18, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(child: Text(keluhan, style: TextStyle(fontSize: 14, color: Colors.grey.shade600, height: 1.5))),
                ],
              ),
              
              if (!['dibatalkan', 'ditolak', 'menunggu_pembayaran'].contains(status)) ...[
                const SizedBox(height: 20),
                _buildStepper(status, primaryColor),
              ],

              if (status == 'menunggu_pembayaran' && paymentUrl.isNotEmpty) ...[
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () async {
                      final url = Uri.parse(paymentUrl);
                      if (await canLaunchUrl(url)) await launchUrl(url);
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
                    child: const Text("Lanjut Pembayaran", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                )
              ]
            ],
          ),
        );
      },
    );
  }

  // --- WIDGET BANTUAN UI ---
  Widget _buildInputLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: Color(0xFF1E293B))),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.grey, fontSize: 16),
      fillColor: Colors.grey.shade50,
      filled: true,
      // Input padding minimum 12px vertical/horizontal. We use 16px to ensure height >= 48px
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF0F6E56))),
    );
  }

  Widget _buildDropdown({required String hint, required String? value, required List<DropdownMenuItem<String>> items, required Function(String?) onChanged}) {
    return Container(
      // Dropdown -> 44px min, expand chevron zone. 
      constraints: const BoxConstraints(minHeight: 48),
      decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), // Padding inside container
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          hint: Text(hint, style: const TextStyle(color: Colors.grey, fontSize: 16)),
          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.grey, size: 24),
          value: value,
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }

  // --- CUSTOM STEPPER TRACKER ---
  Widget _buildStepper(String status, Color primaryColor) {
    int currentIndex = -1;
    if (['sudah_dibayar', 'dijadwalkan', 'menunggu_konfirmasi'].contains(status)) currentIndex = 1;
    if (status == 'diperjalanan') currentIndex = 2;
    if (status == 'selesai') currentIndex = 3;

    return Container(
      padding: const EdgeInsets.only(top: 10),
      child: Row(
        children: [
          _buildStepIcon(Icons.assignment, "Diproses", currentIndex >= 0, primaryColor),
          _buildStepLine(currentIndex >= 1, primaryColor),
          _buildStepIcon(Icons.local_hospital, "Dijadwal", currentIndex >= 1, primaryColor),
          _buildStepLine(currentIndex >= 2, primaryColor),
          _buildStepIcon(Icons.directions_car, "Otw", currentIndex >= 2, primaryColor),
          _buildStepLine(currentIndex >= 3, primaryColor),
          _buildStepIcon(Icons.flag, "Selesai", currentIndex >= 3, primaryColor),
        ],
      ),
    );
  }

  Widget _buildStepIcon(IconData icon, String label, bool isActive, Color color) {
    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 32, height: 32,
          decoration: BoxDecoration(
            color: isActive ? color : Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: isActive ? color : Colors.grey.shade300, width: 2),
            boxShadow: isActive ? [BoxShadow(color: color.withOpacity(0.3), blurRadius: 6, offset: const Offset(0, 2))] : [],
          ),
          child: Icon(icon, size: 16, color: isActive ? Colors.white : Colors.grey.shade400),
        ),
        const SizedBox(height: 6),
        Text(label, style: TextStyle(fontSize: 10, fontWeight: isActive ? FontWeight.bold : FontWeight.w500, color: isActive ? color : Colors.grey)),
      ],
    );
  }

  Widget _buildStepLine(bool isActive, Color color) {
    return Expanded(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        height: 2,
        margin: const EdgeInsets.only(bottom: 20),
        color: isActive ? color : Colors.grey.shade200,
      ),
    );
  }
}