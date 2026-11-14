import 'package:mocktail/mocktail.dart';
import 'package:papikost_mobile/data/models/user_model.dart';
import 'package:papikost_mobile/data/repositories/auth_repository.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

const testUser = UserModel(
  id: 'firebase-uid-renter',
  name: 'Siti Pengguna',
  email: 'siti@example.com',
  phone: '081234567890',
  role: 'RENTER',
);
