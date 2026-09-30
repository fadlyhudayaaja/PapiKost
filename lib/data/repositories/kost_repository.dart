import '../../core/network/dio_client.dart';
import '../models/kost_model.dart';

/// Repository layer: memisahkan logika API dari Provider/BLoC
class KostRepository {
  KostRepository._();
  static final KostRepository instance = KostRepository._();

  /// Ambil semua kost dengan optional filter query
  Future<List<KostModel>> fetchAll({
    String? search,
    String? type,
    double? maxPrice,
    int page = 0,
    int size = 10,
  }) async {
    final params = <String, dynamic>{'page': page, 'size': size};
    if (search != null && search.isNotEmpty) params['q'] = search;
    if (type != null && type != 'ALL') params['type'] = type;
    if (maxPrice != null) params['maxPrice'] = maxPrice;

    final resp = await DioClient.instance.get('/kost', queryParameters: params);
    final data = resp.data as List;
    return data
        .map((e) => KostModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Ambil detail 1 kost by id
  Future<KostModel> fetchById(int id) async {
    final resp = await DioClient.instance.get('/kost/$id');
    return KostModel.fromJson(resp.data as Map<String, dynamic>);
  }

  /// Buat reservasi baru
  Future<void> createReservation({
    required int kostId,
    required bool isSplitBill,
    int? splitMemberCount,
    required DateTime checkInDate,
    String? notes,
  }) async {
    await DioClient.instance.post(
      '/reservations',
      data: {
        'kostId': kostId,
        'isSplitBill': isSplitBill,
        'splitMemberCount': splitMemberCount,
        'checkInDate': checkInDate.toIso8601String(),
        'notes': notes,
      },
    );
  }
}
