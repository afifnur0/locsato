import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart' hide Category; // <--- PERBAIKAN: Menyembunyikan Category bawaan Flutter
import 'checkout_screen.dart'; 
import 'shop_history_screen.dart'; 
import 'config.dart'; 
import 'models.dart';

class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});

  @override
  _ShopScreenState createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  final String baseUrl = AppConfig.baseUrl; 

  final Color primaryColor = const Color(0xFF3C8085); 
  final Color primaryLight = const Color(0xFFE8F5F5);
  final Color textDark = const Color(0xFF2D3436);
  final Color textMuted = const Color(0xFF636E72);

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
        
        setState(() {
          products = productList.map((json) => Product.fromJson(json)).toList();
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

  void removeFromCart(int index) {
    setState(() {
      cartItems.removeAt(index);
    });
  }

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
    String cleanBaseUrl = baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;
    if (photo.startsWith('http')) return photo;
    if (photo.startsWith('produk_images') || photo.startsWith('storage')) {
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
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text("PetMedic Shop", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: primaryColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.receipt_long),
            tooltip: 'Riwayat Pesanan',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ShopHistoryScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: isLoading 
          ? Center(child: CircularProgressIndicator(color: primaryColor))
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeroBanner(),
                  _buildCategoryFilters(),
                  _buildProductGrid(),
                  const SizedBox(height: 80), 
                ],
              ),
            ),
      floatingActionButton: _buildFloatingCartButton(),
    );
  }

  // --- WIDGETS ---

  Widget _buildHeroBanner() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2A5C5F), Color(0xFF3C8085)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: primaryColor.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8))
        ]
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Kebutuhan Terbaik\nuntuk Anabul Kesayangan", 
            style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold, height: 1.3)
          ),
          const SizedBox(height: 12),
          const Text(
            "Temukan makanan premium, mainan seru, dan perlengkapan kesehatan berkualitas tinggi hanya di LocSato Shop.", 
            style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4)
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(50),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text("Belanja Sekarang", style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(width: 5),
                Icon(Icons.arrow_downward, color: primaryColor, size: 16),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildCategoryFilters() {
    return Container(
      height: 45,
      margin: const EdgeInsets.only(bottom: 20),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _categoryButton('Semua', 'all', Icons.grid_view_outlined),
          _categoryButton('Makanan', 'makanan', Icons.fastfood_outlined),
          // <--- PERBAIKAN: Menggunakan Icons.medical_services_outlined
          _categoryButton('Obat-obatan', 'obat', Icons.medical_services_outlined),
          _categoryButton('Kandang', 'kandang', Icons.home_outlined),
          _categoryButton('Mainan', 'mainan', Icons.sports_tennis_outlined),
        ],
      ),
    );
  }

  Widget _categoryButton(String label, String id, IconData icon) {
    bool isActive = selectedCategory == id;
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: InkWell(
        onTap: () {
          setState(() {
            selectedCategory = id;
          });
        },
        borderRadius: BorderRadius.circular(50),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: isActive ? primaryColor : Colors.white,
            borderRadius: BorderRadius.circular(50),
            border: Border.all(color: isActive ? primaryColor : Colors.grey.shade300, width: 1),
            boxShadow: isActive ? [BoxShadow(color: primaryColor.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))] : [],
          ),
          child: Row(
            children: [
              Icon(icon, size: 16, color: isActive ? Colors.white : textMuted),
              const SizedBox(width: 6),
              Text(
                label, 
                style: TextStyle(
                  color: isActive ? Colors.white : textMuted, 
                  fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                  fontSize: 13
                )
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductGrid() {
    // 1. TAMBAHKAN LOGIKA FILTER DI SINI
    final filteredProducts = products.where((product) {
      if (selectedCategory == 'all') return true;
      // Mencocokkan teks kategori yang dipilih (makanan, obat, dll) dengan nama kategori dari API
      return product.categoryName.toLowerCase().contains(selectedCategory.toLowerCase());
    }).toList();

    // 2. CEK LIST YANG SUDAH DI-FILTER, BUKAN LIST ASLI
    if (filteredProducts.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 50),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.search_off, size: 60, color: Colors.grey[300]),
              const SizedBox(height: 10),
              const Text("Kategori ini belum memiliki produk", style: TextStyle(color: Colors.grey)),
              TextButton(
                onPressed: () {
                  setState(() => selectedCategory = 'all');
                }, 
                child: const Text("Tampilkan Semua")
              )
            ],
          ),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, 
        childAspectRatio: 0.65, 
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      // 3. GUNAKAN LIST YANG SUDAH DI-FILTER
      itemCount: filteredProducts.length,
      itemBuilder: (context, index) {
        final product = filteredProducts[index];
        return _buildProductCard(product);
      },
    );
  }

  Widget _buildProductCard(Product product) {
    bool isOutOfStock = product.stock <= 0;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 5))],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Gambar Produk
          Expanded(
            flex: 4,
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Color(0xFFF9F9F9),
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                child: Image.network(
                  getImageUrl(product.photo),
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (ctx, err, stack) => const Center(child: Icon(Icons.image_not_supported, color: Colors.grey)),
                ),
              ),
            ),
          ),
          
          // Detail Produk
          Expanded(
            flex: 6,
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.categoryName.toUpperCase(), 
                    style: const TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5)
                  ),
                  const SizedBox(height: 4),
                  Text(
                    product.nama, 
                    maxLines: 2, 
                    overflow: TextOverflow.ellipsis, 
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: textDark, height: 1.2)
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 12, color: Colors.grey),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          product.klinikNama, 
                          maxLines: 1, 
                          overflow: TextOverflow.ellipsis, 
                          style: const TextStyle(fontSize: 10, color: Colors.grey)
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    formatRupiah(product.price), 
                    style: TextStyle(color: primaryColor, fontWeight: FontWeight.w900, fontSize: 14)
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isOutOfStock ? const Color(0xFFFFEBEE) : primaryLight,
                      borderRadius: BorderRadius.circular(50)
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(isOutOfStock ? Icons.cancel : Icons.check_circle, size: 10, color: isOutOfStock ? Colors.red : primaryColor),
                        const SizedBox(width: 4),
                        Text(
                          isOutOfStock ? "Stok Habis" : "Sisa Stok: ${product.stock}", 
                          style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: isOutOfStock ? Colors.red : primaryColor)
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 36,
                    child: ElevatedButton(
                      onPressed: isOutOfStock ? null : () => addToCart(product),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryLight,
                        foregroundColor: primaryColor,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        elevation: 0,
                        disabledBackgroundColor: Colors.grey[200],
                        disabledForegroundColor: Colors.grey[500],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(isOutOfStock ? Icons.block : Icons.shopping_bag_outlined, size: 14),
                          const SizedBox(width: 5),
                          Text(isOutOfStock ? "Habis" : "Tambah", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        ],
                      ),
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
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.red, 
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2)
              ),
              child: Text(cartItems.length.toString(), style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
            ),
          )
      ],
    );
  }

  // --- MODAL KERANJANG ---
  void _showCartModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, 
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Container(
              padding: const EdgeInsets.all(20),
              height: MediaQuery.of(context).size.height * 0.85,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(25))
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Keranjang Belanja", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryColor)),
                      IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                    ],
                  ),
                  const Divider(),
                  Expanded(
                    child: cartItems.isEmpty 
                      ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.shopping_cart_outlined, size: 60, color: Colors.grey.shade300), const SizedBox(height: 10), const Text("Keranjang masih kosong", style: TextStyle(color: Colors.grey))]))
                      : ListView.builder(
                          itemCount: cartItems.length,
                          itemBuilder: (context, index) {
                            final item = cartItems[index];
                            final Product p = item['product'];
                            final int qty = item['qty'];

                            return Container(
                              margin: const EdgeInsets.only(bottom: 15),
                              padding: const EdgeInsets.only(bottom: 15),
                              decoration: BoxDecoration(
                                border: Border(bottom: BorderSide(color: Colors.grey.shade200))
                              ),
                              child: Row(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: Image.network(getImageUrl(p.photo), width: 60, height: 60, fit: BoxFit.cover, errorBuilder: (c,e,s) => Container(width:60, height:60, color:Colors.grey.shade200)),
                                  ),
                                  const SizedBox(width: 15),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(p.nama, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                        const SizedBox(height: 4),
                                        Text("$qty x ${formatRupiah(p.price)}", style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                                    onPressed: () {
                                      removeFromCart(index);
                                      setModalState(() {}); 
                                    },
                                  ),
                                ],
                              )
                            );
                          },
                        ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white, 
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, -5))]
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("Total:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            Text(formatRupiah(calculateTotal()), style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryColor)),
                          ],
                        ),
                        const SizedBox(height: 15),
                        SizedBox(
                          width: double.infinity, 
                          height: 50,
                          child: ElevatedButton(
                            onPressed: cartItems.isEmpty ? null : () {
                              Navigator.pop(context); 
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
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor, 
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50))
                            ),
                            child: const Text("Checkout Sekarang", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
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