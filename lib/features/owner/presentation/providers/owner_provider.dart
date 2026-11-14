import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../data/models/kost_model.dart';
import '../../../../data/models/reservation_model.dart';
import '../../../../data/models/ticket_model.dart';
import '../../../../data/models/user_model.dart';
import '../../../../data/repositories/kost_repository.dart';
import '../../../../data/repositories/reservation_repository.dart';
import '../../../../data/repositories/ticket_repository.dart';

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
      totalRooms > 0 ? occupiedRooms / totalRooms * 100 : 0;
}

typedef OwnerKostModel = KostModel;

enum OwnerLoadState { initial, loading, loaded, error }

class OwnerProvider extends ChangeNotifier {
  OwnerProvider({
    KostRepository? repository,
    ReservationRepository? reservationRepository,
    TicketRepository? ticketRepository,
  }) : _repository = repository ?? KostRepository.instance,
       _reservationRepository =
           reservationRepository ?? ReservationRepository.instance,
       _ticketRepository = ticketRepository ?? TicketRepository.instance;
  final KostRepository _repository;
  final ReservationRepository _reservationRepository;
  final TicketRepository _ticketRepository;
  StreamSubscription<List<TicketModel>>? _ticketSubscription;
  bool _ticketLoading = false;
  String? _ticketError;
  StreamSubscription<List<ReservationModel>>? _reservationSubscription;
  bool _reservationLoading = false;
  String? _reservationError;
  UserModel? _user;
  int _session = 0;
  OwnerStats? _stats;
  List<ReservationModel> _reservations = [];
  List<TicketModel> _tickets = [];
  List<KostModel> _kostList = [];
  OwnerLoadState _state = OwnerLoadState.initial;
  String? _errorMessage;
  String? _kostError;
  bool _isSubmitting = false;
  bool _kostLoading = false;

  OwnerStats? get stats => _stats;
  List<ReservationModel> get reservations => List.unmodifiable(_reservations);
  List<TicketModel> get tickets => List.unmodifiable(_tickets);
  List<KostModel> get kostList => List.unmodifiable(_kostList);
  OwnerLoadState get state => _state;
  bool get isLoading => _state == OwnerLoadState.loading;
  bool get isSubmitting => _isSubmitting;
  bool get kostLoading => _kostLoading;
  String? get errorMessage => _errorMessage;
  String? get kostError => _kostError;
  bool get reservationLoading => _reservationLoading;
  String? get reservationError => _reservationError;
  bool get ticketLoading => _ticketLoading;
  String? get ticketError => _ticketError;
  List<ReservationModel> get pendingReservations => _reservations
      .where((item) => item.status == AppConstants.reservationStatusPending)
      .toList();

  // Dipanggil ProxyProvider: bersihkan data sebelum akun berikutnya digunakan.
  void bindUser(UserModel? user) {
    if (_user?.id == user?.id && _user?.role == user?.role) {
      _user = user;
      return;
    }
    _user = user;
    _session++;
    unawaited(_reservationSubscription?.cancel());
    _reservationSubscription = null;
    unawaited(_ticketSubscription?.cancel());
    _ticketSubscription = null;
    _ticketLoading = false;
    _ticketError = null;
    _kostList = [];
    _reservations = [];
    _tickets = [];
    _stats = null;
    _state = OwnerLoadState.initial;
    _errorMessage = null;
    _kostError = null;
    _kostLoading = false;
    _isSubmitting = false;
    _reservationError = null;
    _reservationLoading = false;
    if (user?.role == AppConstants.roleOwner) {
      final session = _session;
      _ticketLoading = true;
      _ticketSubscription = _ticketRepository
          .watchForOwner(user!.id)
          .listen(
            (items) {
              if (session != _session) return;
              _tickets = items;
              _ticketLoading = false;
              _ticketError = null;
              _updateStats();
              notifyListeners();
            },
            onError: (Object error) {
              if (session != _session) return;
              _tickets = [];
              _ticketLoading = false;
              _ticketError = TicketRepository.errorMessage(error);
              _updateStats();
              notifyListeners();
            },
          );
      _reservationLoading = true;
      _reservationSubscription = _reservationRepository
          .watchForOwner(user.id)
          .listen(
            (items) {
              if (session != _session) return;
              _reservations = items;
              _reservationLoading = false;
              _reservationError = null;
              _updateStats();
              notifyListeners();
            },
            onError: (Object error) {
              if (session != _session) return;
              _reservations = [];
              _reservationLoading = false;
              _reservationError = ReservationRepository.errorMessage(error);
              _updateStats();
              notifyListeners();
            },
          );
    }
  }

  @override
  void dispose() {
    _session++;
    unawaited(_reservationSubscription?.cancel());
    unawaited(_ticketSubscription?.cancel());
    super.dispose();
  }

  void _updateStats() {
    _stats = OwnerStats(
      totalRooms: _kostList.fold(0, (sum, kost) => sum + kost.totalRooms),
      occupiedRooms: _kostList.fold(
        0,
        (sum, kost) => sum + kost.totalRooms - kost.availableRooms,
      ),
      pendingReservations: pendingReservations.length,
      pendingTickets: _tickets
          .where((ticket) => ticket.status == 'PENDING')
          .length,
    );
  }

