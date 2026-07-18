// lib/history_screen.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'models.dart'; 
import 'config.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<ConsultationModel> _allConsultations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('id_ID', null).then((_) {
      _fetchConsultations();
    });
  }

  Future<void> _fetchConsultations() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      
      final url = Uri.parse('${AppConfig.baseUrl}/api/consultations');
      
      final response = await http.get(url, headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> jsonList = data['data'];
        
        setState(() {
          _allConsultations = jsonList.map((e) => ConsultationModel.fromJson(e)).toList();
          _isLoading = false;
        });
      } else {
        throw Exception("Gagal memuat riwayat");
      }
    } catch (e) {
      if(mounted) setState(() => _isLoading = false);
      print("Error fetch consultations: $e");
    }
  }

  // Helper Pembersih URL Foto
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
    
    // Filter Data berdasarkan Status (Sesuai Logika Website)
    final upcomingList = _allConsultations.where((item) => 
      ['dijadwalkan', 'menunggu_pembayaran', 'pending', 'proses'].contains(item.status.toLowerCase())
    ).toList();
    
    final historyList = _allConsultations.where((item) => 
      item.status.toLowerCase() == 'selesai'
    ).toList();
    
    final cancelledList = _allConsultations.where((item) => 
      ['dibatalkan', 'menunggu_refund', 'refund_selesai'].contains(item.status.toLowerCase())
    ).toList();

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F7F6),
        appBar: AppBar(
          title: const Text("Konsultasi Saya", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
          backgroundColor: primaryColor,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.white),
          bottom: const TabBar(
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            tabs: [
              Tab(text: "Akan Datang"),
              Tab(text: "Selesai"),
              Tab(text: "Dibatalkan"),
            ],
          ),
        ),
        body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: primaryColor))
          : TabBarView(
              children: [
                _buildTabContent(upcomingList, "Tidak ada jadwal mendatang.", Icons.event_busy, 'upcoming'),
                _buildTabContent(historyList, "Belum ada riwayat sukses.", Icons.history_edu, 'history'),
                _buildTabContent(cancelledList, "Tidak ada riwayat pembatalan.", Icons.folder_open, 'cancelled'),
              ],
            ),
      ),
    );
  }

  // --- BUILDER KONTEN TAB ---
  Widget _buildTabContent(List<ConsultationModel> listData, String emptyMsg, IconData emptyIcon, String type) {
    if (listData.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(emptyIcon, size: 80, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(emptyMsg, style: TextStyle(color: Colors.grey.shade600, fontSize: 16)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: listData.length,
      itemBuilder: (context, index) {
        final item = listData[index];
        return _buildConsultationCard(item, type);
      },
    );
  }

  // --- DESAIN KARTU (Native Mobile Style) ---
  Widget _buildConsultationCard(ConsultationModel item, String type) {
    Color statusColor;
    String statusText;

    // Logika Warna Status (Adaptasi dari web)
    switch (item.status.toLowerCase()) {
      case 'dijadwalkan':
        statusColor = Colors.green; statusText = "Terjadwal"; break;
      case 'menunggu_pembayaran':
      case 'pending':
        statusColor = Colors.orange; statusText = "Menunggu Bayar"; break;
      case 'proses':
        statusColor = Colors.blue; statusText = "Sedang Chat"; break;
      case 'selesai':
        statusColor = Colors.green; statusText = "Selesai"; break;
      case 'menunggu_refund':
        statusColor = Colors.orange; statusText = "Menunggu Refund"; break;
      case 'refund_selesai':
        statusColor = Colors.green; statusText = "Refund Selesai"; break;
      default: // dibatalkan
        statusColor = Colors.red; statusText = "Dibatalkan";
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
          // Header: Tanggal & Status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                DateFormat('dd MMM yyyy', 'id_ID').format(DateTime.parse(item.tanggalKonsultasi)),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              )
            ],
          ),
          const SizedBox(height: 12),
          
          // Body: Info Dokter
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  _getDoctorImageUrl(item.dokter?.fotodokter, item.dokter?.nama ?? 'Dokter'),
                  width: 50, height: 50, fit: BoxFit.cover,
                  color: type == 'cancelled' ? Colors.grey : null,
                  colorBlendMode: type == 'cancelled' ? BlendMode.saturation : null,
                  errorBuilder: (ctx, err, stack) => Container(width: 50, height: 50, color: Colors.grey[200], child: const Icon(Icons.person, color: Colors.grey)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.dokter?.nama ?? 'Unknown',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, decoration: type == 'cancelled' ? TextDecoration.lineThrough : null),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.dokter?.spesialisasi ?? 'Umum',
                      style: const TextStyle(color: Color(0xFF3C8085), fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, color: Color(0xFFEEEEEE)),
          ),
          
          // Footer: Info Hewan & Catatan
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), shape: BoxShape.circle),
                child: const Icon(Icons.pets, size: 14, color: Colors.orange),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  "Pasien: ${item.hewan?.nama ?? 'Dihapus'}",
                  style: const TextStyle(fontSize: 13, color: Colors.black87),
                ),
              ),
            ],
          ),

          if (type == 'history' && (item.catatanDokter != null || item.hasilKonsultasi != null)) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(8)),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.receipt_long, size: 16, color: Color(0xFF3C8085)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item.catatanDokter ?? item.hasilKonsultasi ?? '',
                      style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.black87),
                    ),
                  ),
                ],
              ),
            )
          ],

          if (type == 'cancelled') ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.red.withOpacity(0.05), borderRadius: BorderRadius.circular(8)),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline, size: 16, color: Colors.red),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item.catatanDokter ?? "Sesi ini telah Anda batalkan.",
                      style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.red),
                    ),
                  ),
                ],
              ),
            )
          ],
        ],
      ),
    );
  }
}