// lib/profile_screen.dart
import 'dart:typed_data'; 
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart'; 
import 'dart:convert';
import 'login_screen.dart'; 
import 'history_screen.dart'; 
import 'config.dart'; 

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _userName = "Loading...";
  String _userEmail = "";
  String? _userPhotoUrl; 
  
  // Menggunakan Uint8List agar support Web & Mobile
  Uint8List? _imageBytes; 
  
  final ImagePicker _picker = ImagePicker();
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  // --- 1. LOAD DATA & SUSUN URL FOTO ---
  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    
    // Ambil string JSON utuh
    String? userJson = prefs.getString('user_data');
    String rawPhotoPath = "";

    if (userJson != null) {
      final userData = jsonDecode(userJson);
      _userName = userData['nama'] ?? "Guest";
      _userEmail = userData['email'] ?? "guest@locsato.com";
      
      // Pastikan key sesuai database ('profile_pic')
      rawPhotoPath = userData['profile_pic'] ?? "";
    } 

    setState(() {
      // Logic penyusunan URL Foto yang Support Windows & Linux
      if (rawPhotoPath.isNotEmpty) {
        
        // 1. Bersihkan path dari 'public/' dan ubah Backslash (\) jadi Slash (/)
        String cleanPath = rawPhotoPath
            .replaceAll('public/', '')   // Hapus public/ biasa
            .replaceAll('public\\', '')  // Hapus public\ (versi Windows)
            .replaceAll('\\', '/');      // Ubah semua \ jadi / agar HP bisa baca

        // 2. Hapus slash di awal jika ada (misal: /profile_photos/...)
        if (cleanPath.startsWith('/')) {
            cleanPath = cleanPath.substring(1);
        }
        
        // 3. Susun URL Akhir
        if (cleanPath.startsWith('http')) {
           _userPhotoUrl = cleanPath;
        } else {
           _userPhotoUrl = '${AppConfig.baseUrl}/storage/$cleanPath';
        }

        // Debugging di Terminal
        print("URL Foto Profil: $_userPhotoUrl");

      } else {
        _userPhotoUrl = null;
      }
    });
  }

  // --- 2. PILIH GAMBAR (UNIVERSAL) ---
  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery, 
        imageQuality: 50 
      );

      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        
        setState(() {
          _imageBytes = bytes; // Tampilkan preview lokal dulu biar cepat
        });

        // Langsung upload ke server
        _updateProfilePhoto(bytes);
      }
    } catch (e) {
      debugPrint("Error picking image: $e");
    }
  }

  // --- 3. UPLOAD GAMBAR ---
  Future<void> _updateProfilePhoto(Uint8List bytes) async {
    setState(() => _isUploading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      
      // Endpoint Update Foto
      final uri = Uri.parse('${AppConfig.baseUrl}/api/update-profile-photo'); 

      var request = http.MultipartRequest('POST', uri);
      
      request.headers.addAll({
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      });

      // Upload File dengan key 'photo'
      request.files.add(http.MultipartFile.fromBytes(
        'photo', 
        bytes,
        filename: 'profile_upload.jpg'
      ));

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // --- UPDATE DATA LOKAL SETELAH UPLOAD SUKSES ---
        if (data['data'] != null && data['data']['user'] != null) {
            final newUserObject = data['data']['user'];
            
            // 1. Simpan data user terbaru (yang berisi path foto baru) ke SharedPreferences
            await prefs.setString('user_data', jsonEncode(newUserObject));
            
            // 2. Refresh Tampilan
            await _loadUserData(); 

            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Foto profil berhasil diperbarui!"), backgroundColor: Colors.green),
              );
            }
        } else {
            // Fallback: Reload manual jika struktur beda
            await _loadUserData();
        }

      } else {
        throw Exception("Gagal upload (${response.statusCode}): ${response.body}");
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Gagal mengganti foto: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
           _isUploading = false;
           _imageBytes = null; // Reset bytes agar tampilan kembali menggunakan URL dari server
        });
      }
    }
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear(); 

    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false, 
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF3C8085);
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // COMPACT HEADER
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Profil Saya",
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                    ),
                    IconButton(
                      icon: const Icon(Icons.settings, color: Colors.grey),
                      onPressed: () {}, // Future settings
                    )
                  ],
                ),
              ),

              const SizedBox(height: 10),

              // PROFILE PICTURE & INFO
              Center(
                child: Column(
                  children: [
                    Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        Container(
                          width: 110, height: 110,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.grey[200],
                            border: Border.all(color: primaryColor.withOpacity(0.2), width: 4),
                          ),
                          child: ClipOval(
                            child: _isUploading
                              ? const Padding(padding: EdgeInsets.all(30), child: CircularProgressIndicator())
                              : _imageBytes != null 
                                  ? Image.memory(_imageBytes!, fit: BoxFit.cover) 
                                  : (_userPhotoUrl != null && _userPhotoUrl!.isNotEmpty)
                                    ? Image.network(
                                        '$_userPhotoUrl?v=${DateTime.now().millisecondsSinceEpoch}',
                                        fit: BoxFit.cover,
                                        loadingBuilder: (context, child, loadingProgress) {
                                          if (loadingProgress == null) return child;
                                          return const Center(child: CircularProgressIndicator(strokeWidth: 2));
                                        },
                                        errorBuilder: (context, error, stackTrace) => const Icon(Icons.person, size: 50, color: Colors.grey),
                                      )
                                    : Center(
                                        child: Text(
                                          _userName.isNotEmpty ? _userName[0].toUpperCase() : "U",
                                          style: TextStyle(fontSize: 40, color: Colors.grey[400], fontWeight: FontWeight.bold)
                                        )
                                      ),
                          ),
                        ),
                        InkWell(
                          onTap: _isUploading ? null : _pickImage,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(color: primaryColor, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 3)),
                            child: const Icon(Icons.camera_alt, size: 18, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(_userName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                    const SizedBox(height: 4),
                    Text(_userEmail, style: const TextStyle(color: Colors.grey, fontSize: 13)),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // --- MENU ---
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    children: [
                      _buildMenuItem(
                        context, 
                        Icons.person_outline, 
                        "Informasi Pribadi",
                        () async {
                          await Navigator.push(context, MaterialPageRoute(builder: (context) => const PersonalInfoPage()));
                          _loadUserData(); 
                        },
                      ),
                      Divider(height: 1, indent: 60, color: Colors.grey.shade100),
                      _buildMenuItem(
                        context, 
                        Icons.pets, 
                        "Hewan Peliharaan",
                        () => Navigator.push(context, MaterialPageRoute(builder: (context) => const MyPetsPage())),
                      ),
                      Divider(height: 1, indent: 60, color: Colors.grey.shade100), 
                      _buildMenuItem(
                        context, 
                        Icons.history, 
                        "Riwayat Konsultasi",
                        () => Navigator.push(context, MaterialPageRoute(builder: (context) => const HistoryScreen())),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // --- TOMBOL KELUAR ---
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: TextButton.icon(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      foregroundColor: Colors.red,
                    ),
                    onPressed: _logout,
                    icon: const Icon(Icons.logout),
                    label: const Text("Keluar", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem(BuildContext context, IconData icon, String title, VoidCallback onTap) {
    const primaryColor = Color(0xFF3C8085);
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: primaryColor, size: 22),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1E293B))),
      trailing: Icon(Icons.chevron_right, color: Colors.grey[300]),
      onTap: onTap,
    );
  }
}

// ==========================================
// class PersonalInfoPage dan MyPetsPage
// (TIDAK PERLU DIUBAH, SAMA SEPERTI KODE KAMU)
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
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final url = Uri.parse('${AppConfig.baseUrl}/api/user'); 
      final response = await http.get(url, headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'});

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _nameController.text = data['nama'] ?? ""; 
          _phoneController.text = data['telepon'] ?? ""; 
          _addressController.text = data['alamat'] ?? "";
        });
        // Update SharedPreferences juga
        String? userJson = prefs.getString('user_data');
        if (userJson != null) {
          var userData = jsonDecode(userJson);
          userData['nama'] = data['nama'];
          userData['telepon'] = data['telepon'];
          userData['alamat'] = data['alamat'];
          await prefs.setString('user_data', jsonEncode(userData));
        }
      }
    } catch (e) {
      print("Gagal memuat data profile: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updateProfile() async {
    setState(() { _isLoading = true; });
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token'); 
      final url = Uri.parse('${AppConfig.baseUrl}/api/update-profile');
      final response = await http.post(
        url,
        headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json', 'Content-Type': 'application/json'},
        body: jsonEncode({
          'nama': _nameController.text,
          'telepon': _phoneController.text,
          'alamat': _addressController.text,
        }),
      );

      if (response.statusCode == 200) {
        // Update SharedPreferences
        String? userJson = prefs.getString('user_data');
        if (userJson != null) {
          var userData = jsonDecode(userJson);
          userData['nama'] = _nameController.text;
          userData['telepon'] = _phoneController.text;
          userData['alamat'] = _addressController.text;
          await prefs.setString('user_data', jsonEncode(userData));
        }
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Profil Berhasil Diperbarui!"), backgroundColor: Colors.green));
          Navigator.pop(context); 
        }
      } else {
        throw Exception("Gagal update: ${response.statusCode}");
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
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
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 10)]),
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
                      style: ElevatedButton.styleFrom(backgroundColor: primaryColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)), elevation: 2),
                      onPressed: _isLoading ? null : _updateProfile,
                      child: _isLoading ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text("Simpan Perubahan", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
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
      decoration: InputDecoration(prefixIcon: Icon(icon, color: const Color(0xFF0F766E)), filled: true, fillColor: const Color(0xFFF8FAFC), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
    );
  }
}

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

  Future<void> _fetchPets() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final url = Uri.parse('${AppConfig.baseUrl}/api/pets');
      final response = await http.get(url, headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'});

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) setState(() { _petsList = data['data']; _isLoading = false; });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _savePet({int? id, required String nama, required String spesies, String? ras, String? usia}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final url = id == null ? Uri.parse('${AppConfig.baseUrl}/api/pets') : Uri.parse('${AppConfig.baseUrl}/api/pets/$id');
      final bodyData = jsonEncode({'nama': nama, 'spesies': spesies, 'ras': ras ?? '', 'usia': usia ?? '0'});
      final Map<String, String> headers = {'Authorization': 'Bearer $token', 'Accept': 'application/json', 'Content-Type': 'application/json'};
      final response = id == null ? await http.post(url, headers: headers, body: bodyData) : await http.put(url, headers: headers, body: bodyData);

      if (response.statusCode == 201 || response.statusCode == 200) {
        if(mounted) Navigator.pop(context);
        _fetchPets();
        if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(id == null ? "Hewan ditambahkan!" : "Hewan diperbarui!"), backgroundColor: Colors.green));
      } else {
        throw Exception('Gagal menyimpan: ${response.statusCode}');
      }
    } catch (e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
    }
  }

  Future<void> _deletePet(int id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final url = Uri.parse('${AppConfig.baseUrl}/api/pets/$id');
      final response = await http.delete(url, headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'});
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
                _savePet(id: isEdit ? petData['id_hewan'] : null, nama: nameController.text, spesies: speciesController.text, ras: breedController.text, usia: ageController.text);
              }
            },
            child: Text(isEdit ? "Update" : "Simpan"),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(int id, String nama) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Hapus Hewan?"),
        content: Text("Yakin ingin menghapus $nama?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Batal")),
          TextButton(onPressed: () { Navigator.pop(context); _deletePet(id); }, child: const Text("Hapus", style: TextStyle(color: Colors.red))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF0F766E);
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F6),
      appBar: AppBar(title: const Text("Hewan Peliharaan", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)), backgroundColor: Colors.white, elevation: 0, iconTheme: const IconThemeData(color: primaryColor)),
      floatingActionButton: FloatingActionButton(backgroundColor: primaryColor, child: const Icon(Icons.add, color: Colors.white), onPressed: () => _showPetDialog()),
      body: _isLoading ? const Center(child: CircularProgressIndicator()) : _petsList.isEmpty ? const Center(child: Text("Belum ada hewan peliharaan.")) : ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: _petsList.length,
        itemBuilder: (context, index) {
          final pet = _petsList[index];
          return _buildPetCard(petData: pet, color: (pet['spesies'].toString().toLowerCase() == 'kucing') ? Colors.orange : Colors.blue, icon: (pet['spesies'].toString().toLowerCase() == 'kucing') ? Icons.pets : Icons.flutter_dash);
        },
      ),
    );
  }

  Widget _buildPetCard({required Map<String, dynamic> petData, required Color color, required IconData icon}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16), padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))]),
      child: Row(
        children: [
          Container(width: 70, height: 70, decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(15), border: Border.all(color: color.withOpacity(0.3))), child: Icon(icon, color: color, size: 35)),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(petData['nama'] ?? 'Tanpa Nama', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF334155))),
            const SizedBox(height: 4), Text("${petData['spesies']} • ${petData['ras'] ?? '-'}", style: TextStyle(color: Colors.grey[600], fontSize: 12)),
            const SizedBox(height: 4), Text("${petData['usia'] ?? 0} Tahun", style: const TextStyle(color: Color(0xFF0F766E), fontWeight: FontWeight.w600, fontSize: 12)),
          ])),
          Column(children: [
            IconButton(icon: const Icon(Icons.edit, size: 20, color: Colors.grey), onPressed: () => _showPetDialog(petData: petData)),
            IconButton(icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red), onPressed: () => _confirmDelete(petData['id_hewan'], petData['nama'])),
          ])
        ],
      ),
    );
  }
}