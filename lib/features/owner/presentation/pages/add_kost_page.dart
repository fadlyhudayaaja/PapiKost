import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/dio_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';

class AddKostPage extends StatefulWidget {
  const AddKostPage({super.key});

  @override
  State<AddKostPage> createState() => _AddKostPageState();
}

class _AddKostPageState extends State<AddKostPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _totalRoomsCtrl = TextEditingController();

  String _selectedType = 'CAMPUR';
  bool _isSplitBill = false;
  bool _isSubmitting = false;

  final List<String> _selectedFacilities = [];

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
  void dispose() {
    _nameCtrl.dispose();
    _addressCtrl.dispose();
    _priceCtrl.dispose();
    _descCtrl.dispose();
    _totalRoomsCtrl.dispose();
    super.dispose();
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

    setState(() => _isSubmitting = true);
    try {
      await DioClient.instance.post(
        '/kost',
        data: {
          'name': _nameCtrl.text.trim(),
          'address': _addressCtrl.text.trim(),
          'pricePerMonth':
              int.tryParse(_priceCtrl.text.replaceAll('.', '')) ?? 0,
          'type': _selectedType,
          'description': _descCtrl.text.trim(),
          'totalRooms': int.tryParse(_totalRoomsCtrl.text) ?? 0,
          'facilities': _selectedFacilities,
          'isSplitBillAvailable': _isSplitBill,
        },
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Kost berhasil ditambahkan!'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      context.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal: ${e.toString()}'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffold,
      appBar: AppBar(
        title: const Text('Tambah Listing Kost'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Nama Kost ──
                AppTextField(
                  controller: _nameCtrl,
                  label: 'Nama Kost',
                  hint: 'Contoh: Kost Mawar Indah',
                  prefixIcon: Icons.home_rounded,
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Wajib diisi' : null,
                ),
                const SizedBox(height: 14),

                // ── Alamat ──
                AppTextField(
                  controller: _addressCtrl,
                  label: 'Alamat Lengkap',
                  hint: 'Jl. Dr. Mansyur No. 12, Medan',
                  prefixIcon: Icons.location_on_outlined,
                  maxLines: 2,
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Wajib diisi' : null,
                ),
                const SizedBox(height: 14),

                // ── Harga & Jumlah Kamar ──
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: AppTextField(
                        controller: _priceCtrl,
                        label: 'Harga/Bulan (Rp)',
                        hint: '1200000',
                        prefixIcon: Icons.payments_outlined,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Wajib diisi';
                          if (int.tryParse(v) == null) {
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
                        label: 'Total Kamar',
                        hint: '10',
                        prefixIcon: Icons.door_front_door_outlined,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        validator: (v) =>
                            v == null || v.isEmpty ? 'Wajib diisi' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // ── Tipe Kost ──
                Text('Tipe Kost', style: AppTextStyles.h4),
                const SizedBox(height: 10),
                Row(
                  children: _types.map((t) {
                    final selected = _selectedType == t;
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
                            color: selected
                                ? AppColors.primary
                                : AppColors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: selected
                                  ? AppColors.primary
                                  : AppColors.grey300,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              t,
                              style: AppTextStyles.labelMedium.copyWith(
                                color: selected
                                    ? AppColors.white
                                    : AppColors.grey700,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),

                // ── Split Bill ──
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
                        activeTrackColor: AppColors.secondary.withValues(
                          alpha: 0.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // ── Fasilitas ──
                Text('Fasilitas', style: AppTextStyles.h4),
                const SizedBox(height: 4),
                Text(
                  'Pilih fasilitas yang tersedia',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.grey500,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _allFacilities.map((f) {
                    final selected = _selectedFacilities.contains(f);
                    return FilterChip(
                      label: Text(f),
                      selected: selected,
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
                        color: selected ? AppColors.primary : AppColors.grey300,
                      ),
                      labelStyle: AppTextStyles.labelMedium.copyWith(
                        color: selected ? AppColors.white : AppColors.grey700,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),

                // ── Deskripsi ──
                AppTextField(
                  controller: _descCtrl,
                  label: 'Deskripsi Kost',
                  hint: 'Jelaskan kost Anda secara lengkap...',
                  prefixIcon: Icons.description_outlined,
                  maxLines: 4,
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Wajib diisi' : null,
                ),
                const SizedBox(height: 32),

                AppButton(
                  text: 'Simpan Listing',
                  icon: Icons.save_rounded,
                  isFullWidth: true,
                  isLoading: _isSubmitting,
                  onPressed: _isSubmitting ? null : _submit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
