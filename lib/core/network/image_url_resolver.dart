import 'package:dio/dio.dart';
import 'package:html/parser.dart' as html;

import '../utils/image_url.dart';

class ImageLinkFailure implements Exception {
  const ImageLinkFailure(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Resolves Google share redirects before the image loader requests any pixels.
/// Original links can remain in Firestore; only successful resolutions are cached.
class ImageUrlResolver {
  ImageUrlResolver({Dio? client})
    : _client =
          client ??
          Dio(
            BaseOptions(
              connectTimeout: const Duration(seconds: 8),
              receiveTimeout: const Duration(seconds: 8),
            ),
          );

  static final instance = ImageUrlResolver();
  final Dio _client;
  final _cache = <String, ({List<String> urls, DateTime expires})>{};

  void invalidate(String value) =>
      _cache.remove(ImageUrl.normalizeInput(value));

  Future<List<String>> resolve(String value) async {
    final original = ImageUrl.normalizeInput(value);
    if (!ImageUrl.isValid(original)) return const [];
    final direct = ImageUrl.candidates(original);
    if (direct.isNotEmpty) return direct;
    final cached = _cache[original];
    if (cached != null && cached.expires.isAfter(DateTime.now())) {
      return cached.urls;
    }

    var current = original;
    final visited = <String>{};
    try {
      for (var hop = 0; hop < 6; hop++) {
        if (!ImageUrl.isValid(current) || !visited.add(current)) break;
        final candidates = ImageUrl.candidates(current);
        if (candidates.isNotEmpty) {
          if (_cache.length >= 100) _cache.remove(_cache.keys.first);
          _cache[original] = (
            urls: candidates,
            expires: DateTime.now().add(const Duration(minutes: 5)),
          );
          return candidates;
        }
        if (!ImageUrl.isGoogleShare(current) &&
            !ImageUrl.isGooglePage(current)) {
          break;
        }
        final response = await _client.get<String>(
          current,
          options: Options(
            responseType: ResponseType.plain,
            followRedirects: false,
            validateStatus: (status) =>
                status != null && status >= 200 && status < 400,
            headers: {'Accept': 'text/html', 'User-Agent': 'Mozilla/5.0'},
          ),
        );
        final location = response.headers.value('location');
        if (response.statusCode! >= 300 && location != null) {
          current = Uri.parse(current).resolve(location).toString();
          continue;
        }
        final document = html.parse(response.data ?? '');
        String? next;
        for (final meta in document.querySelectorAll('meta')) {
          if (meta.attributes['http-equiv']?.toLowerCase() != 'refresh') {
            continue;
          }
          final content = meta.attributes['content'] ?? '';
          final match = RegExp(
            r'^\s*[0-9.]+\s*;\s*url\s*=\s*(.+)$',
            caseSensitive: false,
          ).firstMatch(content);
          if (match != null) {
            next = match[1]!.trim();
            if (next.length > 1 &&
                ((next.startsWith('"') && next.endsWith('"')) ||
                    (next.startsWith("'") && next.endsWith("'")))) {
              next = next.substring(1, next.length - 1);
            }
            break;
          }
        }
        if (next == null) break;
        current = Uri.parse(current).resolve(next).toString();
      }
    } on DioException {
      throw const ImageLinkFailure(
        'Link berbagi Google belum bisa dibuka. Periksa koneksi lalu tekan Muat Ulang, atau gunakan alamat gambar langsung.',
      );
    }
    throw const ImageLinkFailure(
      'Link Google ini belum memberikan gambar. Buka gambar di situs asal, lalu pilih Salin alamat gambar.',
    );
  }
}
