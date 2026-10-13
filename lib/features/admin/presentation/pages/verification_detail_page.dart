import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/shimmer_loading.dart';
import '../providers/admin_provider.dart';

// ═══════════════════════════════════════════════════════════════════════════
// Halaman Detail Verifikasi Pengajuan Pemilik Kost
// ═══════════════════════════════════════════════════════════════════════════
class VerificationDetailPage extends StatelessWidget {
  final OwnerSubmission submission;

  const VerificationDetailPage({super.key, required this.submission});

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<AdminProvider>();

    return Scaffold(
      backgroundColor: AppColors.scaffold,
      appBar: AppBar(
        title: const Text('Detail Verifikasi'),
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
            // ── Status Badge ──────────────────────────────────────────────
            _StatusBanner(status: submission.status),
            const SizedBox(height: 20),

            // ── Informasi Pemohon ─────────────────────────────────────────
            _SectionCard(
              title: 'Data Pemohon',
              icon: Icons.person_outline_rounded,
              children: [
                _InfoRow(label: 'Nama', value: submission.name),
                _InfoRow(label: 'Email', value: submission.email),
                _InfoRow(label: 'No. HP', value: submission.phone),
                _InfoRow(label: 'No. KTP', value: submission.ktpNumber),
              ],
            ),
            const SizedBox(height: 16),

            // ── Informasi Properti ────────────────────────────────────────
            _SectionCard(
              title: 'Data Properti',
              icon: Icons.home_outlined,
              children: [
                _InfoRow(label: 'Nama Kost', value: submission.propertyName),
                _InfoRow(label: 'Alamat', value: submission.propertyAddress),
                _InfoRow(label: 'Tipe', value: submission.propertyType),
              ],
            ),
            const SizedBox(height: 16),

            // ── Dokumen ───────────────────────────────────────────────────
            _DocumentSection(
              ktpUrl: submission.ktpImageUrl,
              sertifikatUrl: submission.sertifikatImageUrl,
              fotoRumahUrl: submission.fotoRumahImageUrl,
            ),

            // ── Alasan Penolakan (jika ada) ───────────────────────────────
            if (submission.status == VerificationStatus.tolak &&
                submission.rejectionReason != null) ...[
              const SizedBox(height: 16),
              _RejectionCard(reason: submission.rejectionReason!),
            ],

            const SizedBox(height: 32),

            // ── Tombol aksi (hanya jika masih PROSES) ────────────────────
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
          'Setujui pengajuan dari ${submission.name}?',
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
              final ok = await prov.approveSubmission(submission.id);
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(ok ? 'Pengajuan berhasil disetujui' : 'Gagal'),
                  backgroundColor: ok ? AppColors.success : AppColors.error,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              );
              if (ok) Navigator.pop(context);
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
        title: const Text('Tolak Pengajuan'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tuliskan alasan penolakan agar pemohon dapat memperbaiki dokumennya.',
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
                style: AppTextStyles.bodyMedium,
                decoration: InputDecoration(
                  hintText: 'Contoh: Foto KTP kurang jelas, dokumen tidak sesuai...',
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
                    return 'Alasan penolakan wajib diisi.';
                  }
                  if (v.trim().length < 10) {
                    return 'Alasan minimal 10 karakter.';
                  }
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

              final ok = await prov.rejectSubmission(submission.id, reason);
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(ok ? 'Pengajuan berhasil ditolak' : 'Gagal'),
                  backgroundColor: ok ? AppColors.error : AppColors.grey500,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              );
              if (ok) Navigator.pop(context);
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
        label = 'Pengajuan Disetujui (ACC)';
        icon = Icons.verified_rounded;
        break;
      case VerificationStatus.tolak:
        bg = AppColors.errorLight;
        fg = AppColors.error;
        label = 'Pengajuan Ditolak';
        icon = Icons.cancel_rounded;
        break;
      default:
        bg = AppColors.warningLight;
        fg = AppColors.warning;
        label = 'Menunggu Proses';
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
          Text(
            label,
            style: AppTextStyles.labelLarge.copyWith(color: fg),
          ),
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
            children: children.asMap().entries.map((e) {
              return Column(
                children: [
                  e.value,
                  if (e.key < children.length - 1)
                    const Divider(height: 1, indent: 16),
                ],
              );
            }).toList(),
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
            width: 110,
            child: Text(
              label,
              style: AppTextStyles.caption.copyWith(color: AppColors.grey500),
            ),
          ),
          Expanded(
            child: Text(value, style: AppTextStyles.labelMedium),
          ),
        ],
      ),
    );
  }
}

class _DocumentSection extends StatelessWidget {
  final String ktpUrl;
  final String sertifikatUrl;
  final String fotoRumahUrl;

  const _DocumentSection({
    required this.ktpUrl,
    required this.sertifikatUrl,
    required this.fotoRumahUrl,
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
        _DocCard(title: 'Sertifikat / Dokumen Properti', url: sertifikatUrl),
        const SizedBox(height: 10),
        _DocCard(title: 'Foto Properti (Kost)', url: fotoRumahUrl),
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
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.broken_image_outlined,
                          color: AppColors.grey400,
                          size: 36,
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Gagal memuat gambar',
                          style: TextStyle(color: AppColors.grey400),
                        ),
                      ],
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
        border: Border.all(
          color: AppColors.error.withValues(alpha: 0.3),
        ),
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
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.error,
            ),
          ),
        ],
      ),
    );
  }
}
