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
// Model pengajuan pemilik kost (lebih kaya dari UserModel)
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
// AdminProvider
// ══════════════════════════════════════════════════════════════════════════════
enum AdminLoadState { initial, loading, loaded, error }

class AdminProvider extends ChangeNotifier {
  static const _delay = Duration(milliseconds: 700);

  AdminLoadState _state = AdminLoadState.initial;
  List<OwnerSubmission> _submissions = [];
  String _error = '';
  bool _isSubmitting = false;

  AdminLoadState get state => _state;
  List<OwnerSubmission> get submissions => _submissions;
  String get error => _error;
  bool get isSubmitting => _isSubmitting;
  bool get isLoading => _state == AdminLoadState.loading;

  List<OwnerSubmission> get pendingSubmissions =>
      _submissions.where((s) => s.status == VerificationStatus.proses).toList();

  // ── Load daftar pengajuan ─────────────────────────────────────────────────
  Future<void> loadSubmissions() async {
    _state = AdminLoadState.loading;
    _error = '';
    notifyListeners();

    await Future.delayed(_delay);
    _submissions = _buildMockSubmissions();
    _state = AdminLoadState.loaded;
    notifyListeners();
  }

  // ── Approve pengajuan ─────────────────────────────────────────────────────
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

  // ── Tolak pengajuan dengan alasan ─────────────────────────────────────────
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

  // ── Mock data ─────────────────────────────────────────────────────────────
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
}
