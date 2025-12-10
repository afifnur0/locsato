// lib/models.dart

// ==========================================
// 1. MODEL HEWAN (Dari API /pets)
// ==========================================
class PetModel {
  final int id;
  final String nama;
  final String spesies;
  final String? ras;
  final int? usia;

  PetModel({
    required this.id,
    required this.nama,
    required this.spesies,
    this.ras,
    this.usia,
  });

  factory PetModel.fromJson(Map<String, dynamic> json) {
    return PetModel(
      // Mapping sesuai tabel 'hewan' di database
      id: json['id_hewan'] ?? 0, 
      nama: json['nama'] ?? 'Tanpa Nama',
      spesies: json['spesies'] ?? 'Lainnya',
      ras: json['ras'] ?? '-',
      // Handle jika usia dikirim sebagai String atau Integer
      usia: json['usia'] is String ? int.tryParse(json['usia']) : json['usia'],
    );
  }
}

// ==========================================
// 2. MODEL DOKTER (Dari API /doctors)
// ==========================================
class DoctorModel {
  final int id;
  final String nama;
  final String spesialisasi;
  final String? foto;
  final bool aktif;
  final String harga; 

  DoctorModel({
    required this.id,
    required this.nama,
    required this.spesialisasi,
    this.foto,
    required this.aktif,
    required this.harga,
  });

  factory DoctorModel.fromJson(Map<String, dynamic> json) {
    return DoctorModel(
      // Mapping sesuai tabel 'dokterhewan' di database
      id: json['id_dokter'] ?? 0, 
      nama: json['nama'] ?? 'Tanpa Nama',
      spesialisasi: json['spesialisasi'] ?? 'Umum',
      
      // Pastikan backend mengembalikan 'fotodokter' atau 'foto'
      foto: json['fotodokter'] ?? json['foto'], 
      
      // Cek status aktif (bisa berupa angka 1/0 atau boolean)
      aktif: (json['aktif'] == 1 || json['aktif'] == true || json['status'] == 'aktif'), 
      
      // Hardcode sementara jika belum ada kolom harga di DB
      harga: "Rp 50.000", 
    );
  }
}

// ==========================================
// 3. MODEL KONSULTASI (Untuk Riwayat)
// ==========================================
class ConsultationModel {
  final int id;
  final String status;
  final String tanggal;
  final String diagnosaDokter; // Output: Catatan dari Dokter
  final String keluhan;        // Input: Catatan dari User (Mabok/Flu dll)
  final String namaDokter;
  final String spesialisasiDokter;
  final String? fotoDokter;
  final String namaHewan;

  ConsultationModel({
    required this.id,
    required this.status,
    required this.tanggal,
    required this.diagnosaDokter,
    required this.keluhan,
    required this.namaDokter,
    required this.spesialisasiDokter,
    this.fotoDokter,
    required this.namaHewan,
  });

  factory ConsultationModel.fromJson(Map<String, dynamic> json) {
    // Helper untuk mengambil data nested object (dokter/hewan) dengan aman
    final dokter = json['dokter'] ?? {};
    final hewan = json['hewan'] ?? {};

    return ConsultationModel(
      // Mapping sesuai tabel 'konsultasis'
      id: json['id_konsultasi'] ?? 0,
      
      // Status: pending, dijadwalkan, selesai, dibatalkan
      status: json['status'] ?? 'pending',
      
      tanggal: json['tanggal_konsultasi'] ?? '-',

      // 'catatan_dokter' -> Diagnosa akhir (Apa kata dokter)
      diagnosaDokter: json['catatan_dokter'] ?? '', 
      
      // 'catatan' -> Keluhan awal user (PENTING: ini yg ditampilkan di riwayat agar user ingat)
      keluhan: json['catatan'] ?? '-', 

      // Data Dokter (Relasi)
      namaDokter: dokter['nama'] ?? 'Dokter Tidak Dikenal',
      spesialisasiDokter: dokter['spesialisasi'] ?? 'Umum',
      // Ambil foto dokter (jaga-jaga jika key-nya fotodokter atau foto)
      fotoDokter: dokter['fotodokter'] ?? dokter['foto'], 

      // Data Hewan (Relasi)
      namaHewan: hewan['nama'] ?? 'Hewan Dihapus',
    );
  }
}