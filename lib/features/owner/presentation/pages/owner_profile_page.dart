import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';
import '../providers/owner_provider.dart';

class OwnerProfilePage extends StatelessWidget {
  const OwnerProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final ownerProv = context.watch<OwnerProvider>();
    final user = ownerProv.ownerProfile;

    return Scaffold(
      backgroundColor: AppColors.scaffold,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            automaticallyImplyLeading: false,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: AppColors.primaryGradient,
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 16),
                      CircleAvatar(
                        radius: 44,
                        backgroundColor: AppColors.white.withValues(alpha: 0.2),
                        child: Text(
                          user.name.isNotEmpty
                              ? user.name[0].toUpperCase()
                              : 'O',
                          style: AppTextStyles.displayMedium.copyWith(
                            color: AppColors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        user.name,
                        style: AppTextStyles.h3.copyWith(
                          color: AppColors.white,
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Pemilik Kost',
                          style: AppTextStyles.labelSmall.copyWith(
                            color: AppColors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Informasi Akun ──
                  _SectionCard(
                    title: 'Informasi Akun',
                    items: [
                      _InfoTile(
                        icon: Icons.email_outlined,
                        label: 'Email',
                        value: user.email.isNotEmpty ? user.email : '-',
                      ),
                      _InfoTile(
                        icon: Icons.phone_outlined,
                        label: 'Nomor HP',
                        value: user.phone.isNotEmpty ? user.phone : '-',
                      ),
                      if (user.bio != null && user.bio!.isNotEmpty)
                        _InfoTile(
                          icon: Icons.description_outlined,
                          label: 'Bio',
                          value: user.bio!,
                        ),
                      _InfoTile(
                        icon: Icons.verified_outlined,
                        label: 'Status',
                        value: user.isVerified
                            ? 'Terverifikasi'
                            : 'Menunggu Verifikasi',
                        valueColor: user.isVerified
                            ? AppColors.success
                            : AppColors.warning,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // ── Pengaturan ──
                  _SectionCard(
                    title: 'Pengaturan',
                    items: [
                      _MenuTile(
                        icon: Icons.edit_outlined,
                        label: 'Edit Profil',
                        onTap: () => _showEditProfileSheet(context, ownerProv),
                      ),
                      _MenuTile(
                        icon: Icons.house_outlined,
                        label: 'Kelola Properti Kost',
                        onTap: () {
                          // Navigate to kost management
                          from(context).go(AppRoutes.ownerDashboard);
                        },
                      ),
                      _MenuTile(
                        icon: Icons.notifications_outlined,
                        label: 'Notifikasi',
                        onTap: () {},
                      ),
                      _MenuTile(
                        icon: Icons.help_outline_rounded,
                        label: 'Bantuan',
                        onTap: () {},
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _confirmLogout(context, authProvider),
                      icon: const Icon(Icons.logout_rounded),
                      label: const Text('Keluar'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: const BorderSide(color: AppColors.error),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper untuk navigate
  GoRouter from(BuildContext ctx) => GoRouter.of(ctx);

  void _showEditProfileSheet(BuildContext context, OwnerProvider prov) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider.value(
          value: prov,
          child: const _OwnerEditProfilePage(),
        ),
      ),
    );
  }

  void _confirmLogout(BuildContext ctx, AuthProvider auth) {
    showDialog(
      context: ctx,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Keluar'),
        content: const Text('Apakah Anda yakin ingin keluar?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogCtx);
              await auth.logout();
              if (ctx.mounted) ctx.go(AppRoutes.login);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
  }
}

// ── Edit Profil Owner ─────────────────────────────────────────────────────────
class _OwnerEditProfilePage extends StatefulWidget {
  const _OwnerEditProfilePage();

  @override
  State<_OwnerEditProfilePage> createState() => _OwnerEditProfilePageState();
}

class _OwnerEditProfilePageState extends State<_OwnerEditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _bioCtrl;

  @override
  void initState() {
    super.initState();
    final user = context.read<OwnerProvider>().ownerProfile;
    _nameCtrl = TextEditingController(text: user.name);
    _phoneCtrl = TextEditingController(text: user.phone);
    _bioCtrl = TextEditingController(text: user.bio ?? '');
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
    final prov = context.read<OwnerProvider>();
    if (prov.isSubmitting) return;

    final ok = await prov.updateProfile(
      name: _nameCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      bio: _bioCtrl.text.trim().isEmpty ? null : _bioCtrl.text.trim(),
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok ? 'Profil berhasil diperbarui!' : 'Gagal menyimpan profil.',
        ),
        backgroundColor: ok ? AppColors.success : AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
    if (ok) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<OwnerProvider>();

    return Scaffold(
      backgroundColor: AppColors.scaffold,
      appBar: AppBar(
        title: const Text('Edit Profil'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context),
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
                Center(
                  child: CircleAvatar(
                    radius: 50,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                    child: Text(
                      _nameCtrl.text.isNotEmpty
                          ? _nameCtrl.text[0].toUpperCase()
                          : 'O',
                      style: AppTextStyles.displayLarge.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 28),

                AppTextField(
                  controller: _nameCtrl,
                  label: 'Nama Lengkap *',
                  hint: 'Masukkan nama lengkap',
                  prefixIcon: Icons.person_outline_rounded,
                  textInputAction: TextInputAction.next,
                  onChanged: (_) => setState(() {}),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Nama wajib diisi.';
                    if (v.trim().length < 3) return 'Nama minimal 3 karakter.';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                AppTextField(
                  controller: _phoneCtrl,
                  label: 'Nomor HP *',
                  hint: '08xxxxxxxxxx',
                  prefixIcon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                  maxLength: 15,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Nomor HP wajib diisi.';
                    if (v.trim().length < 10) return 'Nomor HP minimal 10 digit.';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                AppTextField(
                  controller: _bioCtrl,
                  label: 'Bio (Opsional)',
                  hint: 'Ceritakan sedikit tentang Anda...',
                  prefixIcon: Icons.description_outlined,
                  maxLines: 3,
                  maxLength: 200,
                ),
                const SizedBox(height: 32),

                AppButton(
                  text: 'Simpan Perubahan',
                  icon: Icons.save_rounded,
                  isFullWidth: true,
                  isLoading: prov.isSubmitting,
                  onPressed: prov.isSubmitting ? null : _save,
                ),
                const SizedBox(height: 12),
                AppButton(
                  text: 'Batal',
                  isFullWidth: true,
                  isOutlined: true,
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────
class _SectionCard extends StatelessWidget {
  final String title;
  final List<Widget> items;
  const _SectionCard({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTextStyles.h4),
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
            children: items.asMap().entries.map((e) {
              return Column(
                children: [
                  e.value,
                  if (e.key < items.length - 1)
                    const Divider(height: 1, indent: 56),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;
  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: AppColors.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTextStyles.caption),
                Text(
                  value,
                  style: AppTextStyles.labelMedium.copyWith(
                    color: valueColor ?? AppColors.grey800,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _MenuTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: AppColors.primary),
            ),
            const SizedBox(width: 14),
            Expanded(child: Text(label, style: AppTextStyles.labelMedium)),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: AppColors.grey400,
            ),
          ],
        ),
      ),
    );
  }
}
