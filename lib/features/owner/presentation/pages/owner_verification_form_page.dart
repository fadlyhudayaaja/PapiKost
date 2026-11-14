import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/verification_document_image.dart';
import '../../../../data/models/verification_document.dart';
import '../../../../core/utils/image_url.dart';
import '../../../../data/models/owner_submission.dart';
import '../../../../data/repositories/owner_verification_repository.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class OwnerVerificationFormPage extends StatefulWidget {
  const OwnerVerificationFormPage({super.key});

  @override
  State<OwnerVerificationFormPage> createState() =>
      _OwnerVerificationFormPageState();
}

class _OwnerVerificationFormPageState extends State<OwnerVerificationFormPage> {
  late OwnerVerificationRepository _repository;
  Stream<OwnerSubmission?>? _stream;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_stream != null) return;
    _repository = context.read<OwnerVerificationRepository>();
    final uid = context.read<AuthProvider>().currentUser!.id;
    _stream = _repository.watchForOwner(uid);
  }

  void _retry() {
    setState(() {
      _stream = _repository.watchForOwner(
        context.read<AuthProvider>().currentUser!.id,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Verifikasi Pemilik')),
      backgroundColor: AppColors.scaffold,
      body: StreamBuilder<OwnerSubmission?>(
        stream: _stream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      OwnerVerificationRepository.errorMessage(snapshot.error!),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _retry,
                      child: const Text('Coba Lagi'),
                    ),
                  ],
                ),
              ),
            );
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final submission = snapshot.data;
          final verified =
              submission?.status == VerificationStatus.acc ||
              context.watch<AuthProvider>().currentUser!.isVerified;
          if (verified || submission?.status == VerificationStatus.proses) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      verified
                          ? Icons.verified_rounded
                          : Icons.hourglass_top_rounded,
                      size: 64,
                      color: verified ? AppColors.success : AppColors.warning,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      verified
                          ? 'Pemilik sudah terverifikasi'
                          : 'Pengajuan sedang diperiksa admin',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      verified
                          ? 'Pengajuan Anda telah disetujui.'
                          : 'Data dan dokumen berhasil dikirim. Status akan diperbarui setelah admin mengambil keputusan.',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }
          return _SubmissionForm(
            key: ValueKey(submission?.submittedAt),
            previous: submission,
            repository: _repository,
          );
        },
      ),
    );
  }
}

class _SubmissionForm extends StatefulWidget {
  const _SubmissionForm({super.key, this.previous, required this.repository});
  final OwnerSubmission? previous;
  final OwnerVerificationRepository repository;

  @override
  State<_SubmissionForm> createState() => _SubmissionFormState();
}

class _SubmissionFormState extends State<_SubmissionForm> {
  final _form = GlobalKey<FormState>();
  late final List<TextEditingController> _fields;
  late final Map<VerificationDocumentKind, TextEditingController> _urls;
  String _type = 'CAMPUR';
  bool _sending = false;
  bool get _busy => _sending;
  String? _error;

  @override
  void initState() {
    super.initState();
    final previous = widget.previous;
    _type = previous?.propertyType ?? 'CAMPUR';
    _fields = [
      previous?.ktpNumber,
      previous?.propertyName,
      previous?.propertyAddress,
    ].map((text) => TextEditingController(text: text ?? '')).toList();
    _urls = {
      VerificationDocumentKind.ktp: TextEditingController(
        text: previous?.ktpImageUrl ?? '',
      ),
      VerificationDocumentKind.certificate: TextEditingController(
        text: previous?.sertifikatImageUrl ?? '',
      ),
      VerificationDocumentKind.property: TextEditingController(
        text: previous?.fotoRumahImageUrl ?? '',
      ),
    };
  }

