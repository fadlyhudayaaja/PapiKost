import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/shimmer_loading.dart';
import '../../../../data/models/ticket_model.dart';
import '../../../../data/repositories/mock_repository.dart';
import '../providers/renter_ticket_provider.dart';

class RenterTicketListPage extends StatefulWidget {
  const RenterTicketListPage({super.key});

  @override
  State<RenterTicketListPage> createState() => _RenterTicketListPageState();
}

class _RenterTicketListPageState extends State<RenterTicketListPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RenterTicketProvider>().loadTickets();
    });
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<RenterTicketProvider>();

    return Scaffold(
      backgroundColor: AppColors.scaffold,
      appBar: AppBar(
        title: const Text('Laporan Kerusakan'),
        automaticallyImplyLeading: false,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.createTicketRenter),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Buat Laporan'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () => prov.loadTickets(),
        child: _buildBody(prov),
      ),
    );
  }

  Widget _buildBody(RenterTicketProvider prov) {
    switch (prov.listState) {
      // ── State 1: Loading ──────────────────────────────────────────────────
      case ViewState.loading:
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: 4,
          itemBuilder: (_, __) => const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: ListItemShimmer(),
          ),
        );

      // ── State 2: Empty ────────────────────────────────────────────────────
      case ViewState.empty:
        return EmptyState(
          icon: Icons.receipt_long_outlined,
          title: 'Belum Ada Laporan',
          subtitle: 'Tap tombol di bawah untuk membuat laporan kerusakan.',
          buttonLabel: 'Buat Laporan Pertama',
          onButtonTap: () => context.push(AppRoutes.createTicketRenter),
        );

      // ── State 3: Error ────────────────────────────────────────────────────
      case ViewState.error:
        return ErrorState(
          message: prov.listError,
          onRetry: () => prov.loadTickets(),
        );

      // ── State 4: Success ──────────────────────────────────────────────────
      case ViewState.success:
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          itemCount: prov.tickets.length,
          itemBuilder: (ctx, i) {
            final ticket = prov.tickets[i];
            return _TicketCard(
              ticket: ticket,
              onTap: () =>
                  context.push(AppRoutes.ticketDetailRenter, extra: ticket.id),
              onEdit: () =>
                  context.push(AppRoutes.editTicketRenter, extra: ticket),
              onDelete: () => _confirmDelete(ticket),
            );
          },
        );
    }
  }

  // Dialog konfirmasi hapus (Destructive Action)
  void _confirmDelete(TicketModel ticket) {
    showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.errorLight,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.delete_outline_rounded,
            color: AppColors.error,
            size: 28,
          ),
        ),
        title: const Text('Hapus Laporan?'),
        content: Text(
          'Laporan "${ticket.title}" akan dihapus secara permanen.\n\nTindakan ini tidak dapat dibatalkan.',
          textAlign: TextAlign.center,
          style: AppTextStyles.bodyMedium,
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Batal'),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogCtx);
              await _executeDelete(ticket.id);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  Future<void> _executeDelete(int id) async {
    final prov = context.read<RenterTicketProvider>();
    try {
      await prov.deleteTicket(id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle_rounded, color: AppColors.white),
              SizedBox(width: 10),
              Text('Laporan berhasil dihapus'),
            ],
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Ticket Card Widget
// ─────────────────────────────────────────────────────────────────────────────
class _TicketCard extends StatelessWidget {
  final TicketModel ticket;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _TicketCard({
    required this.ticket,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  static final _dateFmt = DateFormat('dd MMM yyyy', 'id_ID');

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ────────────────────────────────────────────────────
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: _categoryColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(_categoryIcon, color: _categoryColor, size: 22),
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
                        Text(_categoryLabel, style: AppTextStyles.bodySmall),
                      ],
                    ),
                  ),
                  _StatusChip(status: ticket.status),
                ],
              ),

              const SizedBox(height: 10),

              // ── Description ───────────────────────────────────────────────
              Text(
                ticket.description,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.grey600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 10),

              // ── Footer ────────────────────────────────────────────────────
              Row(
                children: [
                  const Icon(
                    Icons.access_time_rounded,
                    size: 13,
                    color: AppColors.grey400,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _dateFmt.format(ticket.createdAt),
                    style: AppTextStyles.caption,
                  ),
                  const Spacer(),
                  // Edit hanya jika belum selesai
                  if (ticket.status != AppConstants.ticketStatusDone)
                    IconButton(
                      icon: const Icon(
                        Icons.edit_outlined,
                        size: 18,
                        color: AppColors.grey500,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                      padding: EdgeInsets.zero,
                      tooltip: 'Edit',
                      onPressed: onEdit,
                    ),
                  IconButton(
                    icon: const Icon(
                      Icons.delete_outline_rounded,
                      size: 18,
                      color: AppColors.error,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                    padding: EdgeInsets.zero,
                    tooltip: 'Hapus',
                    onPressed: onDelete,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String get _categoryLabel =>
      MockRepository.categoryLabels[ticket.category] ?? ticket.category;

  Color get _categoryColor {
    switch (ticket.category) {
      case 'LISTRIK':
        return const Color(0xFFF57F17);
      case 'AIR':
        return const Color(0xFF0288D1);
      case 'MEBEL':
        return const Color(0xFF6D4C41);
      case 'STRUKTUR':
        return const Color(0xFF37474F);
      default:
        return AppColors.grey500;
    }
  }

  IconData get _categoryIcon {
    switch (ticket.category) {
      case 'LISTRIK':
        return Icons.bolt_rounded;
      case 'AIR':
        return Icons.water_drop_rounded;
      case 'MEBEL':
        return Icons.weekend_rounded;
      case 'STRUKTUR':
        return Icons.foundation_rounded;
      default:
        return Icons.build_outlined;
    }
  }
}

class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip({required this.status});

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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label, style: AppTextStyles.labelSmall.copyWith(color: fg)),
    );
  }
}
