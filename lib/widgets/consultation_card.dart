import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models.dart';
import '../config.dart';

class ConsultationCard extends StatelessWidget {
  final ConsultationModel item;
  final Color primaryColor;

  const ConsultationCard({
    super.key,
    required this.item,
    required this.primaryColor,
  });

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
    Color borderColor;
    Color statusColor;
    String statusText;
    IconData statusIcon;

    switch (item.status.toLowerCase()) {
      case 'dijadwalkan':
        borderColor = Colors.green; statusColor = Colors.green; statusText = "Terjadwal"; statusIcon = Icons.check_circle; break;
      case 'menunggu_pembayaran':
      case 'pending':
        borderColor = Colors.orange; statusColor = Colors.orange; statusText = "Menunggu Bayar"; statusIcon = Icons.account_balance_wallet; break;
      case 'proses':
        borderColor = Colors.blue; statusColor = Colors.blue; statusText = "Sedang Chat"; statusIcon = Icons.chat; break;
      case 'selesai':
        borderColor = Colors.green; statusColor = Colors.green; statusText = "Selesai"; statusIcon = Icons.check_circle; break;
      case 'menunggu_refund':
        borderColor = Colors.orange; statusColor = Colors.orange; statusText = "Menunggu Refund"; statusIcon = Icons.access_time; break;
      case 'refund_selesai':
        borderColor = Colors.green; statusColor = Colors.green; statusText = "Refund Selesai"; statusIcon = Icons.check_circle; break;
      default: // dibatalkan
        borderColor = Colors.red; statusColor = Colors.red; statusText = "Dibatalkan"; statusIcon = Icons.cancel;
    }

    bool isCancelled = item.status.toLowerCase() == 'dibatalkan';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Garis Warna Samping
            Container(width: 5, decoration: BoxDecoration(color: borderColor, borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)))),
            
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header: Info Dokter & Status
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(50),
                          child: Image.network(
                            _getDoctorImageUrl(item.dokter?.fotodokter ?? item.dokter?.foto, item.dokter?.nama ?? 'Dokter'),
                            width: 50, height: 50, fit: BoxFit.cover,
                            color: isCancelled ? Colors.grey : null,
                            colorBlendMode: isCancelled ? BlendMode.saturation : null,
                            errorBuilder: (ctx, err, stack) => Container(width: 50, height: 50, color: Colors.grey[200], child: const Icon(Icons.person, color: Colors.grey)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item.dokter?.nama ?? 'Unknown', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, decoration: isCancelled ? TextDecoration.lineThrough : null)),
                              const SizedBox(height: 4),
                              Text(item.dokter?.spesialisasi ?? 'Umum', style: const TextStyle(color: Color(0xFF0F766E), fontSize: 12, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: statusColor.withOpacity(0.1), border: Border.all(color: statusColor.withOpacity(0.5)), borderRadius: BorderRadius.circular(20)),
                          child: Row(
                            children: [
                              Icon(statusIcon, size: 12, color: statusColor),
                              const SizedBox(width: 4),
                              Text(statusText, style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        )
                      ],
                    ),
                    const Divider(height: 24, color: Color(0xFFEEEEEE)),
                    
                    // Body: Info Jadwal & Hewan
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("JADWAL KONSULTASI", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.calendar_month, size: 14, color: Color(0xFF0F766E)),
                                  const SizedBox(width: 4),
                                  Text(
                                    item.tanggalKonsultasi != '-' && item.tanggalKonsultasi.isNotEmpty 
                                      ? DateFormat('dd MMM yyyy', 'id_ID').format(DateTime.tryParse(item.tanggalKonsultasi) ?? DateTime.now()) 
                                      : '-', 
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("PASIEN", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.pets, size: 14, color: Colors.orange),
                                  const SizedBox(width: 4),
                                  Text(item.hewan?.nama ?? 'Dihapus', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),
                    
                    // Catatan Box
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: Colors.grey.shade50, border: Border.all(color: Colors.grey.shade200), borderRadius: BorderRadius.circular(8)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.catatanDokter != null ? "Catatan Dokter:" : "Keluhan:", style: TextStyle(color: item.catatanDokter != null ? Colors.green : Colors.grey.shade700, fontSize: 11, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 2),
                          Text('"${item.catatanDokter ?? item.catatan ?? 'Tidak ada catatan'}"', style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic)),
                        ],
                      ),
                    )
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}