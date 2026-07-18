  import 'package:flutter/material.dart';
  import 'package:fl_chart/fl_chart.dart'; // Pastikan package ini sudah diinstall
  import 'package:http/http.dart' as http;
  import 'dart:convert';
  import 'config.dart'; 
  import 'package:shared_preferences/shared_preferences.dart';
  import 'login_screen.dart'; 

  class AdminDashboardScreen extends StatefulWidget {
    const AdminDashboardScreen({super.key});

    @override
    State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
  }

  class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
    final Color primaryColor = const Color(0xFF3C8085);
    final Color bgSoft = const Color(0xFFF8FAFC);

    // Data Statistik
    int totalDokter = 0;
    int totalPemilik = 0;
    int totalProduk = 0;
    int konsultasiAktif = 0;
    
    // Data Grafik
    List<int> chartKonsultasi = [0, 0, 0, 0, 0, 0, 0];
    List<int> chartUser = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];

    bool isLoading = true;

    @override
    void initState() {
      super.initState();
      _fetchDashboardData();
    }

    // --- AMBIL DATA DARI SERVER ---
    Future<void> _fetchDashboardData() async {
      try {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('token'); // Ambil token
        
        final url = Uri.parse('${AppConfig.baseUrl}/api/admin/dashboard-stats');
        
        final response = await http.get(
          url,
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer $token', // <--- HAPUS TANDA // DISINI
          },
        );
        
        // ... sisa kode sama ...

        if (response.statusCode == 200) {
          final body = jsonDecode(response.body);
          if(body['status'] == 'success') {
            final data = body['data'];
            if (mounted) {
              setState(() {
                totalDokter = data['total_dokter'];
                totalPemilik = data['total_pemilik'];
                totalProduk = data['total_produk'];
                konsultasiAktif = data['konsultasi_aktif'];
                
                chartKonsultasi = List<int>.from(data['chart_konsultasi']);
                chartUser = List<int>.from(data['chart_user']);
                
                isLoading = false;
              });
            }
          }
        } else {
          print("Gagal Load Data: ${response.body}");
          if (mounted) setState(() => isLoading = false);
        }
      } catch (e) {
        print("Error fetching data: $e");
        if (mounted) setState(() => isLoading = false);
      }
    }

    Future<void> _logout() async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    }

    @override
    Widget build(BuildContext context) {
      return Scaffold(
        backgroundColor: bgSoft,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: Text(
            "Admin Dashboard",
            style: TextStyle(color: Colors.grey[800], fontWeight: FontWeight.bold),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.grey),
              onPressed: () {
                setState(() => isLoading = true);
                _fetchDashboardData();
              },
            ),
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.red),
              onPressed: _logout,
            ),
            const SizedBox(width: 10),
          ],
        ),
        body: isLoading 
            ? Center(child: CircularProgressIndicator(color: primaryColor))
            : RefreshIndicator(
                onRefresh: _fetchDashboardData,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Overview", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 5),
                      Text("Data real-time LocSato", style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                      const SizedBox(height: 20),

                      // GRID KARTU
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        crossAxisSpacing: 15,
                        mainAxisSpacing: 15,
                        childAspectRatio: 1.1,
                        children: [
                          _buildStatCard("Total Dokter", totalDokter.toString(), Icons.medical_services_outlined, Colors.blue, Colors.blue.shade50),
                          _buildStatCard("Pemilik Hewan", totalPemilik.toString(), Icons.people_outline, Colors.green, Colors.green.shade50),
                          _buildStatCard("Produk Medis", totalProduk.toString(), Icons.shopping_bag_outlined, Colors.orange, Colors.orange.shade50),
                          _buildStatCard("Konsul Aktif", konsultasiAktif.toString(), Icons.chat_bubble_outline, primaryColor, primaryColor.withOpacity(0.1)),
                        ],
                      ),

                      const SizedBox(height: 30),

                      // CHART 1
                      _buildSectionTitle("Statistik Konsultasi (Minggu Ini)"),
                      const SizedBox(height: 15),
                      Container(
                        height: 250,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))]),
                        child: LineChart(
                          LineChartData(
                            gridData: const FlGridData(show: false),
                            titlesData: FlTitlesData(
                              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (value, meta) {
                                    const days = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
                                    if (value.toInt() >= 0 && value.toInt() < days.length) {
                                      return Text(days[value.toInt()], style: const TextStyle(fontSize: 10, color: Colors.grey));
                                    }
                                    return const Text('');
                                  },
                                ),
                              ),
                            ),
                            borderData: FlBorderData(show: false),
                            lineBarsData: [
                              LineChartBarData(
                                spots: List.generate(chartKonsultasi.length, (index) {
                                  return FlSpot(index.toDouble(), chartKonsultasi[index].toDouble());
                                }),
                                isCurved: true,
                                color: primaryColor,
                                barWidth: 3,
                                dotData: const FlDotData(show: true),
                                belowBarData: BarAreaData(show: true, color: primaryColor.withOpacity(0.1)),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 30),

                      // CHART 2
                      _buildSectionTitle("Pertumbuhan User (Tahun Ini)"),
                      const SizedBox(height: 15),
                      Container(
                        height: 250,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))]),
                        child: BarChart(
                          BarChartData(
                            gridData: const FlGridData(show: false),
                            titlesData: FlTitlesData(
                              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (value, meta) {
                                    if (value % 2 != 0) return const SizedBox();
                                    return Text((value.toInt() + 1).toString(), style: const TextStyle(fontSize: 10, color: Colors.grey));
                                  },
                                ),
                              ),
                            ),
                            borderData: FlBorderData(show: false),
                            barGroups: List.generate(chartUser.length, (index) {
                              return BarChartGroupData(
                                x: index,
                                barRods: [
                                  BarChartRodData(
                                    toY: chartUser[index].toDouble(),
                                    color: Colors.orange,
                                    width: 12,
                                    borderRadius: BorderRadius.circular(4),
                                    backDrawRodData: BackgroundBarChartRodData(show: true, toY: (chartUser.reduce((curr, next) => curr > next ? curr : next) + 5).toDouble(), color: Colors.grey[100]),
                                  ),
                                ],
                              );
                            }),
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
      );
    }

    Widget _buildSectionTitle(String title) {
      return Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey[800]));
    }

    Widget _buildStatCard(String title, String value, IconData icon, Color color, Color bgColor) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))]),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle), child: Icon(icon, color: color, size: 24)),
            const Spacer(),
            Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.grey[800])),
            const SizedBox(height: 4),
            Text(title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey[500])),
          ],
        ),
      );
    }
  }