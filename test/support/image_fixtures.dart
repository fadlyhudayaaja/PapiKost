import 'dart:convert';
import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:file/file.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:mocktail/mocktail.dart';

Uint8List testImageBytes() => base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR4nGNgaPj/HwAEggJ/59habAAAAABJRU5ErkJggg==',
);

class _ImageFile extends Fake implements File {
  _ImageFile(this.bytes);
  final Uint8List bytes;

  @override
  Future<Uint8List> readAsBytes() async => bytes;
}

/// Exercises decoding and failures without HTTP, plugins or disk IO.
class TestImageCache extends Fake implements BaseCacheManager {
  final bytesByUrl = <String, Uint8List>{};
  final requests = <String>[];
  final removed = <String>[];

  @override
  Stream<FileResponse> getFileStream(
    String url, {
    String? key,
    Map<String, String>? headers,
    bool withProgress = false,
  }) async* {
    requests.add(url);
    final bytes = bytesByUrl[url];
    if (bytes == null) throw StateError('Image not accessible in test');
    yield FileInfo(
      _ImageFile(bytes),
      FileSource.Online,
      DateTime.now().add(const Duration(hours: 1)),
      url,
    );
  }

  @override
  Future<void> removeFile(String key) async => removed.add(key);
}

TestImageCache configureTestImages() {
  final cache = TestImageCache();
  CachedNetworkImageProvider.defaultCacheManager = cache;
  return cache;
}
