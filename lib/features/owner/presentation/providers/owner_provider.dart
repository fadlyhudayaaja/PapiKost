import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/network/mock_service.dart';
import '../../../../data/models/reservation_model.dart';
import '../../../../data/models/ticket_model.dart';

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

enum OwnerLoadState { initial, loading, loaded, error }

class OwnerProvider extends ChangeNotifier {
  OwnerStats? _stats;
  List<ReservationModel> _reservations = [];
  List<TicketModel> _tickets = [];
  OwnerLoadState _state = OwnerLoadState.initial;
  String? _errorMessage;

  OwnerStats? get stats => _stats;
  List<ReservationModel> get reservations => _reservations;
  List<TicketModel> get tickets => _tickets;
  OwnerLoadState get state => _state;
  bool get isLoading => _state == OwnerLoadState.loading;
  String? get errorMessage => _errorMessage;

  List<ReservationModel> get pendingReservations => _reservations
      .where((r) => r.status == AppConstants.reservationStatusPending)
      .toList();

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

  Future<bool> respondToReservation(int reservationId, bool approve) async {
    try {
      await MockService.respondReservation(reservationId, approve);
      final idx = _reservations.indexWhere((r) => r.id == reservationId);
      if (idx != -1) {
        _reservations.removeAt(idx);
        if (_stats != null) {
          _stats = OwnerStats(
            totalRooms: _stats!.totalRooms,
            occupiedRooms: approve
                ? _stats!.occupiedRooms + 1
                : _stats!.occupiedRooms,
            pendingReservations: (_stats!.pendingReservations - 1).clamp(
              0,
              999,
            ),
            pendingTickets: _stats!.pendingTickets,
          );
        }
        notifyListeners();
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> updateTicketStatus(int ticketId, String newStatus) async {
    try {
      await MockService.updateTicketStatus(ticketId, newStatus);
      final idx = _tickets.indexWhere((t) => t.id == ticketId);
      if (idx != -1) {
        _tickets[idx] = _tickets[idx].copyWith(status: newStatus);
        notifyListeners();
      }
      return true;
    } catch (_) {
      return false;
    }
  }
}
