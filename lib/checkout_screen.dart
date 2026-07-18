import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'shop_screen.dart'; 
import 'config.dart'; 
import 'models.dart'; // <--- PERBAIKAN: Menambahkan import models.dart

class CheckoutScreen extends StatefulWidget {
  final List<Map<String, dynamic>> cartItems;
  final int totalHarga;

  const CheckoutScreen({super.key, required this.cartItems, required this.totalHarga});

  @override
  _CheckoutScreenState createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Controller Input
  final TextEditingController _namaController = TextEditingController();
  final TextEditingController _hpController = TextEditingController(); 
  final TextEditingController _alamatController = TextEditingController();
  
  bool _isLoading = false;

  final String baseUrl = AppConfig.baseUrl; 

  String formatRupiah(int price) {
    return NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0).format(price);
  }

  Future<void> _submitOrder() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() { _isLoading = true; });

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token'); 

    if (token == null || token.isEmpty) {
      setState(() { _isLoading = false; });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Gagal: Anda belum login! Silakan login ulang."),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    List<Map<String, dynamic>> itemsToSend = widget.cartItems.map((item) {
      Product p = item['product'];
      return {
        'product_id': p.id,
        'qty': item['qty'],
        'harga_satuan': p.price,
      };
    }).toList();

    try {
      final url = Uri.parse('$baseUrl/api/checkout');
      
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token', 
        },
        body: jsonEncode({
          'nama_penerima': _namaController.text, 
          'no_hp': _hpController.text,           
          'alamat': _alamatController.text,      
          'total_harga': widget.totalHarga,
          'items': itemsToSend,
        }),
      );

      print("URL: $url"); 
      print("Status Code: ${response.statusCode}");
      print("Response: ${response.body}");

      if (response.statusCode == 201 || response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Pesanan Berhasil Dibuat!"), backgroundColor: Colors.green),
          );
          Navigator.popUntil(context, (route) => route.isFirst);
        }
      } else if (response.statusCode == 401) {
        throw Exception("Sesi login habis atau IP berbeda. Silakan Logout dan Login kembali.");
      } else {
        String errorMsg = "Gagal memproses pesanan.";
        try {
           var jsonResp = jsonDecode(response.body);
           if(jsonResp['message'] != null) errorMsg = jsonResp['message'];
        } catch (_) {
           errorMsg = response.body;
        }
        throw Exception(errorMsg);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll("Exception: ", "")), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Konfirmasi Pesanan"),
        backgroundColor: const Color(0xFF3C8085),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // FORM INPUT
              const Text("Informasi Pengiriman", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 15),
              
              TextFormField(
                controller: _namaController,
                decoration: const InputDecoration(labelText: "Nama Penerima", border: OutlineInputBorder(), prefixIcon: Icon(Icons.person)),
                validator: (val) => val!.isEmpty ? "Nama wajib diisi" : null,
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: _hpController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: "Nomor HP / WhatsApp", border: OutlineInputBorder(), prefixIcon: Icon(Icons.phone)),
                validator: (val) => val!.isEmpty ? "No HP wajib diisi" : null,
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: _alamatController,
                maxLines: 3,
                decoration: const InputDecoration(labelText: "Alamat Lengkap", border: OutlineInputBorder(), prefixIcon: Icon(Icons.home)),
                validator: (val) => val!.isEmpty ? "Alamat wajib diisi" : null,
              ),

              const SizedBox(height: 30),
              
              // RINGKASAN ITEM
              const Text("Ringkasan Item", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Container(
                decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.all(10),
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: widget.cartItems.length,
                  separatorBuilder: (ctx, i) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final item = widget.cartItems[index];
                    Product p = item['product'];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(p.nama, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text("${item['qty']} x ${formatRupiah(p.price)}"),
                      trailing: Text(formatRupiah(p.price * (item['qty'] as int)), style: const TextStyle(fontWeight: FontWeight.bold)),
                    );
                  },
                ),
              ),

              const SizedBox(height: 20),
              
              // TOTAL DAN TOMBOL
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEFCFC),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF3C8085))
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Total Bayar:", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    Text(formatRupiah(widget.totalHarga), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF3C8085))),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitOrder,
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF3C8085)),
                  child: _isLoading 
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Buat Pesanan Sekarang", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}