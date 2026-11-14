import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Gunakan font uji Flutter untuk tes alur, tanpa mengunduh Google Fonts.
void configureTestFonts() {
  final flutterRoot = Platform.environment['FLUTTER_ROOT']!;
  final testAssets = Platform.environment['UNIT_TEST_ASSETS']!;
  final font = File(
    '$flutterRoot/packages/flutter_tools/static/Ahem.ttf',
  ).readAsBytesSync().buffer.asByteData();
  const codec = StandardMessageCodec();
  final manifestFile = File('$testAssets/AssetManifest.bin');
  final manifest = manifestFile.existsSync()
      ? Map<Object?, Object?>.from(
          codec.decodeMessage(
                manifestFile.readAsBytesSync().buffer.asByteData(),
              )
              as Map,
        )
      : <Object?, Object?>{};
  for (final variant in [
    'Thin',
    'ExtraLight',
    'Light',
    'Regular',
    'Medium',
    'SemiBold',
    'Bold',
    'ExtraBold',
    'Black',
    'ThinItalic',
    'ExtraLightItalic',
    'LightItalic',
    'Italic',
    'MediumItalic',
    'SemiBoldItalic',
    'BoldItalic',
    'ExtraBoldItalic',
    'BlackItalic',
  ]) {
    final path = 'test-fonts/Poppins-$variant.ttf';
    manifest[path] = [
      <String, Object>{'asset': path},
    ];
  }
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMessageHandler('flutter/assets', (ByteData? message) async {
        final key = utf8.decode(message!.buffer.asUint8List());
        if (key == 'AssetManifest.bin') return codec.encodeMessage(manifest);
        if (key.startsWith('test-fonts/')) return font;
        final file = File('$testAssets/$key');
        return file.existsSync()
            ? file.readAsBytesSync().buffer.asByteData()
            : null;
      });
}
