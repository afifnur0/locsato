// lib/history_screen.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'models.dart'; 
import 'config.dart';
import 'widgets/consultation_card.dart'; // Import Widget Baru

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<ConsultationModel> _historyList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  Future<void> _fetchHistory() async {
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
          final allData = jsonList.map((e) => ConsultationModel.fromJson(e)).toList();
          
          // FILTER: Hanya tampilkan yang SUDAH BERAKHIR (Selesai / Dibatalkan)
          // Agar yang masih berjalan tampilnya di halaman Konsultasi saja
          _historyList = allData.where((item) => 
             item.status.toLowerCase() == 'selesai' || item.status.toLowerCase() == 'dibatalkan'
          ).toList();
          
          _isLoading = false;
        });
      } else {
        throw Exception("Gagal memuat riwayat");
      }
    } catch (e) {
      if(mounted) setState(() => _isLoading = false);
      print("Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF3C8085);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F6),
      appBar: AppBar(
        title: const Text("Riwayat Selesai", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: primaryColor))
        : _historyList.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.history_edu, size: 80, color: Colors.grey),
                    const SizedBox(height: 16),
                    const Text("Belum ada riwayat selesai.", style: TextStyle(color: Colors.grey, fontSize: 16)),
                  ],
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: _historyList.length,
                itemBuilder: (context, index) {
                  // Gunakan Widget Card yang baru agar seragam
                  return ConsultationCard(item: _historyList[index], primaryColor: primaryColor);
                },
              ),
    );
  }
}