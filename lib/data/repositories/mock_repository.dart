import '../models/kost_model.dart';
import '../models/reservation_model.dart';
import '../models/ticket_model.dart';
import '../models/user_model.dart';
import '../../core/constants/app_constants.dart';

// ═══════════════════════════════════════════════════════════════════════════
// MockRepository — simulasi backend layer
//
// Setiap method:
//   1. Menerapkan Future.delayed(700ms) untuk mensimulasikan network latency
//   2. Membungkus dengan try/catch
//   3. Menerima `simulateError` untuk demo skenario gagal
//   4. Operasi CRUD real-time pada list in-memory
// ═══════════════════════════════════════════════════════════════════════════
class MockRepository {
  MockRepository._();
  static final MockRepository instance = MockRepository._();

  // Simulasi delay jaringan
  static const _delay = Duration(milliseconds: 700);

  // ════════════════════════════════════════════════════════════════════════
  // IN-MEMORY DATABASE
  // ════════════════════════════════════════════════════════════════════════

  // 20 record kost
  final List<KostModel> _kostDb = _buildKostDb();

  // 5 record tiket awal
  final List<TicketModel> _ticketDb = _buildTicketDb();

  // Reservasi user
  final List<ReservationModel> _reservationDb = [];

  // Profil user aktif (disimpan in-memory selama sesi)
  UserModel _activeUser = const UserModel(
    id: 1,
    name: 'Andi Pratama',
    email: 'renter@papikost.com',
    phone: '081234567890',
    role: AppConstants.roleRenter,
    isVerified: true,
  );

  // Daftar pemilik kost pending verifikasi (admin)
  final List<UserModel> _pendingOwnerDb = [
    UserModel(
      id: 20,
      name: 'Pak Joko Susilo',
      email: 'joko@example.com',
      phone: '081234567890',
      role: AppConstants.roleOwner,
      isVerified: false,
    ),
    UserModel(
      id: 21,
      name: 'Bu Siti Rahayu',
      email: 'siti@example.com',
      phone: '082345678901',
      role: AppConstants.roleOwner,
      isVerified: false,
    ),
    UserModel(
      id: 22,
      name: 'Bapak Hendra Gunawan',
      email: 'hendra@example.com',
      phone: '083456789012',
      role: AppConstants.roleOwner,
      isVerified: false,
    ),
  ];

  // ════════════════════════════════════════════════════════════════════════
  // KOST METHODS
  // ════════════════════════════════════════════════════════════════════════