  @override
  void dispose() {
    for (final controller in _fields) {
      controller.dispose();
    }
    for (final controller in _urls.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy || !_form.currentState!.validate()) return;
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      await widget.repository.submit(
        ktpNumber: _fields[0].text.trim(),
        propertyName: _fields[1].text.trim(),
        propertyAddress: _fields[2].text.trim(),
        propertyType: _type,
        ktpImageUrl: ImageUrl.normalizeInput(
          _urls[VerificationDocumentKind.ktp]!.text,
        ),
        sertifikatImageUrl: ImageUrl.normalizeInput(
          _urls[VerificationDocumentKind.certificate]!.text,
        ),
        fotoRumahImageUrl: ImageUrl.normalizeInput(
          _urls[VerificationDocumentKind.property]!.text,
        ),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pengajuan berhasil dikirim.')),
      );
    } catch (error) {
      if (mounted) {
        setState(() {
          _error = OwnerVerificationRepository.errorMessage(error);
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _sending = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_sending,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (widget.previous?.status == VerificationStatus.tolak) ...[
                Text(
                  'Pengajuan ditolak: ${widget.previous!.rejectionReason}',
                  style: const TextStyle(color: AppColors.error),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Perbaiki data atau dokumen, lalu kirim ulang pengajuan.',
                ),
                const SizedBox(height: 20),
              ],
              const Text(
                'Lengkapi data pemilik dan properti untuk diperiksa admin.',
              ),
              const SizedBox(height: 20),
              AppTextField(
                controller: _fields[0],
                label: 'Nomor KTP',
                readOnly: _busy,
                keyboardType: TextInputType.number,
                maxLength: 16,
                validator: (value) =>
                    RegExp(r'^\d{16}$').hasMatch(value?.trim() ?? '')
                    ? null
                    : 'Nomor KTP harus 16 angka.',
              ),
              const SizedBox(height: 16),
              AppTextField(
                controller: _fields[1],
                label: 'Nama Kost',
                readOnly: _busy,
                maxLength: 150,
                validator: (value) => _required(value, 150),
              ),
              const SizedBox(height: 16),
              AppTextField(
                controller: _fields[2],
                label: 'Alamat Kost',
                readOnly: _busy,
                maxLines: 3,
                maxLength: 500,
                validator: (value) => _required(value, 500),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _type,
                decoration: const InputDecoration(labelText: 'Tipe Kost'),
                items: ['PUTRA', 'PUTRI', 'CAMPUR']
                    .map(
                      (type) =>
                          DropdownMenuItem(value: type, child: Text(type)),
                    )
                    .toList(),
                onChanged: _busy
                    ? null
                    : (value) => setState(() {
                        _type = value!;
                      }),
              ),
              const SizedBox(height: 20),
              const Text(
                'Masukkan URL gambar, link berbagi Google Gambar, atau link file Google Drive. Gambar harus bisa diakses tanpa login di aplikasi ini. Untuk KTP dan sertifikat, gunakan tautan akses terbatas yang sesuai.',
              ),
              const SizedBox(height: 16),
              for (final kind in VerificationDocumentKind.values) ...[
                _documentCard(kind),
                const SizedBox(height: 16),
              ],
              if (_error != null) ...[
                Text(_error!, style: const TextStyle(color: AppColors.error)),
                const SizedBox(height: 16),
              ],
              AppButton(
                text: widget.previous == null
                    ? 'Kirim Pengajuan'
                    : 'Kirim Ulang Pengajuan',
                isLoading: _sending,
                onPressed: _busy ? null : _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _documentCard(VerificationDocumentKind kind) {
    final controller = _urls[kind]!;
    final url = ImageUrl.normalizeInput(controller.text);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppTextField(
              key: Key('url-${kind.name}'),
              controller: controller,
              label: 'URL ${kind.label}',
              hint: 'https://contoh.com/gambar.jpg',
              prefixIcon: Icons.link,
              keyboardType: TextInputType.url,
              readOnly: _busy,
              validator: ImageUrl.validate,
              onChanged: (_) => setState(() {}),
            ),
            if (ImageUrl.isValid(url)) ...[
              const SizedBox(height: 12),
              VerificationDocumentImage(reference: url, height: 150),
            ],
          ],
        ),
      ),
    );
  }

  String? _required(String? value, int max) =>
      value == null || value.trim().isEmpty || value.trim().length > max
      ? 'Wajib diisi, maksimal $max karakter.'
      : null;
}
