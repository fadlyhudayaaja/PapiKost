import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/shimmer_loading.dart';
import '../../../../data/models/ticket_model.dart';
import '../providers/ticket_provider.dart';

class TicketListPage extends StatefulWidget {
  const TicketListPage({super.key});

  @override
  State<TicketListPage> createState() => _TicketListPageState();
}

class _TicketListPageState extends State<TicketListPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TicketProvider>().fetchMyTickets();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TicketProvider>();

    return Scaffold(
      backgroundColor: AppColors.scaffold,
      appBar: AppBar(
        title: const Text('Tiket Kerusakan'),
        automaticallyImplyLeading: false,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.createTicketRenter),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Buat Tiket'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () => provider.fetchMyTickets(),
        child: provider.isLoading
            ? _buildSkeleton()
            : provider.tickets.isEmpty
            ? _buildEmpty()
            : _buildList(provider.tickets),
      ),
    );
  }

  Widget _buildSkeleton() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 4,
      itemBuilder: (_, __) => const ListItemShimmer(),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long_outlined, size: 80, color: AppColors.grey300),
          const SizedBox(height: 16),
          Text('Belum ada tiket kerusakan', style: AppTextStyles.h4),
          const SizedBox(height: 8),
          Text(
            'Buat tiket jika ada fasilitas yang rusak',
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.grey500),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => context.push(AppRoutes.createTicketRenter),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Buat Tiket Baru'),
          ),
        ],
      ),
    );
  }

  Widget _buildList(List<TicketModel> tickets) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: tickets.length,
      itemBuilder: (context, i) => _TicketCard(ticket: tickets[i]),
    );
  }
}

class _TicketCard extends StatelessWidget {
  final TicketModel ticket;

  const _TicketCard({required this.ticket});

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('dd MMM yyyy', 'id_ID');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
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
                      Text(
                        ticket.title,
                        style: AppTextStyles.labelLarge,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(ticket.kostName, style: AppTextStyles.bodySmall),
                    ],
                  ),
                ),
                _StatusBadge(status: ticket.status),
              ],
            ),
          ),

          // Description
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
            child: Text(
              ticket.description,
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.grey600),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // Owner Note (if any)
          if (ticket.ownerNote != null && ticket.ownerNote!.isNotEmpty) ...[
            Container(
              margin: const EdgeInsets.fromLTRB(14, 0, 14, 12),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.infoLight,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.info.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    size: 14,
                    color: AppColors.info,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Catatan Pemilik: ${ticket.ownerNote}',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.info,
                      ),
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
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.grey100,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    _getCategoryLabel(ticket.category),
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.grey600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
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

  String _getCategoryLabel(String cat) {
    for (final c in TicketCategory.values) {
      if (c.value == cat) return c.label;
    }
    return cat;
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color bg, fg;
    String label;
    IconData icon;

    switch (status) {
      case AppConstants.ticketStatusInProgress:
        bg = AppColors.statusInProgressBg;
        fg = AppColors.statusInProgress;
        label = 'Diproses';
        icon = Icons.pending_rounded;
        break;
      case AppConstants.ticketStatusDone:
        bg = AppColors.statusDoneBg;
        fg = AppColors.statusDone;
        label = 'Selesai';
        icon = Icons.check_circle_rounded;
        break;
      default:
        bg = AppColors.statusPendingBg;
        fg = AppColors.statusPending;
        label = 'Menunggu';
        icon = Icons.hourglass_empty_rounded;
    }

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
