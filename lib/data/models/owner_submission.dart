import 'package:cloud_firestore/cloud_firestore.dart';
import 'kost_model.dart';

enum VerificationStatus { proses, acc, tolak }

extension VerificationStatusX on VerificationStatus {
  String get label => switch (this) {
    VerificationStatus.proses => 'PROSES',
    VerificationStatus.acc => 'ACC',
    VerificationStatus.tolak => 'TOLAK',
  };
}

class OwnerSubmission {
  const OwnerSubmission({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.ktpNumber,
    required this.propertyName,
    required this.propertyAddress,
    required this.propertyType,
    required this.ktpImageUrl,
    required this.sertifikatImageUrl,
    required this.fotoRumahImageUrl,
    required this.submittedAt,
    this.status = VerificationStatus.proses,
    this.rejectionReason,
    this.reviewedBy,
    this.reviewedAt,
    this.kost,
  });

  // Satu pengajuan per Firebase UID, termasuk ketika diajukan ulang.
  final String id;
  final String name, email, phone, ktpNumber;
  final String propertyName, propertyAddress, propertyType;
  final String ktpImageUrl, sertifikatImageUrl, fotoRumahImageUrl;
  final VerificationStatus status;
  final String? rejectionReason, reviewedBy;
  final DateTime submittedAt;
  final DateTime? reviewedAt;
  final KostModel? kost;
  bool get isKostSubmission => kost != null;

  factory OwnerSubmission.fromKost(String id, Map<String, dynamic> data) {
    final kost = KostModel.fromJson({...data, 'id': id});
    return OwnerSubmission(
      id: 'kost/$id',
      name: kost.ownerName,
      email: '',
      phone: '',
      ktpNumber: '',
      propertyName: kost.name,
      propertyAddress: kost.address,
      propertyType: kost.type,
      ktpImageUrl: '',
      sertifikatImageUrl: '',
      fotoRumahImageUrl: kost.photoUrl ?? '',
      submittedAt:
          (data['updatedAt'] as Timestamp?)?.toDate() ??
          (data['createdAt'] as Timestamp?)?.toDate() ??
          DateTime.fromMillisecondsSinceEpoch(0),
      status: VerificationStatus.values.firstWhere(
        (status) => status.label == kost.verificationStatus,
      ),
      rejectionReason: kost.rejectionReason,
      reviewedBy: data['reviewedBy'] as String?,
      reviewedAt: (data['reviewedAt'] as Timestamp?)?.toDate(),
      kost: kost,
    );
  }

  factory OwnerSubmission.fromFirestore(String id, Map<String, dynamic> data) {
    return OwnerSubmission(
      id: id,
      name: data['name'] as String,
      email: data['email'] as String,
      phone: data['phone'] as String,
      ktpNumber: data['ktpNumber'] as String,
      propertyName: data['propertyName'] as String,
      propertyAddress: data['propertyAddress'] as String,
      propertyType: data['propertyType'] as String,
      ktpImageUrl: data['ktpImageUrl'] as String,
      sertifikatImageUrl: data['sertifikatImageUrl'] as String,
      fotoRumahImageUrl: data['fotoRumahImageUrl'] as String,
      status: VerificationStatus.values.firstWhere(
        (status) => status.label == data['status'],
      ),
      rejectionReason: data['rejectionReason'] as String?,
      reviewedBy: data['reviewedBy'] as String?,
      reviewedAt: (data['reviewedAt'] as Timestamp?)?.toDate(),
      submittedAt:
          (data['submittedAt'] as Timestamp?)?.toDate() ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}
