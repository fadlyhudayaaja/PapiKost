import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/network/mock_service.dart';
import '../../../../data/models/reservation_model.dart';
import '../../../../data/models/ticket_model.dart';
import '../../../../data/models/user_model.dart';

// ══════════════════════════════════════════════════════════════════════════════
// OwnerStats
// ══════════════════════════════════════════════════════════════════════════════
class OwnerStats {
  final int totalRooms;
  final int occupiedRooms;
  final int pendingReservations;
  final int pendingTickets;

  const OwnerStats({
    required this.totalRooms,
    required this.occupiedRooms,
    required this.pendingReservations,
    required this.pendingTickets,
  });

  int get availableRooms => totalRooms - occupiedRooms;
  double get occupancyRate =>
      totalRooms > 0 ? (occupiedRooms / totalRooms) * 100 : 0;
}

// ══════════════════════════════════════════════════════════════════════════════
// OwnerKostModel — Model kamar in-memory untuk Owner CRUD
// ══════════════════════════════════════════════════════════════════════════════
class OwnerKostModel {
  final int id;
  final String name;
  final String address;
  final double pricePerMonth;
  final String type; // PUTRA | PUTRI | CAMPUR
  final int totalRooms;
  final int availableRooms;
  final bool isSplitBillAvailable;
  final List<String> facilities;
  final String? description;
  final String? photoUrl; // foto kamar (URL atau path lokal)

  const OwnerKostModel({
    required this.id,
    required this.name,
    required this.address,
    required this.pricePerMonth,
    required this.type,
    required this.totalRooms,
    required this.availableRooms,
    required this.isSplitBillAvailable,
    required this.facilities,
    this.description,
    this.photoUrl,
  });

