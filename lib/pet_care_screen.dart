import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config.dart'; // Pastikan file ini ada

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
      // Handle ID: Kadang API kirim string, kita paksa jadi int biar aman
      id: json['id'] is String ? int.parse(json['id']) : json['id'],
      title: json['title'] ?? 'Tanpa Judul',
      category: json['category'] ?? 'Umum',
      image: json['image'] ?? '',
      excerpt: json['excerpt'] ?? '',
      externalLink: json['external_link'],
      createdAt: json['created_at'] ?? '',
    );
  }
}

// ==========================================
// 2. SCREEN UTAMA
// ==========================================
class PetCareScreen extends StatefulWidget {
  const PetCareScreen({super.key});

  @override
  State<PetCareScreen> createState() => _PetCareScreenState();
}

class _PetCareScreenState extends State<PetCareScreen> {
  // --- Config Warna ---
  final Color primaryColor = const Color(0xFF3C8085);
  final Color primarySoft = const Color(0xFFE0F2F1);
  final Color textDark = const Color(0xFF1F2937);
  final Color textGrey = const Color(0xFF64748B);

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

  // --- FETCH DATA (CLEAN VERSION) ---
  Future<void> _fetchArticles({String? query}) async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      // Bangun Query Parameters
      String queryString = "?";
      if (_selectedCategory != 'Semua') {
        queryString += "category=$_selectedCategory&";
      }
      if (query != null && query.isNotEmpty) {
        queryString += "q=$query";
      }

      // Gunakan AppConfig.baseUrl (Bukan Hardcode lagi!)
      final url = Uri.parse('${AppConfig.baseUrl}/api/petcare$queryString');
      
      // Debug Print (Opsional, biar tenang)
      print("Requesting: $url");

      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json'
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
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

  // --- HELPER GAMBAR ---
  String _getImageUrl(String rawPath) {
    if (rawPath.isEmpty) return "https://via.placeholder.com/400x300?text=No+Image";
    if (rawPath.startsWith('http')) return rawPath;
    
    // Bersihkan path storage Laravel
    String cleanPath = rawPath.replaceAll('public/', '').replaceAll('public\\', '').replaceAll('\\', '/');
    if (cleanPath.startsWith('/')) cleanPath = cleanPath.substring(1);
    
    // Gunakan AppConfig baseurl
    return '${AppConfig.baseUrl}/storage/$cleanPath';
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _fetchArticles(query: query);
    });
  }

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
          // HEADER
          Container(
            padding: const EdgeInsets.fromLTRB(16, 40, 16, 20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2A5C5F), Color(0xFF3C8085)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
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
                  ),
                ),
              ],
            ),
          ),

          // FILTER KATEGORI
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                _buildCategoryChip("Semua"),
                _buildCategoryChip("Kesehatan"),
                _buildCategoryChip("Vaksinasi"),
                _buildCategoryChip("Perawatan"),
                _buildCategoryChip("Nutrisi"),
              ],
            ),
          ),

          // LIST ARTIKEL
          Expanded(
            child: _isLoading 
              ? Center(child: CircularProgressIndicator(color: primaryColor))
              : _articles.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.article_outlined, size: 60, color: textGrey.withOpacity(0.5)),
                        const SizedBox(height: 10),
                        Text("Belum ada artikel", style: TextStyle(color: textGrey)),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    itemCount: _articles.length,
                    itemBuilder: (context, index) => _buildArticleCard(_articles[index]),
                  ),
          ),
        ],
      ),
    );
  }

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
            border: Border.all(color: isSelected ? primaryColor : Colors.grey.shade300),
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

  Widget _buildArticleCard(Article article) {
    return GestureDetector(
      onTap: () {
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
          boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.08), blurRadius: 15, offset: const Offset(0, 5))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: Image.network(
                _getImageUrl(article.image),
                height: 180, width: double.infinity, fit: BoxFit.cover,
                errorBuilder: (ctx, err, stack) => Container(
                  height: 180, color: Colors.grey.shade200, 
                  child: const Center(child: Icon(Icons.pets, size: 40, color: Colors.grey))
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: primarySoft, borderRadius: BorderRadius.circular(8)),
                    child: Text(article.category, style: TextStyle(color: primaryColor, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 8),
                  Text(article.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textDark)),
                  const SizedBox(height: 6),
                  Text(article.excerpt, maxLines: 3, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: textGrey, height: 1.5)),
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
// 3. SCREEN DETAIL (Simpel)
// ==========================================
class PetCareDetailScreen extends StatelessWidget {
  final Article article;
  final String imageUrl;

  const PetCareDetailScreen({super.key, required this.article, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(backgroundColor: const Color(0xFF3C8085), title: const Text("Detail Artikel")),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Image.network(imageUrl, height: 250, width: double.infinity, fit: BoxFit.cover,
              errorBuilder: (ctx, err, stack) => Container(height: 250, color: Colors.grey),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Text(article.title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                   const SizedBox(height: 10),
                   Text("Kategori: ${article.category}", style: const TextStyle(color: Colors.grey)),
                   const Divider(height: 30),
                   Text(article.excerpt, style: const TextStyle(fontSize: 16, height: 1.6)),
                   const SizedBox(height: 20),
                   const Text("Lorem ipsum dolor sit amet...", style: TextStyle(color: Colors.black54)), // Dummy content
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}