  Future<List<KostModel>> getKostList({
    String? search,
    String? type,
    double? maxPrice,
    bool simulateError = false,
  }) async {
    await Future.delayed(_delay);
    try {
      if (simulateError) {
        throw Exception('Gagal memuat daftar kost. Periksa koneksi Anda.');
      }
      var result = List<KostModel>.from(_kostDb);
      if (search != null && search.isNotEmpty) {
        result = result
            .where(
              (k) =>
                  k.name.toLowerCase().contains(search.toLowerCase()) ||
                  k.address.toLowerCase().contains(search.toLowerCase()),
            )
            .toList();
      }
      if (type != null && type != 'ALL') {
        result = result.where((k) => k.type == type).toList();
      }
      if (maxPrice != null) {
        result = result.where((k) => k.pricePerMonth <= maxPrice).toList();
      }
      return result;
    } catch (e) {
      throw Exception(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<KostModel> getKostById(int id, {bool simulateError = false}) async {
    await Future.delayed(_delay);
    try {
      if (simulateError) {
        throw Exception('Gagal memuat detail kost.');
      }
      return _kostDb.firstWhere(
        (k) => k.id == id,
        orElse: () => throw Exception('Kost tidak ditemukan.'),
      );
    } catch (e) {
      throw Exception(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  // ════════════════════════════════════════════════════════════════════════
  // RESERVATION METHODS
  // ════════════════════════════════════════════════════════════════════════

  Future<List<ReservationModel>> getMyReservations({
    bool simulateError = false,
  }) async {
    await Future.delayed(_delay);
    try {
      if (simulateError) throw Exception('Gagal memuat riwayat reservasi.');
      return List<ReservationModel>.from(_reservationDb);
    } catch (e) {
      throw Exception(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<ReservationModel> createReservation({
    required int kostId,
    required bool isSplitBill,
    int? splitMemberCount,
    required DateTime checkInDate,
    String? notes,
    bool simulateError = false,
  }) async {
    await Future.delayed(_delay);
    try {
      if (simulateError) {
        throw Exception('Reservasi gagal dikirim. Coba lagi.');
      }
      final kost = _kostDb.firstWhere((k) => k.id == kostId);
      final newId = _reservationDb.length + 100;
      final res = ReservationModel(
        id: newId,
        kostId: kostId,
        kostName: kost.name,
        kostAddress: kost.address,
        kostImageUrl: kost.imageUrls.isNotEmpty ? kost.imageUrls.first : null,
        renterId: _activeUser.id,
        renterName: _activeUser.name,
        renterEmail: _activeUser.email,
        renterPhone: _activeUser.phone,
        status: AppConstants.reservationStatusPending,
        isSplitBill: isSplitBill,
        splitMemberCount: splitMemberCount,
        totalPrice: kost.pricePerMonth,
        pricePerPerson: isSplitBill && (splitMemberCount ?? 0) > 0
            ? kost.pricePerMonth / splitMemberCount!
            : null,
        checkInDate: checkInDate,
        notes: notes,
        createdAt: DateTime.now(),
      );
      _reservationDb.add(res);
      return res;
    } catch (e) {
      throw Exception(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  // ════════════════════════════════════════════════════════════════════════
  // TICKET (CRUD) METHODS
  // ════════════════════════════════════════════════════════════════════════

  Future<List<TicketModel>> getMyTickets({bool simulateError = false}) async {
    await Future.delayed(_delay);
    try {
      if (simulateError) throw Exception('Gagal memuat daftar laporan.');
      return List<TicketModel>.from(_ticketDb)
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } catch (e) {
      throw Exception(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<TicketModel> getTicketById(
    int id, {
    bool simulateError = false,
  }) async {
    await Future.delayed(_delay);
    try {
      if (simulateError) throw Exception('Gagal memuat detail laporan.');
      return _ticketDb.firstWhere(
        (t) => t.id == id,
        orElse: () => throw Exception('Laporan tidak ditemukan.'),
      );
    } catch (e) {
      throw Exception(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  /// CREATE — Buat laporan baru
  Future<TicketModel> createTicket({
    required String title,
    required String description,
    required String category,
    required DateTime incidentDate,
    List<String> imageUrls = const [],
    bool simulateError = false,
  }) async {
    await Future.delayed(_delay);
    try {
      if (simulateError) throw Exception('Gagal membuat laporan. Coba lagi.');
      final newId = _ticketDb.isEmpty
          ? 1
          : (_ticketDb.map((t) => t.id).reduce((a, b) => a > b ? a : b) + 1);
      final ticket = TicketModel(
        id: newId,
        title: title,
        description: description,
        category: category,
        status: AppConstants.ticketStatusPending,
        imageUrls: imageUrls,
        renterId: _activeUser.id,
        renterName: _activeUser.name,
        kostId: 1,
        kostName: 'Kost Mawar Indah',
        createdAt: incidentDate,
      );
      _ticketDb.add(ticket);
      return ticket;
    } catch (e) {
      throw Exception(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  /// UPDATE — Edit laporan kerusakan
  Future<TicketModel> updateTicket({
    required int id,
    required String title,
    required String description,
    required String category,
    required DateTime incidentDate,
    List<String>? imageUrls,
    bool simulateError = false,
  }) async {
    await Future.delayed(_delay);
    try {
      if (simulateError) throw Exception('Gagal memperbarui laporan.');
      final idx = _ticketDb.indexWhere((t) => t.id == id);
      if (idx == -1) throw Exception('Laporan tidak ditemukan.');

      final updated = TicketModel(
        id: id,
        title: title,
        description: description,
        category: category,
        status: _ticketDb[idx].status,
        imageUrls: imageUrls ?? _ticketDb[idx].imageUrls,
        renterId: _ticketDb[idx].renterId,
        renterName: _ticketDb[idx].renterName,
        kostId: _ticketDb[idx].kostId,
        kostName: _ticketDb[idx].kostName,
        ownerNote: _ticketDb[idx].ownerNote,
        createdAt: incidentDate,
        updatedAt: DateTime.now(),
      );
      _ticketDb[idx] = updated;
      return updated;
    } catch (e) {
      throw Exception(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  /// DELETE — Hapus laporan
  Future<void> deleteTicket(int id, {bool simulateError = false}) async {
    await Future.delayed(_delay);
    try {
      if (simulateError) throw Exception('Gagal menghapus laporan.');
      _ticketDb.removeWhere((t) => t.id == id);
      final stillExists = _ticketDb.any((t) => t.id == id);
      if (stillExists) throw Exception('Laporan tidak ditemukan.');
    } catch (e) {
      throw Exception(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  // ════════════════════════════════════════════════════════════════════════
  // PROFILE METHODS
  // ════════════════════════════════════════════════════════════════════════

  Future<UserModel> getProfile({bool simulateError = false}) async {
    await Future.delayed(_delay);
    try {
      if (simulateError) throw Exception('Gagal memuat profil.');
      return _activeUser;
    } catch (e) {
      throw Exception(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  /// Update profil — disimpan in-memory selama sesi
  Future<UserModel> updateProfile({
    required String name,
    required String phone,
    String? bio,
    bool simulateError = false,
  }) async {
    await Future.delayed(_delay);
    try {
      if (simulateError) throw Exception('Gagal menyimpan perubahan profil.');
      if (name.trim().isEmpty) throw Exception('Nama tidak boleh kosong.');
      if (phone.trim().length < 10) throw Exception('Nomor HP tidak valid.');

      _activeUser = UserModel(
        id: _activeUser.id,
        name: name.trim(),
        email: _activeUser.email,
        phone: phone.trim(),
        role: _activeUser.role,
        avatarUrl: _activeUser.avatarUrl,
        bio: bio?.trim().isEmpty == true ? null : bio?.trim(),
        isVerified: _activeUser.isVerified,
        createdAt: _activeUser.createdAt,
      );
      return _activeUser;
    } catch (e) {
      throw Exception(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  // ════════════════════════════════════════════════════════════════════════
  // ADMIN METHODS
  // ════════════════════════════════════════════════════════════════════════

  /// Ambil daftar pemilik kost yang belum terverifikasi
  Future<List<UserModel>> fetchPendingOwners({
    bool simulateError = false,
  }) async {
    await Future.delayed(_delay);
    try {
      if (simulateError) throw Exception('Gagal memuat daftar verifikasi.');
      return List<UserModel>.from(_pendingOwnerDb);
    } catch (e) {
      throw Exception(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  /// Verifikasi atau tolak pemilik kost
  Future<void> verifyOwner(
    int userId,
    bool approve, {
    bool simulateError = false,
  }) async {
    await Future.delayed(_delay);
    try {
      if (simulateError) throw Exception('Gagal memproses verifikasi.');
      _pendingOwnerDb.removeWhere((u) => u.id == userId);
    } catch (e) {
      throw Exception(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  // ════════════════════════════════════════════════════════════════════════
  // REFERENCE DATA
  // ════════════════════════════════════════════════════════════════════════

  /// 5 kategori kerusakan
  static const List<String> ticketCategories = [
    'LISTRIK',
    'AIR',
    'MEBEL',
    'STRUKTUR',
    'LAINNYA',
  ];

  static const Map<String, String> categoryLabels = {
    'LISTRIK': 'Listrik & Elektronik',
    'AIR': 'Air & Plumbing',
    'MEBEL': 'Mebel & Perabot',
    'STRUKTUR': 'Struktur Bangunan',
    'LAINNYA': 'Lainnya',
  };

  static const List<String> facilityOptions = [
    'WiFi',
    'AC',
    'TV',
    'Lemari',
    'Meja Belajar',
    'Kamar Mandi Dalam',
    'Dapur Bersama',
    'Parkir Motor',
    'Parkir Mobil',
    'Keamanan 24 Jam',
    'Laundry',
    'Kulkas',
  ];

  // ════════════════════════════════════════════════════════════════════════
  // MOCK DATA BUILDERS
  // ════════════════════════════════════════════════════════════════════════

  static List<KostModel> _buildKostDb() => [
    _kost(
      1,
      'Kost Mawar Indah',
      'Jl. Dr. Mansyur No. 12, Medan',
      1200000,
      'PUTRI',
      4,
      true,
      4.5,
      28,
      ['WiFi', 'AC', 'Kamar Mandi Dalam', 'Lemari', 'Meja Belajar'],
      'Kost putri nyaman dekat USU. Lingkungan bersih dan kondusif.',
    ),
    _kost(
      2,
      'Kost Bumi Putera',
      'Jl. Gagak Hitam No. 5, Medan',
      900000,
      'PUTRA',
      2,
      true,
      4.2,
      15,
      ['WiFi', 'Parkir Motor', 'Dapur Bersama', 'Lemari'],
      'Kost putra strategis dekat Fasilkom USU.',
    ),
    _kost(
      3,
      'Kost Harmoni Residence',
      'Jl. Jamin Ginting No. 88, Medan',
      1500000,
      'CAMPUR',
      7,
      false,
      4.8,
      42,
      ['WiFi', 'AC', 'TV', 'Kamar Mandi Dalam', 'Dapur', 'Keamanan 24 Jam'],
      'Kost campur premium, cocok untuk mahasiswa dan profesional.',
    ),
    _kost(
      4,
      'Kost Green House',
      'Jl. Setia Budi No. 32, Medan',
      800000,
      'CAMPUR',
      6,
      true,
      4.0,
      20,
      ['WiFi', 'Parkir Motor', 'Lemari', 'Meja Belajar'],
      'Kost campur murah dengan lingkungan asri.',
    ),
    _kost(
      5,
      'Kost Putri Cantik',
      'Jl. Perpustakaan No. 7, Medan',
      1100000,
      'PUTRI',
      3,
      true,
      4.6,
      33,
      ['WiFi', 'AC', 'Kamar Mandi Dalam', 'Laundry', 'Keamanan 24 Jam'],
      'Kost putri eksklusif di dalam kampus USU.',
    ),
    _kost(
      6,
      'Kost Sejahtera',
      'Jl. Tritura No. 15, Medan',
      750000,
      'PUTRA',
      5,
      false,
      3.8,
      10,
      ['WiFi', 'Dapur Bersama', 'Parkir Motor'],
      'Kost putra ekonomis dengan lokasi strategis.',
    ),
    _kost(
      7,
      'Kost The Pavilion',
      'Jl. Universitas No. 1, Medan',
      2000000,
      'CAMPUR',
      2,
      false,
      4.9,
      55,
      ['WiFi', 'AC', 'TV', 'Kulkas', 'Kamar Mandi Dalam', 'Keamanan 24 Jam'],
      'Kost premium fasilitas apartemen.',
    ),
    _kost(
      8,
      'Kost Anugrah',
      'Jl. Sei Batanghari No. 4, Medan',
      950000,
      'PUTRI',
      4,
      true,
      4.1,
      18,
      ['WiFi', 'Lemari', 'Meja Belajar', 'Dapur Bersama'],
      'Kost putri dekat kampus, harga bersahabat.',
    ),
    _kost(
      9,
      'Kost Cendana',
      'Jl. Karya No. 22, Medan',
      1050000,
      'PUTRA',
      3,
      true,
      4.3,
      25,
      ['WiFi', 'AC', 'Parkir Motor', 'Lemari'],
      'Kost putra ber-AC dengan parkir luas.',
    ),
    _kost(
      10,
      'Kost Flamboyan',
      'Jl. Bunga Kenanga No. 8, Medan',
      1300000,
      'CAMPUR',
      6,
      true,
      4.4,
      30,
      ['WiFi', 'AC', 'TV', 'Lemari', 'Meja Belajar'],
      'Kost campur nyaman dengan taman belakang.',
    ),
    _kost(
      11,
      'Kost Pesona',
      'Jl. Halat No. 10, Medan',
      870000,
      'PUTRI',
      2,
      false,
      4.0,
      12,
      ['WiFi', 'Kamar Mandi Dalam', 'Lemari'],
      'Kost putri sederhana dan aman.',
    ),
    _kost(
      12,
      'Kost Griya Asri',
      'Jl. Pertahanan No. 7, Medan',
      980000,
      'CAMPUR',
      5,
      true,
      4.2,
      22,
      ['WiFi', 'Dapur Bersama', 'Parkir Motor', 'Lemari'],
      'Kost campur dengan dapur lengkap.',
    ),
    _kost(
      13,
      'Kost Abadi',
      'Jl. Sumber No. 3, Medan',
      690000,
      'PUTRA',
      8,
      false,
      3.7,
      8,
      ['WiFi', 'Parkir Motor'],
      'Kost putra paling murah di area USU.',
    ),
    _kost(
      14,
      'Kost Mentari',
      'Jl. Sisimangaraja No. 45, Medan',
      1150000,
      'PUTRI',
      1,
      true,
      4.5,
      38,
      ['WiFi', 'AC', 'Kamar Mandi Dalam', 'Meja Belajar', 'Laundry'],
      'Kost putri dengan laundry gratis.',
    ),
    _kost(
      15,
      'Kost Delima',
      'Jl. Pelajar No. 17, Medan',
      1400000,
      'CAMPUR',
      4,
      false,
      4.6,
      45,
      ['WiFi', 'AC', 'TV', 'Kamar Mandi Dalam', 'Keamanan 24 Jam'],
      'Kost campur dengan CCTV 24 jam.',
    ),
    _kost(
      16,
      'Kost Bahagia',
      'Jl. Mongonsidi No. 9, Medan',
      820000,
      'PUTRA',
      3,
      true,
      4.0,
      16,
      ['WiFi', 'Dapur Bersama', 'Lemari', 'Parkir Motor'],
      'Kost putra ramah mahasiswa.',
    ),
    _kost(
      17,
      'Kost Nusa Indah',
      'Jl. Arif No. 14, Medan',
      1250000,
      'PUTRI',
      5,
      true,
      4.7,
      50,
      ['WiFi', 'AC', 'Kamar Mandi Dalam', 'Kulkas', 'Meja Belajar'],
      'Kost putri dengan kulkas di setiap kamar.',
    ),
    _kost(
      18,
      'Kost Bintang',
      'Jl. Wahidin No. 21, Medan',
      1600000,
      'CAMPUR',
      2,
      false,
      4.8,
      60,
      ['WiFi', 'AC', 'TV', 'Kamar Mandi Dalam', 'Kulkas', 'Keamanan 24 Jam'],
      'Kost premium di pusat kota Medan.',
    ),
    _kost(
      19,
      'Kost Mutiara',
      'Jl. Imam Bonjol No. 33, Medan',
      760000,
      'PUTRI',
      6,
      false,
      3.9,
      9,
      ['WiFi', 'Lemari', 'Dapur Bersama'],
      'Kost putri ekonomis cocok untuk mahasiswa baru.',
    ),
    _kost(
      20,
      'Kost Surya Mas',
      'Jl. Cemara No. 11, Medan',
      1080000,
      'PUTRA',
      4,
      true,
      4.3,
      27,
      ['WiFi', 'AC', 'Parkir Motor', 'Lemari', 'Meja Belajar'],
      'Kost putra dengan AC dan meja belajar luas.',
    ),
  ];

  static KostModel _kost(
    int id,
    String name,
    String address,
    double price,
    String type,
    int available,
    bool splitBill,
    double rating,
    int reviews,
    List<String> facilities,
    String desc,
  ) {
    return KostModel(
      id: id,
      name: name,
      address: address,
      city: 'Medan',
      pricePerMonth: price,
      type: type,
      facilities: facilities,
      imageUrls: [
        'https://images.unsplash.com/photo-1586023492125-27b2c045efd7?w=600',
        'https://images.unsplash.com/photo-1560185007-cde436f6a4d0?w=600',
      ],
      isSplitBillAvailable: splitBill,
      totalRooms: available + 4,
      availableRooms: available,
      description: desc,
      ownerName: 'Pemilik Kost',
      rating: rating,
      reviewCount: reviews,
    );
  }

  static List<TicketModel> _buildTicketDb() => [
    TicketModel(
      id: 1,
      title: 'Lampu kamar tidak menyala',
      description:
          'Lampu di kamar saya sudah mati sejak 3 hari lalu dan belum ada yang memperbaiki.',
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
      description:
          'Keran air di kamar mandi terus menetes dan menyebabkan pemborosan air.',
      category: 'AIR',
      status: AppConstants.ticketStatusInProgress,
      imageUrls: [
        'https://images.unsplash.com/photo-1585771724684-38269d6639fd?w=400',
      ],
      renterId: 1,
      renterName: 'Andi Pratama',
      kostId: 1,
      kostName: 'Kost Mawar Indah',
      ownerNote: 'Sedang menunggu tukang ledeng.',
      createdAt: DateTime.now().subtract(const Duration(days: 7)),
    ),
    TicketModel(
      id: 3,
      title: 'Pintu lemari rusak',
      description:
          'Engsel pintu lemari patah sehingga tidak bisa ditutup dengan sempurna.',
      category: 'MEBEL',
      status: AppConstants.ticketStatusDone,
      imageUrls: [],
      renterId: 1,
      renterName: 'Andi Pratama',
      kostId: 1,
      kostName: 'Kost Mawar Indah',
      ownerNote: 'Sudah diperbaiki oleh tukang pada 10 Jan.',
      createdAt: DateTime.now().subtract(const Duration(days: 14)),
      updatedAt: DateTime.now().subtract(const Duration(days: 10)),
    ),
    TicketModel(
      id: 4,
      title: 'Retak pada dinding kamar',
      description:
          'Ada retakan memanjang di dinding sebelah timur kamar, khawatir akan semakin melebar.',
      category: 'STRUKTUR',
      status: AppConstants.ticketStatusPending,
      imageUrls: [],
      renterId: 1,
      renterName: 'Andi Pratama',
      kostId: 1,
      kostName: 'Kost Mawar Indah',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
    TicketModel(
      id: 5,
      title: 'Kunci kamar susah dibuka',
      description:
          'Kunci kamar terasa seret dan susah dibuka, terutama di pagi hari.',
      category: 'LAINNYA',
      status: AppConstants.ticketStatusPending,
      imageUrls: [],
      renterId: 1,
      renterName: 'Andi Pratama',
      kostId: 1,
      kostName: 'Kost Mawar Indah',
      createdAt: DateTime.now().subtract(const Duration(hours: 5)),
    ),
  ];
}
