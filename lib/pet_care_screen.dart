import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'config.dart'; // Pastikan file config.dart sudah ada

// ==========================================
// 1. MODEL ARTIKEL
// ==========================================
class Article {
  final int id;
  final String title;
  final String category;
  final String image;
  final String excerpt;
  final String? externalLink;
  final String createdAt;

  Article({
    required this.id,
    required this.title,
    required this.category,
    required this.image,
    required this.excerpt,
    this.externalLink,
    required this.createdAt,
  });

  factory Article.fromJson(Map<String, dynamic> json) {
    return Article(
      id: json['id'],
      title: json['title'],
      category: json['category'],
      // Handle null image dengan string kosong
      image: json['image'] ?? '',
      excerpt: json['excerpt'] ?? '',
      externalLink: json['external_link'],
      createdAt: json['created_at'] ?? '',
    );
  }
}

// ==========================================
// 2. SCREEN UTAMA: LIST ARTIKEL
// ==========================================
class PetCareScreen extends StatefulWidget {
  const PetCareScreen({super.key});

  @override
  State<PetCareScreen> createState() => _PetCareScreenState();
}

class _PetCareScreenState extends State<PetCareScreen> {
  // Config Warna
  final Color primaryColor = const Color(0xFF3C8085);
  final Color primarySoft = const Color(0xFFE0F2F1);
  final Color textDark = const Color(0xFF1F2937);
  final Color textGrey = const Color(0xFF64748B);

  // State Data
  List<Article> _articles = [];
  bool _isLoading = true;
  String _selectedCategory = 'Semua';
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _fetchArticles();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  // --- LOGIC FETCH DATA API ---
  Future<void> _fetchArticles({String? query}) async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      // Bangun URL Query parameters
      String queryString = "?";
      if (_selectedCategory != 'Semua') {
        queryString += "category=$_selectedCategory&";
      }
      if (query != null && query.isNotEmpty) {
        queryString += "q=$query";
      }

      // Pastikan route API Laravel Anda sesuai: /api/petcare
      final url = Uri.parse('${AppConfig.baseUrl}/api/petcare$queryString');

      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json'
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Sesuaikan parsing JSON dengan response Laravel (biasanya data['data'])
        final List<dynamic> rawList = data['data'] ?? []; 
        
