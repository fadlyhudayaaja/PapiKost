import '../../data/models/kost_model.dart';
import '../../data/models/reservation_model.dart';
import '../../data/models/ticket_model.dart';
import '../../data/models/user_model.dart';
import '../constants/app_constants.dart';

/// Semua data mock untuk development tanpa backend.
/// Ganti dengan API call asli saat backend sudah siap.
class MockService {
  MockService._();

  // ── Simulasi delay network ──────────────────────────────────────────────────
  static Future<void> _delay([int ms = 600]) =>
      Future.delayed(Duration(milliseconds: ms));

  // ── Mock Users ──────────────────────────────────────────────────────────────
  static final List<Map<String, String>> _accounts = [
    {
      'email': 'renter@papikost.com',
      'password': '123456',
      'role': AppConstants.roleRenter,
      'name': 'Andi Pratama',
      'phone': '081234567890',
    },
    {
      'email': 'owner@papikost.com',
      'password': '123456',
      'role': AppConstants.roleOwner,
      'name': 'Pak Budi Santoso',
      'phone': '082345678901',
    },
    {
      'email': 'admin@papikost.com',
      'password': '123456',
      'role': AppConstants.roleAdmin,
      'name': 'Admin PapiKost',
      'phone': '083456789012',
    },
  ];

