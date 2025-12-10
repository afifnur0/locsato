import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart'; // Wajib untuk deteksi Web/HP
import 'checkout_screen.dart'; // Pastikan file ini ada
import 'config.dart'; // <--- 1. WAJIB IMPORT FILE CONFIG INI

class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});

  @override
  _ShopScreenState createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  // --- 2. PERUBAHAN UTAMA: GUNAKAN CONFIG BASE URL ---
  final String baseUrl = AppConfig.baseUrl; 

  final Color primaryColor = const Color(0xFF0F766E); // Sesuaikan warna dengan LocSato

  // --- STATE DATA ---
  List<Product> products = [];
  List<Category> categories = [];
  
  // Format Cart Item: { 'product': ProductObject, 'qty': int }
  List<Map<String, dynamic>> cartItems = []; 
  
  String selectedCategory = 'all';
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchData(); 
  }

  // --- LOGIC: FETCH DATA DARI API ---
  Future<void> fetchData() async {
    setState(() { isLoading = true; });

    try {
      final url = Uri.parse('$baseUrl/api/shop');
      print("Mengambil data dari: $url");

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        final List<dynamic> productList = responseData['products'];
        
        // Ambil kategori juga jika API menyediakan (opsional)
        // final List<dynamic> catList = responseData['categories'] ?? [];
        
        setState(() {
          products = productList.map((json) => Product.fromJson(json)).toList();
          // categories = catList.map((json) => Category.fromJson(json)).toList();
          isLoading = false;
        });
      } else {
        throw Exception('Gagal load data: ${response.statusCode}');
      }
    } catch (e) {
      print("Error: $e");
      setState(() { isLoading = false; products = []; });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Gagal mengambil data dari ${AppConfig.baseUrl}: $e"),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  // --- LOGIC: CART FUNCTIONALITY ---

  // 1. Tambah ke Keranjang
  void addToCart(Product product) {
    setState(() {
      int index = cartItems.indexWhere((item) => item['product'].id == product.id);

      if (index != -1) {
        cartItems[index]['qty'] = cartItems[index]['qty'] + 1;
      } else {
        cartItems.add({'product': product, 'qty': 1});
      }
    });

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("${product.nama} masuk keranjang"),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 1),
      )
    );
  }

  // 2. Hapus dari Keranjang
  void removeFromCart(int index) {
    setState(() {
      cartItems.removeAt(index);
    });
  }

  // 3. Hitung Total Harga
  int calculateTotal() {
    int total = 0;
    for (var item in cartItems) {
      Product p = item['product'];
      int qty = item['qty'];
      total += (p.price * qty);
    }
    return total;
  }

  // --- HELPER FUNCTIONS ---
  String getImageUrl(String photo) {
    if (photo.isEmpty) return "https://placehold.co/400x300?text=No+Image";
    
    // Logika URL Gambar agar tidak double slash
    String cleanBaseUrl = baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;
    
    // Jika foto sudah berisi path lengkap 'storage/...' atau 'produk_images/...'
    if (photo.startsWith('http')) return photo;
    
    // Perbaikan Path Gambar Laravel (Storage Link)
    if (photo.startsWith('produk_images') || photo.startsWith('storage')) {
       // Hapus kata 'public/' jika tidak sengaja tersimpan di database
       String cleanPhotoPath = photo.replaceAll('public/', '');
       return "$cleanBaseUrl/storage/$cleanPhotoPath";
    } else {
       return "$cleanBaseUrl/storage/produk_images/$photo";
    }
  }

  String formatRupiah(int price) {
    return NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0).format(price);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("PetMedic Shop", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: primaryColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: isLoading 
          ? Center(child: CircularProgressIndicator(color: primaryColor))
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                _buildCategoryFilters(),
                Expanded(child: _buildProductGrid()),
              ],
            ),
      floatingActionButton: _buildFloatingCartButton(),
    );
  }

  // --- WIDGETS ---
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Produk Kesehatan", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF2D3436))),
          Text("Temukan obat & vitamin untuk anabul.", style: TextStyle(color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildCategoryFilters() {
    return Container(
      height: 50,
      margin: const EdgeInsets.only(bottom: 10),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 15),
        children: [
          _categoryButton('Semua', 'all'),
          // Jika categories sudah diisi dari API, map disini
          // ...categories.map((cat) => _categoryButton(cat.nama, cat.id.toString())).toList(),
        ],
      ),
    );
  }

  Widget _categoryButton(String label, String id) {
    bool isActive = selectedCategory == id;
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: InkWell(
        onTap: () {
          setState(() {
            selectedCategory = id;
            // Di sini nanti bisa tambah logika filter list produk lokal
            // isLoading = true;
          });
          // fetchData(); // Atau filter lokal saja tanpa request ulang
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: isActive ? primaryColor : Colors.transparent,
            borderRadius: BorderRadius.circular(50),
            border: Border.all(color: primaryColor, width: 2),
          ),
          child: Center(
            child: Text(label, style: TextStyle(color: isActive ? Colors.white : primaryColor, fontWeight: FontWeight.w600)),
          ),
        ),
      ),
    );
  }

  Widget _buildProductGrid() {
    if (products.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_outlined, size: 60, color: Colors.grey[300]),
            const SizedBox(height: 10),
            const Text("Tidak ada produk tersedia", style: TextStyle(color: Colors.grey)),
            TextButton(onPressed: fetchData, child: const Text("Coba Lagi"))
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(15),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, 
        childAspectRatio: 0.65, 
        crossAxisSpacing: 15,
        mainAxisSpacing: 15,
      ),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        return _buildProductCard(product);
      },
    );
  }

  Widget _buildProductCard(Product product) {
    bool isOutOfStock = product.stock <= 0;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
        border: Border.all(color: const Color(0xFFF0F0F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: Image.network(
                getImageUrl(product.photo),
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (ctx, err, stack) => Container(color: Colors.grey[200], child: const Center(child: Icon(Icons.image_not_supported, color: Colors.grey))),
              ),
            ),
          ),
          Expanded(
            flex: 4,
            child: Padding(
              padding: const EdgeInsets.all(10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (product.categoryName != 'Umum')
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: const Color(0xFFEEFCFC), borderRadius: BorderRadius.circular(8)),
                      child: Text(product.categoryName, style: TextStyle(color: primaryColor, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  const SizedBox(height: 5),
                  Text(product.nama, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  Text(product.description, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10, color: Colors.grey)),
                  const Spacer(),
                  Text(formatRupiah(product.price), style: TextStyle(color: primaryColor, fontWeight: FontWeight.w800, fontSize: 14)),
                  Text("Stok: ${product.stock}", style: const TextStyle(fontSize: 10, color: Colors.grey)),
                  const SizedBox(height: 5),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isOutOfStock ? null : () => addToCart(product),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(vertical: 0),
                        disabledBackgroundColor: Colors.grey[300],
                      ),
                      child: Text(isOutOfStock ? "Habis" : "Beli", style: const TextStyle(fontSize: 12, color: Colors.white)),
                    ),
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingCartButton() {
    return Stack(
      children: [
        FloatingActionButton(
          backgroundColor: primaryColor,
          onPressed: _showCartModal,
          child: const Icon(Icons.shopping_cart, color: Colors.white),
        ),
        if (cartItems.isNotEmpty)
          Positioned(
            right: 0, top: 0,
            child: Container(
              padding: const EdgeInsets.all(5),
              decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
              child: Text(cartItems.length.toString(), style: const TextStyle(color: Colors.white, fontSize: 10)),
            ),
          )
      ],
    );
  }

  // --- MODAL KERANJANG (NAVIGASI KE CHECKOUT) ---
  void _showCartModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, 
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Container(
              padding: const EdgeInsets.all(20),
              height: MediaQuery.of(context).size.height * 0.8,
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Keranjang Belanja", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                    ],
                  ),
                  const Divider(),
                  
                  // LIST BELANJAAN
                  Expanded(
                    child: cartItems.isEmpty 
                      ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.shopping_cart_outlined, size: 50, color: Colors.grey), Text("Keranjang Kosong", style: TextStyle(color: Colors.grey))]))
                      : ListView.builder(
                          itemCount: cartItems.length,
                          itemBuilder: (context, index) {
                            final item = cartItems[index];
                            final Product p = item['product'];
                            final int qty = item['qty'];

                            return Card(
                              margin: const EdgeInsets.only(bottom: 10),
                              child: ListTile(
                                leading: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(getImageUrl(p.photo), width: 50, height: 50, fit: BoxFit.cover, errorBuilder: (c,e,s) => Container(width:50, height:50, color:Colors.grey)),
                                ),
                                title: Text(p.nama, maxLines: 1, overflow: TextOverflow.ellipsis),
                                subtitle: Text("${qty} x ${formatRupiah(p.price)}", style: TextStyle(color: primaryColor)),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () {
                                    removeFromCart(index);
                                    setModalState(() {}); 
                                  },
                                ),
                              ),
                            );
                          },
                        ),
                  ),

                  // TOTAL HARGA & CHECKOUT
                  Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(15)),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("Total Pembayaran:", style: TextStyle(fontWeight: FontWeight.bold)),
                            Text(formatRupiah(calculateTotal()), style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryColor)),
                          ],
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity, 
                          child: ElevatedButton(
                            onPressed: cartItems.isEmpty ? null : () {
                              Navigator.pop(context); // Tutup modal dulu
                              
                              // Pindah ke Halaman Checkout membawa data belanjaan
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => CheckoutScreen(
                                    cartItems: cartItems, 
                                    totalHarga: calculateTotal()
                                  )
                                ),
                              );
                            }, 
                            style: ElevatedButton.styleFrom(backgroundColor: primaryColor, padding: const EdgeInsets.symmetric(vertical: 12)),
                            child: const Text("Checkout Sekarang", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          )
                        )
                      ],
                    ),
                  )
                ],
              ),
            );
          }
        );
      },
    );
  }
}

// ==========================================
// MODELS
// ==========================================

class Category {
  final int id;
  final String nama;
  Category({required this.id, required this.nama});
  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(id: json['id_kategori'] ?? 0, nama: json['nama_kategori'] ?? 'Kategori');
  }
}

class Product {
  final int id;
  final String nama;
  final String description;
  final int price;
  final int stock;
  final String photo;
  final String categoryName;

  Product({
    required this.id, required this.nama, required this.description, 
    required this.price, required this.stock, required this.photo, required this.categoryName,
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
    );
  }
}