import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/shimmer_loading.dart';
import '../../../../data/models/reservation_model.dart';
import '../providers/owner_provider.dart';

class ReservationManagementPage extends StatelessWidget {
  const ReservationManagementPage({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<OwnerProvider>();

    return Scaffold(
      backgroundColor: AppColors.scaffold,
      appBar: AppBar(title: const Text('Manajemen Reservasi')),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () => provider.fetchDashboard(),
        child: provider.isLoading
            ? ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: 4,
                itemBuilder: (_, __) => const ListItemShimmer(),
              )
            : provider.reservations.isEmpty
            ? const Center(child: Text('Belum ada reservasi'))
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: provider.reservations.length,
                itemBuilder: (context, i) => _ReservationCard(
                  reservation: provider.reservations[i],
                  onApprove: (id) =>
                      _handleResponse(context, provider, id, true),
                  onReject: (id) =>
                      _handleResponse(context, provider, id, false),
                ),
              ),
      ),
    );
  }

  Future<void> _handleResponse(
    BuildContext context,
    OwnerProvider provider,
    int id,
    bool approve,
  ) async {
    final success = await provider.respondToReservation(id, approve);
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? (approve ? 'Reservasi disetujui' : 'Reservasi ditolak')
              : 'Gagal memproses reservasi',
        ),
        backgroundColor: success
            ? (approve ? AppColors.success : AppColors.error)
            : AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}

class _ReservationCard extends StatelessWidget {
  final ReservationModel reservation;
  final void Function(int) onApprove;
  final void Function(int) onReject;

  const _ReservationCard({
    required this.reservation,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('dd MMM yyyy', 'id_ID');
    final currencyFmt = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    final isPending =
        reservation.status == AppConstants.reservationStatusPending;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  child: Text(
                    reservation.renterName.isNotEmpty
                        ? reservation.renterName[0].toUpperCase()
                        : 'A',
                    style: AppTextStyles.h4.copyWith(color: AppColors.primary),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        reservation.renterName,
                        style: AppTextStyles.labelLarge,
                      ),
                      Text(
                        reservation.renterPhone,
                        style: AppTextStyles.bodySmall,
                      ),
                    ],
                  ),
                ),
                // Status Badge
                _StatusBadge(status: reservation.status),
              ],
            ),
          ),

          const Divider(height: 1),

          // Details
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                _InfoRow(
                  icon: Icons.calendar_month_rounded,
                  label: 'Check-in',
                  value: dateFmt.format(reservation.checkInDate),
                ),
                const SizedBox(height: 8),
                _InfoRow(
                  icon: Icons.payments_outlined,
                  label: 'Tipe Sewa',
                  value: reservation.isSplitBill
                      ? 'Patungan (${reservation.splitMemberCount} orang)'
                      : 'Solo',
                  valueColor: reservation.isSplitBill
                      ? AppColors.secondary
                      : AppColors.grey800,
                ),
                const SizedBox(height: 8),
                _InfoRow(
                  icon: Icons.attach_money_rounded,
                  label: 'Total',
                  value: currencyFmt.format(reservation.totalPrice),
                  valueColor: AppColors.primary,
                ),
                if (reservation.isSplitBill &&
                    reservation.pricePerPerson != null) ...[
                  const SizedBox(height: 8),
                  _InfoRow(
                    icon: Icons.person_outline_rounded,
                    label: 'Per Orang',
                    value: currencyFmt.format(reservation.pricePerPerson),
                    valueColor: AppColors.secondary,
                  ),
                ],

                // Split Bill indicator
                if (reservation.isSplitBill) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.people_rounded,
                          size: 16,
                          color: AppColors.secondary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Sewa Patungan: biaya dibagi ${reservation.splitMemberCount} orang',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.secondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Action Buttons (hanya jika pending)
          if (isPending) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => onReject(reservation.id),
                      icon: const Icon(Icons.close_rounded, size: 18),
                      label: const Text('Tolak'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: const BorderSide(color: AppColors.error),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => onApprove(reservation.id),
                      icon: const Icon(Icons.check_rounded, size: 18),
                      label: const Text('Setujui'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.grey400),
        const SizedBox(width: 8),
        Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(color: AppColors.grey500),
        ),
        const Spacer(),
        Text(
          value,
          style: AppTextStyles.labelMedium.copyWith(
            color: valueColor ?? AppColors.grey800,
          ),
        ),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color bg, fg;
    String label;

    switch (status) {
      case AppConstants.reservationStatusApproved:
        bg = AppColors.statusDoneBg;
        fg = AppColors.statusDone;
        label = 'Disetujui';
        break;
      case AppConstants.reservationStatusRejected:
        bg = AppColors.errorLight;
        fg = AppColors.error;
        label = 'Ditolak';
        break;
      default:
        bg = AppColors.statusPendingBg;
        fg = AppColors.statusPending;
        label = 'Menunggu';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label, style: AppTextStyles.labelSmall.copyWith(color: fg)),
    );
  }
}
