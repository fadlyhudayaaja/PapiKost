import 'package:mocktail/mocktail.dart';
import 'package:papikost_mobile/data/models/kost_model.dart';
import 'package:papikost_mobile/data/repositories/kost_repository.dart';

class MockKostRepository extends Mock implements KostRepository {}

const testKost = KostModel(
  id: 'firestore-listing-a',
  ownerId: 'firebase-owner-a',
  name: 'Kost Melati',
  address: 'Jalan Melati 10',
  city: 'Medan',
  pricePerMonth: 1000000,
  type: 'CAMPUR',
  facilities: ['WiFi'],
  imageUrls: [],
  isSplitBillAvailable: false,
  totalRooms: 5,
  availableRooms: 3,
  ownerName: 'Owner A',
  verificationStatus: 'ACC',
);
