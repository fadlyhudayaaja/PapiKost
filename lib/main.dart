import 'package:flutter/material.dart';

void main() {
  runApp(const PapiKostApp());
}

// =============================================================
// ROOT APP
// =============================================================
class PapiKostApp extends StatelessWidget {
  const PapiKostApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PapiKost Mobile',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0D2B55), // Navy
          primary: const Color(0xFF0D2B55),
          secondary: const Color(0xFF00BCD4), // Cyan/Teal
          surface: Colors.white,
        ),
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      home: const HomeScreen(),
    );
  }
}

// =============================================================
// DATA DUMMY
// =============================================================

// Model sederhana untuk properti kost
class KostProperty {
  final String name;
  final String location;
  final String price;
  final String imageUrl;
  final bool bisaPatungan;
  final String type; // Putra / Putri / Campur
  final double rating;

  const KostProperty({
    required this.name,
    required this.location,
    required this.price,
    required this.imageUrl,
    required this.bisaPatungan,
    required this.type,
    required this.rating,
  });
}

const List<KostProperty> dummyProperties = [
  KostProperty(
    name: 'Kost Harmoni Residence',
    location: 'Jl. Dr. Mansyur No. 12, Medan',
    price: 'Rp 800.000 / bln',
    imageUrl: 'https://images.unsplash.com/photo-1555854877-bab0e564b8d5?w=600',
    bisaPatungan: true,
    type: 'Campur',
    rating: 4.8,
  ),
  KostProperty(
    name: 'Kost Putri Melati',
    location: 'Jl. Setia Budi No. 45, Medan',
    price: 'Rp 650.000 / bln',
    imageUrl:
        'https://images.unsplash.com/photo-1631049307264-da0ec9d70304?w=600',
    bisaPatungan: false,
    type: 'Putri',
    rating: 4.5,
  ),
  KostProperty(
    name: 'Kost Putra Sejahtera',
    location: 'Jl. Universitas No. 7, Medan',
    price: 'Rp 750.000 / bln',
    imageUrl:
        'https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?w=600',
    bisaPatungan: true,
    type: 'Putra',
    rating: 4.7,
  ),
  KostProperty(
    name: 'Kost Grand Serdang',
    location: 'Jl. Jamin Ginting No. 88, Medan',
    price: 'Rp 1.200.000 / bln',
    imageUrl:
        'https://images.unsplash.com/photo-1502672260266-1c1ef2d93688?w=600',
    bisaPatungan: true,
    type: 'Campur',
    rating: 4.9,
  ),
];

