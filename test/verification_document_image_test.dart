import 'dart:convert';
import 'dart:async';
import 'dart:typed_data';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:papikost_mobile/core/utils/image_url.dart';
import 'package:papikost_mobile/core/widgets/verification_document_image.dart';
import 'package:papikost_mobile/core/widgets/url_image.dart';
import 'support/image_fixtures.dart';
import 'support/image_redirect_fixtures.dart';
import 'package:papikost_mobile/core/network/image_url_resolver.dart';

void main() {
  late TestImageCache cache;
  const driveLink =
      'https://drive.google.com/file/d/room_123456/view?usp=drive_link&resourcekey=key123';
  setUp(() {
    cache = configureTestImages();
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
  });

  Future<void> open(
    WidgetTester tester,
    String url, {
    double height = 180,
    ImageUrlResolver? resolver,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: resolver == null
              ? VerificationDocumentImage(reference: url, height: height)
              : UrlImage(imageUrl: url, height: height, resolver: resolver),
        ),
      ),
    );
    // Flush the engine image decoder as well as normal widget frames.
    for (var i = 0; i < 4; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump(const Duration(seconds: 1));
    }
    await tester.pumpAndSettle();
  }

  bool hasDecodedImage(WidgetTester tester) => tester
      .widgetList<RawImage>(find.byType(RawImage))
      .any((image) => image.image != null);

  testWidgets(
    'share.google resolves to real image bytes and displays the decoded photo',
    (tester) async {
      final adapter = googleRoomAdapter();
      cache.bytesByUrl[googleRoomImage] = testImageBytes();
      await open(tester, googleRoomShare, resolver: adapter.createResolver());
      expect(adapter.requests, [googleRoomShare, googleShareRedirect]);
      expect(cache.requests, [googleRoomImage]);
      expect(hasDecodedImage(tester), isTrue);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'a late Google redirect cannot replace a newly entered image URL',
    (tester) async {
      final pending = Completer<ResponseBody>();
      final adapter = ImageRedirectAdapter((_) => pending.future);
      final resolver = adapter.createResolver();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UrlImage(
              imageUrl: googleRoomShare,
              height: 180,
              resolver: resolver,
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 400));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump();
      expect(adapter.requests, [googleRoomShare]);

      const replacement = 'https://example.com/new-room.jpg';
      cache.bytesByUrl[replacement] = testImageBytes();
      await open(tester, replacement, resolver: resolver);
      pending.complete(redirectTo(googleImageViewer));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pumpAndSettle();
      expect(cache.requests, [replacement]);
      expect(hasDecodedImage(tester), isTrue);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Google resolution errors can be retried after the network recovers',
    (tester) async {
      var unavailable = true;
      final adapter = ImageRedirectAdapter(
        (_) => unavailable
            ? ResponseBody.fromString('Unavailable', 503)
            : redirectTo(googleImageViewer),
      );
      final resolver = adapter.createResolver();
      await open(tester, googleRoomShare, resolver: resolver);
      expect(
        find.textContaining('Link berbagi Google belum bisa dibuka.'),
        findsOneWidget,
      );
      unavailable = false;
      cache.bytesByUrl[googleRoomImage] = testImageBytes();
      await tester.tap(find.text('Muat Ulang'));
      for (var i = 0; i < 4; i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 20)),
        );
        await tester.pump(const Duration(seconds: 1));
      }
      await tester.pumpAndSettle();
      expect(cache.requests, [googleRoomImage]);
      expect(hasDecodedImage(tester), isTrue);
    },
  );

  testWidgets(
    'external HTTPS image actually decodes without Firebase providers',
    (tester) async {
      const url = 'https://example.com/ktp.jpg';
      cache.bytesByUrl[url] = testImageBytes();
      await open(tester, url);
      expect(cache.requests, [url]);
      expect(hasDecodedImage(tester), isTrue);
      expect(find.text('Muat Ulang'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Drive viewer link requests image bytes and renders the decoded thumbnail',
    (tester) async {
      final candidates = ImageUrl.candidates(driveLink);
      cache.bytesByUrl[candidates.first] = testImageBytes();
      await open(tester, driveLink);
      expect(cache.requests, [candidates.first]);
      expect(cache.requests.any((url) => url.contains('/view')), isFalse);
      expect(hasDecodedImage(tester), isTrue);
    },
  );

  testWidgets(
    'HTML instead of a thumbnail falls back to the Drive download image',
    (tester) async {
      final candidates = ImageUrl.candidates(driveLink);
      cache.bytesByUrl[candidates.first] = Uint8List.fromList(
        utf8.encode('<html>Not an image</html>'),
      );
      cache.bytesByUrl[candidates.last] = testImageBytes();
      await open(tester, driveLink);
      expect(cache.requests, candidates);
      expect(hasDecodedImage(tester), isTrue);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'unavailable Drive image shows access guidance and retries after access changes',
    (tester) async {
      final candidates = ImageUrl.candidates(driveLink);
      await open(tester, driveLink);
      expect(find.textContaining('Periksa izin akses file'), findsOneWidget);
      cache.bytesByUrl[candidates.first] = testImageBytes();
      await tester.tap(find.text('Muat Ulang'));
      for (var i = 0; i < 4; i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 20)),
        );
        await tester.pump(const Duration(seconds: 1));
      }
      await tester.pumpAndSettle();
      expect(cache.removed, candidates);
      expect(hasDecodedImage(tester), isTrue);
    },
  );

  testWidgets(
    'changing a failed URL resets fallback state for the next image',
    (tester) async {
      await open(tester, driveLink);
      const next = 'https://example.com/replacement.jpg';
      cache.bytesByUrl[next] = testImageBytes();
      await open(tester, next);
      expect(hasDecodedImage(tester), isTrue);
      expect(cache.requests.last, next);
    },
  );

  testWidgets('invalid references fail without HTTP or Storage', (
    tester,
  ) async {
    await open(tester, 'verificationDocuments/owner-a/old/ktp.jpg');
    expect(find.byType(CachedNetworkImage), findsNothing);
    expect(find.textContaining('URL gambar tidak valid.'), findsOneWidget);
    expect(cache.requests, isEmpty);
  });

  testWidgets('small thumbnails show a compact failure without overflowing', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 90,
            height: 90,
            child: UrlImage(imageUrl: 'invalid'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.broken_image_outlined), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
