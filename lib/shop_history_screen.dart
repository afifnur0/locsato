import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:async';
import 'package:url_launcher/url_launcher.dart';
import 'config.dart';

class ShopHistoryScreen extends StatefulWidget {
  const ShopHistoryScreen({super.key});

  @override
  State<ShopHistoryScreen> createState() => _ShopHistoryScreenState();
}

class _ShopHistoryScreenState extends State<ShopHistoryScreen> {
  String _selectedFilter = 'all';
  bool _isLoading = false;
  List<dynamic> _orders = [];

  @override
  void initState() {
    super.initState();
    _fetchOrderHistory();
  }

  // --- FUNGSI MENGAMBIL DATA DARI API ---
  Future<void> _fetchOrderHistory() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      final url = Uri.parse('${AppConfig.baseUrl}/api/orders');
      final response = await http.get(url, headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _orders = data['data'] ?? [];
        });
      } else {
        print("Gagal memuat pesanan. Status: ${response.statusCode}");
      }
    } catch (e) {
      print("Error fetching order history: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF3C8085);
    const bgColor = Color(0xFFF5F7FA);

    // Menerapkan Filter Logika Web
    final filteredOrders = _orders.where((order) {
      if (_selectedFilter == 'all') return true;
      final status = (order['status'] ?? '').toString().toLowerCase();
      
      if (_selectedFilter == 'selesai') {
        return ['sudah_dibayar', 'dibayar', 'diproses', 'dikirim', 'selesai'].contains(status);
      }
      return status == _selectedFilter;
    }).toList();

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text("Riwayat Pesanan", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: primaryColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          // Filter Tabs
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _buildFilterBtn('Semua', 'all', primaryColor),
                  _buildFilterBtn('Menunggu', 'menunggu_pembayaran', primaryColor),
                  _buildFilterBtn('Selesai', 'selesai', primaryColor),
                  _buildFilterBtn('Dibatalkan', 'dibatalkan', primaryColor),
                ],
              ),
            ),
          ),

          // List Pesanan
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredOrders.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.shopping_bag_outlined, size: 80, color: Colors.grey.shade400),
                            const SizedBox(height: 16),
                            Text("Belum ada pesanan", style: TextStyle(color: Colors.grey.shade600, fontSize: 16)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filteredOrders.length,
                        itemBuilder: (context, index) {
                          return OrderCardWidget(order: filteredOrders[index], primaryColor: primaryColor);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBtn(String label, String value, Color primaryColor) {
    bool isActive = _selectedFilter == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = value),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? primaryColor : Colors.white,
          border: Border.all(color: isActive ? primaryColor : Colors.grey.shade300),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.white : Colors.grey.shade600,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

// =======================================================
// WIDGET KARTU PESANAN
// =======================================================
class OrderCardWidget extends StatefulWidget {
  final Map<String, dynamic> order;
  final Color primaryColor;

  const OrderCardWidget({super.key, required this.order, required this.primaryColor});

  @override
  State<OrderCardWidget> createState() => _OrderCardWidgetState();
}

class _OrderCardWidgetState extends State<OrderCardWidget> {
  bool _isExpanded = false;
  Timer? _timer;
  Duration _timeLeft = const Duration();
  bool _isExpired = false;

  @override
  void initState() {
    super.initState();
    _checkTimer();
  }

  void _checkTimer() {
    final status = widget.order['status']?.toString() ?? '';
    if (status == 'menunggu_pembayaran') {
      final createdAt = DateTime.tryParse(widget.order['created_at']?.toString() ?? '') ?? DateTime.now();
      final expireTime = createdAt.add(const Duration(minutes: 5));
      
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        final now = DateTime.now();
        if (now.isAfter(expireTime)) {
          setState(() {
            _isExpired = true;
            _timeLeft = const Duration();
          });
          timer.cancel();
        } else {
          setState(() {
            _timeLeft = expireTime.difference(now);
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _getProductImageUrl(String? fotoPath) {
    if (fotoPath == null || fotoPath.isEmpty) return '';
    String cleanPath = fotoPath;
    if (cleanPath.startsWith('public/')) cleanPath = cleanPath.replaceFirst('public/', '');
    if (cleanPath.startsWith('storage/')) cleanPath = cleanPath.replaceFirst('storage/', '');
    if (cleanPath.startsWith('/')) cleanPath = cleanPath.substring(1);

    if (!cleanPath.startsWith('produk_images/')) {
      cleanPath = 'produk_images/$cleanPath';
    }
    return '${AppConfig.baseUrl}/storage/$cleanPath';
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final String status = (order['status'] ?? '').toString().toLowerCase();
    final List<dynamic> items = order['items'] ?? [];
    
    // SAFETY PARSING UNTUK TOTAL HARGA
    final int totalPrice = int.tryParse(order['total_price']?.toString() ?? '0') ?? 0;
    
    // MAPPING STATUS
    Color badgeBgColor; Color badgeTextColor; String labelStatus;

    if (['sudah_dibayar', 'dibayar'].contains(status)) {
      badgeBgColor = const Color(0xFFFFF8E1); badgeTextColor = const Color(0xFFF57F17); labelStatus = 'Sudah Dibayar';
    } else if (status == 'diproses') {
      badgeBgColor = const Color(0xFFE3F2FD); badgeTextColor = const Color(0xFF1565C0); labelStatus = 'Diproses';
    } else if (status == 'dikirim') {
      badgeBgColor = const Color(0xFFE8F5E9); badgeTextColor = const Color(0xFF2E7D32); labelStatus = 'Dikirim';
    } else if (status == 'selesai') {
      badgeBgColor = const Color(0xFFE8F5E9); badgeTextColor = const Color(0xFF2E7D32); labelStatus = 'Selesai';
    } else if (status == 'dibatalkan') {
      badgeBgColor = const Color(0xFFFFEBEE); badgeTextColor = const Color(0xFFC62828); labelStatus = 'Dibatalkan';
    } else { 
      badgeBgColor = const Color(0xFFFFF8E1); badgeTextColor = const Color(0xFFF57F17); labelStatus = 'Menunggu Pembayaran';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // HEADER KARTU
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(color: const Color(0xFFFAFBFC), borderRadius: const BorderRadius.vertical(top: Radius.circular(12)), border: Border.all(color: Colors.grey.shade100)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 6,
                    children: [
                      const Icon(Icons.receipt_long, size: 14, color: Colors.grey),
                      Text(order['external_id']?.toString() ?? '-', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      const Text("|", style: TextStyle(color: Colors.grey, fontSize: 12)),
                      Text(DateFormat('dd MMM yyyy, HH:mm').format(DateTime.tryParse(order['created_at']?.toString() ?? '') ?? DateTime.now()), style: const TextStyle(color: Colors.grey, fontSize: 11)),
                      
                      if (status == 'menunggu_pembayaran') ...[
                        const Text("|", style: TextStyle(color: Colors.grey, fontSize: 12)),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.timer, size: 12, color: Colors.red),
                            const SizedBox(width: 4),
                            Text(
                              _isExpired ? "Waktu Habis" : "${_timeLeft.inMinutes.toString().padLeft(2, '0')}:${(_timeLeft.inSeconds % 60).toString().padLeft(2, '0')}",
                              style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 11),
                            )
                          ],
                        )
                      ]
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: badgeBgColor, borderRadius: BorderRadius.circular(6)),
                  child: Text(labelStatus, style: TextStyle(color: badgeTextColor, fontSize: 10, fontWeight: FontWeight.bold)),
                )
              ],
            ),
          ),

          // BODY KARTU (Items)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...items.take(2).map((item) => _buildProductRow(item)).toList(),

                if (items.length > 2) ...[
                  AnimatedCrossFade(
                    firstChild: const SizedBox(width: double.infinity),
                    secondChild: Column(
                      children: [
                        const Divider(color: Colors.grey, height: 20),
                        ...items.skip(2).map((item) => _buildProductRow(item)).toList(),
                      ],
                    ),
                    crossFadeState: _isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                    duration: const Duration(milliseconds: 300),
                  ),
                  
                  Center(
                    child: TextButton.icon(
                      onPressed: () => setState(() => _isExpanded = !_isExpanded),
                      icon: Icon(_isExpanded ? Icons.expand_less : Icons.expand_more, size: 16, color: widget.primaryColor),
                      label: Text(_isExpanded ? "Tutup" : "Lihat ${items.length - 2} produk lainnya", style: TextStyle(fontSize: 11, color: widget.primaryColor)),
                      style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(50, 30), tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                    ),
                  )
                ]
              ],
            ),
          ),

          // FOOTER KARTU (Total & Tombol)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(border: Border(top: BorderSide(color: Colors.grey.shade200))),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Total Belanja", style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
                    Text(NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0).format(totalPrice), style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: widget.primaryColor)),
                  ],
                ),
                Row(
                  children: [
                    if (status != 'dibatalkan' && status != 'menunggu_pembayaran')
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(foregroundColor: widget.primaryColor, side: BorderSide(color: widget.primaryColor), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                        onPressed: () {}, 
                        icon: const Icon(Icons.location_on, size: 14),
                        label: const Text("Lacak", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                      
                    if (status == 'menunggu_pembayaran' && order['payment_url'] != null && order['payment_url'].toString().isNotEmpty)
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: widget.primaryColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8)),
                        onPressed: () async {
                          final url = Uri.parse(order['payment_url'].toString());
                          if (await canLaunchUrl(url)) await launchUrl(url, mode: LaunchMode.externalApplication);
                        },
                        child: const Text("Bayar Sekarang", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                      )
                    else if (['sudah_dibayar', 'dibayar', 'diproses', 'dikirim', 'selesai'].contains(status))
                      Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(foregroundColor: Colors.grey.shade700, side: BorderSide(color: Colors.grey.shade300), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                          onPressed: () {}, 
                          child: const Text("Beli Lagi", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                      )
                  ],
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildProductRow(Map<String, dynamic> item) {
    String imageUrl = _getProductImageUrl(item['foto']?.toString());
    
    // SAFETY PARSING UNTUK ANGKA
    final int qty = int.tryParse(item['qty']?.toString() ?? '0') ?? 0;
    final int price = int.tryParse(item['price']?.toString() ?? '0') ?? 0;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 50, height: 50,
            decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(8)),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: imageUrl.isEmpty 
                  ? const Icon(Icons.image, color: Colors.grey, size: 20)
                  : Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const Icon(Icons.image, color: Colors.grey, size: 20),
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item['nama_produk']?.toString() ?? 'Produk Tidak Ditemukan', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(Icons.storefront, size: 10, color: Color(0xFF3C8085)),
                    const SizedBox(width: 4),
                    Text(item['klinik']?.toString() ?? 'Klinik Umum', style: const TextStyle(fontSize: 10, color: Color(0xFF3C8085))),
                  ],
                ),
                const SizedBox(height: 2),
                Text("$qty x Rp ${NumberFormat('#,###', 'id_ID').format(price)}", style: const TextStyle(fontSize: 11, color: Colors.grey)),
              ],
            ),
          )
        ],
      ),
    );
  }
}