import 'package:equatable/equatable.dart';

class ReservationModel extends Equatable {
  final int id;
  final int kostId;
  final String kostName;
  final String kostAddress;
  final String? kostImageUrl;
  final int renterId;
  final String renterName;
  final String renterEmail;
  final String renterPhone;
  final String status; // PENDING | APPROVED | REJECTED
  final bool isSplitBill;
  final int? splitMemberCount;
  final double totalPrice;
  final double? pricePerPerson;
  final DateTime checkInDate;
  final DateTime? checkOutDate;
  final String? notes;
  final DateTime createdAt;

  const ReservationModel({
    required this.id,
    required this.kostId,
    required this.kostName,
    required this.kostAddress,
    this.kostImageUrl,
    required this.renterId,
    required this.renterName,
    required this.renterEmail,
    required this.renterPhone,
    required this.status,
    required this.isSplitBill,
    this.splitMemberCount,
    required this.totalPrice,
    this.pricePerPerson,
    required this.checkInDate,
    this.checkOutDate,
    this.notes,
    required this.createdAt,
  });

  factory ReservationModel.fromJson(Map<String, dynamic> json) {
    return ReservationModel(
      id: json['id'] as int,
      kostId: json['kostId'] as int,
      kostName: json['kostName'] as String,
      kostAddress: json['kostAddress'] as String? ?? '',
      kostImageUrl: json['kostImageUrl'] as String?,
      renterId: json['renterId'] as int,
      renterName: json['renterName'] as String,
      renterEmail: json['renterEmail'] as String,
      renterPhone: json['renterPhone'] as String? ?? '',
      status: json['status'] as String,
      isSplitBill: json['isSplitBill'] as bool? ?? false,
      splitMemberCount: json['splitMemberCount'] as int?,
      totalPrice: (json['totalPrice'] as num).toDouble(),
      pricePerPerson: (json['pricePerPerson'] as num?)?.toDouble(),
      checkInDate: DateTime.parse(json['checkInDate'] as String),
      checkOutDate: json['checkOutDate'] != null
          ? DateTime.tryParse(json['checkOutDate'] as String)
          : null,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'kostId': kostId,
    'renterId': renterId,
    'isSplitBill': isSplitBill,
    'splitMemberCount': splitMemberCount,
    'totalPrice': totalPrice,
    'checkInDate': checkInDate.toIso8601String(),
    'notes': notes,
  };

  @override
  List<Object?> get props => [id, kostId, renterId, status, isSplitBill];
}
