import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/shimmer_loading.dart';
import '../../../../data/models/kost_model.dart';
import '../providers/kost_provider.dart';

class KostDetailPage extends StatefulWidget {
  final int kostId;
  const KostDetailPage({super.key, required this.kostId});

  @override
  State<KostDetailPage> createState() => _KostDetailPageState();
}

class _KostDetailPageState extends State<KostDetailPage> {
  final _pageCtrl = PageController();
  final _currencyFmt = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<KostProvider>().fetchKostDetail(widget.kostId);
    });
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  void _showReservationModal(KostModel kost, bool isSplitBill) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ReservationModal(
        kost: kost,
        isSplitBill: isSplitBill,
        currencyFmt: _currencyFmt,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<KostProvider>();
    final kost = provider.selectedKost;

    return Scaffold(
      backgroundColor: AppColors.scaffold,
      body: provider.isLoading
          ? _buildSkeleton()
          : kost == null
          ? _buildError()
          : _buildContent(kost),
    );
  }

  Widget _buildContent(KostModel kost) {
    return Stack(
      children: [
        // Scrollable Content
        CustomScrollView(
          slivers: [
            // Image Carousel AppBar
            SliverAppBar(
              expandedHeight: 280,
              pinned: true,
              backgroundColor: AppColors.primary,
              leading: IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.4),
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
                    // Photo Carousel
                    PageView.builder(
                      controller: _pageCtrl,
                      itemCount: kost.imageUrls.isEmpty
                          ? 1
                          : kost.imageUrls.length,
                      itemBuilder: (context, index) {
                        if (kost.imageUrls.isEmpty) {
                          return Container(
                            color: AppColors.grey200,
                            child: const Icon(
                              Icons.home_outlined,
                              size: 64,
                              color: AppColors.grey400,
                            ),
                          );
                        }
                        return CachedNetworkImage(
                          imageUrl: kost.imageUrls[index],
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

                    // Page Indicator
                    if (kost.imageUrls.length > 1)
                      Positioned(
                        bottom: 16,
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

            // Content
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Badges
                    Row(
                      children: [
                        _TypeBadge(type: kost.type),
                        if (kost.isSplitBillAvailable) ...[
                          const SizedBox(width: 8),
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
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Name
                    Text(kost.name, style: AppTextStyles.h2),
                    const SizedBox(height: 6),

                    // Address
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: 16,
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
                    const SizedBox(height: 8),

                    // Rating & Reviews
                    if (kost.rating != null)
                      Row(
                        children: [
                          ...List.generate(5, (i) {
                            return Icon(
                              i < kost.rating!.floor()
                                  ? Icons.star_rounded
                                  : Icons.star_outline_rounded,
                              color: const Color(0xFFFFB300),
                              size: 18,
                            );
                          }),
                          const SizedBox(width: 6),
                          Text(
                            '${kost.rating} (${kost.reviewCount} ulasan)',
                            style: AppTextStyles.labelMedium,
                          ),
                        ],
                      ),
                    const SizedBox(height: 16),

                    // Price Card
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
                                  _currencyFmt.format(kost.pricePerMonth),
                                  style: AppTextStyles.priceLarge,
                                ),
                                Text('/bulan', style: AppTextStyles.caption),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'Kamar Tersedia',
                                style: AppTextStyles.bodySmall,
                              ),
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

                    // Description
                    if (kost.description != null) ...[
                      Text('Deskripsi', style: AppTextStyles.h4),
                      const SizedBox(height: 8),
                      Text(kost.description!, style: AppTextStyles.bodyMedium),
                      const SizedBox(height: 20),
                    ],

                    // Facilities
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

                    // Owner Info
                    Text('Pemilik Kost', style: AppTextStyles.h4),
                    const SizedBox(height: 12),
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
                            backgroundColor: AppColors.primary.withValues(alpha: 0.1),
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

        // Bottom Action Bar
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: EdgeInsets.fromLTRB(
              20,
              16,
              20,
              MediaQuery.of(context).padding.bottom + 16,
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
                        ? () => _showReservationModal(kost, false)
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
                          ? () => _showReservationModal(kost, true)
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

  Widget _buildSkeleton() {
    return Shimmer.fromColors(
      baseColor: AppColors.grey200,
      highlightColor: AppColors.grey100,
      child: Column(
        children: [
          const ShimmerBox(height: 280, borderRadius: 0),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const ShimmerBox(height: 24, width: 200),
                  const SizedBox(height: 12),
                  const ShimmerBox(height: 16, width: 280),
                  const SizedBox(height: 20),
                  const ShimmerBox(height: 80),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            size: 64,
            color: AppColors.grey300,
          ),
          const SizedBox(height: 16),
          Text('Gagal memuat detail kost', style: AppTextStyles.h4),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => context.pop(),
            child: const Text('Kembali'),
          ),
        ],
      ),
    );
  }
}

// Reservation Modal
class _ReservationModal extends StatefulWidget {
  final KostModel kost;
  final bool isSplitBill;
  final NumberFormat currencyFmt;

  const _ReservationModal({
    required this.kost,
    required this.isSplitBill,
    required this.currencyFmt,
  });

  @override
  State<_ReservationModal> createState() => _ReservationModalState();
}

class _ReservationModalState extends State<_ReservationModal> {
  int _memberCount = 2;
  DateTime _checkInDate = DateTime.now().add(const Duration(days: 1));
  final _notesCtrl = TextEditingController();
  bool _isSubmitting = false;

  double get pricePerPerson => widget.kost.pricePerMonth / _memberCount;

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _checkInDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: AppColors.primary),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) setState(() => _checkInDate = picked);
  }

  Future<void> _submitReservation() async {
    setState(() => _isSubmitting = true);
    // TODO: Panggil API reservasi via provider
    await Future.delayed(const Duration(seconds: 2)); // Simulasi API call
    setState(() => _isSubmitting = false);

    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          widget.isSplitBill
              ? 'Pengajuan sewa patungan berhasil dikirim!'
              : 'Pengajuan sewa berhasil dikirim!',
        ),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    final dateFmt = DateFormat('dd MMM yyyy', 'id_ID');

    return Container(
      padding: EdgeInsets.fromLTRB(
        24,
        0,
        24,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Center(
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.grey300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: widget.isSplitBill
                        ? AppColors.secondary.withValues(alpha: 0.1)
                        : AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    widget.isSplitBill
                        ? Icons.people_rounded
                        : Icons.person_rounded,
                    color: widget.isSplitBill
                        ? AppColors.secondary
                        : AppColors.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.isSplitBill
                            ? 'Sewa Patungan (Split-Bill)'
                            : 'Sewa Solo',
                        style: AppTextStyles.h4,
                      ),
                      Text(
                        widget.kost.name,
                        style: AppTextStyles.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 16),

            // Split Bill Member Selector
            if (widget.isSplitBill) ...[
              Text('Jumlah Anggota Patungan', style: AppTextStyles.h4),
              const SizedBox(height: 4),
              Text(
                'Pilih berapa orang yang akan berbagi biaya sewa',
                style: AppTextStyles.bodySmall,
              ),
              const SizedBox(height: 16),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: _memberCount > AppConstants.minSplitMembers
                        ? () => setState(() => _memberCount--)
                        : null,
                    icon: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: _memberCount > AppConstants.minSplitMembers
                            ? AppColors.primary
                            : AppColors.grey200,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.remove_rounded,
                        color: AppColors.white,
                        size: 20,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        Text(
                          '$_memberCount',
                          style: AppTextStyles.displayLarge.copyWith(
                            color: AppColors.primary,
                          ),
                        ),
                        Text('orang', style: AppTextStyles.bodySmall),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: _memberCount < AppConstants.maxSplitMembers
                        ? () => setState(() => _memberCount++)
                        : null,
                    icon: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: _memberCount < AppConstants.maxSplitMembers
                            ? AppColors.primary
                            : AppColors.grey200,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.add_rounded,
                        color: AppColors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Price Breakdown
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.secondary.withValues(alpha: 0.08),
                      AppColors.secondary.withValues(alpha: 0.04),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.secondary.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  children: [
                    _PriceRow(
                      label: 'Total Sewa/Bulan',
                      value: fmt.format(widget.kost.pricePerMonth),
                    ),
                    const Divider(height: 16),
                    _PriceRow(label: 'Dibagi $_memberCount orang', value: ''),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Per Orang/Bulan',
                          style: AppTextStyles.labelLarge.copyWith(
                            color: AppColors.secondary,
                          ),
                        ),
                        Text(
                          fmt.format(pricePerPerson),
                          style: AppTextStyles.priceLarge.copyWith(
                            color: AppColors.secondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ] else ...[
              // Solo price summary
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.15),
                  ),
                ),
                child: _PriceRow(
                  label: 'Total Sewa/Bulan',
                  value: fmt.format(widget.kost.pricePerMonth),
                  isTotal: true,
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Check-in Date
            Text('Tanggal Mulai Sewa', style: AppTextStyles.labelLarge),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _selectDate,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: AppColors.inputBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.grey200),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.calendar_month_outlined,
                      color: AppColors.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      dateFmt.format(_checkInDate),
                      style: AppTextStyles.bodyMedium,
                    ),
                    const Spacer(),
                    const Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 14,
                      color: AppColors.grey400,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Notes
            Text('Catatan (Opsional)', style: AppTextStyles.labelLarge),
            const SizedBox(height: 8),
            TextField(
              controller: _notesCtrl,
              maxLines: 3,
              style: AppTextStyles.bodyMedium,
              decoration: InputDecoration(
                hintText: 'Tuliskan pesan untuk pemilik kost...',
                hintStyle: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.grey400,
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Submit Button
            AppButton(
              text: widget.isSplitBill ? 'Ajukan Sewa Patungan' : 'Ajukan Sewa',
              backgroundColor: widget.isSplitBill
                  ? AppColors.secondary
                  : AppColors.primary,
              isFullWidth: true,
              isLoading: _isSubmitting,
              onPressed: _isSubmitting ? null : _submitReservation,
            ),
          ],
        ),
      ),
    );
  }
}

class _PriceRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isTotal;

  const _PriceRow({
    required this.label,
    required this.value,
    this.isTotal = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: isTotal ? AppTextStyles.labelLarge : AppTextStyles.bodyMedium,
        ),
        if (value.isNotEmpty)
          Text(
            value,
            style: isTotal ? AppTextStyles.price : AppTextStyles.bodyMedium,
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
    Color color;
    switch (type) {
      case 'PUTRA':
        color = const Color(0xFF1565C0);
        break;
      case 'PUTRI':
        color = const Color(0xFFAD1457);
        break;
      default:
        color = const Color(0xFF2E7D32);
    }

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

  static final Map<String, IconData> _facilityIcons = {
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
  };

  @override
  Widget build(BuildContext context) {
    final icon = _facilityIcons[label] ?? Icons.check_circle_outline_rounded;
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
