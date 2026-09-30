import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Badge status tiket kerusakan
class TicketStatusBadge extends StatelessWidget {
  final String status;

  const TicketStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final config = _resolveConfig(status);
    return _Badge(
      label: config.$1,
      icon: config.$2,
      bg: config.$3,
      fg: config.$4,
    );
  }

  (String, IconData, Color, Color) _resolveConfig(String s) {
    switch (s) {
      case AppConstants.ticketStatusInProgress:
        return (
          'Diproses',
          Icons.pending_rounded,
          AppColors.statusInProgressBg,
          AppColors.statusInProgress,
        );
      case AppConstants.ticketStatusDone:
        return (
          'Selesai',
          Icons.check_circle_rounded,
          AppColors.statusDoneBg,
          AppColors.statusDone,
        );
      default:
        return (
          'Menunggu',
          Icons.hourglass_empty_rounded,
          AppColors.statusPendingBg,
          AppColors.statusPending,
        );
    }
  }
}

/// Badge status reservasi
class ReservationStatusBadge extends StatelessWidget {
  final String status;

  const ReservationStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final config = _resolveConfig(status);
    return _Badge(
      label: config.$1,
      icon: config.$2,
      bg: config.$3,
      fg: config.$4,
    );
  }

  (String, IconData, Color, Color) _resolveConfig(String s) {
    switch (s) {
      case AppConstants.reservationStatusApproved:
        return (
          'Disetujui',
          Icons.check_circle_rounded,
          AppColors.statusDoneBg,
          AppColors.statusDone,
        );
      case AppConstants.reservationStatusRejected:
        return (
          'Ditolak',
          Icons.cancel_rounded,
          AppColors.errorLight,
          AppColors.error,
        );
      default:
        return (
          'Menunggu',
          Icons.hourglass_empty_rounded,
          AppColors.statusPendingBg,
          AppColors.statusPending,
        );
    }
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color bg;
  final Color fg;

  const _Badge({
    required this.label,
    required this.icon,
    required this.bg,
    required this.fg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: fg),
          const SizedBox(width: 4),
          Text(label, style: AppTextStyles.labelSmall.copyWith(color: fg)),
        ],
      ),
    );
  }
}
