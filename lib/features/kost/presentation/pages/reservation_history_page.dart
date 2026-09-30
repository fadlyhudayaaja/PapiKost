import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/shimmer_loading.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../data/models/reservation_model.dart';

// ── Provider lokal untuk halaman ini ──────────────────────────
class _ReservationHistoryProvider extends ChangeNotifier {
  List<ReservationModel> _reservations = [];
  bool _loading = false;
  String? _error;

  List<ReservationModel> get reservations => _reservations;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> fetch() async {
    _loading = true;
    notifyListeners();
    try {
      final resp = await DioClient.instance.get('/reservations/my');
      final data = resp.data as List;
      _reservations = data
          .map((e) => ReservationModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      // Mock fallback
      _reservations = _mockList;
    }
    _loading = false;
    notifyListeners();
  }

  static final List<ReservationModel> _mockList = [
    ReservationModel(
      id: 1,
      kostId: 1,
      kostName: 'Kost Mawar Indah',
      kostAddress: 'Jl. Dr. Mansyur No. 12',
      renterId: 1,
      renterName: 'Andi',
      renterEmail: 'andi@mail.com',
      renterPhone: '081234',
      status: AppConstants.reservationStatusApproved,
      isSplitBill: false,
      totalPrice: 1200000,
      checkInDate: DateTime.now().add(const Duration(days: 5)),
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
    ReservationModel(
      id: 2,
      kostId: 2,
      kostName: 'Kost Bumi Putera',
      kostAddress: 'Jl. Gagak Hitam No. 5',
      renterId: 1,
      renterName: 'Andi',
      renterEmail: 'andi@mail.com',
      renterPhone: '081234',
      status: AppConstants.reservationStatusPending,
      isSplitBill: true,
      splitMemberCount: 2,
      totalPrice: 900000,
      pricePerPerson: 450000,
      checkInDate: DateTime.now().add(const Duration(days: 14)),
      createdAt: DateTime.now().subtract(const Duration(hours: 3)),
    ),
    ReservationModel(
      id: 3,
      kostId: 3,
      kostName: 'Kost Harmoni Residence',
      kostAddress: 'Jl. Jamin Ginting No. 88',
      renterId: 1,
      renterName: 'Andi',
      renterEmail: 'andi@mail.com',
      renterPhone: '081234',
      status: AppConstants.reservationStatusRejected,
      isSplitBill: false,
      totalPrice: 1500000,
      checkInDate: DateTime.now().subtract(const Duration(days: 3)),
      createdAt: DateTime.now().subtract(const Duration(days: 10)),
    ),
  ];
}

// ── Page ──────────────────────────────────────────────────────
class ReservationHistoryPage extends StatelessWidget {
  const ReservationHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => _ReservationHistoryProvider()..fetch(),
      child: const _ReservationHistoryView(),
    );
  }
}

class _ReservationHistoryView extends StatelessWidget {
  const _ReservationHistoryView();

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<_ReservationHistoryProvider>();

    return Scaffold(
      backgroundColor: AppColors.scaffold,
      appBar: AppBar(title: const Text('Riwayat Reservasi')),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () => context.read<_ReservationHistoryProvider>().fetch(),
        child: prov.loading
            ? ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: 4,
                itemBuilder: (_, __) => const ListItemShimmer(),
              )
            : prov.reservations.isEmpty
            ? const EmptyState(
                icon: Icons.receipt_long_outlined,
                title: 'Belum ada riwayat reservasi',
                subtitle: 'Reservasi yang Anda buat akan muncul di sini',
              )
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                itemCount: prov.reservations.length,
                itemBuilder: (ctx, i) =>
                    _ReservationCard(res: prov.reservations[i]),
              ),
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
