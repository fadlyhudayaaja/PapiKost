import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/shimmer_loading.dart';
import '../providers/admin_provider.dart';

// ═══════════════════════════════════════════════════════════════════════════
// Halaman Verifikasi Berkas Penyewa — Admin
// ═══════════════════════════════════════════════════════════════════════════
class RenterVerificationPage extends StatefulWidget {
  const RenterVerificationPage({super.key});

  @override
  State<RenterVerificationPage> createState() => _RenterVerificationPageState();
}

class _RenterVerificationPageState extends State<RenterVerificationPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().loadRenterSubmissions();
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

    final proses = prov.renterSubmissions
        .where((s) => s.status == VerificationStatus.proses)
        .toList();
    final acc = prov.renterSubmissions
        .where((s) => s.status == VerificationStatus.acc)
        .toList();
    final tolak = prov.renterSubmissions
        .where((s) => s.status == VerificationStatus.tolak)
        .toList();

    return Scaffold(
      backgroundColor: AppColors.scaffold,
      appBar: AppBar(
        title: const Text('Verifikasi Berkas Penyewa'),
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
                  const SizedBox(width: 5),
                  _CountBadge(count: proses.length, color: AppColors.warning),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('ACC'),
                  const SizedBox(width: 5),
                  _CountBadge(count: acc.length, color: AppColors.success),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Tolak'),
                  const SizedBox(width: 5),
                  _CountBadge(count: tolak.length, color: AppColors.error),
                ],
              ),
            ),
          ],
        ),
      ),
      body: prov.isLoadingRenterSubmissions
          ? ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: 4,
              itemBuilder: (_, i) => const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: ListItemShimmer(),
              ),
            )
          : TabBarView(
              controller: _tabCtrl,
              children: [
                _RenterList(
                  submissions: proses,
                  emptyTitle: 'Tidak Ada Pengajuan',
                  emptySubtitle: 'Semua berkas penyewa sudah diproses',
                  onRefresh: () => prov.loadRenterSubmissions(),
                ),
                _RenterList(
                  submissions: acc,
                  emptyTitle: 'Belum Ada yang Di-ACC',
                  emptySubtitle: 'Belum ada berkas penyewa yang disetujui',
                  onRefresh: () => prov.loadRenterSubmissions(),
                ),
                _RenterList(
                  submissions: tolak,
                  emptyTitle: 'Tidak Ada Penolakan',
                  emptySubtitle: 'Belum ada berkas penyewa yang ditolak',
                  onRefresh: () => prov.loadRenterSubmissions(),
                ),
              ],
            ),
    );
  }
}

// ── List pengajuan ────────────────────────────────────────────────────────────
class _RenterList extends StatelessWidget {
  final List<RenterSubmission> submissions;
  final String emptyTitle;
  final String emptySubtitle;
  final Future<void> Function() onRefresh;

  const _RenterList({
    required this.submissions,
    required this.emptyTitle,
    required this.emptySubtitle,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    if (submissions.isEmpty) {
      return EmptyState(
        icon: Icons.badge_outlined,
        title: emptyTitle,
        subtitle: emptySubtitle,
      );
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: onRefresh,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: submissions.length,
        itemBuilder: (_, i) => _RenterCard(submission: submissions[i]),
      ),
    );
  }
}

// ── Card pengajuan renter ─────────────────────────────────────────────────────
class _RenterCard extends StatelessWidget {
  final RenterSubmission submission;
  const _RenterCard({required this.submission});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChangeNotifierProvider.value(
            value: context.read<AdminProvider>(),
            child: RenterVerificationDetailPage(submission: submission),
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
              CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                child: Text(
                  submission.name.isNotEmpty
                      ? submission.name[0].toUpperCase()
                      : 'P',
                  style: AppTextStyles.h4.copyWith(color: AppColors.primary),
                ),
              ),
              const SizedBox(width: 12),
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
                            '${submission.kostName} · ${submission.occupation}',
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

// ═══════════════════════════════════════════════════════════════════════════
// Halaman Detail Verifikasi Berkas Penyewa — Admin
// ═══════════════════════════════════════════════════════════════════════════
class RenterVerificationDetailPage extends StatelessWidget {
  final RenterSubmission submission;
  const RenterVerificationDetailPage({super.key, required this.submission});

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<AdminProvider>();

