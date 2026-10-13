import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/shimmer_loading.dart';
import '../providers/admin_provider.dart';
import 'verification_detail_page.dart';

class OwnerVerificationPage extends StatefulWidget {
  const OwnerVerificationPage({super.key});

  @override
  State<OwnerVerificationPage> createState() => _OwnerVerificationPageState();
}

class _OwnerVerificationPageState extends State<OwnerVerificationPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().loadSubmissions();
    });
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<AdminProvider>();

    return Scaffold(
      backgroundColor: AppColors.scaffold,
      appBar: AppBar(
        title: const Text('Verifikasi Pemilik Kost'),
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.grey500,
          tabs: [
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Proses'),
                  const SizedBox(width: 6),
                  _CountBadge(
                    count: prov.submissions
                        .where((s) => s.status == VerificationStatus.proses)
                        .length,
                    color: AppColors.warning,
                  ),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('ACC'),
                  const SizedBox(width: 6),
                  _CountBadge(
                    count: prov.submissions
                        .where((s) => s.status == VerificationStatus.acc)
                        .length,
                    color: AppColors.success,
                  ),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Tolak'),
                  const SizedBox(width: 6),
                  _CountBadge(
                    count: prov.submissions
                        .where((s) => s.status == VerificationStatus.tolak)
                        .length,
                    color: AppColors.error,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: prov.isLoading
          ? ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: 3,
              itemBuilder: (_, __) => const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: ListItemShimmer(),
              ),
            )
          : TabBarView(
              controller: _tabCtrl,
              children: [
                _SubmissionList(
                  submissions: prov.submissions
                      .where((s) => s.status == VerificationStatus.proses)
                      .toList(),
                  emptyTitle: 'Tidak Ada Pengajuan',
                  emptySubtitle: 'Semua pengajuan sudah diproses',
                ),
                _SubmissionList(
                  submissions: prov.submissions
                      .where((s) => s.status == VerificationStatus.acc)
                      .toList(),
                  emptyTitle: 'Belum Ada yang ACC',
                  emptySubtitle: 'Belum ada pengajuan yang disetujui',
                ),
                _SubmissionList(
                  submissions: prov.submissions
                      .where((s) => s.status == VerificationStatus.tolak)
                      .toList(),
                  emptyTitle: 'Tidak Ada Penolakan',
                  emptySubtitle: 'Belum ada pengajuan yang ditolak',
                ),
              ],
            ),
    );
  }
}

// ── List pengajuan ────────────────────────────────────────────────────────────
class _SubmissionList extends StatelessWidget {
  final List<OwnerSubmission> submissions;
  final String emptyTitle;
  final String emptySubtitle;

  const _SubmissionList({
    required this.submissions,
    required this.emptyTitle,
    required this.emptySubtitle,
  });

  @override
  Widget build(BuildContext context) {
    if (submissions.isEmpty) {
      return EmptyState(
        icon: Icons.verified_user_outlined,
        title: emptyTitle,
        subtitle: emptySubtitle,
      );
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () => context.read<AdminProvider>().loadSubmissions(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: submissions.length,
        itemBuilder: (_, i) => _SubmissionCard(submission: submissions[i]),
      ),
    );
  }
}

// ── Card pengajuan ────────────────────────────────────────────────────────────
class _SubmissionCard extends StatelessWidget {
  final OwnerSubmission submission;
  const _SubmissionCard({required this.submission});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChangeNotifierProvider.value(
            value: context.read<AdminProvider>(),
            child: VerificationDetailPage(submission: submission),
          ),
        ),
      ),
      child: Container(
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
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // Avatar
              CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                child: Text(
                  submission.name.isNotEmpty
                      ? submission.name[0].toUpperCase()
                      : 'O',
                  style: AppTextStyles.h4.copyWith(color: AppColors.primary),
                ),
              ),
              const SizedBox(width: 12),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(submission.name, style: AppTextStyles.labelLarge),
                    Text(submission.email, style: AppTextStyles.bodySmall),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.home_outlined,
                          size: 13,
                          color: AppColors.grey400,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            submission.propertyName,
                            style: AppTextStyles.caption,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _StatusBadge(status: submission.status),
                  const SizedBox(height: 6),
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 14,
                    color: AppColors.grey400,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final VerificationStatus status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color bg, fg;
    String label;

    switch (status) {
      case VerificationStatus.acc:
        bg = AppColors.successLight;
        fg = AppColors.success;
        label = 'ACC';
        break;
      case VerificationStatus.tolak:
        bg = AppColors.errorLight;
        fg = AppColors.error;
        label = 'TOLAK';
        break;
      default:
        bg = AppColors.warningLight;
        fg = AppColors.warning;
        label = 'PROSES';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: AppTextStyles.labelSmall.copyWith(color: fg),
      ),
    );
  }
}

class _CountBadge extends StatelessWidget {
  final int count;
  final Color color;
  const _CountBadge({required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    if (count == 0) return const SizedBox.shrink();
    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Center(
        child: Text(
          '$count',
          style: TextStyle(
            color: color,
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
