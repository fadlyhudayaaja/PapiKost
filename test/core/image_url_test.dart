import 'package:flutter_test/flutter_test.dart';
import 'package:papikost_mobile/core/utils/image_url.dart';

void main() {
  test(
    'Drive file share links resolve to image endpoints with resource keys',
    () {
      const share =
          'https://drive.google.com/file/d/room_123456/view?usp=drive_link&resourcekey=key_123';
      final urls = ImageUrl.candidates(share).map(Uri.parse).toList();
      expect(urls.map((uri) => uri.path), ['/thumbnail', '/uc']);
      for (final uri in urls) {
        expect(uri.queryParameters['id'], 'room_123456');
        expect(uri.queryParameters['resourcekey'], 'key_123');
        expect(uri.queryParameters.containsKey('usp'), isFalse);
      }
      expect(ImageUrl.normalizeInput('  $share  '), share);
    },
  );
  test(
    'Drive open and download links work, including pasted links without a scheme',
    () {
      for (final link in [
        'drive.google.com/file/d/room_123456/view?usp=drive_link',
        'https://drive.google.com/open?id=room_123456',
        'https://drive.google.com/uc?export=view&id=room_123456',
        'https://drive.google.com/file/u/0/d/room_123456/view',
      ]) {
        expect(ImageUrl.validate(link), isNull);
        expect(
          Uri.parse(ImageUrl.candidates(link).first).queryParameters['id'],
          'room_123456',
        );
      }
    },
  );
  test('Drive folders and incomplete links give a useful validation error', () {
    for (final link in [
      'https://drive.google.com/drive/folders/room_123456',
      'https://drive.google.com/file/d/',
      'https://drive.google.com/open',
    ]) {
      expect(ImageUrl.candidates(link), isEmpty);
      expect(ImageUrl.validate(link), contains('link satu file gambar'));
    }
  });
  test(
    'ordinary signed image URLs and lookalike hosts are never rewritten',
    () {
      for (final url in [
        'https://example.com/photo.png?token=abc&expires=123',
        'https://drive.google.com.example.com/file/d/room_123456/view',
      ]) {
        expect(ImageUrl.candidates(url), [url]);
      }
    },
  );
  test('external HTTPS links support query tokens and escaped filenames', () {
    expect(
      ImageUrl.isValid(
        'https://example.com/foto%20kost.jpg?token=abc&alt=media',
      ),
      isTrue,
    );
    expect(ImageUrl.validate('  https://example.com/foto.jpg  '), isNull);
    expect(ImageUrl.validate('', required: false), isNull);
  });
  test(
    'required, local, insecure, credential-bearing and oversized URLs are rejected',
    () {
      for (final value in [
        '',
        '/local/foto.jpg',
        'file:///foto.jpg',
        'gs://bucket/foto.jpg',
        'http://example.com/foto.jpg',
        'https://user:pass@example.com/foto.jpg',
        'https://',
        'https://example.com/a b.jpg',
        'https://example.com/${'a' * 2048}',
      ]) {
        expect(ImageUrl.isValid(value), isFalse, reason: value);
        expect(ImageUrl.validate(value), isNotNull);
      }
    },
  );
}
