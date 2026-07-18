import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'login_screen.dart'; 
import 'config.dart';

class KlinikDashboardScreen extends StatefulWidget {
  const KlinikDashboardScreen({super.key});

  @override
  State<KlinikDashboardScreen> createState() => _KlinikDashboardScreenState();
}

class _KlinikDashboardScreenState extends State<KlinikDashboardScreen> {
  // Warna Tema LocSato
  final Color primaryColor = const Color(0xFF0F766E);
  final Color primaryHover = const Color(0xFF115E59);
  final Color lightColor = const Color(0xFFCCFBF1);
  final Color bgColor = const Color(0xFFF4F7F6);
  final Color textMuted = const Color(0xFF64748B);

  bool _isOpen = true;
  late Timer _timer;
  DateTime _currentTime = DateTime.now();

  // STATE VARIABEL REAL DARI API
  bool _isLoading = true;
  String _namaKlinik = "Memuat data...";
  int _totalProduk = 0;
  int _pesananPetshop = 0;
  int _homeVisitAktif = 0;
  int _pendapatanHariIni = 0;
  int _pendapatanBulanIni = 0;
  int _saldoTersedia = 0;
  
  // LIST BARU UNTUK MENAMPUNG ANTREAN
  List<dynamic> _antreanVisits = [];

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('id_ID', null);
    _fetchDashboardData();

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

 // --- AMBIL DATA DASHBOARD DARI API ---
  Future<void> _fetchDashboardData() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    print("=== DEBUG API DASHBOARD KLINIK ===");
    print("Token: $token");

    if (token == null) {
      print("Error: Token kosong / Belum Login!");
      setState(() => _isLoading = false);
      return;
    }

    try {
      final url = Uri.parse('${AppConfig.baseUrl}/api/klinik/dashboard');
      print("Request URL: $url");

      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      print("Status Code: ${response.statusCode}");
      print("Response Body: ${response.body}");

      if (response.statusCode == 200) {
        final jsonResp = jsonDecode(response.body);
        if (jsonResp['status'] == 'success') {
          final data = jsonResp['data'];
          if (mounted) {
            setState(() {
              _namaKlinik = data['klinik_nama'] ?? "Klinik LocSato";
              _isOpen = data['is_open'] ?? false;
              _totalProduk = data['total_produk'] ?? 0;
              _pesananPetshop = data['pesanan_petshop'] ?? 0;
              _homeVisitAktif = data['home_visit_aktif'] ?? 0;
              _pendapatanHariIni = data['pendapatan_hari_ini'] ?? 0;
              _pendapatanBulanIni = data['pendapatan_bulan_ini'] ?? 0;
              _saldoTersedia = data['saldo_tersedia'] ?? 0;
              
              _antreanVisits = data['antrean_visits'] ?? []; 
              _isLoading = false;
            });
            print("Sukses: Data berhasil dimasukkan ke state Flutter!");
          }
        } else {
          print("API mengembalikan status selain success");
          setState(() => _isLoading = false);
        }
      } else {
        print("Error HTTP: Server menolak request.");
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print("Exception Error: $e");
      setState(() => _isLoading = false);
    }
    print("=== END DEBUG ===");
  }
  

