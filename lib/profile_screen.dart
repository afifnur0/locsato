// lib/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'login_screen.dart'; 
import 'history_screen.dart'; // <--- Import Halaman Riwayat yang asli
import 'config.dart'; // <--- 1. WAJIB IMPORT CONFIG

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _userName = "Loading...";
  String _userEmail = "";

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  // Load data user dari SharedPreferences
  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userName = prefs.getString('user_name') ?? "Guest User";
      _userEmail = prefs.getString('user_email') ?? "guest@locsato.com";
    });
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // Hapus Token & Data User

    if (mounted) {
      // Kembali ke Login dan hapus semua riwayat navigasi
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false, 
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F6),
      appBar: AppBar(
        title: const Text("Profil Saya", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // --- HEADER PROFIL ---
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(color: Colors.grey.withOpacity(0.08), blurRadius: 15, offset: const Offset(0, 5)),
                ],
              ),
              child: Column(
                children: [
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundImage: NetworkImage(
                          'https://ui-avatars.com/api/?name=${Uri.encodeComponent(_userName)}&background=0F766E&color=fff&size=128'
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(color: primaryColor, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 3)),
                        child: const Padding(
                          padding: EdgeInsets.all(6.0),
                          child: Icon(Icons.camera_alt, size: 16, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(_userName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF134E4A))),
                  const SizedBox(height: 4),
                  Text(_userEmail, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // --- MENU LIST ---
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: Column(
                children: [
                  _buildMenuItem(
                    context, 
                    Icons.person_outline, 
                    "Informasi Pribadi",
                    () async {
                      await Navigator.push(context, MaterialPageRoute(builder: (context) => const PersonalInfoPage()));
                      _loadUserData(); // Refresh tampilan nama setelah edit
                    },
                  ),
                  const Divider(height: 1, indent: 60),
                  
                  _buildMenuItem(
                    context, 
                    Icons.pets, 
                    "Hewan Peliharaan",
                    () => Navigator.push(context, MaterialPageRoute(builder: (context) => const MyPetsPage())),
                  ),
                  const Divider(height: 1, indent: 60),
                  
                  _buildMenuItem(
                    context, 
                    Icons.history, 
                    "Riwayat Konsultasi",
                    // Arahkan ke HistoryScreen yang asli (bukan dummy lagi)
                    () => Navigator.push(context, MaterialPageRoute(builder: (context) => const HistoryScreen())),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // --- TOMBOL KELUAR ---
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextButton.icon(
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  foregroundColor: Colors.red,
                  alignment: Alignment.centerLeft,
                ),
                onPressed: _logout,
                icon: const Padding(padding: EdgeInsets.only(left: 20, right: 12), child: Icon(Icons.logout)),
                label: const Text("Keluar", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(BuildContext context, IconData icon, String title, VoidCallback onTap) {
    final primaryColor = Theme.of(context).primaryColor;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFFCCFBF1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: primaryColor, size: 22),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF334155))),
      trailing: Icon(Icons.chevron_right, color: Colors.grey[400]),
      onTap: onTap,
    );
  }
}

// ==========================================
// 1. HALAMAN INFORMASI PRIBADI
// ==========================================
class PersonalInfoPage extends StatefulWidget {
  const PersonalInfoPage({super.key});

  @override
  State<PersonalInfoPage> createState() => _PersonalInfoPageState();
}

class _PersonalInfoPageState extends State<PersonalInfoPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentData();
  }

  Future<void> _loadCurrentData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _nameController.text = prefs.getString('user_name') ?? "";
      _phoneController.text = prefs.getString('user_phone') ?? ""; 
      _addressController.text = prefs.getString('user_address') ?? "";
    });
  }

  Future<void> _updateProfile() async {
    setState(() { _isLoading = true; });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token'); 

      // 2. GUNAKAN APPCONFIG BASE URL
      final url = Uri.parse('${AppConfig.baseUrl}/api/update-profile');

      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'nama': _nameController.text,
          'telepon': _phoneController.text,
          'alamat': _addressController.text,
        }),
      );

      if (response.statusCode == 200) {
        // Simpan data baru ke HP agar profil terupdate
        await prefs.setString('user_name', _nameController.text);
        await prefs.setString('user_phone', _phoneController.text);
        await prefs.setString('user_address', _addressController.text);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Profil Berhasil Diperbarui!"), backgroundColor: Colors.green),
          );
          Navigator.pop(context); 
        }
      } else {
        throw Exception("Gagal update: ${response.statusCode}");
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF0F766E);
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F6),
      appBar: AppBar(
        title: const Text("Informasi Pribadi", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: primaryColor),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 10)],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Edit Data Diri", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: primaryColor)),
                  const Divider(height: 30),
                  _buildInputLabel("Nama Lengkap"),
                  _buildTextField(_nameController, Icons.person_outline),
                  const SizedBox(height: 16),
                  _buildInputLabel("Nomor Telepon"),
                  _buildTextField(_phoneController, Icons.phone_android, isNumber: true),
                  const SizedBox(height: 16),
                  _buildInputLabel("Alamat Lengkap"),
                  _buildTextField(_addressController, Icons.location_on_outlined, maxLines: 3),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        elevation: 2,
                      ),
                      onPressed: _isLoading ? null : _updateProfile,
                      child: _isLoading 
                        ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text("Simpan Perubahan", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputLabel(String label) => Padding(padding: const EdgeInsets.only(bottom: 8.0), child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.grey)));
  
  Widget _buildTextField(TextEditingController controller, IconData icon, {bool isNumber = false, int maxLines = 1}) {
    return TextField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.phone : TextInputType.text,
      maxLines: maxLines,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: const Color(0xFF0F766E)),
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
    );
  }
}

