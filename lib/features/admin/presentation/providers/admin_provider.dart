import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../data/models/user_model.dart';

// ══════════════════════════════════════════════════════════════════════════════
// Enum Status Verifikasi (3 state)
// ══════════════════════════════════════════════════════════════════════════════
enum VerificationStatus { proses, acc, tolak }

extension VerificationStatusX on VerificationStatus {
  String get label {
    switch (this) {
      case VerificationStatus.proses:
        return 'PROSES';
      case VerificationStatus.acc:
        return 'ACC';
      case VerificationStatus.tolak:
        return 'TOLAK';
    }
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Model pengajuan pemilik kost
// ══════════════════════════════════════════════════════════════════════════════
class OwnerSubmission {
  final int id;
  final String name;
  final String email;
  final String phone;
  final String ktpNumber;
  final String propertyName;
  final String propertyAddress;
  final String propertyType;
  final String ktpImageUrl;
  final String sertifikatImageUrl;
  final String fotoRumahImageUrl;
  VerificationStatus status;
  String? rejectionReason;
  final DateTime submittedAt;

  OwnerSubmission({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.ktpNumber,
    required this.propertyName,
    required this.propertyAddress,
    required this.propertyType,
    required this.ktpImageUrl,
    required this.sertifikatImageUrl,
    required this.fotoRumahImageUrl,
    this.status = VerificationStatus.proses,
    this.rejectionReason,
    required this.submittedAt,
  });

  UserModel toUserModel() => UserModel(
    id: id,
    name: name,
    email: email,
    phone: phone,
    role: AppConstants.roleOwner,
    isVerified: status == VerificationStatus.acc,
  );

  OwnerSubmission copyWith({
    VerificationStatus? status,
    String? rejectionReason,
  }) => OwnerSubmission(
    id: id,
    name: name,
    email: email,
    phone: phone,
    ktpNumber: ktpNumber,
    propertyName: propertyName,
    propertyAddress: propertyAddress,
    propertyType: propertyType,
    ktpImageUrl: ktpImageUrl,
    sertifikatImageUrl: sertifikatImageUrl,
    fotoRumahImageUrl: fotoRumahImageUrl,
    status: status ?? this.status,
    rejectionReason: rejectionReason ?? this.rejectionReason,
    submittedAt: submittedAt,
  );
}

// ══════════════════════════════════════════════════════════════════════════════
// Model berkas pengajuan penyewa kost
// ══════════════════════════════════════════════════════════════════════════════
class RenterSubmission {
  final int id;
  final String name;
  final String email;
  final String phone;
  final String ktpNumber;
  final String occupation; // pekerjaan/status (Mahasiswa, Karyawan, dll)
  final String emergencyContact;
  final String emergencyPhone;
  final String kostName; // nama kost yang dituju
  final int kostId;
  final String ownerName; // nama pemilik kost
  final String ktpImageUrl;
  final String fotoSelfieUrl;
  final String? suratKeteranganUrl; // surat mahasiswa / slip gaji (opsional)
  VerificationStatus status;
  String? rejectionReason;
  String? ownerNote; // catatan dari owner setelah ACC
  final DateTime submittedAt;

  RenterSubmission({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.ktpNumber,
    required this.occupation,
    required this.emergencyContact,
    required this.emergencyPhone,
    required this.kostName,
    required this.kostId,
    required this.ownerName,
    required this.ktpImageUrl,
    required this.fotoSelfieUrl,
    this.suratKeteranganUrl,
    this.status = VerificationStatus.proses,
    this.rejectionReason,
    this.ownerNote,
    required this.submittedAt,
  });

  RenterSubmission copyWith({
    VerificationStatus? status,
    String? rejectionReason,
    String? ownerNote,
  }) => RenterSubmission(
    id: id,
    name: name,
    email: email,
    phone: phone,
    ktpNumber: ktpNumber,
    occupation: occupation,
    emergencyContact: emergencyContact,
    emergencyPhone: emergencyPhone,
    kostName: kostName,
    kostId: kostId,
    ownerName: ownerName,
    ktpImageUrl: ktpImageUrl,
    fotoSelfieUrl: fotoSelfieUrl,
    suratKeteranganUrl: suratKeteranganUrl,
    status: status ?? this.status,
    rejectionReason: rejectionReason ?? this.rejectionReason,
    ownerNote: ownerNote ?? this.ownerNote,
    submittedAt: submittedAt,
  );
}

// ══════════════════════════════════════════════════════════════════════════════
// AdminProvider
// ══════════════════════════════════════════════════════════════════════════════
enum AdminLoadState { initial, loading, loaded, error }

class AdminProvider extends ChangeNotifier {
  static const _delay = Duration(milliseconds: 700);

  // ── State verifikasi owner ────────────────────────────────────────────────
  AdminLoadState _state = AdminLoadState.initial;
  List<OwnerSubmission> _submissions = [];
  String _error = '';
  bool _isSubmitting = false;

  // ── State manajemen user ──────────────────────────────────────────────────
  bool _isLoadingUsers = false;
  List<UserModel> _allUsers = [];

  // ── State verifikasi renter ───────────────────────────────────────────────
  bool _isLoadingRenterSubmissions = false;
  List<RenterSubmission> _renterSubmissions = [];

  AdminLoadState get state => _state;
  List<OwnerSubmission> get submissions => _submissions;
  String get error => _error;
  bool get isSubmitting => _isSubmitting;
  bool get isLoading => _state == AdminLoadState.loading;

  bool get isLoadingUsers => _isLoadingUsers;
  List<UserModel> get allUsers => _allUsers;

  bool get isLoadingRenterSubmissions => _isLoadingRenterSubmissions;
  List<RenterSubmission> get renterSubmissions => _renterSubmissions;
  List<RenterSubmission> get pendingRenterSubmissions => _renterSubmissions
      .where((s) => s.status == VerificationStatus.proses)
      .toList();

  List<OwnerSubmission> get pendingSubmissions =>
      _submissions.where((s) => s.status == VerificationStatus.proses).toList();

  // ── Load daftar pengajuan owner ───────────────────────────────────────────
  Future<void> loadSubmissions() async {
    _state = AdminLoadState.loading;
    _error = '';
    notifyListeners();
    await Future.delayed(_delay);
    _submissions = _buildMockSubmissions();
    _state = AdminLoadState.loaded;
    notifyListeners();
  }

  // ── Approve pengajuan owner ───────────────────────────────────────────────
  Future<bool> approveSubmission(int id) async {
    if (_isSubmitting) return false;
    _isSubmitting = true;
    notifyListeners();
    await Future.delayed(_delay);
    final idx = _submissions.indexWhere((s) => s.id == id);
    if (idx != -1) {
      _submissions[idx] = _submissions[idx].copyWith(
        status: VerificationStatus.acc,
      );
    }
    _isSubmitting = false;
    notifyListeners();
    return true;
  }

  // ── Tolak pengajuan owner ─────────────────────────────────────────────────
  Future<bool> rejectSubmission(int id, String reason) async {
    if (_isSubmitting) return false;
    if (reason.trim().isEmpty) return false;
    _isSubmitting = true;
    notifyListeners();
    await Future.delayed(_delay);
    final idx = _submissions.indexWhere((s) => s.id == id);
    if (idx != -1) {
      _submissions[idx] = _submissions[idx].copyWith(
        status: VerificationStatus.tolak,
        rejectionReason: reason.trim(),
      );
    }
    _isSubmitting = false;
    notifyListeners();
    return true;
  }

  // ── Load semua user (Renter + Owner) ─────────────────────────────────────
  Future<void> loadUsers() async {
    _isLoadingUsers = true;
    notifyListeners();
    await Future.delayed(_delay);
    _allUsers = _buildMockUsers();
    _isLoadingUsers = false;
    notifyListeners();
  }

  // ── ACC akun user ─────────────────────────────────────────────────────────
  Future<bool> accUser(int userId) async {
    if (_isSubmitting) return false;
    _isSubmitting = true;
    notifyListeners();
    await Future.delayed(_delay);
    final idx = _allUsers.indexWhere((u) => u.id == userId);
    if (idx != -1) {
      _allUsers[idx] = _allUsers[idx].copyWith(isVerified: true);
    }
    _isSubmitting = false;
    notifyListeners();
    return idx != -1;
  }

  // ── Nonaktifkan akun user ─────────────────────────────────────────────────
  Future<bool> deactivateUser(int userId) async {
    if (_isSubmitting) return false;
    _isSubmitting = true;
    notifyListeners();
    await Future.delayed(_delay);
    final before = _allUsers.length;
    _allUsers.removeWhere((u) => u.id == userId);
    _isSubmitting = false;
    notifyListeners();
    return _allUsers.length < before;
  }

  // ── Load berkas pengajuan renter (admin) ──────────────────────────────────
  Future<void> loadRenterSubmissions() async {
    _isLoadingRenterSubmissions = true;
    notifyListeners();
    await Future.delayed(_delay);
    _renterSubmissions = _buildMockRenterSubmissions();
    _isLoadingRenterSubmissions = false;
    notifyListeners();
  }

  // ── ACC berkas renter (admin) ─────────────────────────────────────────────
  Future<bool> approveRenterSubmission(int id) async {
    if (_isSubmitting) return false;
    _isSubmitting = true;
    notifyListeners();
    await Future.delayed(_delay);
    final idx = _renterSubmissions.indexWhere((s) => s.id == id);
    if (idx != -1) {
      _renterSubmissions[idx] = _renterSubmissions[idx].copyWith(
        status: VerificationStatus.acc,
      );
    }
    _isSubmitting = false;
    notifyListeners();
    return idx != -1;
  }

  // ── Tolak berkas renter (admin) ───────────────────────────────────────────
  Future<bool> rejectRenterSubmission(int id, String reason) async {
    if (_isSubmitting) return false;
    if (reason.trim().isEmpty) return false;
    _isSubmitting = true;
    notifyListeners();
    await Future.delayed(_delay);
    final idx = _renterSubmissions.indexWhere((s) => s.id == id);
    if (idx != -1) {
      _renterSubmissions[idx] = _renterSubmissions[idx].copyWith(
        status: VerificationStatus.tolak,
        rejectionReason: reason.trim(),
      );
    }
    _isSubmitting = false;
    notifyListeners();
    return idx != -1;
  }

  // ── Mock data users ───────────────────────────────────────────────────────
  static List<UserModel> _buildMockUsers() => [
    UserModel(
      id: 1,
      name: 'Budi Santoso',
      email: 'budi.santoso@gmail.com',
      phone: '081234567890',
      role: 'RENTER',
      isVerified: true,
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
    ),
    UserModel(
      id: 2,
      name: 'Dewi Anggraini',
      email: 'dewi.anggraini@gmail.com',
      phone: '082345678901',
      role: 'RENTER',
      isVerified: true,
      createdAt: DateTime.now().subtract(const Duration(days: 25)),
    ),
    UserModel(
      id: 3,
      name: 'Ahmad Fauzi',
      email: 'ahmad.fauzi@gmail.com',
      phone: '083456789012',
      role: 'RENTER',
      isVerified: true,
      createdAt: DateTime.now().subtract(const Duration(days: 18)),
    ),
    UserModel(
      id: 4,
      name: 'Rina Wulandari',
      email: 'rina.wulandari@gmail.com',
      phone: '084567890123',
      role: 'RENTER',
      isVerified: true,
      createdAt: DateTime.now().subtract(const Duration(days: 10)),
    ),
    UserModel(
      id: 5,
      name: 'Pak Joko Susilo',
      email: 'joko@example.com',
      phone: '081234567890',
      role: 'OWNER',
      isVerified: true,
      createdAt: DateTime.now().subtract(const Duration(days: 45)),
    ),
    UserModel(
      id: 6,
      name: 'Bu Siti Rahayu',
      email: 'siti@example.com',
      phone: '082345678901',
      role: 'OWNER',
      isVerified: false,
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
    ),
    UserModel(
      id: 7,
      name: 'Bapak Hendra Gunawan',
      email: 'hendra@example.com',
      phone: '083456789012',
      role: 'OWNER',
      isVerified: false,
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
  ];

  // ── Mock data owner submissions ───────────────────────────────────────────
  static List<OwnerSubmission> _buildMockSubmissions() => [
    OwnerSubmission(
      id: 20,
      name: 'Pak Joko Susilo',
      email: 'joko@example.com',
      phone: '081234567890',
      ktpNumber: '1271010101890001',
      propertyName: 'Kost Joko Indah',
      propertyAddress: 'Jl. Setia Budi No. 45, Medan',
      propertyType: 'CAMPUR',
      ktpImageUrl:
          'https://images.unsplash.com/photo-1554774853-719586f82d77?w=600',
      sertifikatImageUrl:
          'https://images.unsplash.com/photo-1568234928966-359c35dd8327?w=600',
      fotoRumahImageUrl:
          'https://images.unsplash.com/photo-1586023492125-27b2c045efd7?w=600',
      submittedAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
    OwnerSubmission(
      id: 21,
      name: 'Bu Siti Rahayu',
      email: 'siti@example.com',
      phone: '082345678901',
      ktpNumber: '1271020202900002',
      propertyName: 'Kost Putri Siti',
      propertyAddress: 'Jl. Dr. Mansyur No. 33, Medan',
      propertyType: 'PUTRI',
      ktpImageUrl:
          'https://images.unsplash.com/photo-1554774853-719586f82d77?w=600',
      sertifikatImageUrl:
          'https://images.unsplash.com/photo-1568234928966-359c35dd8327?w=600',
      fotoRumahImageUrl:
          'https://images.unsplash.com/photo-1560185007-cde436f6a4d0?w=600',
      submittedAt: DateTime.now().subtract(const Duration(days: 5)),
    ),
    OwnerSubmission(
      id: 22,
      name: 'Bapak Hendra Gunawan',
      email: 'hendra@example.com',
      phone: '083456789012',
      ktpNumber: '1271030303850003',
      propertyName: 'Kost Hendra Putra',
      propertyAddress: 'Jl. Jamin Ginting No. 12, Medan',
      propertyType: 'PUTRA',
      ktpImageUrl:
          'https://images.unsplash.com/photo-1554774853-719586f82d77?w=600',
      sertifikatImageUrl:
          'https://images.unsplash.com/photo-1568234928966-359c35dd8327?w=600',
      fotoRumahImageUrl:
          'https://images.unsplash.com/photo-1631049307264-da0ec9d70304?w=600',
      submittedAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
  ];

  // ── Mock data renter submissions ──────────────────────────────────────────
  static List<RenterSubmission> _buildMockRenterSubmissions() => [
    RenterSubmission(
      id: 101,
      name: 'Budi Santoso',
      email: 'budi.santoso@gmail.com',
      phone: '081234567890',
      ktpNumber: '1271011505000001',
      occupation: 'Mahasiswa',
      emergencyContact: 'Ibu Santoso',
      emergencyPhone: '081111111111',
      kostName: 'Kost Mawar Indah',
      kostId: 1,
      ownerName: 'Pak Budi Santoso',
      ktpImageUrl:
          'https://images.unsplash.com/photo-1554774853-719586f82d77?w=600',
      fotoSelfieUrl:
          'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=600',
      suratKeteranganUrl:
          'https://images.unsplash.com/photo-1568234928966-359c35dd8327?w=600',
      submittedAt: DateTime.now().subtract(const Duration(days: 3)),
    ),
    RenterSubmission(
      id: 102,
      name: 'Dewi Anggraini',
      email: 'dewi.anggraini@gmail.com',
      phone: '082345678901',
      ktpNumber: '1271022020010002',
      occupation: 'Mahasiswi',
      emergencyContact: 'Bapak Anggraini',
      emergencyPhone: '082222222222',
      kostName: 'Kost Mawar Indah',
      kostId: 1,
      ownerName: 'Pak Budi Santoso',
      ktpImageUrl:
          'https://images.unsplash.com/photo-1554774853-719586f82d77?w=600',
      fotoSelfieUrl:
          'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=600',
      submittedAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
    RenterSubmission(
      id: 103,
      name: 'Ahmad Fauzi',
      email: 'ahmad.fauzi@gmail.com',
      phone: '083456789012',
      ktpNumber: '1271030303990003',
      occupation: 'Karyawan Swasta',
      emergencyContact: 'Ibu Fauzi',
      emergencyPhone: '083333333333',
      kostName: 'Kost Bumi Putera',
      kostId: 2,
      ownerName: 'Pak Budi Santoso',
      ktpImageUrl:
          'https://images.unsplash.com/photo-1554774853-719586f82d77?w=600',
      fotoSelfieUrl:
          'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=600',
      suratKeteranganUrl:
          'https://images.unsplash.com/photo-1568234928966-359c35dd8327?w=600',
      status: VerificationStatus.acc,
      submittedAt: DateTime.now().subtract(const Duration(days: 10)),
    ),
    RenterSubmission(
      id: 104,
      name: 'Rina Wulandari',
      email: 'rina.wulandari@gmail.com',
      phone: '084567890123',
      ktpNumber: '1271040404020004',
      occupation: 'Mahasiswi',
      emergencyContact: 'Ibu Wulandari',
      emergencyPhone: '084444444444',
      kostName: 'Kost Mawar Indah',
      kostId: 1,
      ownerName: 'Pak Budi Santoso',
      ktpImageUrl:
          'https://images.unsplash.com/photo-1554774853-719586f82d77?w=600',
      fotoSelfieUrl:
          'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=600',
      status: VerificationStatus.tolak,
      rejectionReason:
          'Foto KTP buram, mohon kirim ulang dengan kualitas lebih jelas.',
      submittedAt: DateTime.now().subtract(const Duration(days: 7)),
    ),
  ];
}
