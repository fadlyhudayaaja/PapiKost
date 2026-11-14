import 'package:flutter/material.dart';
import 'url_image.dart';

/// Documents and room photos use the same URL resolver, including Drive links.
class VerificationDocumentImage extends StatelessWidget {
  const VerificationDocumentImage({
    super.key,
    required this.reference,
    this.height,
    this.fit = BoxFit.contain,
  });
  final String reference;
  final double? height;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) => UrlImage(
    imageUrl: reference,
    height: height,
    width: double.infinity,
    fit: fit,
  );
}
