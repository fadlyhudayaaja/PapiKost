import 'package:equatable/equatable.dart';

class KostModel extends Equatable {
  final String id;
  final String ownerId;
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
  final String verificationStatus;
  final String? rejectionReason;

  const KostModel({
    required this.id,
    this.ownerId = '',
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
    this.verificationStatus = 'PROSES',
    this.rejectionReason,
  });

  factory KostModel.fromJson(Map<String, dynamic> json) {
    return KostModel(
      id: json['id'].toString(),
      ownerId: json['ownerId'] as String? ?? '',
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
      verificationStatus: json['verificationStatus'] as String? ?? 'PROSES',
      rejectionReason: json['rejectionReason'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'ownerId': ownerId,
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
    'verificationStatus': verificationStatus,
    'rejectionReason': rejectionReason,
  };

  String? get photoUrl => imageUrls.isEmpty ? null : imageUrls.first;

  @override
  List<Object?> get props => [
    id,
    ownerId,
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
    verificationStatus,
    rejectionReason,
  ];
}
