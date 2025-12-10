import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Jangan lupa: flutter pub add intl
import '../models.dart';
import '../config.dart';

class ConsultationCard extends StatelessWidget {
  final ConsultationModel item;
  final Color primaryColor;

  const ConsultationCard({super.key, required this.item, required this.primaryColor});

  @override
  Widget build(BuildContext context) {
    // Format Tanggal: "Minggu, 7 Des 2025"
    String formattedDate = item.tanggal;
    try {
      final date = DateTime.parse(item.tanggal);
      formattedDate = DateFormat('EEEE, d MMM y', 'id_ID').format(date); // Perlu locale Indonesia
    } catch (e) {
      formattedDate = item.tanggal;
    }

    // Warna Status
    Color statusColor;
    Color statusBgColor;
    String statusText = item.status.toUpperCase(); // DIJADWALKAN / SELESAI

    if (item.status == 'selesai') {
      statusColor = Colors.green;
      statusBgColor = Colors.green.shade50;
    } else if (item.status == 'dibatalkan') {
      statusColor = Colors.red;
      statusBgColor = Colors.red.shade50;
    } else {
      statusColor = Colors.orange;
      statusBgColor = Colors.orange.shade50;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // HEADER: TANGGAL & STATUS
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                    const SizedBox(width: 6),
                    Text(formattedDate, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87)),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: statusBgColor, borderRadius: BorderRadius.circular(20)),
                  child: Text(statusText, style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
          
          const Divider(height: 24),

          // ISI: DOKTER & KELUHAN
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Foto Dokter
                CircleAvatar(
                  radius: 28,
                  backgroundImage: NetworkImage(
                    item.fotoDokter != null 
                      ? '${AppConfig.baseUrl}/storage/${item.fotoDokter}' 
                      : 'https://ui-avatars.com/api/?name=${Uri.encodeComponent(item.namaDokter)}'
                  ),
                ),
                const SizedBox(width: 16),
                
                // Detail
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Dr. ${item.namaDokter}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      const SizedBox(height: 4),
                      Text("Pasien: ${item.namaHewan}", style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                      const SizedBox(height: 8),
                      
                      // KELUHAN (Supaya user ingat ini konsultasi apa)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(8)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Keluhan:", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: primaryColor)),
                            const SizedBox(height: 2),
                            Text(
                              "\"${item.keluhan}\"", // Menampilkan catatan user (flu, mabok, dll)
                              style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 12),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}