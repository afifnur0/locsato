import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

// Import Config Anda (Pastikan path-nya benar)
import '../config.dart'; // Sesuaikan path '../' jika file config ada di luar folder screens

class HomeVisitScreen extends StatefulWidget {
  const HomeVisitScreen({Key? key}) : super(key: key);

  @override
  State<HomeVisitScreen> createState() => _HomeVisitScreenState();
}

class _HomeVisitScreenState extends State<HomeVisitScreen> {
  bool isLoading = true;

  // --- VARIABLES ---
  List<dynamic> myPets = []; 
  List<dynamic> visitHistory = [];
  
  // Form Inputs
  int? selectedPetId; // Menyimpan ID Hewan (Integer)
  TextEditingController dateController = TextEditingController();
  DateTime? selectedDate;
  int estimatedPrice = 0;

  // Layanan (Services)
  List<Map<String, dynamic>> treatments = [
    {"name": "Vaksinasi", "price": 100000, "isChecked": false},
    {"name": "Grooming", "price": 75000, "isChecked": false},
    {"name": "Sterilisasi", "price": 150000, "isChecked": false},
  ];

  @override
  void initState() {
    super.initState();
    _fetchHomeVisitData();
  }

  String formatRupiah(int number) {
    final currencyFormatter = NumberFormat.currency(locale: 'id', symbol: 'Rp', decimalDigits: 0);
    return currencyFormatter.format(number);
  }

  // --- 1. LOAD DATA DARI LARAVEL (FULL VERSION) ---
  Future<void> _fetchHomeVisitData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    // URL 1: Data Hewan (PetController)
    final urlPets = Uri.parse('${AppConfig.baseUrl}/api/pets');
    // URL 2: Data History (HomVisitController) - SUDAH ADA SEKARANG!
    final urlHistory = Uri.parse('${AppConfig.baseUrl}/api/home-visit-history');

