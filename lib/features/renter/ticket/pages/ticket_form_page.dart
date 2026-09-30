import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../data/models/ticket_model.dart';
import '../../../../data/repositories/mock_repository.dart';
import '../providers/renter_ticket_provider.dart';

/// Mode form: create atau edit
enum TicketFormMode { create, edit }

class TicketFormPage extends StatefulWidget {
  /// Jika [existingTicket] != null → mode Edit
  final TicketModel? existingTicket;

  const TicketFormPage({super.key, this.existingTicket});

  @override
  State<TicketFormPage> createState() => _TicketFormPageState();
}

class _TicketFormPageState extends State<TicketFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _dateFmt = DateFormat('dd MMMM yyyy', 'id_ID');

  // Controllers
  late final TextEditingController _titleCtrl;
  late final TextEditingController _descCtrl;

  // Form values
  String _selectedCategory = 'LISTRIK';
  DateTime _incidentDate = DateTime.now();
  final List<XFile> _images = [];
  final ImagePicker _picker = ImagePicker();

  TicketFormMode get _mode => widget.existingTicket == null
      ? TicketFormMode.create
      : TicketFormMode.edit;

  @override
  void initState() {
    super.initState();
    final t = widget.existingTicket;
    _titleCtrl = TextEditingController(text: t?.title ?? '');
    _descCtrl = TextEditingController(text: t?.description ?? '');
    if (t != null) {
      _selectedCategory = t.category;
      _incidentDate = t.createdAt;
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    if (_images.length >= 3) {
      _showInfo('Maksimal 3 foto.');
      return;
    }
    try {
      final picked = await _picker.pickImage(
        source: source,
        imageQuality: 70,
        maxWidth: 1280,
      );
      if (picked != null) setState(() => _images.add(picked));
    } catch (_) {
      _showInfo('Gagal memilih foto.');
    }
  }

  void _showImageSourcePicker() {
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
              Text('Pilih Sumber Foto', style: AppTextStyles.h4),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _SourceButton(
                      icon: Icons.camera_alt_rounded,
                      label: 'Kamera',
                      onTap: () {
                        Navigator.pop(context);
                        _pickImage(ImageSource.camera);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _SourceButton(
                      icon: Icons.photo_library_rounded,
                      label: 'Galeri',
                      onTap: () {
                        Navigator.pop(context);
                        _pickImage(ImageSource.gallery);
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _incidentDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _incidentDate = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final prov = context.read<RenterTicketProvider>();
    if (prov.isSubmitting) return; // Cegah double submit

    try {
      if (_mode == TicketFormMode.create) {
        await prov.createTicket(
          title: _titleCtrl.text.trim(),
          description: _descCtrl.text.trim(),
          category: _selectedCategory,
          incidentDate: _incidentDate,
          imageUrls: _images.map((x) => x.path).toList(),
        );
        if (!mounted) return;
        _showSnackbar('Laporan berhasil dibuat!', isSuccess: true);
        context.pop();
      } else {
        await prov.updateTicket(
          id: widget.existingTicket!.id,
          title: _titleCtrl.text.trim(),
          description: _descCtrl.text.trim(),
          category: _selectedCategory,
          incidentDate: _incidentDate,
        );
        if (!mounted) return;
        _showSnackbar('Laporan berhasil diperbarui!', isSuccess: true);
        context.pop();
      }
    } catch (e) {
      if (!mounted) return;
      _showSnackbar(
        e.toString().replaceFirst('Exception: ', ''),
        isSuccess: false,
      );
    }
  }

  void _showSnackbar(String msg, {required bool isSuccess}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isSuccess
                  ? Icons.check_circle_rounded
                  : Icons.error_outline_rounded,
              color: AppColors.white,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(msg)),
          ],
        ),
        backgroundColor: isSuccess ? AppColors.success : AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showInfo(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<RenterTicketProvider>();
    final isEdit = _mode == TicketFormMode.edit;

    return Scaffold(
      backgroundColor: AppColors.scaffold,
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Laporan' : 'Buat Laporan Baru'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ══ FIELD 1: Judul (TextField) ══════════════════════════════
                AppTextField(
                  controller: _titleCtrl,
                  label: 'Judul Kerusakan *',
                  hint: 'Contoh: Lampu kamar tidak menyala',
                  prefixIcon: Icons.title_rounded,
                  maxLength: 100,
                  textInputAction: TextInputAction.next,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Judul wajib diisi.';
                    }
                    if (v.trim().length < 5) {
                      return 'Judul minimal 5 karakter.';
                    }
                    if (v.trim().length > 100) {
                      return 'Judul maksimal 100 karakter.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // ══ FIELD 2: Kategori (Dropdown) ════════════════════════════
                Text('Kategori Kerusakan *', style: AppTextStyles.labelLarge),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: _selectedCategory,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.category_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.grey200),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.grey200),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: AppColors.primary,
                        width: 1.5,
                      ),
                    ),
                    filled: true,
                    fillColor: AppColors.inputBg,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                  items: MockRepository.ticketCategories.map((cat) {
                    return DropdownMenuItem(
                      value: cat,
                      child: Text(
                        MockRepository.categoryLabels[cat] ?? cat,
                        style: AppTextStyles.bodyMedium,
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedCategory = val);
                  },
                  validator: (v) =>
                      v == null ? 'Pilih kategori kerusakan.' : null,
                ),
                const SizedBox(height: 16),

                // ══ FIELD 3: Tanggal Kejadian (DatePicker) ══════════════════
                Text('Tanggal Kejadian *', style: AppTextStyles.labelLarge),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: _selectDate,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.inputBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.grey200),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.calendar_today_outlined,
                          color: AppColors.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          _dateFmt.format(_incidentDate),
                          style: AppTextStyles.bodyMedium,
                        ),
                        const Spacer(),
                        const Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 14,
                          color: AppColors.grey400,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // ══ FIELD 4: Deskripsi (TextArea) ══════════════════════════
                AppTextField(
                  controller: _descCtrl,
                  label: 'Deskripsi Kerusakan *',
                  hint: 'Jelaskan detail kerusakan (lokasi, kondisi, dll.)',
                  prefixIcon: Icons.description_outlined,
                  maxLines: 5,
                  maxLength: 500,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Deskripsi wajib diisi.';
                    }
                    if (v.trim().length < 15) {
                      return 'Deskripsi minimal 15 karakter.';
                    }
                    if (v.trim().length > 500) {
                      return 'Deskripsi maksimal 500 karakter.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // ══ FIELD 5: Foto (ImagePicker) ══════════════════════════════
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Foto Kerusakan', style: AppTextStyles.h4),
                    Text(
                      '${_images.length}/3 (opsional)',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.grey500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Tambahkan foto untuk memperjelas laporan.',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.grey500,
                  ),
                ),
                const SizedBox(height: 12),

                SizedBox(
                  height: 110,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      // Tombol tambah foto
                      GestureDetector(
                        onTap: _showImageSourcePicker,
                        child: Container(
                          width: 100,
                          height: 100,
                          margin: const EdgeInsets.only(right: 10),
                          decoration: BoxDecoration(
                            color: AppColors.inputBg,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.grey300),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.add_photo_alternate_outlined,
                                color: AppColors.primary,
                                size: 28,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Tambah Foto',
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.primary,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Preview foto terpilih
                      ..._images.asMap().entries.map((e) {
                        return Stack(
                          children: [
                            Container(
                              width: 100,
                              height: 100,
                              margin: const EdgeInsets.only(right: 10),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                image: DecorationImage(
                                  image: FileImage(File(e.value.path)),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            Positioned(
                              top: 4,
                              right: 14,
                              child: GestureDetector(
                                onTap: () =>
                                    setState(() => _images.removeAt(e.key)),
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Colors.black54,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.close_rounded,
                                    color: Colors.white,
                                    size: 14,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      }),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // ══ Submit Button ══════════════════════════════════════════
                // Tombol dinonaktifkan saat isSubmitting
                AppButton(
                  text: isEdit ? 'Simpan Perubahan' : 'Kirim Laporan',
                  icon: isEdit ? Icons.save_rounded : Icons.send_rounded,
                  isFullWidth: true,
                  isLoading: prov.isSubmitting,
                  onPressed: prov.isSubmitting ? null : _submit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SourceButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _SourceButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: AppColors.inputBg,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 36, color: AppColors.primary),
            const SizedBox(height: 8),
            Text(label, style: AppTextStyles.labelMedium),
          ],
        ),
      ),
    );
  }
}
