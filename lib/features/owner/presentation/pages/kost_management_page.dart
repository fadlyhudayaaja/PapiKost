import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/shimmer_loading.dart';
import '../providers/owner_provider.dart';

// ═══════════════════════════════════════════════════════════════════════════
// Halaman Daftar Kamar (READ + DELETE)
// ═══════════════════════════════════════════════════════════════════════════
class KostManagementPage extends StatefulWidget {
  const KostManagementPage({super.key});

  @override
  State<KostManagementPage> createState() => _KostManagementPageState();
}

class _KostManagementPageState extends State<KostManagementPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OwnerProvider>().fetchKostList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<OwnerProvider>();

    return Scaffold(
      backgroundColor: AppColors.scaffold,
      appBar: AppBar(
        title: const Text('Manajemen Kamar'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            tooltip: 'Tambah Kamar',
            onPressed: () => _navigateToForm(context, null),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToForm(context, null),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Tambah Kamar'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () => prov.fetchKostList(),
        child: _buildBody(prov),
      ),
    );
  }

  Widget _buildBody(OwnerProvider prov) {
    if (prov.kostLoading) {
      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 3,
        itemBuilder: (_, __) => const Padding(
          padding: EdgeInsets.only(bottom: 12),
          child: ListItemShimmer(),
        ),
      );
    }

    if (prov.kostList.isEmpty) {
      return EmptyState(
        icon: Icons.home_outlined,
        title: 'Belum Ada Kamar',
        subtitle: 'Tap tombol + untuk menambahkan properti kamar kost Anda.',
        buttonLabel: 'Tambah Kamar Pertama',
        onButtonTap: () => _navigateToForm(context, null),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: prov.kostList.length,
      itemBuilder: (ctx, i) {
        final kost = prov.kostList[i];
        return _KostCard(
          kost: kost,
          onEdit: () => _navigateToForm(ctx, kost),
          onDelete: () => _confirmDelete(ctx, kost),
        );
      },
    );
  }

  void _navigateToForm(BuildContext context, OwnerKostModel? existing) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => KostFormPage(existingKost: existing),
      ),
    );
  }

  void _confirmDelete(BuildContext context, OwnerKostModel kost) {
    showDialog(
      context: context,
      builder: (dCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon: Container(
          padding: const EdgeInsets.all(12),
          decoration: const BoxDecoration(
            color: AppColors.errorLight,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.delete_outline_rounded,
            color: AppColors.error,
            size: 28,
          ),
        ),
        title: const Text('Hapus Kamar?'),
        content: Text(
          '"${kost.name}" akan dihapus secara permanen.',
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
              await context.read<OwnerProvider>().deleteKost(kost.id);
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Kamar berhasil dihapus'),
                  backgroundColor: AppColors.success,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }
}

// ── KostCard ──────────────────────────────────────────────────────────────────
class _KostCard extends StatelessWidget {
  final OwnerKostModel kost;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _KostCard({
    required this.kost,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

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
          // Foto kamar
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            child: _buildPhoto(),
          ),

          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        kost.name,
                        style: AppTextStyles.labelLarge,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    _TypeBadge(type: kost.type),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      size: 13,
                      color: AppColors.grey400,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        kost.address,
                        style: AppTextStyles.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(fmt.format(kost.pricePerMonth),
                        style: AppTextStyles.price),
                    Text('/bulan', style: AppTextStyles.caption),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: kost.availableRooms > 0
                            ? AppColors.successLight
                            : AppColors.errorLight,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${kost.availableRooms}/${kost.totalRooms} tersedia',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: kost.availableRooms > 0
                              ? AppColors.success
                              : AppColors.error,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton.icon(
                      onPressed: onEdit,
                      icon: const Icon(Icons.edit_rounded, size: 16),
                      label: const Text('Edit'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: onDelete,
                      icon: const Icon(Icons.delete_outline_rounded, size: 16),
                      label: const Text('Hapus'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: const BorderSide(color: AppColors.error),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhoto() {
    if (kost.photoUrl == null) {
      return Container(
        height: 140,
        color: AppColors.grey100,
        child: const Center(
          child: Icon(Icons.home_outlined, size: 48, color: AppColors.grey300),
        ),
      );
    }

    final isNetwork = kost.photoUrl!.startsWith('http');
    if (isNetwork) {
      return CachedNetworkImage(
        imageUrl: kost.photoUrl!,
        height: 140,
        width: double.infinity,
        fit: BoxFit.cover,
        placeholder: (_, __) => const ShimmerBox(height: 140),
        errorWidget: (_, __, ___) => Container(
          height: 140,
          color: AppColors.grey100,
          child: const Center(
            child: Icon(Icons.broken_image_outlined, color: AppColors.grey400),
          ),
        ),
      );
    } else {
      return Image.file(
        File(kost.photoUrl!),
        height: 140,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          height: 140,
          color: AppColors.grey100,
          child: const Center(
            child: Icon(Icons.broken_image_outlined, color: AppColors.grey400),
          ),
        ),
      );
    }
  }
}

class _TypeBadge extends StatelessWidget {
  final String type;
  const _TypeBadge({required this.type});
  @override
  Widget build(BuildContext context) {
    final color = switch (type) {
      'PUTRA' => const Color(0xFF1565C0),
      'PUTRI' => const Color(0xFFAD1457),
      _ => const Color(0xFF2E7D32),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        type,
        style: AppTextStyles.labelSmall.copyWith(color: AppColors.white),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Form Tambah / Edit Kamar (CREATE + UPDATE)
// ═══════════════════════════════════════════════════════════════════════════
class KostFormPage extends StatefulWidget {
  final OwnerKostModel? existingKost;
  const KostFormPage({super.key, this.existingKost});

  @override
  State<KostFormPage> createState() => _KostFormPageState();
}

class _KostFormPageState extends State<KostFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _addressCtrl;
  late final TextEditingController _priceCtrl;
  late final TextEditingController _totalRoomsCtrl;
  late final TextEditingController _descCtrl;

  String _selectedType = 'CAMPUR';
  bool _isSplitBill = false;
  final List<String> _selectedFacilities = [];
  String? _photoPath; // path lokal atau URL
  final ImagePicker _picker = ImagePicker();

  bool get _isEdit => widget.existingKost != null;

  static const _types = ['PUTRA', 'PUTRI', 'CAMPUR'];

  static const _allFacilities = [
    'WiFi',
    'AC',
    'TV',
    'Lemari',
    'Meja Belajar',
    'Kamar Mandi Dalam',
    'Dapur Bersama',
    'Parkir Motor',
    'Parkir Mobil',
    'Keamanan 24 Jam',
    'Laundry',
    'Kulkas',
  ];

  @override
  void initState() {
    super.initState();
    final k = widget.existingKost;
    _nameCtrl = TextEditingController(text: k?.name ?? '');
    _addressCtrl = TextEditingController(text: k?.address ?? '');
    _priceCtrl = TextEditingController(
      text: k != null ? k.pricePerMonth.toInt().toString() : '',
    );
    _totalRoomsCtrl = TextEditingController(
      text: k != null ? k.totalRooms.toString() : '',
    );
    _descCtrl = TextEditingController(text: k?.description ?? '');

    if (k != null) {
      _selectedType = k.type;
      _isSplitBill = k.isSplitBillAvailable;
      _selectedFacilities.addAll(k.facilities);
      _photoPath = k.photoUrl;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _addressCtrl.dispose();
    _priceCtrl.dispose();
    _totalRoomsCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  // ── Pilih foto dari galeri / kamera ────────────────────────────────────────
  void _showPhotoPicker() {
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
              Text('Pilih Foto Kamar', style: AppTextStyles.h4),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _PhotoSourceBtn(
                      icon: Icons.camera_alt_rounded,
                      label: 'Kamera',
                      onTap: () async {
                        Navigator.pop(context);
                        await _pickImage(ImageSource.camera);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _PhotoSourceBtn(
                      icon: Icons.photo_library_rounded,
                      label: 'Galeri',
                      onTap: () async {
                        Navigator.pop(context);
                        await _pickImage(ImageSource.gallery);
                      },
                    ),
                  ),
                ],
              ),
              if (_photoPath != null) ...[
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    setState(() => _photoPath = null);
                  },
                  icon: const Icon(Icons.delete_outline_rounded),
                  label: const Text('Hapus Foto'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: const BorderSide(color: AppColors.error),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        imageQuality: 75,
        maxWidth: 1280,
      );
      if (picked != null) setState(() => _photoPath = picked.path);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal memilih foto.')),
        );
      }
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedFacilities.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Pilih minimal satu fasilitas'),
          backgroundColor: AppColors.warning,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }

    final prov = context.read<OwnerProvider>();
    if (prov.isSubmitting) return;

    final price = double.tryParse(
          _priceCtrl.text.replaceAll('.', '').replaceAll(',', ''),
        ) ??
        0;
    final rooms = int.tryParse(_totalRoomsCtrl.text) ?? 0;

    bool success;
    if (_isEdit) {
      success = await prov.updateKost(
        id: widget.existingKost!.id,
        name: _nameCtrl.text.trim(),
        address: _addressCtrl.text.trim(),
        pricePerMonth: price,
        type: _selectedType,
        totalRooms: rooms,
        isSplitBillAvailable: _isSplitBill,
        facilities: List.from(_selectedFacilities),
        description: _descCtrl.text.trim().isEmpty
            ? null
            : _descCtrl.text.trim(),
        photoUrl: _photoPath,
      );
    } else {
      success = await prov.addKost(
        name: _nameCtrl.text.trim(),
        address: _addressCtrl.text.trim(),
        pricePerMonth: price,
        type: _selectedType,
        totalRooms: rooms,
        isSplitBillAvailable: _isSplitBill,
        facilities: List.from(_selectedFacilities),
        description: _descCtrl.text.trim().isEmpty
            ? null
            : _descCtrl.text.trim(),
        photoUrl: _photoPath,
      );
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? (_isEdit ? 'Kamar berhasil diperbarui!' : 'Kamar berhasil ditambahkan!')
              : 'Gagal menyimpan data kamar.',
        ),
        backgroundColor: success ? AppColors.success : AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
    if (success) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<OwnerProvider>();

    return Scaffold(
      backgroundColor: AppColors.scaffold,
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit Kamar' : 'Tambah Kamar'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context),
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
                // ══ FOTO KAMAR ══════════════════════════════════════════════
                Text('Foto Kamar', style: AppTextStyles.h4),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: _showPhotoPicker,
                  child: Container(
                    width: double.infinity,
                    height: 160,
                    decoration: BoxDecoration(
                      color: AppColors.inputBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.grey300,
                        style: BorderStyle.solid,
                      ),
                    ),
                    child: _buildPhotoPreview(),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Ketuk untuk pilih foto kamar (opsional)',
                  style: AppTextStyles.caption,
                ),
                const SizedBox(height: 20),

                // ══ NAMA KOST ══════════════════════════════════════════════
                AppTextField(
                  controller: _nameCtrl,
                  label: 'Nama Kost *',
                  hint: 'Contoh: Kost Mawar Indah',
                  prefixIcon: Icons.home_rounded,
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Wajib diisi' : null,
                ),
                const SizedBox(height: 14),

                // ══ ALAMAT ══════════════════════════════════════════════════
                AppTextField(
                  controller: _addressCtrl,
                  label: 'Alamat Lengkap *',
                  hint: 'Jl. Dr. Mansyur No. 12, Medan',
                  prefixIcon: Icons.location_on_outlined,
                  maxLines: 2,
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Wajib diisi' : null,
                ),
                const SizedBox(height: 14),

                // ══ HARGA & KAMAR ══════════════════════════════════════════
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: AppTextField(
                        controller: _priceCtrl,
                        label: 'Harga/Bulan (Rp) *',
                        hint: '1200000',
                        prefixIcon: Icons.payments_outlined,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Wajib diisi';
                          }
                          if (double.tryParse(v) == null) {
                            return 'Angka tidak valid';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: AppTextField(
                        controller: _totalRoomsCtrl,
                        label: 'Total Kamar *',
                        hint: '10',
                        prefixIcon: Icons.door_front_door_outlined,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        validator: (v) =>
                            v == null || v.trim().isEmpty ? 'Wajib diisi' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // ══ TIPE KOST ══════════════════════════════════════════════
                Text('Tipe Kost *', style: AppTextStyles.h4),
                const SizedBox(height: 10),
                Row(
                  children: _types.map((t) {
                    final sel = _selectedType == t;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedType = t),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          margin: EdgeInsets.only(
                            right: t != _types.last ? 8 : 0,
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: sel ? AppColors.primary : AppColors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color:
                                  sel ? AppColors.primary : AppColors.grey300,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              t,
                              style: AppTextStyles.labelMedium.copyWith(
                                color:
                                    sel ? AppColors.white : AppColors.grey700,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),

                // ══ SPLIT BILL ════════════════════════════════════════════
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.grey200),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.secondary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.people_rounded,
                          color: AppColors.secondary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Aktifkan Sewa Patungan',
                              style: AppTextStyles.labelLarge,
                            ),
                            Text(
                              'Izinkan penyewa berbagi biaya',
                              style: AppTextStyles.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: _isSplitBill,
                        onChanged: (v) => setState(() => _isSplitBill = v),
                        activeThumbColor: AppColors.secondary,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // ══ FASILITAS ════════════════════════════════════════════
                Text('Fasilitas *', style: AppTextStyles.h4),
                const SizedBox(height: 4),
                Text(
                  'Pilih minimal satu fasilitas',
                  style: AppTextStyles.caption,
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _allFacilities.map((f) {
                    final sel = _selectedFacilities.contains(f);
                    return FilterChip(
                      label: Text(f),
                      selected: sel,
                      onSelected: (v) {
                        setState(() {
                          if (v) {
                            _selectedFacilities.add(f);
                          } else {
                            _selectedFacilities.remove(f);
                          }
                        });
                      },
                      selectedColor: AppColors.primary,
                      backgroundColor: AppColors.white,
                      checkmarkColor: AppColors.white,
                      side: BorderSide(
                        color: sel ? AppColors.primary : AppColors.grey300,
                      ),
                      labelStyle: AppTextStyles.labelMedium.copyWith(
                        color: sel ? AppColors.white : AppColors.grey700,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),

                // ══ DESKRIPSI ════════════════════════════════════════════
                AppTextField(
                  controller: _descCtrl,
                  label: 'Deskripsi Kost (Opsional)',
                  hint: 'Ceritakan kost Anda...',
                  prefixIcon: Icons.description_outlined,
                  maxLines: 3,
                ),
                const SizedBox(height: 32),

                AppButton(
                  text: _isEdit ? 'Simpan Perubahan' : 'Tambah Kamar',
                  icon: _isEdit ? Icons.save_rounded : Icons.add_rounded,
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

  Widget _buildPhotoPreview() {
    if (_photoPath == null) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.add_photo_alternate_outlined,
            size: 40,
            color: AppColors.primary,
          ),
          const SizedBox(height: 8),
          Text(
            'Pilih Foto Kamar',
            style: AppTextStyles.labelMedium.copyWith(
              color: AppColors.primary,
            ),
          ),
        ],
      );
    }

    final isNetwork = _photoPath!.startsWith('http');
    Widget img;

    if (isNetwork) {
      img = CachedNetworkImage(
        imageUrl: _photoPath!,
        width: double.infinity,
        height: 160,
        fit: BoxFit.cover,
      );
    } else {
      img = Image.file(
        File(_photoPath!),
        width: double.infinity,
        height: 160,
        fit: BoxFit.cover,
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Stack(
        children: [
          img,
          Positioned(
            bottom: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.edit_rounded,
                color: Colors.white,
                size: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PhotoSourceBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _PhotoSourceBtn({
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
