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
      id: json['id_hewan'] ?? json['id'] ?? 0, 
      nama: json['nama'] ?? 'Tanpa Nama',
      spesies: json['spesies'] ?? 'Lainnya',
      ras: json['ras'] ?? '-',
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
  final String? fotodokter; 
  final bool aktif;
  final String harga;
  final List<dynamic> jadwals;

  DoctorModel({
    required this.id,
    required this.nama,
    required this.spesialisasi,
    this.foto,
    this.fotodokter,
    required this.aktif,
    required this.harga,
    this.jadwals = const [],
  });

  factory DoctorModel.fromJson(Map<String, dynamic> json) {
    return DoctorModel(
      id: json['id_dokter'] ?? json['id'] ?? 0, 
      nama: json['nama'] ?? 'Tanpa Nama',
      spesialisasi: json['spesialisasi'] ?? 'Umum',
      foto: json['foto'] ?? json['fotodokter'], 
      fotodokter: json['fotodokter'] ?? json['foto'], 
      aktif: (json['aktif'] == 1 || json['aktif'] == true || json['status'] == 'aktif'), 
      harga: "Rp 50.000",
      jadwals: json['jadwals'] ?? json['jadwal'] ?? [],
    );
  }
}

// ==========================================
// 3. MODEL KONSULTASI (Untuk Riwayat)
// ==========================================
class ConsultationModel {
  final int idKonsultasi;
  final String status;
  final String tanggalKonsultasi;
  final String? catatanDokter;   
  final String? hasilKonsultasi; 
  final String? catatan;         
  final DoctorModel? dokter;
  final PetModel? hewan;

  ConsultationModel({
    required this.idKonsultasi,
    required this.status,
    required this.tanggalKonsultasi,
    this.catatanDokter,
    this.hasilKonsultasi,
    this.catatan,
    this.dokter,
    this.hewan,
  });

  factory ConsultationModel.fromJson(Map<String, dynamic> json) {
    return ConsultationModel(
      idKonsultasi: json['id_konsultasi'] ?? json['id'] ?? 0,
      status: json['status'] ?? 'pending',
      tanggalKonsultasi: json['tanggal_konsultasi'] ?? json['created_at'] ?? '-',
      catatanDokter: json['catatan_dokter'], 
      hasilKonsultasi: json['hasil_konsultasi'],
      catatan: json['catatan'], 
      dokter: json['dokter'] != null ? DoctorModel.fromJson(json['dokter']) : null,
      hewan: json['hewan'] != null ? PetModel.fromJson(json['hewan']) : null,
    );
  }
}

// ==========================================
// 4. MODEL KATEGORI PRODUK (Dari API /shop)
// ==========================================
class Category {
  final int id;
  final String nama;

  Category({required this.id, required this.nama});

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id_kategori'] ?? 0, 
      nama: json['nama_kategori'] ?? 'Kategori',
    );
  }
}

// ==========================================
// 5. MODEL PRODUK SHOP (Dari API /shop)
// ==========================================
class Product {
  final int id;
  final String nama;
  final String description;
  final int price;
  final int stock;
  final String photo;
  final String categoryName;
  final String klinikNama; 

  Product({
    required this.id, 
    required this.nama, 
    required this.description, 
    required this.price, 
    required this.stock, 
    required this.photo, 
    required this.categoryName, 
    required this.klinikNama,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    int parsePrice(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      if (value is double) return value.toInt();
      if (value is String) return double.tryParse(value)?.toInt() ?? 0;
      return 0;
    }

    return Product(
      id: json['id'],
      nama: json['nama'] ?? 'Tanpa Nama', 
      description: json['deskripsi'] ?? '-',
      price: parsePrice(json['harga']),
      stock: json['stok'] is String ? int.parse(json['stok']) : (json['stok'] ?? 0),
      photo: json['foto'] ?? '',
      categoryName: (json['kategori_produk'] != null && json['kategori_produk']['nama_kategori'] != null)
          ? json['kategori_produk']['nama_kategori'] : 'Umum',
      klinikNama: (json['klinik'] != null && json['klinik']['nama'] != null) 
          ? json['klinik']['nama'] : 'Klinik Hewan LocSato',
    );
  }
}