import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/verification_document_image.dart';
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
    final latest = prov.submissions.where(
      (item) => item.id == this.submission.id,
    );
    if (latest.isEmpty || prov.state == AdminLoadState.error) {
      return Scaffold(
        appBar: AppBar(title: const Text('Detail Verifikasi')),
        body: Center(
          child: Text(
            prov.error.isEmpty
                ? 'Pengajuan tidak tersedia. Kembali dan muat ulang daftar.'
                : prov.error,
          ),
        ),
      );
    }
    final submission = latest.first;

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
                if (!submission.isKostSubmission) ...[
                  _InfoRow(label: 'Email', value: submission.email),
                  _InfoRow(label: 'No. HP', value: submission.phone),
                  _InfoRow(label: 'No. KTP', value: submission.ktpNumber),
                ],
                _InfoRow(
                  label: 'Diajukan',
                  value: DateFormat(
                    'dd MMM yyyy HH:mm',
                    'id_ID',
                  ).format(submission.submittedAt),
                ),
                if (submission.reviewedAt != null)
                  _InfoRow(
                    label: 'Diproses',
                    value: DateFormat(
                      'dd MMM yyyy HH:mm',
                      'id_ID',
                    ).format(submission.reviewedAt!),
                  ),
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
                if (submission.kost case final kost?) ...[
                  _InfoRow(label: 'Kota', value: kost.city),
                  _InfoRow(
                    label: 'Harga / bulan',
                    value: NumberFormat.currency(
                      locale: 'id_ID',
                      symbol: 'Rp ',
                      decimalDigits: 0,
                    ).format(kost.pricePerMonth),
                  ),
                  _InfoRow(label: 'Jumlah kamar', value: '${kost.totalRooms}'),
                  _InfoRow(
                    label: 'Fasilitas',
                    value: kost.facilities.join(', '),
                  ),
                  _InfoRow(
                    label: 'Patungan',
                    value: kost.isSplitBillAvailable ? 'Ya' : 'Tidak',
                  ),
                  if (kost.description?.isNotEmpty == true)
                    _InfoRow(label: 'Deskripsi', value: kost.description!),
                ],
              ],
            ),
            const SizedBox(height: 16),

            // ── Dokumen ───────────────────────────────────────────────────
            if (submission.isKostSubmission)
              if (submission.fotoRumahImageUrl.isNotEmpty)
                VerificationDocumentImage(
                  reference: submission.fotoRumahImageUrl,
                  height: 220,
                )
              else
                const Text('Foto kamar belum ditambahkan.')
            else
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
                  content: Text(
                    ok ? 'Pengajuan berhasil disetujui' : prov.error,
                  ),
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

  Future<void> _showRejectDialog(
    BuildContext context,
    AdminProvider prov,
  ) async {
    final reason = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _RejectDialog(),
    );
    if (reason == null || !context.mounted) return;
    final ok = await prov.rejectSubmission(submission.id, reason);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? 'Pengajuan berhasil ditolak' : prov.error),
        backgroundColor: ok ? AppColors.error : AppColors.grey500,
        behavior: SnackBarBehavior.floating,
      ),
    );
    if (ok) Navigator.pop(context);
  }
}

class _RejectDialog extends StatefulWidget {
  const _RejectDialog();

  @override
  State<_RejectDialog> createState() => _RejectDialogState();
}

class _RejectDialogState extends State<_RejectDialog> {
  final _reason = TextEditingController();
  final _form = GlobalKey<FormState>();

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      icon: const Icon(Icons.cancel_outlined, color: AppColors.error, size: 32),
      title: const Text('Tolak Pengajuan'),
      content: Form(
        key: _form,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Tuliskan alasan penolakan agar pemohon dapat memperbaiki dokumennya.',
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _reason,
              maxLines: 4,
              maxLength: 300,
              decoration: const InputDecoration(
                hintText:
                    'Contoh: Foto KTP kurang jelas, dokumen tidak sesuai...',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                final reason = value?.trim() ?? '';
                if (reason.isEmpty) return 'Alasan penolakan wajib diisi.';
                if (reason.length < 10) return 'Alasan minimal 10 karakter.';
                if (reason.length > 300) return 'Alasan maksimal 300 karakter.';
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        OutlinedButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_form.currentState!.validate()) {
              Navigator.pop(context, _reason.text.trim());
            }
          },
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
          child: const Text('Tolak Sekarang'),
        ),
      ],
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
          Expanded(child: Text(value, style: AppTextStyles.labelMedium)),
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
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                const Icon(
                  Icons.image_outlined,
                  size: 18,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 8),
                Expanded(child: Text(title, style: AppTextStyles.labelMedium)),
                const Icon(Icons.zoom_in_rounded, size: 20),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => _viewFullImage(context),
            child: VerificationDocumentImage(reference: url, height: 180),
          ),
        ],
      ),
    );
  }

  void _viewFullImage(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog(
        insetPadding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const SizedBox(width: 16),
                Expanded(child: Text(title)),
                IconButton(
                  tooltip: 'Tutup',
                  onPressed: () => Navigator.pop(dialogContext),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            InteractiveViewer(
              minScale: 0.7,
              maxScale: 5,
              child: VerificationDocumentImage(
                reference: url,
                height: MediaQuery.sizeOf(context).height * 0.65,
              ),
            ),
          ],
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
