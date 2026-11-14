import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../utils/image_url.dart';
import '../network/image_url_resolver.dart';

/// Resolves external image links consistently in previews and saved listings.
class UrlImage extends StatefulWidget {
  const UrlImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
    this.resolver,
  });

  final String imageUrl;
  final double? width, height;
  final BoxFit fit;
  final Widget Function(BuildContext, String)? placeholder;
  final Widget Function(BuildContext, String, Object)? errorWidget;
  final ImageUrlResolver? resolver;

  @override
  State<UrlImage> createState() => _UrlImageState();
}

class _UrlImageState extends State<UrlImage> {
  int _retry = 0;
  int _revision = 0;
  late Future<List<String>> _resolution;
  List<String> _lastCandidates = const [];

  @override
  void initState() {
    super.initState();
    _startResolution();
  }

  @override
  void didUpdateWidget(UrlImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl ||
        oldWidget.resolver != widget.resolver) {
      _startResolution();
    }
  }

  void _startResolution() {
    _lastCandidates = const [];
    _resolution = _resolve(
      widget.imageUrl,
      ++_revision,
      widget.resolver ?? ImageUrlResolver.instance,
    );
  }

  Future<List<String>> _resolve(
    String url,
    int revision,
    ImageUrlResolver resolver,
  ) async {
    // Avoid a redirect request for every character while pasting/editing a link.
    if (ImageUrl.isGoogleShare(url)) {
      await Future<void>.delayed(const Duration(milliseconds: 350));
      if (!mounted || revision != _revision) return const [];
    }
    return resolver.resolve(url);
  }

  Future<void> _reload() async {
    final original = widget.imageUrl;
    (widget.resolver ?? ImageUrlResolver.instance).invalidate(original);
    for (final url in _lastCandidates) {
      try {
        await CachedNetworkImage.evictFromCache(url);
      } on Object {
        // A cache cleanup failure must not prevent another image request.
      }
    }
    if (mounted && widget.imageUrl == original) {
      setState(() {
        _retry++;
        _startResolution();
      });
    }
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<List<String>>(
    future: _resolution,
    builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) {
        return SizedBox(
          width: widget.width,
          height: widget.height,
          child:
              widget.placeholder?.call(context, widget.imageUrl) ??
              const Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
        );
      }
      final urls = snapshot.data ?? const <String>[];
      _lastCandidates = urls;
      Widget failure(BuildContext context, String url, Object error) {
        if (widget.errorWidget != null) {
          return widget.errorWidget!(context, url, error);
        }
        final message = error is ImageLinkFailure
            ? error.message
            : urls.isEmpty
            ? 'URL gambar tidak valid. Tempel link HTTPS lengkap.'
            : ImageUrl.isDrive(widget.imageUrl)
            ? 'Gambar Google Drive belum bisa dibuka. Periksa izin akses file, koneksi, dan pastikan berkas berupa gambar.'
            : 'Gagal memuat gambar. Periksa koneksi dan pastikan link langsung membuka gambar.';
        return LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxHeight < 130 || constraints.maxWidth < 150) {
              return Center(
                child: IconButton(
                  tooltip: message,
                  onPressed: ImageUrl.isValid(widget.imageUrl) ? _reload : null,
                  icon: const Icon(Icons.broken_image_outlined),
                ),
              );
            }
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(message, textAlign: TextAlign.center),
                    if (ImageUrl.isValid(widget.imageUrl))
                      TextButton(
                        onPressed: _reload,
                        child: const Text('Muat Ulang'),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      }

      Widget attempt(int index) => CachedNetworkImage(
        key: ValueKey('${widget.imageUrl}:$_retry:$index'),
        imageUrl: urls[index],
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        placeholder:
            widget.placeholder ??
            (_, _) => const Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
        errorWidget: (context, url, error) => index + 1 < urls.length
            ? attempt(index + 1)
            : failure(context, url, error),
      );

      return SizedBox(
        width: widget.width,
        height: widget.height,
        child: urls.isEmpty
            ? failure(
                context,
                widget.imageUrl,
                snapshot.error ?? StateError('Invalid image URL'),
              )
            : attempt(0),
      );
    },
  );
}
