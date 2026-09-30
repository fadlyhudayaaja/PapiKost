import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../data/models/reservation_model.dart';

/// Layar akhir Alur 1: Eksplorasi → Reservasi → Sukses
class ReservationSuccessPage extends StatelessWidget {
  final ReservationModel reservation;

  const ReservationSuccessPage({super.key, required this.reservation});

  @override
  Widget build(BuildContext context) {
    final currFmt = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    final dateFmt = DateFormat('dd MMMM yyyy', 'id_ID');

    return Scaffold(
      backgroundColor: AppColors.scaffold,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const Spacer(flex: 2),

              // ── Ikon sukses animasi ───────────────────────────────────
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(milliseconds: 700),
                curve: Curves.elasticOut,
                builder: (_, v, child) =>
                    Transform.scale(scale: v, child: child),
                child: Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF43A047), Color(0xFF66BB6A)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.success.withValues(alpha: 0.35),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: Colors.white,
                    size: 56,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // ── Judul ───────────────────────────────────────────────
              Text(
                'Pengajuan Berhasil!',
                style: AppTextStyles.h1,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                reservation.isSplitBill
                    ? 'Pengajuan sewa patungan Anda telah terkirim.\nMenunggu konfirmasi dari pemilik kost.'
                    : 'Pengajuan sewa Anda telah terkirim.\nMenunggu konfirmasi dari pemilik kost.',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.grey500,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 32),

              // ── Ringkasan reservasi ─────────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Ringkasan Reservasi', style: AppTextStyles.h4),
                    const Divider(height: 20),
                    _SummaryRow(label: 'Kost', value: reservation.kostName),
                    const SizedBox(height: 10),
                    _SummaryRow(
                      label: 'Tipe Sewa',
                      value: reservation.isSplitBill
                          ? 'Patungan (${reservation.splitMemberCount} orang)'
                          : 'Solo',
                      valueColor: reservation.isSplitBill
                          ? AppColors.secondary
                          : null,
                    ),
                    const SizedBox(height: 10),
                    _SummaryRow(
                      label: 'Check-in',
                      value: dateFmt.format(reservation.checkInDate),
                    ),
                    const Divider(height: 20),
                    _SummaryRow(
                      label: reservation.isSplitBill
                          ? 'Per Orang/Bulan'
                          : 'Total/Bulan',
                      value: currFmt.format(
                        reservation.isSplitBill &&
                                reservation.pricePerPerson != null
                            ? reservation.pricePerPerson!
                            : reservation.totalPrice,
                      ),
                      isTotal: true,
                      valueColor: reservation.isSplitBill
                          ? AppColors.secondary
                          : AppColors.primary,
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.statusPendingBg,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.hourglass_empty_rounded,
                            size: 14,
                            color: AppColors.statusPending,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Menunggu Konfirmasi Pemilik',
                            style: AppTextStyles.labelSmall.copyWith(
                              color: AppColors.statusPending,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(flex: 3),

              // ── Tombol aksi ─────────────────────────────────────────
              AppButton(
                text: 'Lihat Riwayat Reservasi',
                icon: Icons.receipt_long_rounded,
                isFullWidth: true,
                onPressed: () => context.go(AppRoutes.renterReservations),
              ),
              const SizedBox(height: 12),
              AppButton(
                text: 'Kembali ke Beranda',
                isFullWidth: true,
                isOutlined: true,
                onPressed: () => context.go(AppRoutes.renterHome),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isTotal;
  final Color? valueColor;

  const _SummaryRow({
    required this.label,
    required this.value,
    this.isTotal = false,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.grey500),
        ),
        const Spacer(),
        Flexible(
          child: Text(
            value,
            style: isTotal
                ? AppTextStyles.price.copyWith(
                    color: valueColor ?? AppColors.primary,
                  )
                : AppTextStyles.labelMedium.copyWith(
                    color: valueColor ?? AppColors.grey800,
                  ),
            textAlign: TextAlign.end,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
