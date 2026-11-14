import 'package:mocktail/mocktail.dart';
import 'package:papikost_mobile/data/models/owner_submission.dart';
import 'package:papikost_mobile/data/models/user_model.dart';
import 'package:papikost_mobile/data/repositories/owner_verification_repository.dart';

class MockVerificationRepository extends Mock
    implements OwnerVerificationRepository {}

const verificationOwner = UserModel(
  id: 'owner-a',
  name: 'Owner A',
  email: 'owner@example.com',
  phone: '081234567890',
  role: 'OWNER',
);
const verificationAdmin = UserModel(
  id: 'admin-a',
  name: 'Admin A',
  email: 'admin@example.com',
  phone: '081234567891',
  role: 'ADMIN',
);

OwnerSubmission submissionFixture({
  VerificationStatus status = VerificationStatus.proses,
}) => OwnerSubmission(
  id: verificationOwner.id,
  name: verificationOwner.name,
  email: verificationOwner.email,
  phone: verificationOwner.phone,
  ktpNumber: '1234567890123456',
  propertyName: 'Kost Melati',
  propertyAddress: 'Jalan Melati 10',
  propertyType: 'CAMPUR',
  ktpImageUrl: 'https://example.com/ktp.jpg',
  sertifikatImageUrl: 'https://example.com/sertifikat.jpg',
  fotoRumahImageUrl: 'https://example.com/kost.jpg',
  status: status,
  submittedAt: DateTime(2026, 11, 12),
  rejectionReason: status == VerificationStatus.tolak
      ? 'Foto KTP tidak terbaca.'
      : null,
);
