import 'package:equatable/equatable.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TicketModel extends Equatable {
  final String id;
  final String ownerId;
  final String reservationId;
  final DateTime incidentDate;
  final String title;
  final String description;
  final String category;
  final String status;
  final List<String> imageUrls;
  final String renterId;
  final String renterName;
  final String kostId;
  final String kostName;
  final String? ownerNote;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const TicketModel({
    required this.id,
    this.ownerId = '',
    this.reservationId = '',
    DateTime? incidentDate,
    required this.title,
    required this.description,
    required this.category,
    required this.status,
    required this.imageUrls,
    required this.renterId,
    required this.renterName,
    required this.kostId,
    required this.kostName,
    this.ownerNote,
    required this.createdAt,
    this.updatedAt,
  }) : incidentDate = incidentDate ?? createdAt;

  factory TicketModel.fromJson(Map<String, dynamic> json) {
    return TicketModel(
      id: json['id'].toString(),
      ownerId: json['ownerId'] as String? ?? '',
      reservationId: json['reservationId'] as String? ?? '',
      incidentDate: _date(json['incidentDate'] ?? json['createdAt']),
      title: json['title'] as String,
      description: json['description'] as String,
      category: json['category'] as String? ?? 'LAINNYA',
      status: json['status'] as String? ?? 'PENDING',
      imageUrls: List<String>.from(json['imageUrls'] as List? ?? []),
      renterId: json['renterId'].toString(),
      renterName: json['renterName'] as String? ?? '',
      kostId: json['kostId'].toString(),
      kostName: json['kostName'] as String? ?? '',
      ownerNote: json['ownerNote'] as String?,
      createdAt: _date(json['createdAt']),
      updatedAt: json['updatedAt'] != null ? _date(json['updatedAt']) : null,
    );
  }

  static DateTime _date(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.parse(value);
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'ownerId': ownerId,
    'reservationId': reservationId,
    'incidentDate': incidentDate.toIso8601String(),
    'title': title,
    'description': description,
    'category': category,
    'kostId': kostId,
    'kostName': kostName,
    'renterId': renterId,
    'renterName': renterName,
    'status': status,
    'imageUrls': imageUrls,
    'ownerNote': ownerNote,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt?.toIso8601String(),
  };

  TicketModel copyWith({String? status, String? ownerNote}) {
    return TicketModel(
      id: id,
      ownerId: ownerId,
      reservationId: reservationId,
      incidentDate: incidentDate,
      title: title,
      description: description,
      category: category,
      status: status ?? this.status,
      imageUrls: imageUrls,
      renterId: renterId,
      renterName: renterName,
      kostId: kostId,
      kostName: kostName,
      ownerNote: ownerNote ?? this.ownerNote,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    title,
    description,
    category,
    status,
    kostId,
    renterId,
    ownerId,
    reservationId,
    incidentDate,
    ownerNote,
    imageUrls,
    updatedAt,
  ];
}

// Enum helper untuk kategori tiket
enum TicketCategory {
  air('AIR', 'Air & Plumbing'),
  listrik('LISTRIK', 'Listrik'),
  mebel('MEBEL', 'Mebel & Perabot'),
  struktur('STRUKTUR', 'Struktur Bangunan'),
  lainnya('LAINNYA', 'Lainnya');

  final String value;
  final String label;
  const TicketCategory(this.value, this.label);
}
