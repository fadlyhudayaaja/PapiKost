import 'dart:async';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:papikost_mobile/core/network/image_url_resolver.dart';

const googleRoomShare = 'https://share.google/Br7ug1JpcsJ2VECzw';
const googleRoomImage =
    'https://images.rukita.co/buildings/building/5f39604b-731b-4d11-aa4f-e186239a70ec.jpg?tr=w-1440%2Cc-at_max%2Cq-65';
const googleShareRedirect =
    'https://www.google.com/share.google?q=Br7ug1JpcsJ2VECzw';
final googleImageViewer = Uri.https('www.google.com', '/imgres', {
  'imgurl': googleRoomImage,
}).toString();

class ImageRedirectAdapter implements HttpClientAdapter {
  ImageRedirectAdapter(this.respond);
  final FutureOr<ResponseBody> Function(RequestOptions) respond;
  final requests = <String>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options.uri.toString());
    return respond(options);
  }

  ImageUrlResolver createResolver() =>
      ImageUrlResolver(client: Dio()..httpClientAdapter = this);

  @override
  void close({bool force = false}) {}
}

ResponseBody redirectTo(String url, {int status = 302}) =>
    ResponseBody.fromString(
      '',
      status,
      headers: {
        'location': [url],
      },
    );

ImageRedirectAdapter googleRoomAdapter() => ImageRedirectAdapter((options) {
  if (options.uri.toString() == googleRoomShare) {
    return redirectTo(googleShareRedirect);
  }
  if (options.uri.toString() == googleShareRedirect) {
    return redirectTo(googleImageViewer, status: 301);
  }
  throw StateError('An image viewer should not be fetched as an image');
});