        if (mounted) {
          setState(() {
            _articles = rawList.map((json) => Article.fromJson(json)).toList();
            _isLoading = false;
          });
        }
      } else {
        throw Exception('Gagal load data: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint("Error fetching articles: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Helper URL Gambar
  String _getImageUrl(String rawPath) {
    if (rawPath.isEmpty) return "https://via.placeholder.com/400x300?text=No+Image";
    if (rawPath.startsWith('http')) return rawPath;
    
    String cleanPath = rawPath.replaceAll('public/', '').replaceAll('public\\', '').replaceAll('\\', '/');
    if (cleanPath.startsWith('/')) cleanPath = cleanPath.substring(1);
    
    return '${AppConfig.baseUrl}/storage/$cleanPath';
  }

  // Fungsi Pencarian (Debounce)
  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _fetchArticles(query: query);
    });
  }

  // Fungsi Ganti Kategori
  void _onCategoryChanged(String category) {
    setState(() {
      _selectedCategory = category;
    });
    _fetchArticles(query: _searchController.text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          // --- HERO HEADER ---
          Container(
            padding: const EdgeInsets.fromLTRB(20, 50, 20, 30),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [primaryColor, const Color(0xFF1a4042)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Expanded(
                      child: Text(
                        "Pet Care Center",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 40), 
                  ],
                ),
                const SizedBox(height: 20),
                const Text(
                  "Peduli Kesehatan Hewan Anda",
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  "Temukan tips & trik merawat anabul.",
                  style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 12),
                ),
                const SizedBox(height: 20),
                
                // Search Box
                TextField(
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                  decoration: InputDecoration(
                    hintText: "Cari artikel...",
                    fillColor: Colors.white,
                    filled: true,
                    prefixIcon: Icon(Icons.search, color: primaryColor),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(50),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                  ),
                ),
              ],
            ),
          ),

          // --- KATEGORI FILTER ---
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            child: Row(
              children: [
                _buildCategoryChip("Semua"),
                _buildCategoryChip("Kesehatan"),
                _buildCategoryChip("Vaksinasi"),
                _buildCategoryChip("Perawatan"),
              ],
            ),
          ),

          // --- LIST ARTIKEL ---
          Expanded(
            child: _isLoading 
              ? Center(child: CircularProgressIndicator(color: primaryColor))
              : _articles.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off, size: 60, color: textGrey.withOpacity(0.5)),
                        const SizedBox(height: 10),
                        Text("Artikel tidak ditemukan", style: TextStyle(color: textGrey)),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    itemCount: _articles.length,
                    itemBuilder: (context, index) {
                      final article = _articles[index];
                      return _buildArticleCard(article);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // WIDGET: Category Chip
  Widget _buildCategoryChip(String label) {
    bool isSelected = _selectedCategory == label;
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: GestureDetector(
        onTap: () => _onCategoryChanged(label),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? primaryColor : Colors.white,
            borderRadius: BorderRadius.circular(50),
            border: Border.all(
              color: isSelected ? primaryColor : Colors.grey.shade300,
            ),
            boxShadow: isSelected 
              ? [BoxShadow(color: primaryColor.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))] 
              : [],
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : textGrey,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }

  // WIDGET: Article Card
  Widget _buildArticleCard(Article article) {
    return GestureDetector(
      onTap: () {
        // Navigasi ke Detail Screen (Class ada di bawah)
        Navigator.push(
          context, 
          MaterialPageRoute(
            builder: (_) => PetCareDetailScreen(
              article: article, 
              imageUrl: _getImageUrl(article.image)
            )
          )
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.grey.withOpacity(0.08), blurRadius: 15, offset: const Offset(0, 5)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Gambar Artikel
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: Image.network(
                _getImageUrl(article.image),
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (ctx, err, stack) => Container(
                  height: 180, color: Colors.grey.shade200, 
                  child: const Center(child: Icon(Icons.broken_image, color: Colors.grey))
                ),
              ),
            ),
            
            // Konten Text
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Label Kategori
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: primarySoft,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      article.category,
                      style: TextStyle(color: primaryColor, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  // Judul
                  Text(
                    article.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textDark),
                  ),
                  const SizedBox(height: 6),
                  
                  // Excerpt
                  Text(
                    article.excerpt,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, color: textGrey, height: 1.5),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// 3. SCREEN DETAIL: BACA ARTIKEL
// ==========================================
class PetCareDetailScreen extends StatelessWidget {
  final Article article;
  final String imageUrl;

  const PetCareDetailScreen({
    super.key, 
    required this.article, 
    required this.imageUrl
  });

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF3C8085);
    
    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          // Header Gambar Parallax
          SliverAppBar(
            expandedHeight: 250,
            pinned: true,
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              background: Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (ctx, err, stack) => Container(
                  color: Colors.grey.shade300,
                  child: const Center(child: Icon(Icons.broken_image, size: 50, color: Colors.grey)),
                ),
              ),
            ),
          ),

          // Konten Detail
          SliverToBoxAdapter(
            child: Container(
              transform: Matrix4.translationValues(0, -20, 0),
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Badge Kategori
                  Center(
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 20),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE0F2F1),
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: Text(
                        article.category,
                        style: const TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),

                  // Judul
                  Text(
                    article.title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.black87),
                  ),
                  const SizedBox(height: 10),

                  // Tanggal
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                      const SizedBox(width: 5),
                      Text(
                        article.createdAt.length > 10 
                            ? article.createdAt.substring(0, 10) 
                            : article.createdAt, 
                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 30),
                  const Divider(),
                  const SizedBox(height: 20),

                  // Excerpt (Highlight)
                  Text(
                    article.excerpt,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, height: 1.6, color: Colors.black87),
                  ),
                  const SizedBox(height: 20),
                  
                  // Body (Dummy Text - karena di Laravel juga dummy)
                  const Text(
                    "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.\n\nDuis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident.",
                    style: TextStyle(fontSize: 15, height: 1.8, color: Colors.black54),
                    textAlign: TextAlign.justify,
                  ),

                  // Link Eksternal Box
                  if (article.externalLink != null && article.externalLink!.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(top: 30),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFBFDBFE)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.info_outline, color: Colors.blue, size: 20),
                              SizedBox(width: 8),
                              Text("Sumber Asli", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Text("Baca artikel selengkapnya di website sumber:", style: TextStyle(fontSize: 12)),
                          const SizedBox(height: 10),
                          InkWell(
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text("Membuka: ${article.externalLink}")),
                              );
                            },
                            child: Row(
                              children: const [
                                Text("Kunjungi Website", style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, decoration: TextDecoration.underline)),
                                SizedBox(width: 5),
                                Icon(Icons.open_in_new, size: 14, color: Colors.blue)
                              ],
                            ),
                          )
                        ],
                      ),
                    ),
                    
                  const SizedBox(height: 50),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}