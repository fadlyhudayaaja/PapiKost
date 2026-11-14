import 'package:mocktail/mocktail.dart';
import 'package:papikost_mobile/data/models/ticket_model.dart';
import 'package:papikost_mobile/data/repositories/ticket_repository.dart';

class MockTicketRepository extends Mock implements TicketRepository {}

MockTicketRepository emptyTicketRepository() {
  final repository = MockTicketRepository();
  when(
    () => repository.watchForOwner(any()),
  ).thenAnswer((_) => const Stream.empty());
  when(() => repository.fetchForOwner(any())).thenAnswer((_) async => []);
  when(
    () => repository.watchForRenter(any()),
  ).thenAnswer((_) => const Stream.empty());
  when(() => repository.fetchForRenter(any())).thenAnswer((_) async => []);
  return repository;
}

final testTicket = TicketModel(
  id: 'ticket-a',
  ownerId: 'firebase-owner-a',
  reservationId: 'reservation-a',
  title: 'Lampu kamar mati',
  description: 'Lampu di kamar tidak menyala sejak tadi pagi.',
  category: 'LISTRIK',
  status: 'PENDING',
  imageUrls: const [],
  renterId: 'firebase-uid-renter',
  renterName: 'Siti Pengguna',
  kostId: 'firestore-listing-a',
  kostName: 'Kost Melati',
  incidentDate: DateTime.now(),
  createdAt: DateTime.now(),
  updatedAt: DateTime.now(),
);
