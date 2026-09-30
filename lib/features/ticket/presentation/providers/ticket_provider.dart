import 'package:flutter/material.dart';
import '../../../../core/network/mock_service.dart';
import '../../../../data/models/ticket_model.dart';

enum TicketLoadState { initial, loading, loaded, error, submitting }

class TicketProvider extends ChangeNotifier {
  List<TicketModel> _tickets = [];
  TicketLoadState _state = TicketLoadState.initial;
  String? _errorMessage;

  List<TicketModel> get tickets => _tickets;
  TicketLoadState get state => _state;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _state == TicketLoadState.loading;
  bool get isSubmitting => _state == TicketLoadState.submitting;

  Future<void> fetchMyTickets() async {
    _state = TicketLoadState.loading;
    notifyListeners();
    try {
      _tickets = await MockService.fetchMyTickets();
      _state = TicketLoadState.loaded;
    } catch (e) {
      _errorMessage = e.toString();
      _state = TicketLoadState.error;
    }
    notifyListeners();
  }

  Future<bool> createTicket({
    required String title,
    required String description,
    required String category,
    required int kostId,
    List<String>? imageUrls,
  }) async {
    _state = TicketLoadState.submitting;
    notifyListeners();
    try {
      await MockService.createTicket(
        title: title,
        description: description,
        category: category,
        kostId: kostId,
      );
      // Tambahkan ke list lokal dengan mock data
      _tickets.insert(
        0,
        TicketModel(
          id: DateTime.now().millisecondsSinceEpoch,
          title: title,
          description: description,
          category: category,
          status: 'PENDING',
          imageUrls: imageUrls ?? [],
          renterId: 1,
          renterName: 'Anda',
          kostId: kostId,
          kostName: 'Kost Anda',
          createdAt: DateTime.now(),
        ),
      );
      _state = TicketLoadState.loaded;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _state = TicketLoadState.error;
      notifyListeners();
      return false;
    }
  }
}
