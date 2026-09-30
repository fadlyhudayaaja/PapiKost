import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/shimmer_loading.dart';
import '../../../../data/repositories/mock_repository.dart';
import '../providers/renter_ticket_provider.dart';

class TicketDetailPage extends StatefulWidget {
  final int ticketId;
  const TicketDetailPage({super.key, required this.ticketId});

  @override
  State<TicketDetailPage> createState() => _TicketDetailPageState();
}

class _TicketDetailPageState extends State<TicketDetailPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RenterTicketProvider>().loadTicketDetail(widget.ticketId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<RenterTicketProvider>();

    return Scaffold(
      backgroundColor: AppColors.scaffold,
      appBar: AppBar(
        title: const Text('Detail Laporan'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: _buildBody(prov),
    );
  }

  Widget _buildBody(RenterTicketProvider prov) {
    switch (prov.detailState) {
      case ViewState.loading:
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: const [
              ShimmerBox(height: 24, width: 200),
              SizedBox(height: 16),
              ShimmerBox(height: 80),
              SizedBox(height: 12),
              ShimmerBox(height: 60),
            ],
          ),
        );

      case ViewState.error:
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
              Text(prov.detailError, style: AppTextStyles.bodyMedium),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => prov.loadTicketDetail(widget.ticketId),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Coba Lagi'),
              ),
            ],
          ),
        );

      case ViewState.empty:
        return const Center(child: Text('Laporan tidak ditemukan.'));

      case ViewState.success:
        final t = prov.selectedTicket!;
        final dateFmt = DateFormat('EEEE, dd MMMM yyyy', 'id_ID');
        final isEditable = t.status != AppConstants.ticketStatusDone;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Status + judul
              Row(
                children: [
                  Expanded(child: Text(t.title, style: AppTextStyles.h2)),
                  _StatusBadge(status: t.status),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                MockRepository.categoryLabels[t.category] ?? t.category,
                style: AppTextStyles.bodySmall,
              ),
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 16),

              // Info grid
              _InfoSection(
                label: 'Tanggal Laporan',
                value: dateFmt.format(t.createdAt),
                icon: Icons.calendar_today_outlined,
              ),
              const SizedBox(height: 12),
              _InfoSection(
                label: 'Nama Kost',
                value: t.kostName,
                icon: Icons.home_outlined,
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),

              // Deskripsi
              Text('Deskripsi Kerusakan', style: AppTextStyles.h4),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.grey200),
                ),
                child: Text(t.description, style: AppTextStyles.bodyMedium),
              ),

              // Catatan owner
              if (t.ownerNote != null && t.ownerNote!.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text('Catatan Pemilik Kost', style: AppTextStyles.h4),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.infoLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.info.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.info_outline_rounded,
                        color: AppColors.info,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          t.ownerNote!,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.info,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 32),

              // Action button (hanya jika belum done)
              if (isEditable)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () =>
                        context.push(AppRoutes.editTicketRenter, extra: t),
                    icon: const Icon(Icons.edit_rounded),
                    label: const Text('Edit Laporan'),
                  ),
                ),
            ],
          ),
        );
    }
  }
}

class _InfoSection extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _InfoSection({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.grey400),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: AppTextStyles.caption),
            Text(value, style: AppTextStyles.labelMedium),
          ],
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
    late Color bg, fg;
    late String label;
    switch (status) {
      case AppConstants.ticketStatusInProgress:
        bg = AppColors.statusInProgressBg;
        fg = AppColors.statusInProgress;
        label = 'Diproses';
        break;
      case AppConstants.ticketStatusDone:
        bg = AppColors.statusDoneBg;
        fg = AppColors.statusDone;
        label = 'Selesai';
        break;
      default:
        bg = AppColors.statusPendingBg;
        fg = AppColors.statusPending;
        label = 'Menunggu';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label, style: AppTextStyles.labelMedium.copyWith(color: fg)),
    );
  }
}
