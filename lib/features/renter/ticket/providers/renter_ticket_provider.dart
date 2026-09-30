import 'package:flutter/material.dart';
import '../../../../data/models/ticket_model.dart';
import '../../../../data/repositories/mock_repository.dart';

/// 4 UI States: loading / empty / error / success
enum ViewState { loading, empty, error, success }

class RenterTicketProvider extends ChangeNotifier {
  final MockRepository _repo = MockRepository.instance;

  // ── List state ─────────────────────────────────────────────────────────────
  ViewState _listState = ViewState.loading;
  List<TicketModel> _tickets = [];
  String _listError = '';

  ViewState get listState => _listState;
  List<TicketModel> get tickets => _tickets;
  String get listError => _listError;

  // ── Detail state ───────────────────────────────────────────────────────────
  ViewState _detailState = ViewState.loading;
  TicketModel? _selectedTicket;
  String _detailError = '';

  ViewState get detailState => _detailState;
  TicketModel? get selectedTicket => _selectedTicket;
  String get detailError => _detailError;

  // ── Form state (mencegah double submit) ───────────────────────────────────
  bool _isSubmitting = false;
  bool get isSubmitting => _isSubmitting;

  // ════════════════════════════════════════════════════════════════════════════
  // LIST
  // ════════════════════════════════════════════════════════════════════════════

  Future<void> loadTickets({bool simulateError = false}) async {
    _listState = ViewState.loading;
    _listError = '';
    notifyListeners();

    try {
      final data = await _repo.getMyTickets(simulateError: simulateError);
      _tickets = data;
      _listState = data.isEmpty ? ViewState.empty : ViewState.success;
    } catch (e) {
      _listError = e.toString().replaceFirst('Exception: ', '');
      _listState = ViewState.error;
    }
    notifyListeners();
  }

  // ════════════════════════════════════════════════════════════════════════════
  // DETAIL
  // ════════════════════════════════════════════════════════════════════════════

  Future<void> loadTicketDetail(int id, {bool simulateError = false}) async {
    _detailState = ViewState.loading;
    _detailError = '';
    _selectedTicket = null;
    notifyListeners();

    try {
      _selectedTicket = await _repo.getTicketById(
        id,
        simulateError: simulateError,
      );
      _detailState = ViewState.success;
    } catch (e) {
      _detailError = e.toString().replaceFirst('Exception: ', '');
      _detailState = ViewState.error;
    }
    notifyListeners();
  }

  // ════════════════════════════════════════════════════════════════════════════
  // CREATE
  // ════════════════════════════════════════════════════════════════════════════

  /// Returns created ticket or null on error.
  /// Tombol submit dinonaktifkan selama proses (isSubmitting = true).
  Future<TicketModel?> createTicket({
    required String title,
    required String description,
    required String category,
    required DateTime incidentDate,
    List<String> imageUrls = const [],
    bool simulateError = false,
  }) async {
    if (_isSubmitting) return null; // Cegah double submit
    _isSubmitting = true;
    notifyListeners();

    try {
      final ticket = await _repo.createTicket(
        title: title,
        description: description,
        category: category,
        incidentDate: incidentDate,
        imageUrls: imageUrls,
        simulateError: simulateError,
      );
      _tickets.insert(0, ticket); // Tambah ke awal list lokal
      _listState = ViewState.success;
      return ticket;
    } catch (e) {
      rethrow;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  // ════════════════════════════════════════════════════════════════════════════
  // UPDATE
  // ════════════════════════════════════════════════════════════════════════════

  Future<TicketModel?> updateTicket({
    required int id,
    required String title,
    required String description,
    required String category,
    required DateTime incidentDate,
    List<String>? imageUrls,
    bool simulateError = false,
  }) async {
    if (_isSubmitting) return null;
    _isSubmitting = true;
    notifyListeners();

    try {
      final updated = await _repo.updateTicket(
        id: id,
        title: title,
        description: description,
        category: category,
        incidentDate: incidentDate,
        imageUrls: imageUrls,
        simulateError: simulateError,
      );
      // Update di list lokal
      final idx = _tickets.indexWhere((t) => t.id == id);
      if (idx != -1) _tickets[idx] = updated;
      _selectedTicket = updated;
      return updated;
    } catch (e) {
      rethrow;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  // ════════════════════════════════════════════════════════════════════════════
  // DELETE
  // ════════════════════════════════════════════════════════════════════════════

  Future<bool> deleteTicket(int id, {bool simulateError = false}) async {
    if (_isSubmitting) return false;
    _isSubmitting = true;
    notifyListeners();

    try {
      await _repo.deleteTicket(id, simulateError: simulateError);
      _tickets.removeWhere((t) => t.id == id);
      _listState = _tickets.isEmpty ? ViewState.empty : ViewState.success;
      return true;
    } catch (e) {
      rethrow;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }
}
