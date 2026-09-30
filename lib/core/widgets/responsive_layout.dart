import 'package:flutter/material.dart';

/// Breakpoints sesuai spesifikasi UTS:
/// mobile  < 768px
/// tablet  768 – 1279px
/// desktop ≥ 1280px
class Breakpoints {
  static const double tablet = 768;
  static const double desktop = 1280;
}

/// Widget yang secara otomatis memilih layout berdasarkan lebar layar.
/// Dipakai di halaman Katalog, Detail, dan Form agar aman di semua ukuran.
class ResponsiveLayout extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;

  const ResponsiveLayout({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= Breakpoints.desktop && desktop != null) {
          return desktop!;
        }
        if (constraints.maxWidth >= Breakpoints.tablet && tablet != null) {
          return tablet!;
        }
        return mobile;
      },
    );
  }
}

/// Helper extension untuk mendapatkan tipe layout saat ini
extension ResponsiveContext on BuildContext {
  double get screenWidth => MediaQuery.of(this).size.width;
  bool get isMobile => screenWidth < Breakpoints.tablet;
  bool get isTablet =>
      screenWidth >= Breakpoints.tablet && screenWidth < Breakpoints.desktop;
  bool get isDesktop => screenWidth >= Breakpoints.desktop;

  /// Horizontal padding yang responsive
  double get horizontalPadding {
    if (isDesktop) return screenWidth * 0.15;
    if (isTablet) return 48.0;
    return 20.0;
  }

  /// Lebar konten maksimum
  double get contentMaxWidth {
    if (isDesktop) return 900;
    if (isTablet) return 600;
    return double.infinity;
  }

  /// Jumlah kolom untuk grid
  int get gridColumns {
    if (isDesktop) return 4;
    if (isTablet) return 2;
    return 1;
  }
}

/// Container yang membatasi lebar konten di layar besar
/// Mencegah konten terlalu lebar di tablet/desktop
class ContentConstrainedBox extends StatelessWidget {
  final Widget child;
  final double? maxWidth;

  const ContentConstrainedBox({super.key, required this.child, this.maxWidth});

  @override
  Widget build(BuildContext context) {
    final mw = maxWidth ?? context.contentMaxWidth;
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: mw),
        child: child,
      ),
    );
  }
}