// =============================================================
// HOME SCREEN (StatefulWidget untuk state tab & filter aktif)
// =============================================================
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedNavIndex = 0;
  int _selectedFilterIndex = 0;

  // Warna utama
  static const Color navyColor = Color(0xFF0D2B55);
  static const Color cyanColor = Color(0xFF00BCD4);
  static const Color lightNavy = Color(0xFF1A3F73);

  final List<String> _filterLabels = [
    'Semua',
    'Bisa Patungan',
    'Kost Putra',
    'Kost Putri',
    'Terdekat',
    'Terjangkau',
  ];

  // Filter properties berdasarkan kategori yang dipilih
  List<KostProperty> get _filteredProperties {
    switch (_selectedFilterIndex) {
      case 1:
        return dummyProperties.where((p) => p.bisaPatungan).toList();
      case 2:
        return dummyProperties.where((p) => p.type == 'Putra').toList();
      case 3:
        return dummyProperties.where((p) => p.type == 'Putri').toList();
      default:
        return dummyProperties;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      // ── BODY ──────────────────────────────────────────────
      body: CustomScrollView(
        slivers: [
          // ── SLIVER APP BAR (Header) ──────────────────────
          SliverAppBar(
            expandedHeight: 180,
            floating: false,
            pinned: true,
            backgroundColor: navyColor,
            flexibleSpace: FlexibleSpaceBar(background: _buildHeader()),
            // Search bar muncul saat di-scroll (pinned)
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(56),
              child: _buildSearchBar(),
            ),
          ),

          // ── KONTEN UTAMA ─────────────────────────────────
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                // Filter Kategori
                _buildFilterCategories(),
                const SizedBox(height: 16),
                // Judul Daftar Properti
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Kost Tersedia',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: navyColor,
                        ),
                      ),
                      TextButton(
                        onPressed: () {},
                        child: Text(
                          'Lihat Semua',
                          style: TextStyle(
                            color: cyanColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                // Daftar Properti
                ..._filteredProperties.map(
                  (property) => _buildPropertyCard(property),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),

      // ── BOTTOM NAVIGATION BAR ─────────────────────────────
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  // -----------------------------------------------------------
  // WIDGET: Header
  // -----------------------------------------------------------
  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [navyColor, lightNavy],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.fromLTRB(16, 48, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // -- Teks sapaan & lokasi
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Halo, Mahasiswa! 👋',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          color: Color(0xFF00BCD4),
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        const Flexible(
                          child: Text(
                            'Universitas Sumatera Utara, Medan',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFFB0C4DE),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // -- Foto Profil
              GestureDetector(
                onTap: () {},
                child: Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFF00BCD4),
                          width: 2.5,
                        ),
                      ),
                      child: const CircleAvatar(
                        radius: 26,
                        backgroundImage: NetworkImage(
                          'https://i.pravatar.cc/150?img=12',
                        ),
                        backgroundColor: Color(0xFF1A3F73),
                      ),
                    ),
                    // Notifikasi badge
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: Colors.redAccent,
                          shape: BoxShape.circle,
                          border: Border.all(color: navyColor, width: 1.5),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // -----------------------------------------------------------
  // WIDGET: Search Bar
  // -----------------------------------------------------------
  Widget _buildSearchBar() {
    return Container(
      color: navyColor,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            const SizedBox(width: 12),
            // Ikon sparkles (AI)
            ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [Color(0xFF00BCD4), Color(0xFF0D2B55)],
              ).createShader(bounds),
              child: const Icon(
                Icons.auto_awesome, // sparkles / AI icon
                size: 22,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Tanya PapiBot untuk cari kost...',
                style: TextStyle(color: Color(0xFF9E9E9E), fontSize: 14),
              ),
            ),
            Container(
              margin: const EdgeInsets.all(6),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF0D2B55),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Cari',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // -----------------------------------------------------------
  // WIDGET: Filter Kategori (Horizontal Scroll)
  // -----------------------------------------------------------
  Widget _buildFilterCategories() {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _filterLabels.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final bool isActive = _selectedFilterIndex == index;
          return GestureDetector(
            onTap: () => setState(() => _selectedFilterIndex = index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isActive ? navyColor : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isActive ? navyColor : const Color(0xFFDDE3F0),
                ),
                boxShadow: isActive
                    ? [
                        BoxShadow(
                          color: navyColor.withOpacity(0.3),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : [],
              ),
              child: Text(
                _filterLabels[index],
                style: TextStyle(
                  color: isActive ? Colors.white : const Color(0xFF555E7A),
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                  fontSize: 13,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // -----------------------------------------------------------
  // WIDGET: Property Card
  // -----------------------------------------------------------
  Widget _buildPropertyCard(KostProperty property) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // -- Foto Properti
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Stack(
              children: [
                Image.network(
                  property.imageUrl,
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  // Placeholder saat gambar loading
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      height: 180,
                      color: const Color(0xFFEBEFF7),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: cyanColor,
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                              : null,
                        ),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 180,
                    color: const Color(0xFFEBEFF7),
                    child: const Center(
                      child: Icon(
                        Icons.image_not_supported_outlined,
                        color: Colors.grey,
                        size: 40,
                      ),
                    ),
                  ),
                ),
                // Badge "Bisa Patungan"
                if (property.bisaPatungan)
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2E7D32), // hijau gelap
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(
                            Icons.people_alt_rounded,
                            color: Colors.white,
                            size: 12,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Bisa Patungan',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                // Badge tipe kost (Putra/Putri/Campur)
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: navyColor.withOpacity(0.85),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Kost ${property.type}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // -- Info Properti
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Nama kost & rating
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        property.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0D2B55),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          color: Colors.amber,
                          size: 16,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          property.rating.toString(),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF555E7A),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                // Lokasi
                Row(
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      size: 14,
                      color: Color(0xFF00BCD4),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        property.location,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF777E90),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // Divider
                const Divider(height: 1, color: Color(0xFFEBEFF7)),
                const SizedBox(height: 10),
                // Harga & tombol detail
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Mulai dari',
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF9E9E9E),
                          ),
                        ),
                        Text(
                          property.price,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0D2B55),
                          ),
                        ),
                      ],
                    ),
                    ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0D2B55),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Lihat Detail',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // -----------------------------------------------------------
  // WIDGET: Bottom Navigation Bar
  // -----------------------------------------------------------
  Widget _buildBottomNavBar() {
    const Color navyColor = Color(0xFF0D2B55);
    const Color cyanColor = Color(0xFF00BCD4);

    final List<Map<String, dynamic>> navItems = [
      {'icon': Icons.home_rounded, 'label': 'Beranda'},
      {'icon': Icons.smart_toy_rounded, 'label': 'PapiBot'},
      {'icon': Icons.receipt_long_rounded, 'label': 'Tiket'},
      {'icon': Icons.person_rounded, 'label': 'Profil'},
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          height: 64,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(navItems.length, (index) {
              final bool isActive = _selectedNavIndex == index;
              return GestureDetector(
                onTap: () => setState(() => _selectedNavIndex = index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isActive
                        ? navyColor.withOpacity(0.08)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        navItems[index]['icon'] as IconData,
                        color: isActive ? navyColor : const Color(0xFFADB5BD),
                        size: 24,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        navItems[index]['label'] as String,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: isActive
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: isActive ? navyColor : const Color(0xFFADB5BD),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