  // --- UPDATE STATUS OPERASIONAL KE API ---
  Future<void> _updateOperationalStatus(bool isOpen) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) return;

    try {
      final url = Uri.parse('${AppConfig.baseUrl}/api/klinik/update-status');
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'is_open': isOpen}),
      );

      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(isOpen ? "Klinik dibuka" : "Klinik ditutup sementara"), 
              backgroundColor: isOpen ? Colors.green : Colors.orange,
              duration: const Duration(seconds: 2)
            )
          );
        }
      }
    } catch (e) {
      print("Error update status: $e");
    }
  }

  void _logout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Keluar"),
        content: const Text("Apakah Anda yakin ingin keluar dari Panel Klinik?"),
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

  String formatRupiah(int amount) {
    return NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0).format(amount);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text("Dashboard Klinik", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: primaryColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            tooltip: "Keluar",
            onPressed: _logout,
          ),
        ],
      ),
      body: _isLoading 
        ? Center(child: CircularProgressIndicator(color: primaryColor))
        : SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. HEADER & JAM REALTIME
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_namaKlinik, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: primaryColor)),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(10)),
                              child: const Text("Panel Vendor", style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(DateFormat('HH:mm:ss', 'id_ID').format(_currentTime) + " WIB", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryColor)),
                          Text(DateFormat('EEEE, dd MMM yyyy', 'id_ID').format(_currentTime), style: TextStyle(fontSize: 11, color: textMuted)),
                        ],
                      )
                    ],
                  ),
                ),

                // 2. TOGGLE OPERASIONAL
                Container(
                  margin: const EdgeInsets.all(20),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(50), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))]),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.storefront, color: _isOpen ? Colors.green : Colors.red),
                          const SizedBox(width: 10),
                          Text(_isOpen ? "Buka (Operasional)" : "Tutup Sementara", style: TextStyle(fontWeight: FontWeight.bold, color: _isOpen ? Colors.green : Colors.red)),
                        ],
                      ),
                      Switch(
                        value: _isOpen,
                        activeColor: primaryColor,
                        onChanged: (val) {
                          setState(() {
                            _isOpen = val;
                          });
                          _updateOperationalStatus(val);
                        },
                      )
                    ],
                  ),
                ),

                // 3. STATISTIK GRID DINAMIS
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: 15,
                    mainAxisSpacing: 15,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    childAspectRatio: 1.2, 
                    children: [
                      _buildStatCard("Total Produk", _totalProduk.toString(), "Item", Icons.inventory_2, lightColor, primaryColor),
                      _buildStatCard("Pesanan Petshop", _pesananPetshop.toString(), "Order", Icons.shopping_bag, const Color(0xFFE0F2FE), const Color(0xFF0284C7)),
                      _buildStatCard("Home Visit Aktif", _homeVisitAktif.toString(), "Visit", Icons.medical_services, const Color(0xFFFEF3C7), const Color(0xFFD97706)),
                      _buildStatCard("Pendapatan Hari Ini", formatRupiah(_pendapatanHariIni), "", Icons.account_balance_wallet, const Color(0xFFD1FAE5), const Color(0xFF059669)),
                      _buildStatCard("Total Bulan Ini", formatRupiah(_pendapatanBulanIni), "", Icons.payments, const Color(0xFFFCE7F3), const Color(0xFFDB2777)),
                    ],
                  ),
                ),

                // KARTU KHUSUS: SALDO
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [primaryColor, primaryHover], begin: Alignment.topLeft, end: Alignment.bottomRight),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(color: primaryColor.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 5))],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(15)),
                              child: const Icon(Icons.account_balance_wallet, color: Colors.white, size: 30),
                            ),
                            const SizedBox(width: 15),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text("Saldo Bisa Ditarik", style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 5),
                                Text(formatRupiah(_saldoTersedia), style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ],
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: primaryColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Fitur Penarikan Dana segera hadir.")));
                          },
                          child: const Text("Tarik", style: TextStyle(fontWeight: FontWeight.bold)),
                        )
                      ],
                    ),
                  ),
                ),

                // 4. ANTREAN HOME VISIT (DINAMIS)
                _buildSectionHeader("Antrean Home Visit", "Kelola pesanan masuk dan jadwal kunjungan."),
                _antreanVisits.isEmpty
                    ? _buildEmptyState(Icons.inbox, "Belum Ada Pesanan", "Pesanan Home Visit dari pelanggan akan muncul di sini.")
                    : _buildAntreanList(),

                const SizedBox(height: 20),

                _buildSectionHeader("Riwayat Penarikan Dana", "Status pengajuan pencairan saldo Anda."),
                _buildEmptyState(Icons.receipt_long, "Belum ada riwayat", "Belum ada riwayat penarikan dana."),

                const SizedBox(height: 40),
              ],
            ),
          ),
    );
  }

  // --- WIDGET HELPER ---
  
  Widget _buildAntreanList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _antreanVisits.length,
      itemBuilder: (context, index) {
        final visit = _antreanVisits[index];
        
        // Penentuan warna badge status
        Color statusBgColor;
        Color statusTextColor;
        String statusText = (visit['status'] ?? '').toString().replaceAll('_', ' ').toUpperCase();
        
        if (visit['status'] == 'dijadwalkan' || visit['status'] == 'sudah_dibayar' || visit['status'] == 'berjalan') {
          statusBgColor = const Color(0xFFECFDF5);
          statusTextColor = const Color(0xFF059669); // Hijau
        } else if (visit['status'] == 'menunggu_persetujuan' || visit['status'] == 'menunggu_pembayaran') {
          statusBgColor = const Color(0xFFFFFBEB);
          statusTextColor = const Color(0xFFD97706); // Kuning/Oranye
        } else {
          statusBgColor = const Color(0xFFF1F5F9);
          statusTextColor = const Color(0xFF475569); // Abu-abu
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 15),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 4))
            ]
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Card (No Order & Status)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    visit['no_order'] ?? '-', 
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusBgColor,
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: Text(
                      statusText,
                      style: TextStyle(color: statusTextColor, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  )
                ],
              ),
              const SizedBox(height: 12),
              
              // Tengah Card (Jadwal & Profil Pasien)
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(10)),
                    child: Icon(Icons.calendar_month, color: primaryColor, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(visit['schedule'] ?? '-', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(Icons.person, size: 12, color: Colors.grey.shade600),
                            const SizedBox(width: 4),
                            Text("${visit['pelanggan']} • ", style: TextStyle(color: Colors.grey.shade600, fontSize: 11)),
                            Icon(Icons.pets, size: 12, color: primaryColor),
                            const SizedBox(width: 4),
                            Text(visit['hewan'], style: TextStyle(color: primaryColor, fontSize: 11, fontWeight: FontWeight.w600)),
                          ],
                        )
                      ],
                    ),
                  )
                ],
              ),
              
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 10),
                child: Divider(height: 1),
              ),
              
              // Bawah Card (Layanan & Biaya)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      visit['services'] ?? '-', 
                      maxLines: 1, 
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, color: Colors.grey)
                    ),
                  ),
                  Text(
                    formatRupiah(visit['estimated_cost'] ?? 0), 
                    style: TextStyle(fontWeight: FontWeight.w900, color: primaryColor, fontSize: 14)
                  ),
                ],
              )
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatCard(String title, String value, String suffix, IconData icon, Color iconBg, Color iconColor) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.shade200), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const Spacer(),
          Text(title, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: textMuted), maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: const Color(0xFF1E293B))),
              if (suffix.isNotEmpty) ...[
                const SizedBox(width: 4),
                Text(suffix, style: const TextStyle(fontSize: 10, color: Colors.grey)),
              ]
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryColor)),
          Text(subtitle, style: TextStyle(fontSize: 12, color: textMuted)),
        ],
      ),
    );
  }

  Widget _buildEmptyState(IconData icon, String title, String subtitle) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.shade200)),
      child: Center(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.grey.shade100, shape: BoxShape.circle),
              child: Icon(icon, size: 40, color: Colors.grey.shade400),
            ),
            const SizedBox(height: 15),
            Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
            const SizedBox(height: 5),
            Text(subtitle, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}