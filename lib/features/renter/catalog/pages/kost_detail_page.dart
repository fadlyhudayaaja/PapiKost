import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../data/models/kost_model.dart';
import '../../../../data/repositories/mock_repository.dart';

enum _DetailState { loading, error, success }

class RenterKostDetailPage extends StatefulWidget {
  final int kostId;
  const RenterKostDetailPage({super.key, required this.kostId});

  @override
  State<RenterKostDetailPage> createState() => _RenterKostDetailPageState();
}

class _RenterKostDetailPageState extends State<RenterKostDetailPage> {
  final _repo = MockRepository.instance;
  final _pageCtrl = PageController();
  final _fmt = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  _DetailState _state = _DetailState.loading;
  KostModel? _kost;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  Future<void> _load({bool simulateError = false}) async {
    setState(() {
      _state = _DetailState.loading;
      _error = '';
    });
    try {
      final data = await _repo.getKostById(
        widget.kostId,
        simulateError: simulateError,
      );
      setState(() {
        _kost = data;
        _state = _DetailState.success;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _state = _DetailState.error;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffold,
      body: switch (_state) {
        _DetailState.loading => _buildSkeleton(),
        _DetailState.error => _buildError(),
        _DetailState.success => _buildContent(_kost!),
      },
    );
  }

  // ── Loading skeleton ───────────────────────────────────────────────────────
  Widget _buildSkeleton() {
    return Column(
      children: [
        const ShimmerBox(height: 280, borderRadius: 0),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                ShimmerBox(height: 28, width: 220),
                SizedBox(height: 10),
                ShimmerBox(height: 16, width: 300),
                SizedBox(height: 20),
                ShimmerBox(height: 90),
                SizedBox(height: 14),
                ShimmerBox(height: 60),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── Error state ────────────────────────────────────────────────────────────
  Widget _buildError() {
    return SafeArea(
      child: Column(
        children: [
          AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_rounded),
              onPressed: () => context.pop(),
            ),
            backgroundColor: AppColors.primary,
          ),
          Expanded(
            child: ErrorState(message: _error, onRetry: _load),
          ),
        ],
      ),
    );
  }

  // ── Success content ────────────────────────────────────────────────────────
  Widget _buildContent(KostModel kost) {
    return Stack(
      children: [
        CustomScrollView(
          slivers: [
            // Photo carousel
            SliverAppBar(
              expandedHeight: 280,
              pinned: true,
              backgroundColor: AppColors.primary,
              leading: IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.35),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_back_ios_rounded,
                    color: AppColors.white,
                    size: 18,
                  ),
                ),
                onPressed: () => context.pop(),
              ),
              flexibleSpace: FlexibleSpaceBar(
                background: Stack(
                  children: [
                    PageView.builder(
                      controller: _pageCtrl,
                      itemCount: kost.imageUrls.isEmpty
                          ? 1
                          : kost.imageUrls.length,
                      itemBuilder: (_, i) {
                        if (kost.imageUrls.isEmpty) {
                          return Container(
                            color: AppColors.grey200,
                            child: const Center(
                              child: Icon(
                                Icons.home_outlined,
                                size: 64,
                                color: AppColors.grey400,
                              ),
                            ),
                          );
                        }
                        return CachedNetworkImage(
                          imageUrl: kost.imageUrls[i],
                          fit: BoxFit.cover,
                          placeholder: (_, __) => const ShimmerBox(height: 280),
                          errorWidget: (_, __, ___) => Container(
                            color: AppColors.grey200,
                            child: const Icon(
                              Icons.home_outlined,
                              size: 64,
                              color: AppColors.grey400,
                            ),
                          ),
                        );
                      },
                    ),
                    if (kost.imageUrls.length > 1)
                      Positioned(
                        bottom: 14,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: SmoothPageIndicator(
                            controller: _pageCtrl,
                            count: kost.imageUrls.length,
                            effect: const WormEffect(
                              dotColor: Colors.white54,
                              activeDotColor: Colors.white,
                              dotHeight: 8,
                              dotWidth: 8,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Type + split bill badges
                    Wrap(
                      spacing: 8,
                      children: [
                        _TypeBadge(type: kost.type),
                        if (kost.isSplitBillAvailable)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.secondary,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.people_rounded,
                                  color: AppColors.white,
                                  size: 14,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Bisa Patungan',
                                  style: AppTextStyles.labelSmall.copyWith(
                                    color: AppColors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Nama
                    Text(kost.name, style: AppTextStyles.h2),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: 15,
                          color: AppColors.grey500,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            kost.address,
                            style: AppTextStyles.bodySmall,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    if (kost.rating != null)
                      Row(
                        children: [
                          ...List.generate(
                            5,
                            (i) => Icon(
                              i < kost.rating!.floor()
                                  ? Icons.star_rounded
                                  : Icons.star_outline_rounded,
                              color: const Color(0xFFFFB300),
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${kost.rating} (${kost.reviewCount} ulasan)',
                            style: AppTextStyles.labelMedium,
                          ),
                        ],
                      ),

                    const SizedBox(height: 16),

                    // Harga card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.15),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Harga Sewa',
                                  style: AppTextStyles.bodySmall,
                                ),
                                Text(
                                  _fmt.format(kost.pricePerMonth),
                                  style: AppTextStyles.priceLarge,
                                ),
                                Text('/bulan', style: AppTextStyles.caption),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('Tersedia', style: AppTextStyles.bodySmall),
                              Text(
                                '${kost.availableRooms}/${kost.totalRooms}',
                                style: AppTextStyles.h3.copyWith(
                                  color: AppColors.success,
                                ),
                              ),
                              Text('kamar', style: AppTextStyles.caption),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Deskripsi
                    if (kost.description != null) ...[
                      Text('Deskripsi', style: AppTextStyles.h4),
                      const SizedBox(height: 8),
                      Text(kost.description!, style: AppTextStyles.bodyMedium),
                      const SizedBox(height: 20),
                    ],

                    // Fasilitas
                    Text('Fasilitas', style: AppTextStyles.h4),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: kost.facilities
                          .map((f) => _FacilityChip(label: f))
                          .toList(),
                    ),
                    const SizedBox(height: 20),

                    // Pemilik
                    Text('Pemilik Kost', style: AppTextStyles.h4),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.grey200),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 22,
                            backgroundColor: AppColors.primary.withValues(
                              alpha: 0.1,
                            ),
                            child: const Icon(
                              Icons.person_rounded,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                kost.ownerName,
                                style: AppTextStyles.labelLarge,
                              ),
                              Text(
                                'Pemilik Kost',
                                style: AppTextStyles.bodySmall,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),

        // Bottom action bar
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: EdgeInsets.fromLTRB(
              20,
              14,
              20,
              MediaQuery.of(context).padding.bottom + 14,
            ),
            decoration: BoxDecoration(
              color: AppColors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 12,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: AppButton(
                    text: 'Sewa Solo',
                    icon: Icons.person_rounded,
                    isOutlined: true,
                    onPressed: kost.availableRooms > 0
                        ? () => context.push(
                            AppRoutes.reservationForm,
                            extra: {'kost': kost, 'isSplit': false},
                          )
                        : null,
                  ),
                ),
                if (kost.isSplitBillAvailable) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppButton(
                      text: 'Patungan',
                      icon: Icons.people_rounded,
                      backgroundColor: AppColors.secondary,
                      onPressed: kost.availableRooms > 0
                          ? () => context.push(
                              AppRoutes.reservationForm,
                              extra: {'kost': kost, 'isSplit': true},
                            )
                          : null,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _TypeBadge extends StatelessWidget {
  final String type;
  const _TypeBadge({required this.type});
  @override
  Widget build(BuildContext context) {
    final color = switch (type) {
      'PUTRA' => const Color(0xFF1565C0),
      'PUTRI' => const Color(0xFFAD1457),
      _ => const Color(0xFF2E7D32),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        'Kost $type',
        style: AppTextStyles.labelSmall.copyWith(color: AppColors.white),
      ),
    );
  }
}

class _FacilityChip extends StatelessWidget {
  final String label;
  const _FacilityChip({required this.label});

  static const _icons = <String, IconData>{
    'WiFi': Icons.wifi_rounded,
    'AC': Icons.ac_unit_rounded,
    'TV': Icons.tv_rounded,
    'Parkir Motor': Icons.two_wheeler_rounded,
    'Parkir Mobil': Icons.directions_car_rounded,
    'Dapur': Icons.kitchen_rounded,
    'Dapur Bersama': Icons.kitchen_rounded,
    'Lemari': Icons.weekend_rounded,
    'Kamar Mandi Dalam': Icons.bathtub_outlined,
    'Meja Belajar': Icons.desk_rounded,
    'Keamanan 24 Jam': Icons.security_rounded,
    'Laundry': Icons.local_laundry_service_rounded,
    'Kulkas': Icons.kitchen_outlined,
  };

  @override
  Widget build(BuildContext context) {
    final icon = _icons[label] ?? Icons.check_circle_outline_rounded;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.grey200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.primary),
          const SizedBox(width: 6),
          Text(label, style: AppTextStyles.labelMedium),
        ],
      ),
    );
  }
}

// Re-export shimmer
class ShimmerBox extends StatelessWidget {
  final double? width;
  final double? height;
  final double borderRadius;

  const ShimmerBox({super.key, this.width, this.height, this.borderRadius = 8});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.grey200,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}

// Error state local
class ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  const ErrorState({super.key, required this.message, this.onRetry});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.errorLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                size: 40,
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Terjadi Kesalahan',
              style: AppTextStyles.h4,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.grey500,
              ),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Coba Lagi'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