    return Scaffold(
      backgroundColor: AppColors.scaffold,
      appBar: AppBar(
        title: const Text('Detail Berkas Penyewa'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _StatusBanner(status: submission.status),
            const SizedBox(height: 20),

            _SectionCard(
              title: 'Data Penyewa',
              icon: Icons.person_outline_rounded,
              children: [
                _InfoRow(label: 'Nama', value: submission.name),
                _InfoRow(label: 'Email', value: submission.email),
                _InfoRow(label: 'No. HP', value: submission.phone),
                _InfoRow(label: 'No. KTP', value: submission.ktpNumber),
                _InfoRow(label: 'Pekerjaan', value: submission.occupation),
              ],
            ),
            const SizedBox(height: 16),

            _SectionCard(
              title: 'Kontak Darurat',
              icon: Icons.contact_phone_outlined,
              children: [
                _InfoRow(label: 'Nama', value: submission.emergencyContact),
                _InfoRow(label: 'No. HP', value: submission.emergencyPhone),
              ],
            ),
            const SizedBox(height: 16),

            _SectionCard(
              title: 'Informasi Kost',
              icon: Icons.home_outlined,
              children: [
                _InfoRow(label: 'Kost Dituju', value: submission.kostName),
                _InfoRow(label: 'Pemilik', value: submission.ownerName),
              ],
            ),
            const SizedBox(height: 16),

            // Dokumen
            _DocumentSection(
              ktpUrl: submission.ktpImageUrl,
              selfieUrl: submission.fotoSelfieUrl,
              suratUrl: submission.suratKeteranganUrl,
            ),

            if (submission.status == VerificationStatus.tolak &&
                submission.rejectionReason != null) ...[
              const SizedBox(height: 16),
              _RejectionCard(reason: submission.rejectionReason!),
            ],

            const SizedBox(height: 32),

            if (submission.status == VerificationStatus.proses) ...[
              Row(
                children: [
                  Expanded(
                    child: AppButton(
                      text: 'Tolak',
                      icon: Icons.close_rounded,
                      isOutlined: true,
                      textColor: AppColors.error,
                      backgroundColor: AppColors.white,
                      isLoading: prov.isSubmitting,
                      onPressed: prov.isSubmitting
                          ? null
                          : () => _showRejectDialog(context, prov),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppButton(
                      text: 'ACC',
                      icon: Icons.verified_rounded,
                      backgroundColor: AppColors.success,
                      isLoading: prov.isSubmitting,
                      onPressed: prov.isSubmitting
                          ? null
                          : () => _approve(context, prov),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  'Keputusan tidak dapat diubah setelah dikonfirmasi.',
                  style: AppTextStyles.caption,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  void _approve(BuildContext context, AdminProvider prov) {
    showDialog(
      context: context,
      builder: (dCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon: Container(
          padding: const EdgeInsets.all(12),
          decoration: const BoxDecoration(
            color: AppColors.successLight,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.verified_rounded,
            color: AppColors.success,
            size: 28,
          ),
        ),
        title: const Text('Konfirmasi Verifikasi'),
        content: Text(
          'Setujui berkas dari ${submission.name}?',
          textAlign: TextAlign.center,
          style: AppTextStyles.bodyMedium,
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(dCtx),
            child: const Text('Batal'),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dCtx);
              final ok = await prov.approveRenterSubmission(submission.id);
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(ok ? 'Berkas berhasil disetujui' : 'Gagal'),
                  backgroundColor: ok ? AppColors.success : AppColors.error,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              );
              if (ok && context.mounted) Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
            child: const Text('ACC Sekarang'),
          ),
        ],
      ),
    );
  }

  void _showRejectDialog(BuildContext context, AdminProvider prov) {
    final reasonCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon: Container(
          padding: const EdgeInsets.all(12),
          decoration: const BoxDecoration(
            color: AppColors.errorLight,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.cancel_outlined,
            color: AppColors.error,
            size: 28,
          ),
        ),
        title: const Text('Tolak Berkas'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Tuliskan alasan penolakan agar penyewa dapat melengkapi berkasnya.',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.grey600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: reasonCtrl,
                maxLines: 4,
                maxLength: 300,
                decoration: InputDecoration(
                  hintText: 'Contoh: Foto KTP buram, selfie tidak sesuai...',
                  hintStyle: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.grey400,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.primary),
                  ),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Alasan wajib diisi';
                  }
                  if (v.trim().length < 10) return 'Minimal 10 karakter';
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          OutlinedButton(
            onPressed: () {
              Navigator.pop(dCtx);
              reasonCtrl.dispose();
            },
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              final reason = reasonCtrl.text.trim();
              Navigator.pop(dCtx);
              reasonCtrl.dispose();
              final ok = await prov.rejectRenterSubmission(
                submission.id,
                reason,
              );
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(ok ? 'Berkas berhasil ditolak' : 'Gagal'),
                  backgroundColor: ok ? AppColors.error : AppColors.grey500,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              );
              if (ok && context.mounted) Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Tolak Sekarang'),
          ),
        ],
      ),
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _DocumentSection extends StatelessWidget {
  final String ktpUrl;
  final String selfieUrl;
  final String? suratUrl;

  const _DocumentSection({
    required this.ktpUrl,
    required this.selfieUrl,
    this.suratUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.folder_open_rounded,
              size: 18,
              color: AppColors.primary,
            ),
            const SizedBox(width: 8),
            Text('Dokumen & Foto', style: AppTextStyles.h4),
          ],
        ),
        const SizedBox(height: 10),
        _DocCard(title: 'Foto KTP', url: ktpUrl),
        const SizedBox(height: 10),
        _DocCard(title: 'Foto Selfie dengan KTP', url: selfieUrl),
        if (suratUrl != null) ...[
          const SizedBox(height: 10),
          _DocCard(
            title: 'Surat Keterangan (Mahasiswa / Karyawan)',
            url: suratUrl!,
          ),
        ],
      ],
    );
  }
}

class _DocCard extends StatelessWidget {
  final String title;
  final String url;
  const _DocCard({required this.title, required this.url});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
            child: Row(
              children: [
                const Icon(
                  Icons.image_outlined,
                  size: 16,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 6),
                Text(title, style: AppTextStyles.labelMedium),
              ],
            ),
          ),
          ClipRRect(
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(12),
            ),
            child: GestureDetector(
              onTap: () => _viewFullImage(context, url),
              child: CachedNetworkImage(
                imageUrl: url,
                width: double.infinity,
                height: 180,
                fit: BoxFit.cover,
                placeholder: (_, __) => const ShimmerBox(height: 180),
                errorWidget: (_, __, ___) => Container(
                  height: 180,
                  color: AppColors.grey100,
                  child: const Center(
                    child: Icon(
                      Icons.broken_image_outlined,
                      color: AppColors.grey400,
                      size: 36,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _viewFullImage(BuildContext context, String url) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: CachedNetworkImage(imageUrl: url, fit: BoxFit.contain),
        ),
      ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  final VerificationStatus status;
  const _StatusBanner({required this.status});

  @override
  Widget build(BuildContext context) {
    Color bg, fg;
    String label;
    IconData icon;
    switch (status) {
      case VerificationStatus.acc:
        bg = AppColors.successLight;
        fg = AppColors.success;
        label = 'Berkas Disetujui (ACC)';
        icon = Icons.verified_rounded;
        break;
      case VerificationStatus.tolak:
        bg = AppColors.errorLight;
        fg = AppColors.error;
        label = 'Berkas Ditolak';
        icon = Icons.cancel_rounded;
        break;
      default:
        bg = AppColors.warningLight;
        fg = AppColors.warning;
        label = 'Menunggu Verifikasi';
        icon = Icons.hourglass_empty_rounded;
    }
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: fg, size: 24),
          const SizedBox(width: 12),
          Text(label, style: AppTextStyles.labelLarge.copyWith(color: fg)),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;
  const _SectionCard({
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: AppColors.primary),
            const SizedBox(width: 8),
            Text(title, style: AppTextStyles.h4),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            children: children
                .asMap()
                .entries
                .map(
                  (e) => Column(
                    children: [
                      e.value,
                      if (e.key < children.length - 1)
                        const Divider(height: 1, indent: 16),
                    ],
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: AppTextStyles.caption.copyWith(color: AppColors.grey500),
            ),
          ),
          Expanded(child: Text(value, style: AppTextStyles.labelMedium)),
        ],
      ),
    );
  }
}

class _RejectionCard extends StatelessWidget {
  final String reason;
  const _RejectionCard({required this.reason});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.errorLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.info_outline_rounded,
                color: AppColors.error,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                'Alasan Penolakan',
                style: AppTextStyles.labelLarge.copyWith(
                  color: AppColors.error,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            reason,
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.error),
          ),
        ],
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
      child: Text(label, style: AppTextStyles.labelSmall.copyWith(color: fg)),
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
