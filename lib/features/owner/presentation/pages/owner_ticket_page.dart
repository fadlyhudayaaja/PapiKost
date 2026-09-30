import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/shimmer_loading.dart';
import '../../../../data/models/ticket_model.dart';
import '../providers/owner_provider.dart';

class OwnerTicketPage extends StatelessWidget {
  const OwnerTicketPage({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<OwnerProvider>();

    return Scaffold(
      backgroundColor: AppColors.scaffold,
      appBar: AppBar(title: const Text('Pusat Tiket Kerusakan')),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () => provider.fetchDashboard(),
        child: provider.isLoading
            ? ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: 4,
                itemBuilder: (_, __) => const ListItemShimmer(),
              )
            : provider.tickets.isEmpty
            ? const Center(child: Text('Tidak ada tiket kerusakan'))
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: provider.tickets.length,
                itemBuilder: (context, i) => _OwnerTicketCard(
                  ticket: provider.tickets[i],
                  onStatusChange: (id, status) =>
                      _changeStatus(context, provider, id, status),
                ),
              ),
      ),
    );
  }

  Future<void> _changeStatus(
    BuildContext context,
    OwnerProvider provider,
    int ticketId,
    String newStatus,
  ) async {
    final success = await provider.updateTicketStatus(ticketId, newStatus);
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success ? 'Status tiket diperbarui' : 'Gagal update status',
        ),
        backgroundColor: success ? AppColors.success : AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}

class _OwnerTicketCard extends StatelessWidget {
  final TicketModel ticket;
  final void Function(int, String) onStatusChange;

  const _OwnerTicketCard({required this.ticket, required this.onStatusChange});

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('dd MMM yyyy', 'id_ID');

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
          // Header
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: _getCategoryColor(ticket.category).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    _getCategoryIcon(ticket.category),
                    color: _getCategoryColor(ticket.category),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(ticket.title, style: AppTextStyles.labelLarge),
                      Text(
                        'dari: ${ticket.renterName}',
                        style: AppTextStyles.bodySmall,
                      ),
                    ],
                  ),
                ),
                _buildStatusDropdown(context),
              ],
            ),
          ),

          // Description
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
            child: Text(
              ticket.description,
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.grey600),
            ),
          ),

          // Photos (if any)
          if (ticket.imageUrls.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Foto Laporan', style: AppTextStyles.labelMedium),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 90,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: ticket.imageUrls.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, i) {
                        return GestureDetector(
                          onTap: () => _viewImage(context, ticket.imageUrls[i]),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: CachedNetworkImage(
                              imageUrl: ticket.imageUrls[i],
                              width: 90,
                              height: 90,
                              fit: BoxFit.cover,
                              placeholder: (_, __) =>
                                  const ShimmerBox(width: 90, height: 90),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Footer
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
            child: Row(
              children: [
                const Icon(
                  Icons.access_time_rounded,
                  size: 13,
                  color: AppColors.grey400,
                ),
                const SizedBox(width: 4),
                Text(
                  dateFmt.format(ticket.createdAt),
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusDropdown(BuildContext context) {
    final statuses = [
      AppConstants.ticketStatusPending,
      AppConstants.ticketStatusInProgress,
      AppConstants.ticketStatusDone,
    ];

    final labels = {
      AppConstants.ticketStatusPending: 'Menunggu',
      AppConstants.ticketStatusInProgress: 'Diproses',
      AppConstants.ticketStatusDone: 'Selesai',
    };

    final colors = {
      AppConstants.ticketStatusPending: AppColors.statusPending,
      AppConstants.ticketStatusInProgress: AppColors.statusInProgress,
      AppConstants.ticketStatusDone: AppColors.statusDone,
    };

    final bgs = {
      AppConstants.ticketStatusPending: AppColors.statusPendingBg,
      AppConstants.ticketStatusInProgress: AppColors.statusInProgressBg,
      AppConstants.ticketStatusDone: AppColors.statusDoneBg,
    };

    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          builder: (_) => SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: AppColors.grey300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Text('Update Status Tiket', style: AppTextStyles.h4),
                  const SizedBox(height: 16),
                  ...statuses.map((s) {
                    final isCurrentStatus = ticket.status == s;
                    return ListTile(
                      onTap: () {
                        Navigator.pop(context);
                        if (!isCurrentStatus) {
                          onStatusChange(ticket.id, s);
                        }
                      },
                      leading: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: bgs[s],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          _getStatusIcon(s),
                          color: colors[s],
                          size: 18,
                        ),
                      ),
                      title: Text(labels[s]!, style: AppTextStyles.labelLarge),
                      trailing: isCurrentStatus
                          ? Icon(Icons.check_circle_rounded, color: colors[s])
                          : null,
                    );
                  }),
                ],
              ),
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: bgs[ticket.status],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              labels[ticket.status] ?? ticket.status,
              style: AppTextStyles.labelSmall.copyWith(
                color: colors[ticket.status],
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.arrow_drop_down_rounded,
              size: 16,
              color: colors[ticket.status],
            ),
          ],
        ),
      ),
    );
  }

  void _viewImage(BuildContext context, String url) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: CachedNetworkImage(imageUrl: url, fit: BoxFit.contain),
        ),
      ),
    );
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case AppConstants.ticketStatusInProgress:
        return Icons.pending_rounded;
      case AppConstants.ticketStatusDone:
        return Icons.check_circle_rounded;
      default:
        return Icons.hourglass_empty_rounded;
    }
  }

  Color _getCategoryColor(String cat) {
    switch (cat) {
      case 'AIR':
        return const Color(0xFF0288D1);
      case 'LISTRIK':
        return const Color(0xFFF57F17);
      case 'MEBEL':
        return const Color(0xFF6D4C41);
      case 'STRUKTUR':
        return const Color(0xFF37474F);
      default:
        return AppColors.grey500;
    }
  }

  IconData _getCategoryIcon(String cat) {
    switch (cat) {
      case 'AIR':
        return Icons.water_drop_rounded;
      case 'LISTRIK':
        return Icons.bolt_rounded;
      case 'MEBEL':
        return Icons.weekend_rounded;
      case 'STRUKTUR':
        return Icons.foundation_rounded;
      default:
        return Icons.build_outlined;
    }
  }

  Map<String, String> get labels => {
    AppConstants.ticketStatusPending: 'Menunggu',
    AppConstants.ticketStatusInProgress: 'Diproses',
    AppConstants.ticketStatusDone: 'Selesai',
  };

  Map<String, Color> get bgs => {
    AppConstants.ticketStatusPending: AppColors.statusPendingBg,
    AppConstants.ticketStatusInProgress: AppColors.statusInProgressBg,
    AppConstants.ticketStatusDone: AppColors.statusDoneBg,
  };

  Map<String, Color> get colors => {
    AppConstants.ticketStatusPending: AppColors.statusPending,
    AppConstants.ticketStatusInProgress: AppColors.statusInProgress,
    AppConstants.ticketStatusDone: AppColors.statusDone,
  };
}
