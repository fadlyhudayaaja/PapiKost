import '../../core/network/dio_client.dart';
import '../models/ticket_model.dart';

class TicketRepository {
  TicketRepository._();
  static final TicketRepository instance = TicketRepository._();

  Future<List<TicketModel>> fetchMyTickets() async {
    final resp = await DioClient.instance.get('/tickets/my');
    final data = resp.data as List;
    return data
        .map((e) => TicketModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<TicketModel>> fetchOwnerTickets() async {
    final resp = await DioClient.instance.get('/owner/tickets');
    final data = resp.data as List;
    return data
        .map((e) => TicketModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> createTicket({
    required String title,
    required String description,
    required String category,
    required int kostId,
    List<String> imageUrls = const [],
  }) async {
    await DioClient.instance.post(
      '/tickets',
      data: {
        'title': title,
        'description': description,
        'category': category,
        'kostId': kostId,
        'imageUrls': imageUrls,
      },
    );
  }

  Future<void> updateStatus(int ticketId, String status) async {
    await DioClient.instance.put(
      '/owner/tickets/$ticketId',
      data: {'status': status},
    );
  }
}
