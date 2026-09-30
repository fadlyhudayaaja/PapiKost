import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../data/repositories/mock_repository.dart';

/// Alur 3: Edit Profil — simpan state di sesi (in-memory)
class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _repo = MockRepository.instance;
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();

  bool _isLoading = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final user = await _repo.getProfile();
      _nameCtrl.text = user.name;
      _phoneCtrl.text = user.phone;
      _bioCtrl.text = user.bio ?? '';
    } catch (_) {}
    setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _bioCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isSubmitting) return; // cegah double submit

    setState(() => _isSubmitting = true);
    try {
      await _repo.updateProfile(
        name: _nameCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        bio: _bioCtrl.text.trim().isEmpty ? null : _bioCtrl.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(
                Icons.check_circle_rounded,
                color: AppColors.white,
                size: 20,
              ),
              SizedBox(width: 10),
              Text('Profil berhasil diperbarui!'),
            ],
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      // Return true → ProfilePage akan reload data
      context.pop(true);
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
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffold,
      appBar: AppBar(
        title: const Text('Edit Profil'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => context.pop(false),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Avatar ────────────────────────────────────────
                      Center(
                        child: Stack(
                          children: [
                            CircleAvatar(
                              radius: 50,
                              backgroundColor: AppColors.primary.withValues(
                                alpha: 0.1,
                              ),
                              child: Text(
                                _nameCtrl.text.isNotEmpty
                                    ? _nameCtrl.text[0].toUpperCase()
                                    : 'U',
                                style: AppTextStyles.displayLarge.copyWith(
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.secondary,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: AppColors.white,
                                    width: 2,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.camera_alt_rounded,
                                  color: AppColors.white,
                                  size: 16,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Center(
                        child: Text(
                          'Ketuk untuk ganti foto',
                          style: AppTextStyles.caption,
                        ),
                      ),
                      const SizedBox(height: 28),

                      // ── Field: Nama ───────────────────────────────────
                      AppTextField(
                        controller: _nameCtrl,
                        label: 'Nama Lengkap *',
                        hint: 'Masukkan nama lengkap',
                        prefixIcon: Icons.person_outline_rounded,
                        textInputAction: TextInputAction.next,
                        onChanged: (_) => setState(() {}),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Nama wajib diisi.';
                          }
                          if (v.trim().length < 3) {
                            return 'Nama minimal 3 karakter.';
                          }
                          if (v.trim().length > 60) {
                            return 'Nama maksimal 60 karakter.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // ── Field: Nomor HP ───────────────────────────────
                      AppTextField(
                        controller: _phoneCtrl,
                        label: 'Nomor HP *',
                        hint: '08xxxxxxxxxx',
                        prefixIcon: Icons.phone_outlined,
                        keyboardType: TextInputType.phone,
                        textInputAction: TextInputAction.next,
                        maxLength: 15,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Nomor HP wajib diisi.';
                          }
                          if (v.trim().length < 10) {
                            return 'Nomor HP minimal 10 digit.';
                          }
                          if (!RegExp(r'^[0-9+]+$').hasMatch(v.trim())) {
                            return 'Nomor HP hanya boleh berisi angka.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // ── Field: Bio ────────────────────────────────────
                      AppTextField(
                        controller: _bioCtrl,
                        label: 'Bio (Opsional)',
                        hint: 'Ceritakan sedikit tentang diri Anda...',
                        prefixIcon: Icons.description_outlined,
                        maxLines: 3,
                        maxLength: 200,
                        validator: (v) {
                          if (v != null && v.trim().length > 200) {
                            return 'Bio maksimal 200 karakter.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 32),

                      // ── Submit ────────────────────────────────────────
                      AppButton(
                        text: 'Simpan Perubahan',
                        icon: Icons.save_rounded,
                        isFullWidth: true,
                        isLoading: _isSubmitting,
                        onPressed: _isSubmitting ? null : _save,
                      ),
                      const SizedBox(height: 12),
                      AppButton(
                        text: 'Batal',
                        isFullWidth: true,
                        isOutlined: true,
                        onPressed: () => context.pop(false),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
