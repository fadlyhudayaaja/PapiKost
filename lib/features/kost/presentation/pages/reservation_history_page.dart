import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/shimmer_loading.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../data/models/reservation_model.dart';
import '../../../../data/repositories/reservation_repository.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class ReservationHistoryPage extends StatefulWidget {
  const ReservationHistoryPage({super.key});

  @override
  State<ReservationHistoryPage> createState() => _ReservationHistoryPageState();
}

class _ReservationHistoryPageState extends State<ReservationHistoryPage> {
  String? _uid;
  Stream<List<ReservationModel>>? _stream;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final uid = context.watch<AuthProvider>().currentUser?.id;
    if (_uid != uid) {
      _uid = uid;
      _stream = uid == null
          ? null
          : context.read<ReservationRepository>().watchForRenter(uid);
    }
  }

  Future<void> _refresh() async {
    final uid = _uid;
    if (uid == null) return;
    setState(() {
      _stream = context.read<ReservationRepository>().watchForRenter(uid);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffold,
      appBar: AppBar(title: const Text('Riwayat Reservasi')),
      body: _uid == null
          ? const Center(child: Text('Silakan login untuk melihat reservasi.'))
          : StreamBuilder<List<ReservationModel>>(
              key: ValueKey(_uid),
              stream: _stream,
              builder: (context, snapshot) {
                final items = snapshot.data ?? [];
                return RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: _refresh,
                  child: snapshot.hasError
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [
                            ErrorState(
                              message: ReservationRepository.errorMessage(
                                snapshot.error!,
                              ),
                              onRetry: _refresh,
                            ),
                          ],
                        )
                      : snapshot.connectionState == ConnectionState.waiting &&
                            !snapshot.hasData
                      ? ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: 4,
                          itemBuilder: (_, _) => const ListItemShimmer(),
                        )
                      : items.isEmpty
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: const [
                            EmptyState(
                              icon: Icons.receipt_long_outlined,
                              title: 'Belum ada riwayat reservasi',
                              subtitle:
                                  'Reservasi yang Anda buat akan muncul di sini',
                            ),
                          ],
                        )
                      : ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                          itemCount: items.length,
                          itemBuilder: (_, i) =>
                              _ReservationCard(res: items[i]),
                        ),
                );
              },
            ),
    );
  }
}

class _ReservationCard extends StatelessWidget {
  final ReservationModel res;
  const _ReservationCard({required this.res});

  static final _dateFmt = DateFormat('dd MMM yyyy', 'id_ID');
  static final _currFmt = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  @override
  Widget build(BuildContext context) {
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.home_rounded,
                    color: AppColors.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(res.kostName, style: AppTextStyles.labelLarge),
                      const SizedBox(height: 2),
                      Text(res.kostAddress, style: AppTextStyles.bodySmall),
                    ],
                  ),
                ),
                _StatusBadge(status: res.status),
              ],
            ),
          ),

          const Divider(height: 1, indent: 14, endIndent: 14),

          // ── Details ──
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                _Row(
                  icon: Icons.calendar_today_outlined,
                  label: 'Check-in',
                  value: _dateFmt.format(res.checkInDate),
                ),
                const SizedBox(height: 8),
                _Row(
                  icon: res.isSplitBill
                      ? Icons.people_rounded
                      : Icons.person_rounded,
                  label: 'Tipe Sewa',
                  value: res.isSplitBill
                      ? 'Patungan (${res.splitMemberCount} orang)'
                      : 'Solo',
                  valueColor: res.isSplitBill ? AppColors.secondary : null,
                ),
                const SizedBox(height: 8),
                _Row(
                  icon: Icons.payments_outlined,
                  label: res.isSplitBill ? 'Per Orang' : 'Total',
                  value: _currFmt.format(
                    res.isSplitBill && res.pricePerPerson != null
                        ? res.pricePerPerson!
                        : res.totalPrice,
                  ),
                  valueColor: AppColors.primary,
                ),
                const SizedBox(height: 8),
                _Row(
                  icon: Icons.access_time_rounded,
                  label: 'Dibuat',
                  value: _dateFmt.format(res.createdAt),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _Row({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 15, color: AppColors.grey400),
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
    final (label, bg, fg) = switch (status) {
      AppConstants.reservationStatusApproved => (
        'Disetujui',
        AppColors.statusDoneBg,
        AppColors.statusDone,
      ),
      AppConstants.reservationStatusRejected => (
        'Ditolak',
        AppColors.errorLight,
        AppColors.error,
      ),
      _ => ('Menunggu', AppColors.statusPendingBg, AppColors.statusPending),
    };

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
