import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../data/models/ticket_model.dart';
import '../../../../data/models/user_model.dart';
import '../../../../data/repositories/auth_repository.dart';
import '../../../../data/repositories/ticket_repository.dart';

enum ViewState { loading, empty, error, success }

class RenterTicketProvider extends ChangeNotifier {
  RenterTicketProvider({TicketRepository? repository})
    : _repository = repository ?? TicketRepository.instance;
  final TicketRepository _repository;
  UserModel? _user;
  int _session = 0, _detailVersion = 0;
  StreamSubscription<List<TicketModel>>? _subscription;
  StreamSubscription<TicketModel?>? _detailSubscription;
  ViewState _listState = ViewState.empty, _detailState = ViewState.empty;
  List<TicketModel> _tickets = [];
  String _listError = '', _detailError = '';
  TicketModel? _selectedTicket;
  bool _isSubmitting = false;
  ViewState get listState => _listState;
  List<TicketModel> get tickets => List.unmodifiable(_tickets);
  String get listError => _listError;
  ViewState get detailState => _detailState;
  TicketModel? get selectedTicket => _selectedTicket;
  String get detailError => _detailError;
  bool get isSubmitting => _isSubmitting;

  void bindUser(UserModel? user) {
    if (_user?.id == user?.id && _user?.role == user?.role) {
      _user = user;
      return;
    }
    _user = user;
    _session++;
    _detailVersion++;
    unawaited(_subscription?.cancel());
    unawaited(_detailSubscription?.cancel());
    _subscription = null;
    _detailSubscription = null;
    _tickets = [];
    _selectedTicket = null;
    _listError = '';
    _detailError = '';
    _isSubmitting = false;
    _listState = ViewState.empty;
    _detailState = ViewState.empty;
    if (user?.role == 'RENTER') {
      final session = _session;
      _listState = ViewState.loading;
      _subscription = _repository
          .watchForRenter(user!.id)
          .listen(
            (items) {
              if (session != _session) return;
              _tickets = items;
              _listError = '';
              _listState = items.isEmpty ? ViewState.empty : ViewState.success;
              notifyListeners();
            },
            onError: (Object error) {
              if (session != _session) return;
              _tickets = [];
              _listError = TicketRepository.errorMessage(error);
              _listState = ViewState.error;
              notifyListeners();
            },
          );
    }
  }

  Future<void> loadTickets() async {
    final user = _user, session = _session;
    if (user?.role != 'RENTER') return;
    _listState = ViewState.loading;
    _listError = '';
    notifyListeners();
    try {
      final items = await _repository.fetchForRenter(user!.id);
      if (session != _session) return;
      _tickets = items;
      _listState = items.isEmpty ? ViewState.empty : ViewState.success;
    } catch (error) {
      if (session != _session) return;
      _listError = TicketRepository.errorMessage(error);
      _listState = ViewState.error;
    }
    if (session == _session) notifyListeners();
  }

  Future<void> loadTicketDetail(String id) async {
    final session = _session;
    final version = ++_detailVersion;
    unawaited(_detailSubscription?.cancel());
    _selectedTicket = null;
    _detailState = ViewState.loading;
    _detailError = '';
    notifyListeners();
    if (_user?.role != 'RENTER') {
      _detailState = ViewState.empty;
      notifyListeners();
      return;
    }
    _detailSubscription = _repository
        .watchById(id)
        .listen(
          (item) {
            if (session != _session || version != _detailVersion) return;
            _selectedTicket = item;
            _detailState = item == null ? ViewState.empty : ViewState.success;
            _detailError = '';
            notifyListeners();
          },
          onError: (Object error) {
            if (session != _session || version != _detailVersion) return;
            _selectedTicket = null;
            _detailError = TicketRepository.errorMessage(error);
            _detailState = ViewState.error;
            notifyListeners();
          },
        );
  }

  Future<T?> _mutate<T>(Future<T> Function() operation) async {
    if (_isSubmitting) {
      throw const AuthFailure('Laporan sedang diproses. Tunggu sebentar.');
    }
    if (_user?.role != 'RENTER') {
      throw const AuthFailure('Silakan login sebagai penyewa.');
    }
    final session = _session;
    _isSubmitting = true;
    notifyListeners();
    try {
      final value = await operation();
      return session == _session ? value : null;
    } catch (error) {
      throw AuthFailure(TicketRepository.errorMessage(error));
    } finally {
      if (session == _session) {
        _isSubmitting = false;
        notifyListeners();
      }
    }
  }

  void _upsert(TicketModel ticket) {
    _tickets = [ticket, ..._tickets.where((item) => item.id != ticket.id)];
    _listError = '';
    _listState = ViewState.success;
    notifyListeners();
  }

  Future<TicketModel?> createTicket({
    required String reservationId,
    required String title,
    required String description,
    required String category,
    required DateTime incidentDate,
    List<String> imageUrls = const [],
  }) async {
    final session = _session;
    final ticket = await _mutate(
      () => _repository.createTicket(
        reservationId: reservationId,
        title: title,
        description: description,
        category: category,
        incidentDate: incidentDate,
        imageUrls: imageUrls,
      ),
    );
    if (session != _session) return null;
    if (ticket != null) _upsert(ticket);
    return ticket;
  }

  Future<TicketModel?> updateTicket({
    required String id,
    required String title,
    required String description,
    required String category,
    required DateTime incidentDate,
    List<String>? imageUrls,
  }) async {
    final session = _session;
    final ticket = await _mutate(
      () => _repository.updateTicket(
        id: id,
        title: title,
        description: description,
        category: category,
        incidentDate: incidentDate,
        imageUrls: imageUrls,
      ),
    );
    if (session != _session) return null;
    if (ticket != null) {
      _upsert(ticket);
      if (_selectedTicket?.id == id) {
        _selectedTicket = ticket;
        _detailState = ViewState.success;
      }
      notifyListeners();
    }
    return ticket;
  }

  Future<bool> deleteTicket(String id) async {
    final session = _session;
    final success = await _mutate(() async {
      await _repository.deleteTicket(id);
      return true;
    });
    if (session != _session || success != true) return false;
    _tickets = _tickets.where((item) => item.id != id).toList();
    _listState = _tickets.isEmpty ? ViewState.empty : ViewState.success;
    if (_selectedTicket?.id == id) {
      _selectedTicket = null;
      _detailState = ViewState.empty;
    }
    notifyListeners();
    return true;
  }

  @override
  void dispose() {
    _session++;
    _detailVersion++;
    unawaited(_subscription?.cancel());
    unawaited(_detailSubscription?.cancel());
    super.dispose();
  }
}