  Future<void> fetchDashboard() async {
    final session = _session;
    _state = OwnerLoadState.loading;
    notifyListeners();
    await fetchKostList();
    if (session != _session) return;
    await fetchReservations();
    if (session != _session) return;
    await fetchTickets();
    if (session != _session) return;
    if (_kostError != null ||
        _reservationError != null ||
        _ticketError != null) {
      _errorMessage = _kostError ?? _reservationError ?? _ticketError;
      _state = OwnerLoadState.error;
    } else {
      _errorMessage = null;
      _updateStats();
      _state = OwnerLoadState.loaded;
    }
    notifyListeners();
  }

  Future<void> fetchReservations() async {
    final session = _session;
    final user = _user;
    if (user?.role != AppConstants.roleOwner) return;
    _reservationLoading = true;
    _reservationError = null;
    notifyListeners();
    try {
      final items = await _reservationRepository.fetchForOwner(user!.id);
      if (session != _session) return;
      _reservations = items;
      _updateStats();
    } catch (error) {
      if (session == _session) {
        _reservationError = ReservationRepository.errorMessage(error);
      }
    } finally {
      if (session == _session) {
        _reservationLoading = false;
        notifyListeners();
      }
    }
  }

  Future<void> fetchKostList() async {
    final session = _session;
    final user = _user;
    _kostLoading = true;
    _kostError = null;
    notifyListeners();
    try {
      if (user == null || user.role != AppConstants.roleOwner) {
        _kostList = [];
      } else {
        final list = await _repository.fetchForOwner(user.id);
        if (session != _session) return;
        _kostList = list;
      }
      _updateStats();
    } catch (error) {
      if (session != _session) return;
      _kostError = KostRepository.errorMessage(error);
    } finally {
      if (session == _session) {
        _kostLoading = false;
        notifyListeners();
      }
    }
  }

  Future<bool> _mutate(
    Future<void> Function() operation, {
    String Function(Object)? errorMessage,
  }) async {
    if (_isSubmitting || _user?.role != AppConstants.roleOwner) return false;
    final session = _session;
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await operation();
      if (session != _session) return false;
      _kostError = null;
      _updateStats();
      return true;
    } catch (error) {
      if (session == _session) {
        _errorMessage = (errorMessage ?? KostRepository.errorMessage)(error);
      }
      return false;
    } finally {
      if (session == _session) {
        _isSubmitting = false;
        notifyListeners();
      }
    }
  }

  Future<bool> addKost({
    required String name,
    required String address,
    required String city,
    required double pricePerMonth,
    required String type,
    required int totalRooms,
    required bool isSplitBillAvailable,
    required List<String> facilities,
    String? description,
    String? photoUrl,
  }) {
    final session = _session;
    return _mutate(() async {
      final kost = await _repository.createKost(
        name: name,
        address: address,
        city: city,
        pricePerMonth: pricePerMonth,
        type: type,
        totalRooms: totalRooms,
        isSplitBillAvailable: isSplitBillAvailable,
        facilities: facilities,
        description: description,
        photoUrl: photoUrl,
      );
      if (session == _session) _kostList = [..._kostList, kost];
    });
  }

  Future<bool> updateKost({
    required String id,
    required String name,
    required String address,
    required String city,
    required double pricePerMonth,
    required String type,
    required int totalRooms,
    required bool isSplitBillAvailable,
    required List<String> facilities,
    String? description,
    String? photoUrl,
  }) {
    final session = _session;
    return _mutate(() async {
      final updated = await _repository.updateKost(
        id: id,
        name: name,
        address: address,
        city: city,
        pricePerMonth: pricePerMonth,
        type: type,
        totalRooms: totalRooms,
        isSplitBillAvailable: isSplitBillAvailable,
        facilities: facilities,
        description: description,
        photoUrl: photoUrl,
      );
      if (session == _session) {
        _kostList = _kostList
            .map((kost) => kost.id == id ? updated : kost)
            .toList();
      }
    });
  }

  Future<bool> deleteKost(String id) {
    final session = _session;
    return _mutate(() async {
      await _repository.deleteKost(id);
      if (session == _session) {
        _kostList = _kostList.where((kost) => kost.id != id).toList();
      }
    });
  }

  Future<bool> respondToReservation(String reservationId, bool approve) {
    final session = _session;
    return _mutate(() async {
      await _reservationRepository.respond(reservationId, approve: approve);
      if (session != _session) return;
      await fetchReservations();
      if (session != _session) return;
      await fetchKostList();
    }, errorMessage: ReservationRepository.errorMessage);
  }

  Future<void> fetchTickets() async {
    final user = _user, session = _session;
    if (user?.role != AppConstants.roleOwner) return;
    _ticketLoading = true;
    _ticketError = null;
    notifyListeners();
    try {
      final items = await _ticketRepository.fetchForOwner(user!.id);
      if (session != _session) return;
      _tickets = items;
      _updateStats();
    } catch (error) {
      if (session == _session) {
        _ticketError = TicketRepository.errorMessage(error);
      }
    } finally {
      if (session == _session) {
        _ticketLoading = false;
        notifyListeners();
      }
    }
  }

  Future<bool> updateTicketStatus(
    String ticketId,
    String newStatus, {
    String? ownerNote,
  }) {
    final session = _session;
    return _mutate(() async {
      final updated = await _ticketRepository.updateStatus(
        ticketId,
        newStatus,
        ownerNote: ownerNote,
      );
      if (session != _session) return;
      _tickets = _tickets
          .map((item) => item.id == ticketId ? updated : item)
          .toList();
    }, errorMessage: TicketRepository.errorMessage);
  }
}