    try {
      // A. REQUEST DATA HEWAN
      final responsePets = await http.get(
        urlPets,
        headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
      );

      // B. REQUEST DATA HISTORY
      final responseHistory = await http.get(
        urlHistory,
        headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
      );

      // Debugging Output
      // print("Pets Status: ${responsePets.statusCode}");
      print("History Status: ${responseHistory.statusCode}");
      print("History Body: ${responseHistory.body}");

      List<dynamic> fetchedPets = [];
      List<dynamic> fetchedHistory = [];

      // Proses Response Hewan
      if (responsePets.statusCode == 200) {
        final jsonPets = json.decode(responsePets.body);
        if (jsonPets['status'] == 'success') {
          fetchedPets = jsonPets['data']; 
        }
      }

      // Proses Response History
      if (responseHistory.statusCode == 200) {
        final jsonHistory = json.decode(responseHistory.body);
        if (jsonHistory['status'] == 'success') {
          fetchedHistory = jsonHistory['data'];
        }
      }

      if (mounted) {
        setState(() {
          myPets = fetchedPets;
          visitHistory = fetchedHistory; // <--- ISI DATA HISTORY
          isLoading = false;
        });
      }

    } catch (e) {
      print("Error koneksi: $e");
      if (mounted) setState(() => isLoading = false);
    }
  }

  // --- 2. KIRIM DATA KE LARAVEL ---
  Future<void> _submitSchedule() async {
    if (selectedPetId == null || selectedDate == null || estimatedPrice == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Lengkapi data hewan, tanggal, dan layanan.")),
      );
      return;
    }

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');
    
    // Endpoint Simpan Jadwal
    final url = Uri.parse('${AppConfig.baseUrl}/api/home-visit');

    // Ambil layanan yang dicentang
    List<String> selectedServices = treatments
        .where((t) => t['isChecked'] == true)
        .map((t) => t['name'] as String)
        .toList();

    try {
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({
          'pet_id': selectedPetId, 
          'schedule': DateFormat('yyyy-MM-dd').format(selectedDate!),
          'services': selectedServices, 
          'estimated_cost': estimatedPrice, 
        }),
      );

      print("Submit Status: ${response.statusCode}");

      if (response.statusCode == 201 || response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Berhasil! Kunjungan telah dijadwalkan.")),
        );
        
        // Reset Form UI
        setState(() {
          selectedPetId = null;
          dateController.clear();
          selectedDate = null;
          estimatedPrice = 0;
          for (var t in treatments) t['isChecked'] = false;
        });
        
        // Refresh Data (Ambil ulang history terbaru)
        _fetchHomeVisitData(); 

      } else {
        final msg = json.decode(response.body)['message'] ?? "Gagal menyimpan";
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Gagal: $msg"), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
      );
    }
  }

  void _calculateTotal() {
    int total = 0;
    for (var item in treatments) {
      if (item['isChecked'] == true) total += (item['price'] as int);
    }
    setState(() { estimatedPrice = total; });
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        selectedDate = picked;
        dateController.text = DateFormat('MM/dd/yyyy').format(picked);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Home Visit"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: isLoading 
          ? const Center(child: CircularProgressIndicator()) 
          : SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Banner Info
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0F2F1), 
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.teal.shade100),
                  ),
                  child: const Text(
                    "Jadwalkan kunjungan dokter ke rumah Anda.",
                    style: TextStyle(color: Colors.teal, fontWeight: FontWeight.w500),
                  ),
                ),

                const Text("Jadwalkan Kunjungan", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.teal)),
                const SizedBox(height: 10),
                
                // --- CARD FORMULIR ---
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Pilih Hewan:", style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        
                        // LOGIK DROPDOWN
                        if (myPets.isEmpty)
                           Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF8E1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFFFFECB3)),
                            ),
                            child: const Text("Anda belum punya hewan. Silakan tambah di menu Profile.", style: TextStyle(fontSize: 13, color: Colors.orange)),
                          )
                        else
                          DropdownButtonFormField<int>(
                            value: selectedPetId,
                            isExpanded: true,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              filled: true,
                              fillColor: Colors.grey.shade50,
                            ),
                            hint: const Text("Pilih hewan peliharaan"),
                            // Mapping items dari JSON Laravel
                            items: myPets.map((pet) {
                              return DropdownMenuItem<int>(
                                value: pet['id_hewan'], // Value = ID
                                child: Text(pet['nama']), // Tampilan = Nama
                              );
                            }).toList(),
                            onChanged: (val) => setState(() => selectedPetId = val),
                          ),

                        const SizedBox(height: 16),

                        const Text("Tanggal Kunjungan:", style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        TextField(
                          controller: dateController,
                          readOnly: true,
                          decoration: InputDecoration(
                            hintText: "mm/dd/yyyy",
                            suffixIcon: const Icon(Icons.calendar_today_outlined),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                          ),
                          onTap: () => _selectDate(context),
                        ),

                        const SizedBox(height: 16),
                        const Text("Pilih Layanan:", style: TextStyle(fontWeight: FontWeight.bold)),
                        
                        ...treatments.map((t) => CheckboxListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text("${t['name']} - ${formatRupiah(t['price'])}"),
                          value: t['isChecked'],
                          activeColor: Colors.teal,
                          controlAffinity: ListTileControlAffinity.trailing,
                          onChanged: (val) {
                            setState(() { t['isChecked'] = val; _calculateTotal(); });
                          },
                        )).toList(),

                        const SizedBox(height: 10),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Text("Total: ${formatRupiah(estimatedPrice)}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.orange)),
                        ),

                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: (myPets.isEmpty) ? null : _submitSchedule,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.teal,
                              disabledBackgroundColor: Colors.grey.shade300,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            child: const Text("Buat Jadwal", style: TextStyle(color: Colors.white, fontSize: 16)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                // --- RIWAYAT KUNJUNGAN ---
                const Text("Riwayat Kunjungan", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.teal)),
                const Divider(),
                
                if (visitHistory.isEmpty)
                   const Padding(
                     padding: EdgeInsets.all(20),
                     child: Center(child: Text("Belum ada kunjungan yang dijadwalkan.")),
                   )
                else
                   ListView.builder(
                     shrinkWrap: true,
                     physics: const NeverScrollableScrollPhysics(),
                     itemCount: visitHistory.length,
                    itemBuilder: (context, index) {
                       final visit = visitHistory[index];
                       
                       // Penanganan Null Safety & Konversi Tipe Data (SOLUSI ERROR MERAH)
                       String petName = visit['pet_name'] ?? (visit['hewan'] != null ? visit['hewan']['nama'] : 'Hewan Dihapus');
                       String status = visit['status'] ?? 'pending';
                       
                       // Handle services: Jika array, gabungkan jadi string. Jika string, pakai langsung.
                       String services = '-';
                       if (visit['services'] is List) {
                         services = (visit['services'] as List).join(', ');
                       } else {
                         services = visit['services']?.toString() ?? '-';
                       }

                       // --- [BAGIAN INI YANG DIPERBAIKI] ---
                       // Kita ubah apapun yang datang jadi String dulu, baru dipaksa jadi Int
                       int cost = int.tryParse(visit['estimated_cost'].toString()) ?? 0;
                       // ------------------------------------

                       String date = visit['schedule'] ?? '-';

                       return Card(
                         // ... (sisa kode Card ke bawah sama persis, tidak perlu diubah)
                         margin: const EdgeInsets.only(bottom: 12),
                         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                         child: Padding(
                           padding: const EdgeInsets.all(16.0),
                           child: Column(
                             crossAxisAlignment: CrossAxisAlignment.start,
                             children: [
                               Row(
                                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                 children: [
                                   Text(date, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.teal)),
                                   Container(
                                     padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                     decoration: BoxDecoration(
                                       color: status == 'pending' ? Colors.orange.shade100 : Colors.green.shade100,
                                       borderRadius: BorderRadius.circular(4)
                                     ),
                                     child: Text(status.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: status == 'pending' ? Colors.deepOrange : Colors.green)),
                                   )
                                 ],
                               ),
                               const SizedBox(height: 8),
                               Row(
                                 children: [
                                   const Icon(Icons.pets, size: 16, color: Colors.grey),
                                   const SizedBox(width: 5),
                                   Text(petName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                 ],
                               ),
                               const SizedBox(height: 4),
                               Text("Layanan: $services", style: TextStyle(color: Colors.grey.shade700)),
                               const Divider(),
                               Align(
                                 alignment: Alignment.centerRight,
                                 child: Text("Biaya: ${formatRupiah(cost)}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
                               )
                             ],
                           ),
                         ),
                       );
                     },
                   ),
                 const SizedBox(height: 50),
              ],
            ),
          ),
    );
  }
}