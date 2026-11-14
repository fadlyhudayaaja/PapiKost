import 'package:mocktail/mocktail.dart';
import 'package:papikost_mobile/data/models/reservation_model.dart';
import 'package:papikost_mobile/data/repositories/reservation_repository.dart';

class MockReservationRepository extends Mock implements ReservationRepository {}

final testReservation = ReservationModel(
  id: 'reservation-a',
  ownerId: 'firebase-owner-a',
  kostId: 'firestore-listing-a',
  kostName: 'Kost Melati',
  kostAddress: 'Jalan Melati 10',
  renterId: 'firebase-uid-renter',
  renterName: 'Siti Pengguna',
  renterEmail: 'siti@example.com',
  renterPhone: '081234567890',
  status: 'PENDING',
  isSplitBill: false,
  totalPrice: 1000000,
  checkInDate: DateTime.now().add(const Duration(days: 7)),
  createdAt: DateTime.now(),
);