  OwnerKostModel copyWith({
    String? name,
    String? address,
    double? pricePerMonth,
    String? type,
    int? totalRooms,
    int? availableRooms,
    bool? isSplitBillAvailable,
    List<String>? facilities,
    String? description,
    String? photoUrl,
  }) {
    return OwnerKostModel(
      id: id,
      name: name ?? this.name,
      address: address ?? this.address,
      pricePerMonth: pricePerMonth ?? this.pricePerMonth,
      type: type ?? this.type,
      totalRooms: totalRooms ?? this.totalRooms,
      availableRooms: availableRooms ?? this.availableRooms,
      isSplitBillAvailable: isSplitBillAvailable ?? this.isSplitBillAvailable,
      facilities: facilities ?? this.facilities,
      description: description ?? this.description,
      photoUrl: photoUrl ?? this.photoUrl,
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// OwnerProvider
// ══════════════════════════════════════════════════════════════════════════════
enum OwnerLoadState { initial, loading, loaded, error }

class OwnerProvider extends ChangeNotifier {
  static const _delay = Duration(milliseconds: 700);

  OwnerStats? _stats;
  List<ReservationModel> _reservations = [];
  List<TicketModel> _tickets = [];
  OwnerLoadState _state = OwnerLoadState.initial;
  String? _errorMessage;
  bool _isSubmitting = false;

  // ─── Manajemen Kamar (CRUD lokal) ─────────────────────────────────────────
  List<OwnerKostModel> _kostList = [];
  bool _kostLoading = false;

  // ─── Profil Owner (in-memory) ─────────────────────────────────────────────
  UserModel _ownerProfile = const UserModel(
    id: 2,
    name: 'Pak Budi Santoso',
    email: 'owner@papikost.com',
    phone: '082345678901',
    role: AppConstants.roleOwner,
    isVerified: true,
  );

  // ── Getters ──────────────────────────────────────────────────────────────
  OwnerStats? get stats => _stats;
  List<ReservationModel> get reservations => _reservations;
  List<TicketModel> get tickets => _tickets;
  OwnerLoadState get state => _state;
  bool get isLoading => _state == OwnerLoadState.loading;
  bool get isSubmitting => _isSubmitting;
  String? get errorMessage => _errorMessage;
  List<OwnerKostModel> get kostList => _kostList;
  bool get kostLoading => _kostLoading;
  UserModel get ownerProfile => _ownerProfile;

  List<ReservationModel> get pendingReservations => _reservations
      .where((r) => r.status == AppConstants.reservationStatusPending)
      .toList();

  // ── Dashboard ─────────────────────────────────────────────────────────────
  Future<void> fetchDashboard() async {
    _state = OwnerLoadState.loading;
    notifyListeners();
    try {
      final results = await Future.wait([
        MockService.fetchOwnerStats(),
        MockService.fetchOwnerReservations(),
        MockService.fetchOwnerTickets(),
      ]);

      final statsMap = results[0] as Map<String, dynamic>;
      _stats = OwnerStats(
        totalRooms: statsMap['totalRooms'] as int,
        occupiedRooms: statsMap['occupiedRooms'] as int,
        pendingReservations: statsMap['pendingReservations'] as int,
        pendingTickets: statsMap['pendingTickets'] as int,
      );
      _reservations = results[1] as List<ReservationModel>;
      _tickets = results[2] as List<TicketModel>;
      _state = OwnerLoadState.loaded;
    } catch (e) {
      _errorMessage = e.toString();
      _state = OwnerLoadState.error;
    }
    notifyListeners();
  }

  // ── Reservasi ─────────────────────────────────────────────────────────────
  Future<bool> respondToReservation(int reservationId, bool approve) async {
    _isSubmitting = true;
    notifyListeners();
    try {
      await Future.delayed(_delay);
      final idx = _reservations.indexWhere((r) => r.id == reservationId);
      if (idx != -1) {
        _reservations.removeAt(idx);
        if (_stats != null) {
          _stats = OwnerStats(
            totalRooms: _stats!.totalRooms,
            occupiedRooms:
                approve ? _stats!.occupiedRooms + 1 : _stats!.occupiedRooms,
            pendingReservations:
                (_stats!.pendingReservations - 1).clamp(0, 999),
            pendingTickets: _stats!.pendingTickets,
          );
        }
      }
      return true;
    } catch (_) {
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  // ── Tiket ─────────────────────────────────────────────────────────────────
  Future<bool> updateTicketStatus(int ticketId, String newStatus) async {
    _isSubmitting = true;
    notifyListeners();
    try {
      await Future.delayed(_delay);
      final idx = _tickets.indexWhere((t) => t.id == ticketId);
      if (idx != -1) {
        _tickets[idx] = _tickets[idx].copyWith(status: newStatus);
      }
      return true;
    } catch (_) {
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // CRUD KAMAR (Manajemen Properti)
  // ══════════════════════════════════════════════════════════════════════════

  /// Load daftar kamar milik owner
  Future<void> fetchKostList() async {
    _kostLoading = true;
    notifyListeners();

    await Future.delayed(_delay);
    if (_kostList.isEmpty) {
      _kostList = _buildInitialKostList();
    }
    _kostLoading = false;
    notifyListeners();
  }

  /// CREATE — Tambah kamar baru
  Future<bool> addKost({
    required String name,
    required String address,
    required double pricePerMonth,
    required String type,
    required int totalRooms,
    required bool isSplitBillAvailable,
    required List<String> facilities,
    String? description,
    String? photoUrl,
  }) async {
    _isSubmitting = true;
    notifyListeners();

    await Future.delayed(_delay);
    final newId = _kostList.isEmpty
        ? 1
        : (_kostList.map((k) => k.id).reduce((a, b) => a > b ? a : b) + 1);

    _kostList.add(
      OwnerKostModel(
        id: newId,
        name: name,
        address: address,
        pricePerMonth: pricePerMonth,
        type: type,
        totalRooms: totalRooms,
        availableRooms: totalRooms,
        isSplitBillAvailable: isSplitBillAvailable,
        facilities: facilities,
        description: description,
        photoUrl: photoUrl,
      ),
    );

    _isSubmitting = false;
    notifyListeners();
    return true;
  }

  /// UPDATE — Edit data kamar
  Future<bool> updateKost({
    required int id,
    required String name,
    required String address,
    required double pricePerMonth,
    required String type,
    required int totalRooms,
    required bool isSplitBillAvailable,
    required List<String> facilities,
    String? description,
    String? photoUrl,
  }) async {
    _isSubmitting = true;
    notifyListeners();

    await Future.delayed(_delay);
    final idx = _kostList.indexWhere((k) => k.id == id);
    if (idx != -1) {
      _kostList[idx] = _kostList[idx].copyWith(
        name: name,
        address: address,
        pricePerMonth: pricePerMonth,
        type: type,
        totalRooms: totalRooms,
        isSplitBillAvailable: isSplitBillAvailable,
        facilities: facilities,
        description: description,
        photoUrl: photoUrl,
      );
    }

    _isSubmitting = false;
    notifyListeners();
    return true;
  }

  /// DELETE — Hapus kamar
  Future<bool> deleteKost(int id) async {
    _isSubmitting = true;
    notifyListeners();

    await Future.delayed(_delay);
    _kostList.removeWhere((k) => k.id == id);

    _isSubmitting = false;
    notifyListeners();
    return true;
  }

  // ── Profil Owner ──────────────────────────────────────────────────────────
  Future<bool> updateProfile({
    required String name,
    required String phone,
    String? bio,
  }) async {
    _isSubmitting = true;
    notifyListeners();

    await Future.delayed(_delay);
    _ownerProfile = UserModel(
      id: _ownerProfile.id,
      name: name.trim(),
      email: _ownerProfile.email,
      phone: phone.trim(),
      role: _ownerProfile.role,
      avatarUrl: _ownerProfile.avatarUrl,
      bio: bio?.trim().isEmpty == true ? null : bio?.trim(),
      isVerified: _ownerProfile.isVerified,
      createdAt: _ownerProfile.createdAt,
    );

    _isSubmitting = false;
    notifyListeners();
    return true;
  }

  // ── Initial mock data kamar ───────────────────────────────────────────────
  static List<OwnerKostModel> _buildInitialKostList() => [
    OwnerKostModel(
      id: 1,
      name: 'Kost Mawar Indah',
      address: 'Jl. Dr. Mansyur No. 12, Medan',
      pricePerMonth: 1200000,
      type: 'PUTRI',
      totalRooms: 12,
      availableRooms: 4,
      isSplitBillAvailable: true,
      facilities: ['WiFi', 'AC', 'Kamar Mandi Dalam', 'Lemari'],
      description: 'Kost putri nyaman dekat USU.',
      photoUrl:
          'https://images.unsplash.com/photo-1586023492125-27b2c045efd7?w=600',
    ),
    OwnerKostModel(
      id: 2,
      name: 'Kost Bumi Putera',
      address: 'Jl. Gagak Hitam No. 5, Medan',
      pricePerMonth: 900000,
      type: 'PUTRA',
      totalRooms: 8,
      availableRooms: 2,
      isSplitBillAvailable: true,
      facilities: ['WiFi', 'Parkir Motor', 'Dapur Bersama'],
      description: 'Kost putra strategis dekat Fasilkom USU.',
      photoUrl:
          'https://images.unsplash.com/photo-1560185007-cde436f6a4d0?w=600',
    ),
  ];
}