  // ── Auth ────────────────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> login(
    String email,
    String password,
  ) async {
    await _delay(800);

    final account = _accounts.firstWhere(
      (a) => a['email'] == email.trim().toLowerCase(),
      orElse: () => {},
    );

    if (account.isEmpty) {
      throw Exception('Email tidak terdaftar');
    }
    if (account['password'] != password) {
      throw Exception('Password salah');
    }

    final user = UserModel(
      id: _accounts.indexOf(account) + 1,
      name: account['name']!,
      email: account['email']!,
      phone: account['phone']!,
      role: account['role']!,
      isVerified: true,
    );

    return {'token': 'mock_jwt_token_${user.id}_${user.role}', 'user': user};
  }

  static Future<void> register({
    required String name,
    required String email,
    required String password,
    required String phone,
    required String role,
  }) async {
    await _delay(800);
    // Cek duplikat email
    final exists = _accounts.any(
      (a) => a['email'] == email.trim().toLowerCase(),
    );
    if (exists) throw Exception('Email sudah terdaftar');
    // Di mock tidak benar-benar disimpan (session only)
  }

  // ── Kost ────────────────────────────────────────────────────────────────────
  static Future<List<KostModel>> fetchKostList({
    String? search,
    String? type,
  }) async {
    await _delay(700);
    var list = _mockKostList;
    if (search != null && search.isNotEmpty) {
      list = list
          .where(
            (k) =>
                k.name.toLowerCase().contains(search.toLowerCase()) ||
                k.address.toLowerCase().contains(search.toLowerCase()),
          )
          .toList();
    }
    if (type != null && type != 'ALL') {
      list = list.where((k) => k.type == type).toList();
    }
    return list;
  }

  static Future<KostModel> fetchKostById(int id) async {
    await _delay(500);
    return _mockKostList.firstWhere(
      (k) => k.id == id,
      orElse: () => _mockKostList.first,
    );
  }

  // ── Reservasi ───────────────────────────────────────────────────────────────
  static Future<List<ReservationModel>> fetchMyReservations() async {
    await _delay(600);
    return _mockReservations;
  }

  static Future<void> createReservation({
    required int kostId,
    required bool isSplitBill,
    int? splitMemberCount,
    required DateTime checkInDate,
    String? notes,
  }) async {
    await _delay(800);
    // Mock: selalu sukses
  }

  // ── Tiket ───────────────────────────────────────────────────────────────────
  static Future<List<TicketModel>> fetchMyTickets() async {
    await _delay(600);
    return _mockTickets;
  }

  static Future<void> createTicket({
    required String title,
    required String description,
    required String category,
    required int kostId,
  }) async {
    await _delay(800);
    // Mock: selalu sukses
  }

  // ── Owner ───────────────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> fetchOwnerStats() async {
    await _delay(500);
    return {
      'totalRooms': 12,
      'occupiedRooms': 8,
      'pendingReservations': 3,
      'pendingTickets': 2,
    };
  }

  static Future<List<ReservationModel>> fetchOwnerReservations() async {
    await _delay(600);
    return _mockOwnerReservations;
  }

  static Future<List<TicketModel>> fetchOwnerTickets() async {
    await _delay(600);
    return _mockOwnerTickets;
  }

  static Future<void> respondReservation(int id, bool approve) async {
    await _delay(500);
  }

  static Future<void> updateTicketStatus(int id, String status) async {
    await _delay(500);
  }

  // ── Admin ───────────────────────────────────────────────────────────────────
  static Future<List<UserModel>> fetchPendingOwners() async {
    await _delay(600);
    return _mockPendingOwners;
  }

  static Future<void> verifyOwner(int id, bool approve) async {
    await _delay(500);
  }

  // ════════════════════════════════════════════════════════════════════════════
  // MOCK DATA
  // ════════════════════════════════════════════════════════════════════════════

  static final List<KostModel> _mockKostList = [
    KostModel(
      id: 1,
      name: 'Kost Mawar Indah',
      address: 'Jl. Dr. Mansyur No. 12, Medan',
      city: 'Medan',
      pricePerMonth: 1200000,
      type: 'PUTRI',
      facilities: ['WiFi', 'AC', 'Kamar Mandi Dalam', 'Lemari', 'Meja Belajar'],
      imageUrls: [
        'https://images.unsplash.com/photo-1586023492125-27b2c045efd7?w=800',
        'https://images.unsplash.com/photo-1555041469-a586c61ea9bc?w=800',
      ],
      isSplitBillAvailable: true,
      totalRooms: 12,
      availableRooms: 4,
      description:
          'Kost putri nyaman dan aman dekat Universitas Sumatera Utara. '
          'Lingkungan bersih, kondusif untuk belajar, dan dekat dengan berbagai fasilitas kampus.',
      ownerName: 'Ibu Sari Dewi',
      rating: 4.5,
      reviewCount: 28,
      latitude: 3.5952,
      longitude: 98.6722,
    ),
    KostModel(
      id: 2,
      name: 'Kost Bumi Putera',
      address: 'Jl. Gagak Hitam No. 5, Medan',
      city: 'Medan',
      pricePerMonth: 900000,
      type: 'PUTRA',
      facilities: ['WiFi', 'Parkir Motor', 'Dapur Bersama', 'Lemari'],
      imageUrls: [
        'https://images.unsplash.com/photo-1560185007-cde436f6a4d0?w=800',
        'https://images.unsplash.com/photo-1631049307264-da0ec9d70304?w=800',
      ],
      isSplitBillAvailable: true,
      totalRooms: 8,
      availableRooms: 2,
      description:
          'Kost putra strategis dekat kampus USU dan Fasilkom. '
          'Akses mudah ke transportasi umum dan warung makan.',
      ownerName: 'Pak Budi Santoso',
      rating: 4.2,
      reviewCount: 15,
      latitude: 3.5870,
      longitude: 98.6764,
    ),
    KostModel(
      id: 3,
      name: 'Kost Harmoni Residence',
      address: 'Jl. Jamin Ginting No. 88, Medan',
      city: 'Medan',
      pricePerMonth: 1500000,
      type: 'CAMPUR',
      facilities: [
        'WiFi',
        'AC',
        'TV',
        'Kamar Mandi Dalam',
        'Dapur',
        'Keamanan 24 Jam',
      ],
      imageUrls: [
        'https://images.unsplash.com/photo-1631049307264-da0ec9d70304?w=800',
        'https://images.unsplash.com/photo-1618221195710-dd6b41faaea6?w=800',
      ],
      isSplitBillAvailable: false,
      totalRooms: 20,
      availableRooms: 7,
      description:
          'Kost campur premium dengan fasilitas lengkap. '
          'Cocok untuk mahasiswa maupun pekerja profesional yang menginginkan kenyamanan.',
      ownerName: 'Pak Hendri Wijaya',
      rating: 4.8,
      reviewCount: 42,
      latitude: 3.5620,
      longitude: 98.6901,
    ),
    KostModel(
      id: 4,
      name: 'Kost Green House',
      address: 'Jl. Setia Budi No. 32, Medan',
      city: 'Medan',
      pricePerMonth: 800000,
      type: 'CAMPUR',
      facilities: ['WiFi', 'Parkir Motor', 'Lemari', 'Meja Belajar'],
      imageUrls: [
        'https://images.unsplash.com/photo-1493809842364-78817add7ffb?w=800',
      ],
      isSplitBillAvailable: true,
      totalRooms: 15,
      availableRooms: 6,
      description:
          'Kost campur dengan harga terjangkau dan lingkungan asri. '
          'Cocok untuk mahasiswa yang mencari tempat tinggal ekonomis.',
      ownerName: 'Bu Ratna Sari',
      rating: 4.0,
      reviewCount: 20,
      latitude: 3.5750,
      longitude: 98.6850,
    ),
    KostModel(
      id: 5,
      name: 'Kost Putri Cantik',
      address: 'Jl. Perpustakaan No. 7, USU, Medan',
      city: 'Medan',
      pricePerMonth: 1100000,
      type: 'PUTRI',
      facilities: ['WiFi', 'AC', 'Kamar Mandi Dalam', 'Laundry', 'CCTV'],
      imageUrls: [
        'https://images.unsplash.com/photo-1616594039964-ae9021a400a0?w=800',
      ],
      isSplitBillAvailable: true,
      totalRooms: 10,
      availableRooms: 3,
      description:
          'Kost putri eksklusif tepat di dalam lingkungan USU. '
          'Keamanan terjamin dengan CCTV 24 jam dan akses kartu.',
      ownerName: 'Ibu Fitri Handayani',
      rating: 4.6,
      reviewCount: 33,
      latitude: 3.5900,
      longitude: 98.6800,
    ),
  ];

  static final List<ReservationModel> _mockReservations = [
    ReservationModel(
      id: 1,
      kostId: 1,
      kostName: 'Kost Mawar Indah',
      kostAddress: 'Jl. Dr. Mansyur No. 12',
      renterId: 1,
      renterName: 'Andi Pratama',
      renterEmail: 'renter@papikost.com',
      renterPhone: '081234567890',
      status: AppConstants.reservationStatusApproved,
      isSplitBill: false,
      totalPrice: 1200000,
      checkInDate: DateTime.now().add(const Duration(days: 5)),
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
    ReservationModel(
      id: 2,
      kostId: 2,
      kostName: 'Kost Bumi Putera',
      kostAddress: 'Jl. Gagak Hitam No. 5',
      renterId: 1,
      renterName: 'Andi Pratama',
      renterEmail: 'renter@papikost.com',
      renterPhone: '081234567890',
      status: AppConstants.reservationStatusPending,
      isSplitBill: true,
      splitMemberCount: 2,
      totalPrice: 900000,
      pricePerPerson: 450000,
      checkInDate: DateTime.now().add(const Duration(days: 14)),
      createdAt: DateTime.now().subtract(const Duration(hours: 3)),
    ),
  ];

  static final List<TicketModel> _mockTickets = [
    TicketModel(
      id: 1,
      title: 'Lampu kamar tidak menyala',
      description: 'Lampu di kamar saya sudah mati sejak 3 hari lalu.',
      category: 'LISTRIK',
      status: AppConstants.ticketStatusPending,
      imageUrls: [],
      renterId: 1,
      renterName: 'Andi Pratama',
      kostId: 1,
      kostName: 'Kost Mawar Indah',
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
    ),
    TicketModel(
      id: 2,
      title: 'Keran kamar mandi bocor',
      description: 'Keran air di kamar mandi terus menetes.',
      category: 'AIR',
      status: AppConstants.ticketStatusInProgress,
      imageUrls: [],
      renterId: 1,
      renterName: 'Andi Pratama',
      kostId: 1,
      kostName: 'Kost Mawar Indah',
      ownerNote: 'Sedang menunggu tukang ledeng',
      createdAt: DateTime.now().subtract(const Duration(days: 7)),
    ),
    TicketModel(
      id: 3,
      title: 'Pintu lemari rusak',
      description: 'Engsel pintu lemari patah dan tidak bisa ditutup.',
      category: 'MEBEL',
      status: AppConstants.ticketStatusDone,
      imageUrls: [],
      renterId: 1,
      renterName: 'Andi Pratama',
      kostId: 1,
      kostName: 'Kost Mawar Indah',
      ownerNote: 'Sudah diperbaiki oleh tukang',
      createdAt: DateTime.now().subtract(const Duration(days: 14)),
      updatedAt: DateTime.now().subtract(const Duration(days: 10)),
    ),
  ];

  static final List<ReservationModel> _mockOwnerReservations = [
    ReservationModel(
      id: 10,
      kostId: 1,
      kostName: 'Kost Mawar Indah',
      kostAddress: 'Jl. Dr. Mansyur No. 12',
      renterId: 3,
      renterName: 'Citra Lestari',
      renterEmail: 'citra@example.com',
      renterPhone: '085678901234',
      status: AppConstants.reservationStatusPending,
      isSplitBill: false,
      totalPrice: 1200000,
      checkInDate: DateTime.now().add(const Duration(days: 7)),
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    ReservationModel(
      id: 11,
      kostId: 1,
      kostName: 'Kost Mawar Indah',
      kostAddress: 'Jl. Dr. Mansyur No. 12',
      renterId: 4,
      renterName: 'Dani Ramadhan',
      renterEmail: 'dani@example.com',
      renterPhone: '086789012345',
      status: AppConstants.reservationStatusPending,
      isSplitBill: true,
      splitMemberCount: 3,
      totalPrice: 1200000,
      pricePerPerson: 400000,
      checkInDate: DateTime.now().add(const Duration(days: 10)),
      createdAt: DateTime.now().subtract(const Duration(hours: 5)),
    ),
    ReservationModel(
      id: 12,
      kostId: 1,
      kostName: 'Kost Mawar Indah',
      kostAddress: 'Jl. Dr. Mansyur No. 12',
      renterId: 5,
      renterName: 'Eka Putri',
      renterEmail: 'eka@example.com',
      renterPhone: '087890123456',
      status: AppConstants.reservationStatusApproved,
      isSplitBill: false,
      totalPrice: 1200000,
      checkInDate: DateTime.now().subtract(const Duration(days: 1)),
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
    ),
  ];

  static final List<TicketModel> _mockOwnerTickets = [
    TicketModel(
      id: 10,
      title: 'AC kamar 2 tidak dingin',
      description: 'AC di kamar 2 sudah seminggu tidak berfungsi optimal.',
      category: 'LISTRIK',
      status: AppConstants.ticketStatusPending,
      imageUrls: [],
      renterId: 3,
      renterName: 'Citra Lestari',
      kostId: 1,
      kostName: 'Kost Mawar Indah',
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
    TicketModel(
      id: 11,
      title: 'Saluran air tersumbat',
      description: 'Kamar mandi kamar 4 salurannya tersumbat.',
      category: 'AIR',
      status: AppConstants.ticketStatusInProgress,
      imageUrls: [
        'https://images.unsplash.com/photo-1585771724684-38269d6639fd?w=400',
      ],
      renterId: 4,
      renterName: 'Dani Ramadhan',
      kostId: 1,
      kostName: 'Kost Mawar Indah',
      ownerNote: 'Sudah dihubungi tukang, akan datang besok',
      createdAt: DateTime.now().subtract(const Duration(days: 4)),
    ),
  ];

  static final List<UserModel> _mockPendingOwners = [
    UserModel(
      id: 20,
      name: 'Pak Joko Susilo',
      email: 'joko@example.com',
      phone: '081234567890',
      role: 'OWNER',
      isVerified: false,
    ),
    UserModel(
      id: 21,
      name: 'Bu Siti Rahayu',
      email: 'siti@example.com',
      phone: '082345678901',
      role: 'OWNER',
      isVerified: false,
    ),
  ];
}
