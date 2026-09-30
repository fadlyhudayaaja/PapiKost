import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

// ═══════════════════════════════════════════════════════════════════════════
// SPLASH PAGE — PapiKost Mobile
//
// Arsitektur:
//   • _SplashPageState   → logika animasi & inisialisasi (orchestrator)
//   • _AnimatedLogo      → widget animasi logo (Fase 1)
//   • _AnimatedTitle     → widget animasi judul + tagline (Fase 2 & 3)
//   • _FloatingParticles → dekorasi partikel bintang mengambang
//   • _BottomBrand       → branding versi di bagian bawah
// ═══════════════════════════════════════════════════════════════════════════

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  // ── Animation Controllers ──────────────────────────────────────────────────
  late final AnimationController _masterCtrl;

  // Fase 1: Logo scale (0.0 → 0.4 durasi total)
  late final Animation<double> _logoScale;
  late final Animation<double> _logoFade;
  late final Animation<double> _logoGlow;

  // Fase 2: Judul slide + fade (0.35 → 0.65)
  late final Animation<Offset> _titleSlide;
  late final Animation<double> _titleFade;

  // Fase 3: Tagline fade (0.55 → 0.80)
  late final Animation<double> _taglineFade;

  // Fase 4: Bottom brand fade (0.70 → 0.90)
  late final Animation<double> _bottomFade;

  // Partikel bintang (0.20 → 1.00)
  late final Animation<double> _particleFade;

  // ── State ──────────────────────────────────────────────────────────────────
  // ignore: unused_field
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _masterCtrl.forward();
    _runInitialization();
  }

  // ── 1. Setup semua animasi ─────────────────────────────────────────────────
  void _setupAnimations() {
    // Total durasi animasi: 2400ms
    _masterCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );

    // Fase 1 — Logo muncul dengan efek elastis (0% → 40%)
    _logoScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _masterCtrl,
        curve: const Interval(0.0, 0.45, curve: Curves.elasticOut),
      ),
    );

    _logoFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _masterCtrl,
        curve: const Interval(0.0, 0.25, curve: Curves.easeIn),
      ),
    );

    // Glow pulse pada logo (terus berulang setelah muncul)
    _logoGlow = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(
        parent: _masterCtrl,
        curve: const Interval(0.45, 1.0, curve: Curves.easeInOut),
      ),
    );

    // Fase 2 — Judul slide up + fade (35% → 65%)
    _titleSlide = Tween<Offset>(begin: const Offset(0, 0.6), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _masterCtrl,
            curve: const Interval(0.35, 0.65, curve: Curves.easeOutCubic),
          ),
        );

    _titleFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _masterCtrl,
        curve: const Interval(0.35, 0.62, curve: Curves.easeIn),
      ),
    );

    // Fase 3 — Tagline fade in (55% → 80%)
    _taglineFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _masterCtrl,
        curve: const Interval(0.55, 0.80, curve: Curves.easeIn),
      ),
    );

    // Fase 4 — Bottom brand (70% → 90%)
    _bottomFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _masterCtrl,
        curve: const Interval(0.70, 0.90, curve: Curves.easeIn),
      ),
    );

    // Partikel bintang (20% → 100%)
    _particleFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _masterCtrl,
        curve: const Interval(0.20, 0.55, curve: Curves.easeIn),
      ),
    );
  }

  // ── 2. Logika inisialisasi & routing ──────────────────────────────────────
  Future<void> _runInitialization() async {
    // Jalankan pengecekan sesi dan timer animasi secara paralel
    final results = await Future.wait([
      _checkUserSession(),
      // Minimal splash time 3 detik agar animasi tampil penuh
      Future.delayed(const Duration(milliseconds: 3000)),
    ]);

    _isInitialized = true;
    if (!mounted) return;

    final hasSession = results[0] as bool;
    _navigateNext(hasSession);
  }

  /// Simulasi pengecekan token JWT di Flutter Secure Storage.
  /// Ganti isi fungsi ini dengan logika AuthProvider.checkAuthStatus()
  /// saat backend sudah siap.
  Future<bool> _checkUserSession() async {
    // Simulasi delay pengecekan token (2 detik)
    await Future.delayed(const Duration(milliseconds: 2000));

    const storage = FlutterSecureStorage();
    final token = await storage.read(key: AppConstants.tokenKey);
    final role = await storage.read(key: AppConstants.userRoleKey);

    return token != null && role != null;
  }

  /// Navigasi ke halaman berikutnya dengan transisi halus.
  void _navigateNext(bool hasSession) {
    if (!mounted) return;

    if (hasSession) {
      // Ada sesi → cek role dan arahkan ke dashboard yang sesuai
      const storage = FlutterSecureStorage();
      storage.read(key: AppConstants.userRoleKey).then((role) {
        if (!mounted) return;
        switch (role) {
          case AppConstants.roleOwner:
            context.go(AppRoutes.ownerDashboard);
            break;
          case AppConstants.roleAdmin:
            context.go(AppRoutes.adminDashboard);
            break;
          default:
            context.go(AppRoutes.renterHome);
        }
      });
    } else {
      // Tidak ada sesi → ke halaman Login
      context.go(AppRoutes.login);
    }
  }

  @override
  void dispose() {
    _masterCtrl.dispose();
    super.dispose();
  }

  // ── 3. Build ───────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        // Background gradient Navy → Teal
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            stops: [0.0, 0.45, 0.75, 1.0],
            colors: [
              Color(0xFF0D1B3E), // Deep Navy
              Color(0xFF1A3C6E), // Primary Navy
              Color(0xFF0D4A6B), // Navy-Teal transition
              Color(0xFF0A7A8C), // Cyan/Teal
            ],
          ),
        ),
        child: Stack(
          children: [
            // ── Layer 1: Partikel bintang mengambang (dekorasi) ──
            AnimatedBuilder(
              animation: _particleFade,
              builder: (_, __) => Opacity(
                opacity: _particleFade.value,
                child: _FloatingParticles(screenSize: size),
              ),
            ),

            // ── Layer 2: Lingkaran dekorasi semi-transparan ──
            _buildDecorativeCircles(size),

            // ── Layer 3: Konten utama ──
            SafeArea(
              child: Column(
                children: [
                  const Spacer(flex: 3),

                  // Logo animasi
                  AnimatedBuilder(
                    animation: _masterCtrl,
                    builder: (_, child) => _AnimatedLogo(
                      scaleAnim: _logoScale,
                      fadeAnim: _logoFade,
                      glowAnim: _logoGlow,
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Judul + Tagline
                  AnimatedBuilder(
                    animation: _masterCtrl,
                    builder: (_, __) => _AnimatedTitle(
                      titleSlide: _titleSlide,
                      titleFade: _titleFade,
                      taglineFade: _taglineFade,
                    ),
                  ),

                  const Spacer(flex: 3),

                  // Bottom branding + loading
                  AnimatedBuilder(
                    animation: _bottomFade,
                    builder: (_, __) => Opacity(
                      opacity: _bottomFade.value,
                      child: const _BottomBrand(),
                    ),
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Dekorasi lingkaran latar
  Widget _buildDecorativeCircles(Size size) {
    return Stack(
      children: [
        // Lingkaran besar kanan atas
        Positioned(
          top: -size.width * 0.3,
          right: -size.width * 0.2,
          child: Container(
            width: size.width * 0.8,
            height: size.width * 0.8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.white.withValues(alpha: 0.04),
            ),
          ),
        ),
        // Lingkaran sedang kiri bawah
        Positioned(
          bottom: -size.width * 0.2,
          left: -size.width * 0.15,
          child: Container(
            width: size.width * 0.6,
            height: size.width * 0.6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.secondary.withValues(alpha: 0.06),
            ),
          ),
        ),
        // Lingkaran kecil tengah kanan
        Positioned(
          top: size.height * 0.35,
          right: size.width * 0.05,
          child: Container(
            width: size.width * 0.25,
            height: size.width * 0.25,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.white.withValues(alpha: 0.03),
            ),
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// WIDGET: Animated Logo (Fase 1)
// ═══════════════════════════════════════════════════════════════════════════
class _AnimatedLogo extends StatelessWidget {
  final Animation<double> scaleAnim;
  final Animation<double> fadeAnim;
  final Animation<double> glowAnim;

  const _AnimatedLogo({
    required this.scaleAnim,
    required this.fadeAnim,
    required this.glowAnim,
  });

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: fadeAnim,
      child: ScaleTransition(
        scale: scaleAnim,
        child: SizedBox(
          width: 130,
          height: 130,
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              // ── Glow ring luar ──
              AnimatedBuilder(
                animation: glowAnim,
                builder: (_, __) => Container(
                  width: 130,
                  height: 130,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.secondary.withValues(
                          alpha: 0.25 * glowAnim.value,
                        ),
                        blurRadius: 40,
                        spreadRadius: 10,
                      ),
                      BoxShadow(
                        color: AppColors.white.withValues(
                          alpha: 0.08 * glowAnim.value,
                        ),
                        blurRadius: 20,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                ),
              ),

              // ── Container logo utama ──
              Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF2A5BA8),
                      Color(0xFF1A3C6E),
                      Color(0xFF0D4A6B),
                    ],
                  ),
                  border: Border.all(
                    color: AppColors.white.withValues(alpha: 0.15),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const _LogoContent(),
              ),

              // ── Badge AI (PapiBot sparkle) — pojok kanan atas ──
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF00E5FF), Color(0xFF00BCD4)],
                    ),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF0D1B3E),
                      width: 2.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.secondary.withValues(alpha: 0.5),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.auto_awesome_rounded, // Sparkle/AI icon
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Konten dalam logo (ikon rumah) ──
// TODO: Ganti Icon widget di bawah dengan Image.asset('assets/images/logo.png')
//       atau SvgPicture.asset('assets/icons/logo.svg') saat aset sudah tersedia.
class _LogoContent extends StatelessWidget {
  const _LogoContent();

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Ikon rumah utama
        // TODO: Ganti dengan: Image.asset('assets/images/logo_papikost.png', width: 60)
        const Icon(Icons.home_rounded, size: 58, color: Colors.white),
        // Shimmer highlight di atas ikon
        Positioned(
          top: 18,
          left: 22,
          child: Container(
            width: 18,
            height: 8,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// WIDGET: Animated Title & Tagline (Fase 2 & 3)
// ═══════════════════════════════════════════════════════════════════════════
class _AnimatedTitle extends StatelessWidget {
  final Animation<Offset> titleSlide;
  final Animation<double> titleFade;
  final Animation<double> taglineFade;

  const _AnimatedTitle({
    required this.titleSlide,
    required this.titleFade,
    required this.taglineFade,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── App Name ──
        SlideTransition(
          position: titleSlide,
          child: FadeTransition(
            opacity: titleFade,
            child: ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [Colors.white, Color(0xFFB2EBF2)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ).createShader(bounds),
              child: Text(
                AppConstants.appName,
                style: AppTextStyles.displayLarge.copyWith(
                  color: Colors.white, // ShaderMask override ini
                  fontSize: 42,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2,
                  shadows: [
                    Shadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        const SizedBox(height: 10),

        // ── Divider dekoratif ──
        FadeTransition(
          opacity: titleFade,
          child: SlideTransition(
            position: titleSlide,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _GradientLine(width: 40, alignment: Alignment.centerRight),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: AppColors.secondary,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.secondary.withValues(alpha: 0.6),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
                _GradientLine(width: 40, alignment: Alignment.centerLeft),
              ],
            ),
          ),
        ),

        const SizedBox(height: 12),

        // ── Tagline ──
        FadeTransition(
          opacity: taglineFade,
          child: Text(
            'Smart Living, Easy Sharing',
            style: AppTextStyles.bodyMedium.copyWith(
              color: Colors.white.withValues(alpha: 0.75),
              fontSize: 14,
              letterSpacing: 0.8,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ],
    );
  }
}

// Garis gradient dekoratif
class _GradientLine extends StatelessWidget {
  final double width;
  final AlignmentGeometry alignment;

  const _GradientLine({required this.width, required this.alignment});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: 1,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: alignment,
          end: alignment == Alignment.centerRight
              ? Alignment.centerLeft
              : Alignment.centerRight,
          colors: [
            Colors.transparent,
            AppColors.secondary.withValues(alpha: 0.6),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// WIDGET: Floating Particles (bintang mengambang)
// ═══════════════════════════════════════════════════════════════════════════
class _FloatingParticles extends StatefulWidget {
  final Size screenSize;

  const _FloatingParticles({required this.screenSize});

  @override
  State<_FloatingParticles> createState() => _FloatingParticlesState();
}

class _FloatingParticlesState extends State<_FloatingParticles>
    with SingleTickerProviderStateMixin {
  late final AnimationController _floatCtrl;
  late final List<_Particle> _particles;
  final math.Random _random = math.Random(42); // seed tetap agar konsisten

  @override
  void initState() {
    super.initState();
    _floatCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    // Buat 12 partikel dengan posisi random
    _particles = List.generate(12, (i) {
      return _Particle(
        x: _random.nextDouble(),
        y: _random.nextDouble(),
        size: 2.0 + _random.nextDouble() * 3.0,
        opacity: 0.3 + _random.nextDouble() * 0.5,
        floatOffset: _random.nextDouble() * math.pi * 2,
        speed: 0.5 + _random.nextDouble() * 0.8,
      );
    });
  }

  @override
  void dispose() {
    _floatCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _floatCtrl,
      builder: (_, __) {
        return CustomPaint(
          size: widget.screenSize,
          painter: _ParticlePainter(
            particles: _particles,
            progress: _floatCtrl.value,
            screenSize: widget.screenSize,
          ),
        );
      },
    );
  }
}

class _Particle {
  final double x, y, size, opacity, floatOffset, speed;

  const _Particle({
    required this.x,
    required this.y,
    required this.size,
    required this.opacity,
    required this.floatOffset,
    required this.speed,
  });
}

class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  final double progress;
  final Size screenSize;

  _ParticlePainter({
    required this.particles,
    required this.progress,
    required this.screenSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      // Efek mengambang vertikal (sinusoidal)
      final floatY =
          math.sin(progress * math.pi * 2 * p.speed + p.floatOffset) * 8;

      final dx = p.x * size.width;
      final dy = p.y * size.height + floatY;

      // Alternasi antara titik dan bintang kecil
      final paint = Paint()
        ..color = Colors.white.withValues(alpha: p.opacity * 0.7)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(dx, dy), p.size / 2, paint);

      // Cross/shimmer pada partikel lebih besar
      if (p.size > 3.5) {
        final shimmerPaint = Paint()
          ..color = const Color(0xFF00E5FF).withValues(alpha: p.opacity * 0.4)
          ..strokeWidth = 0.8
          ..style = PaintingStyle.stroke;

        canvas.drawLine(
          Offset(dx - p.size, dy),
          Offset(dx + p.size, dy),
          shimmerPaint,
        );
        canvas.drawLine(
          Offset(dx, dy - p.size),
          Offset(dx, dy + p.size),
          shimmerPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter old) => old.progress != progress;
}

// ═══════════════════════════════════════════════════════════════════════════
// WIDGET: Bottom Brand (versi + loading indicator)
// ═══════════════════════════════════════════════════════════════════════════
class _BottomBrand extends StatefulWidget {
  const _BottomBrand();

  @override
  State<_BottomBrand> createState() => _BottomBrandState();
}

class _BottomBrandState extends State<_BottomBrand>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _pulseAnim = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Loading dots
        AnimatedBuilder(
          animation: _pulseAnim,
          builder: (_, __) => Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(3, (i) {
              // Delay per titik untuk efek wave
              final delay = i * 0.33;
              final value = ((_pulseAnim.value - delay) % 1.0).clamp(0.0, 1.0);
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: 6,
                height: 6 + (value * 4),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(
                    alpha: 0.4 + (value * 0.6),
                  ),
                  borderRadius: BorderRadius.circular(3),
                ),
              );
            }),
          ),
        ),

        const SizedBox(height: 14),

        // Versi aplikasi
        Text(
          'v${AppConstants.appVersion}',
          style: AppTextStyles.caption.copyWith(
            color: Colors.white.withValues(alpha: 0.4),
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }
}
