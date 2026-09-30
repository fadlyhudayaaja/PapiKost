import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/shimmer_loading.dart';
import '../../../../data/models/user_model.dart';
import '../../../../data/repositories/mock_repository.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';

enum _ProfileState { loading, error, success }

class RenterProfilePage extends StatefulWidget {
  const RenterProfilePage({super.key});

  @override
  State<RenterProfilePage> createState() => _RenterProfilePageState();
}

class _RenterProfilePageState extends State<RenterProfilePage> {
  final _repo = MockRepository.instance;
  _ProfileState _state = _ProfileState.loading;
  UserModel? _user;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool simulateError = false}) async {
    setState(() {
      _state = _ProfileState.loading;
      _error = '';
    });
    try {
      final user = await _repo.getProfile(simulateError: simulateError);
      setState(() {
        _user = user;
        _state = _ProfileState.success;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _state = _ProfileState.error;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffold,
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _load,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    return switch (_state) {
      _ProfileState.loading => _buildSkeleton(),
      _ProfileState.error => ErrorState(message: _error, onRetry: _load),
      _ProfileState.success => _buildProfile(_user!),
    };
  }

  Widget _buildSkeleton() {
    return ListView(
      children: [
        const ShimmerBox(height: 220, borderRadius: 0),
        const Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            children: [
              ShimmerBox(height: 20, width: 160),
              SizedBox(height: 10),
              ShimmerBox(height: 14, width: 200),
              SizedBox(height: 24),
              ShimmerBox(height: 80),
              SizedBox(height: 12),
              ShimmerBox(height: 80),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProfile(UserModel user) {
    final auth = context.read<AuthProvider>();

    return CustomScrollView(
      slivers: [
        // ── Header ──
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
                        user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                        style: AppTextStyles.displayMedium.copyWith(
                          color: AppColors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      user.name,
                      style: AppTextStyles.h3.copyWith(color: AppColors.white),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Penyewa Kost',
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
                // ── Info Section ──
                _SectionCard(
                  title: 'Informasi Akun',
                  children: [
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
                          : 'Belum Terverifikasi',
                      valueColor: user.isVerified
                          ? AppColors.success
                          : AppColors.warning,
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // ── Aktivitas ──
                _SectionCard(
                  title: 'Aktivitas Saya',
                  children: [
                    _MenuTile(
                      icon: Icons.receipt_long_outlined,
                      label: 'Riwayat Reservasi',
                      onTap: () => context.push(AppRoutes.renterReservations),
                    ),
                    _MenuTile(
                      icon: Icons.build_outlined,
                      label: 'Laporan Kerusakan',
                      onTap: () => context.push(AppRoutes.renterTickets),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // ── Pengaturan ──
                _SectionCard(
                  title: 'Pengaturan',
                  children: [
                    _MenuTile(
                      icon: Icons.edit_outlined,
                      label: 'Edit Profil',
                      onTap: () async {
                        final updated = await context.push<bool>(
                          AppRoutes.editProfileRenter,
                        );
                        if (updated == true) _load();
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

                // ── Logout ──
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _confirmLogout(context, auth),
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
    );
  }

  void _confirmLogout(BuildContext ctx, AuthProvider auth) {
    showDialog(
      context: ctx,
      builder: (d) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Keluar'),
        content: const Text('Apakah Anda yakin ingin keluar?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(d),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(d);
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

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SectionCard({required this.title, required this.children});

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
            children: children.asMap().entries.map((e) {
              return Column(
                children: [
                  e.value,
                  if (e.key < children.length - 1)
                    const Divider(height: 1, indent: 56, endIndent: 0),
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

// Error state reuse
class ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  const ErrorState({super.key, required this.message, this.onRetry});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.errorLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                size: 40,
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Terjadi Kesalahan',
              style: AppTextStyles.h4,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.grey500,
              ),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Coba Lagi'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