// ==========================================
// 2. HALAMAN HEWAN PELIHARAAN (CRUD)
// ==========================================
class MyPetsPage extends StatefulWidget {
  const MyPetsPage({super.key});

  @override
  State<MyPetsPage> createState() => _MyPetsPageState();
}

class _MyPetsPageState extends State<MyPetsPage> {
  List<dynamic> _petsList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchPets();
  }

  // --- 1. GET DATA ---
  Future<void> _fetchPets() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      
      // 3. GUNAKAN APPCONFIG BASE URL
      final url = Uri.parse('${AppConfig.baseUrl}/api/pets');
      
      final response = await http.get(url, headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _petsList = data['data']; 
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- 2. ADD / UPDATE DATA ---
  Future<void> _savePet({int? id, required String nama, required String spesies, String? ras, String? usia}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      
      // 4. GUNAKAN APPCONFIG BASE URL
      final url = id == null 
          ? Uri.parse('${AppConfig.baseUrl}/api/pets')
          : Uri.parse('${AppConfig.baseUrl}/api/pets/$id');
      
      final bodyData = jsonEncode({
        'nama': nama,
        'spesies': spesies,
        'ras': ras ?? '',
        'usia': usia ?? '0',
      });

      final Map<String, String> headers = {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      };

      final response = id == null 
          ? await http.post(url, headers: headers, body: bodyData)
          : await http.put(url, headers: headers, body: bodyData);

      if (response.statusCode == 201 || response.statusCode == 200) {
        if(mounted) Navigator.pop(context); // Tutup Dialog
        _fetchPets(); // Refresh List
        if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(id == null ? "Hewan ditambahkan!" : "Hewan diperbarui!"), backgroundColor: Colors.green));
      } else {
        throw Exception('Gagal menyimpan: ${response.statusCode}');
      }
    } catch (e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
    }
  }

  // --- 3. DELETE DATA ---
  Future<void> _deletePet(int id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      
      // 5. GUNAKAN APPCONFIG BASE URL
      final url = Uri.parse('${AppConfig.baseUrl}/api/pets/$id');

      final response = await http.delete(url, headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      });

      if (response.statusCode == 200) {
        _fetchPets();
        if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Hewan berhasil dihapus"), backgroundColor: Colors.green));
      } else {
        throw Exception('Gagal menghapus');
      }
    } catch (e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
    }
  }

  // --- DIALOG FORM ---
  void _showPetDialog({Map<String, dynamic>? petData}) {
    final bool isEdit = petData != null;
    final nameController = TextEditingController(text: isEdit ? petData['nama'] : '');
    final speciesController = TextEditingController(text: isEdit ? petData['spesies'] : '');
    final breedController = TextEditingController(text: isEdit ? petData['ras'] : '');
    final ageController = TextEditingController(text: isEdit ? petData['usia'].toString() : '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEdit ? "Edit Hewan" : "Tambah Hewan Baru"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameController, decoration: const InputDecoration(labelText: "Nama Hewan")),
              TextField(controller: speciesController, decoration: const InputDecoration(labelText: "Jenis (Kucing/Anjing)")),
              TextField(controller: breedController, decoration: const InputDecoration(labelText: "Ras (Optional)")),
              TextField(controller: ageController, decoration: const InputDecoration(labelText: "Usia (Tahun)"), keyboardType: TextInputType.number),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Batal")),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isNotEmpty && speciesController.text.isNotEmpty) {
                _savePet(
                  id: isEdit ? petData['id_hewan'] : null,
                  nama: nameController.text,
                  spesies: speciesController.text,
                  ras: breedController.text,
                  usia: ageController.text,
                );
              }
            },
            child: Text(isEdit ? "Update" : "Simpan"),
          ),
        ],
      ),
    );
  }

  // --- DIALOG KONFIRMASI HAPUS ---
  void _confirmDelete(int id, String nama) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Hapus Hewan?"),
        content: Text("Yakin ingin menghapus $nama?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Batal")),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deletePet(id);
            }, 
            child: const Text("Hapus", style: TextStyle(color: Colors.red))
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF0F766E);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F6),
      appBar: AppBar(
        title: const Text("Hewan Peliharaan", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: primaryColor),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () => _showPetDialog(),
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator()) 
          : _petsList.isEmpty 
              ? const Center(child: Text("Belum ada hewan peliharaan."))
              : ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: _petsList.length,
                  itemBuilder: (context, index) {
                    final pet = _petsList[index];
                    return _buildPetCard(
                      petData: pet,
                      color: (pet['spesies'].toString().toLowerCase() == 'kucing') ? Colors.orange : Colors.blue,
                      icon: (pet['spesies'].toString().toLowerCase() == 'kucing') ? Icons.pets : Icons.flutter_dash,
                    );
                  },
                ),
    );
  }

  Widget _buildPetCard({
    required Map<String, dynamic> petData,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          Container(
            width: 70, height: 70,
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(15), border: Border.all(color: color.withOpacity(0.3))),
            child: Icon(icon, color: color, size: 35),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(petData['nama'] ?? 'Tanpa Nama', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF334155))),
                const SizedBox(height: 4),
                Text("${petData['spesies']} • ${petData['ras'] ?? '-'}", style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                const SizedBox(height: 4),
                Text("${petData['usia'] ?? 0} Tahun", style: const TextStyle(color: Color(0xFF0F766E), fontWeight: FontWeight.w600, fontSize: 12)),
              ],
            ),
          ),
          Column(
            children: [
              IconButton(icon: const Icon(Icons.edit, size: 20, color: Colors.grey), onPressed: () => _showPetDialog(petData: petData)),
              IconButton(icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red), onPressed: () => _confirmDelete(petData['id_hewan'], petData['nama'])),
            ],
          )
        ],
      ),
    );
  }
}