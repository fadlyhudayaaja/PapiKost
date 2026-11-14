import 'package:equatable/equatable.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ReservationModel extends Equatable {
  final String id;
  final String ownerId;
  final String kostId;
  final String kostName;
  final String kostAddress;
  final String? kostImageUrl;
  final String renterId;
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
    this.ownerId = '',
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
      id: json['id'].toString(),
      ownerId: json['ownerId'] as String? ?? '',
      kostId: json['kostId'].toString(),
      kostName: json['kostName'] as String,
      kostAddress: json['kostAddress'] as String? ?? '',
      kostImageUrl: json['kostImageUrl'] as String?,
      renterId: json['renterId'].toString(),
      renterName: json['renterName'] as String,
      renterEmail: json['renterEmail'] as String,
      renterPhone: json['renterPhone'] as String? ?? '',
      status: json['status'] as String,
      isSplitBill: json['isSplitBill'] as bool? ?? false,
      splitMemberCount: json['splitMemberCount'] as int?,
      totalPrice: (json['totalPrice'] as num).toDouble(),
      pricePerPerson: (json['pricePerPerson'] as num?)?.toDouble(),
      checkInDate: _date(json['checkInDate']),
      checkOutDate: json['checkOutDate'] != null
          ? _date(json['checkOutDate'])
          : null,
      notes: json['notes'] as String?,
      createdAt: _date(json['createdAt']),
    );
  }

  static DateTime _date(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.parse(value);
    // Local snapshots can arrive before server timestamps are resolved.
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'ownerId': ownerId,
    'kostId': kostId,
    'kostName': kostName,
    'kostAddress': kostAddress,
    'kostImageUrl': kostImageUrl,
    'renterId': renterId,
    'renterName': renterName,
    'renterEmail': renterEmail,
    'renterPhone': renterPhone,
    'status': status,
    'isSplitBill': isSplitBill,
    'splitMemberCount': splitMemberCount,
    'totalPrice': totalPrice,
    'pricePerPerson': pricePerPerson,
    'checkInDate': checkInDate.toIso8601String(),
    'checkOutDate': checkOutDate?.toIso8601String(),
    'notes': notes,
    'createdAt': createdAt.toIso8601String(),
  };

  @override
  List<Object?> get props => [
    id,
    ownerId,
    kostId,
    renterId,
    status,
    isSplitBill,
  ];
}
