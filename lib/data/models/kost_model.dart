import 'package:equatable/equatable.dart';

class KostModel extends Equatable {
  final int id;
  final String name;
  final String address;
  final String city;
  final double pricePerMonth;
  final String type; // PUTRA | PUTRI | CAMPUR
  final List<String> facilities;
  final List<String> imageUrls;
  final bool isSplitBillAvailable;
  final int totalRooms;
  final int availableRooms;
  final double? latitude;
  final double? longitude;
  final String? description;
  final String ownerName;
  final double? rating;
  final int reviewCount;

  const KostModel({
    required this.id,
    required this.name,
    required this.address,
    required this.city,
    required this.pricePerMonth,
    required this.type,
    required this.facilities,
    required this.imageUrls,
    required this.isSplitBillAvailable,
    required this.totalRooms,
    required this.availableRooms,
    this.latitude,
    this.longitude,
    this.description,
    required this.ownerName,
    this.rating,
    this.reviewCount = 0,
  });

  factory KostModel.fromJson(Map<String, dynamic> json) {
    return KostModel(
      id: json['id'] as int,
      name: json['name'] as String,
      address: json['address'] as String,
      city: json['city'] as String? ?? 'Medan',
      pricePerMonth: (json['pricePerMonth'] as num).toDouble(),
      type: json['type'] as String? ?? 'CAMPUR',
      facilities: List<String>.from(json['facilities'] as List? ?? []),
      imageUrls: List<String>.from(json['imageUrls'] as List? ?? []),
      isSplitBillAvailable: json['isSplitBillAvailable'] as bool? ?? false,
      totalRooms: json['totalRooms'] as int? ?? 0,
      availableRooms: json['availableRooms'] as int? ?? 0,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      description: json['description'] as String?,
      ownerName: json['ownerName'] as String? ?? '',
      rating: (json['rating'] as num?)?.toDouble(),
      reviewCount: json['reviewCount'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'address': address,
    'city': city,
    'pricePerMonth': pricePerMonth,
    'type': type,
    'facilities': facilities,
    'imageUrls': imageUrls,
    'isSplitBillAvailable': isSplitBillAvailable,
    'totalRooms': totalRooms,
    'availableRooms': availableRooms,
    'latitude': latitude,
    'longitude': longitude,
    'description': description,
    'ownerName': ownerName,
    'rating': rating,
    'reviewCount': reviewCount,
  };

  @override
  List<Object?> get props => [
    id,
    name,
    address,
    city,
    pricePerMonth,
    type,
    facilities,
    imageUrls,
    isSplitBillAvailable,
    totalRooms,
    availableRooms,
  ];
}
