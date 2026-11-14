/// External image links stored in Firestore, without uploading image bytes.
class ImageUrl {
  /// Keep the original share URL in Firestore, including its resource key.
  static String normalizeInput(String value) {
    final url = value.trim();
    if (url.startsWith('drive.google.com/') ||
        url.startsWith('www.drive.google.com/') ||
        url.startsWith('share.google/') ||
        url.startsWith('www.google.com/') ||
        url.startsWith('google.com/')) {
      return 'https://$url';
    }
    return url;
  }

  static bool _isDrive(Uri uri) =>
      uri.host == 'drive.google.com' || uri.host == 'www.drive.google.com';

  static bool isGoogleShare(String value) =>
      Uri.tryParse(normalizeInput(value))?.host == 'share.google';

  static bool isGooglePage(String value) => const {
    'google.com',
    'www.google.com',
    'images.google.com',
    'google.co.id',
    'www.google.co.id',
  }.contains(Uri.tryParse(normalizeInput(value))?.host);

  /// Google Images viewer URLs contain the original image in imgurl/mediaurl.
  /// queryParameters decodes this once, preserving the image's own query string.
  static String? googleImageTarget(String value) {
    if (!isGooglePage(value)) return null;
    final uri = Uri.tryParse(normalizeInput(value));
    final image =
        uri?.queryParameters['imgurl'] ?? uri?.queryParameters['mediaurl'];
    return image != null && isValid(image) ? normalizeInput(image) : null;
  }

  static String? _driveId(Uri uri) {
    final parts = uri.pathSegments;
    String? id;
    if (parts.isNotEmpty && parts.first == 'file') {
      final index = parts.indexOf('d');
      if (index >= 0 && index + 1 < parts.length) id = parts[index + 1];
    } else if (['/open', '/uc', '/thumbnail'].contains(uri.path)) {
      id = uri.queryParameters['id'];
    }
    return id != null && RegExp(r'^[A-Za-z0-9_-]+$').hasMatch(id) ? id : null;
  }

  static bool isValid(String value) {
    value = normalizeInput(value);
    if (value.isEmpty || value.length > 2048 || RegExp(r'\s').hasMatch(value)) {
      return false;
    }
    final uri = Uri.tryParse(value);
    return uri != null &&
        uri.scheme == 'https' &&
        uri.host.isNotEmpty &&
        uri.userInfo.isEmpty &&
        (!_isDrive(uri) || _driveId(uri) != null);
  }

  /// Drive /view links return HTML. Request image bytes instead, with a
  /// download fallback when Drive cannot generate a thumbnail.
  static List<String> candidates(String value) {
    var url = normalizeInput(value);
    if (!isValid(url)) return const [];
    for (var i = 0; i < 3; i++) {
      final image = googleImageTarget(url);
      if (image == null) break;
      url = image;
    }
    // A Google viewer/share page must first be resolved, never decoded as pixels.
    if (isGoogleShare(url) || isGooglePage(url)) return const [];
    final uri = Uri.parse(url);
    if (!_isDrive(uri)) return [url];
    final id = _driveId(uri)!;
    final resourceKey = uri.queryParameters['resourcekey'];
    final access = {
      'id': id,
      if (resourceKey != null && resourceKey.isNotEmpty)
        'resourcekey': resourceKey,
    };
    return [
      Uri.https('drive.google.com', '/thumbnail', {
        ...access,
        'sz': 'w1600',
      }).toString(),
      Uri.https('drive.google.com', '/uc', {
        ...access,
        'export': 'download',
      }).toString(),
    ];
  }

  static bool isDrive(String value) {
    final uri = Uri.tryParse(normalizeInput(value));
    return uri != null && _isDrive(uri);
  }

  static String? validate(String? value, {bool required = true}) {
    final url = normalizeInput(value ?? '');
    if (url.isEmpty) return required ? 'URL foto wajib diisi.' : null;
    if (isDrive(url) && _driveId(Uri.parse(url)) == null) {
      return 'Gunakan link satu file gambar Google Drive, bukan link folder.';
    }
    return isValid(url)
        ? null
        : 'Masukkan URL foto HTTPS yang valid (maksimal 2048 karakter).';
  }
}
