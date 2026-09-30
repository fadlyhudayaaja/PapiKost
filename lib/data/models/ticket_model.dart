import 'package:equatable/equatable.dart';

class TicketModel extends Equatable {
  final int id;
  final String title;
  final String description;
  final String category;
  final String status;
  final List<String> imageUrls;
  final int renterId;
  final String renterName;
  final int kostId;
  final String kostName;
  final String? ownerNote;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const TicketModel({
    required this.id,
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
  });

  factory TicketModel.fromJson(Map<String, dynamic> json) {
    return TicketModel(
      id: json['id'] as int,
      title: json['title'] as String,
      description: json['description'] as String,
      category: json['category'] as String? ?? 'LAINNYA',
      status: json['status'] as String? ?? 'PENDING',
      imageUrls: List<String>.from(json['imageUrls'] as List? ?? []),
      renterId: json['renterId'] as int,
      renterName: json['renterName'] as String? ?? '',
      kostId: json['kostId'] as int,
      kostName: json['kostName'] as String? ?? '',
      ownerNote: json['ownerNote'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'title': title,
    'description': description,
    'category': category,
    'kostId': kostId,
  };

  TicketModel copyWith({String? status, String? ownerNote}) {
    return TicketModel(
      id: id,
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
  List<Object?> get props => [id, title, category, status, kostId, renterId];
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
