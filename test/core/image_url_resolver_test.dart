import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:papikost_mobile/core/network/image_url_resolver.dart';
import '../support/images/image_redirect_fixtures.dart';

void main() {
  test(
    'user share.google link follows both redirects and extracts the original image',
    () async {
      final adapter = googleRoomAdapter();
      expect(await adapter.createResolver().resolve(googleRoomShare), [
        googleRoomImage,
      ]);
      expect(adapter.requests, [googleRoomShare, googleShareRedirect]);
    },
  );

  test(
    'Google Images URLs resolve without HTTP and preserve signed image queries',
    () async {
      final adapter = ImageRedirectAdapter(
        (_) => throw StateError('Unexpected HTTP request'),
      );
      final resolver = adapter.createResolver();
      expect(await resolver.resolve(googleImageViewer), [googleRoomImage]);
      expect(await resolver.resolve(googleRoomImage), [googleRoomImage]);
      expect(adapter.requests, isEmpty);
    },
  );

  test('HTML meta redirects decode entities and relative URLs', () async {
    final adapter = ImageRedirectAdapter(
      (options) => options.uri.toString() == googleRoomShare
          ? redirectTo(googleShareRedirect)
          : ResponseBody.fromString(
              '<meta HTTP-EQUIV="refresh" content="0;url=/imgres?imgurl=https%3A%2F%2Fexample.com%2Froom.jpg%3Ftoken%3Dabc%26size%3Dlarge&amp;source=test">',
              200,
              headers: {
                'content-type': ['text/html'],
              },
            ),
    );
    expect(await adapter.createResolver().resolve(googleRoomShare), [
      'https://example.com/room.jpg?token=abc&size=large',
    ]);
    expect(adapter.requests, [googleRoomShare, googleShareRedirect]);
  });

  test(
    'successful resolutions are cached and invalidation refollows the link',
    () async {
      final adapter = googleRoomAdapter();
      final resolver = adapter.createResolver();
      await resolver.resolve(googleRoomShare);
      await resolver.resolve(googleRoomShare);
      expect(adapter.requests.length, 2);
      resolver.invalidate(googleRoomShare);
      await resolver.resolve(googleRoomShare);
      expect(adapter.requests.length, 4);
    },
  );

  test(
    'redirect loops fail clearly instead of hanging or decoding HTML',
    () async {
      final adapter = ImageRedirectAdapter((_) => redirectTo(googleRoomShare));
      await expectLater(
        adapter.createResolver().resolve(googleRoomShare),
        throwsA(isA<ImageLinkFailure>()),
      );
      expect(adapter.requests.length, 1);
    },
  );

  test(
    'non-image Google shares fail and can be retried after a transient error',
    () async {
      var unavailable = true;
      final adapter = ImageRedirectAdapter(
        (_) => unavailable
            ? ResponseBody.fromString('Unavailable', 503)
            : redirectTo(googleImageViewer),
      );
      final resolver = adapter.createResolver();
      await expectLater(
        resolver.resolve(googleRoomShare),
        throwsA(isA<ImageLinkFailure>()),
      );
      unavailable = false;
      expect(await resolver.resolve(googleRoomShare), [googleRoomImage]);
    },
  );

  test(
    'HTML without an image target gives instructions instead of a Google logo',
    () async {
      final adapter = ImageRedirectAdapter(
        (_) => ResponseBody.fromString(
          '<meta property="og:image" content="https://example.com/google-logo.png">',
          200,
        ),
      );
      await expectLater(
        adapter.createResolver().resolve(googleRoomShare),
        throwsA(isA<ImageLinkFailure>()),
      );
    },
  );

  test(
    'insecure or credential-bearing redirect targets are not requested',
    () async {
      for (final target in [
        'http://example.com/room.jpg',
        'https://user:pass@example.com/room.jpg',
      ]) {
        final adapter = ImageRedirectAdapter((_) => redirectTo(target));
        await expectLater(
          adapter.createResolver().resolve(googleRoomShare),
          throwsA(isA<ImageLinkFailure>()),
        );
        expect(adapter.requests, [googleRoomShare]);
      }
    },
  );
}
