// lib/upcoming_schedule_screen.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'models.dart'; 
import 'config.dart';
import 'widgets/consultation_card.dart'; // Reuse widget card yang cantik tadi

class UpcomingScheduleScreen extends StatefulWidget {
  const UpcomingScheduleScreen({super.key});

  @override
  State<UpcomingScheduleScreen> createState() => _UpcomingScheduleScreenState();
}

class _UpcomingScheduleScreenState extends State<UpcomingScheduleScreen> {
  List<ConsultationModel> _upcomingList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUpcomingSchedules();
  }

  Future<void> _fetchUpcomingSchedules() async {
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
          
          // FILTER KHUSUS: Hanya yang statusnya MASIH AKTIF
          _upcomingList = allData.where((item) => 
             item.status.toLowerCase() == 'dijadwalkan' || 
             item.status.toLowerCase() == 'pending'
          ).toList();
          
          _isLoading = false;
        });
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
        title: const Text("Jadwal Akan Datang", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.orange, // Warna beda dikit biar mencolok (warning/schedule)
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: Colors.orange))
        : _upcomingList.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.event_busy, size: 80, color: Colors.grey),
                    const SizedBox(height: 16),
                    const Text("Tidak ada jadwal konsultasi mendatang.", style: TextStyle(color: Colors.grey, fontSize: 16)),
                  ],
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: _upcomingList.length,
                itemBuilder: (context, index) {
                  return ConsultationCard(item: _upcomingList[index], primaryColor: primaryColor);
                },
              ),
    );
  }
}