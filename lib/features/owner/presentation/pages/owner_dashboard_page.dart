import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/shimmer_loading.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';
import '../providers/owner_provider.dart';

class OwnerDashboardPage extends StatefulWidget {
  const OwnerDashboardPage({super.key});

  @override
  State<OwnerDashboardPage> createState() => _OwnerDashboardPageState();
}

class _OwnerDashboardPageState extends State<OwnerDashboardPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OwnerProvider>().fetchDashboard();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<OwnerProvider>();
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: AppColors.scaffold,
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () => provider.fetchDashboard(),
        child: CustomScrollView(
          slivers: [
            // App Bar
            SliverAppBar(
              expandedHeight: 160,
              pinned: true,
              automaticallyImplyLeading: false,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: AppColors.primaryGradient,
                  ),
                  padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        'Dashboard Pemilik',
                        style: AppTextStyles.h2.copyWith(
                          color: AppColors.white,
                        ),
                      ),
                      Text(
                        'Halo, ${authProvider.currentUser?.name ?? "Pemilik"} 👋',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.white.withValues(alpha: 0.85),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(
                    Icons.add_home_rounded,
                    color: AppColors.white,
                  ),
                  tooltip: 'Tambah Kost',
                  onPressed: () => context.push(AppRoutes.ownerAddKost),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.logout_rounded,
                    color: AppColors.white,
                  ),
                  onPressed: () => _confirmLogout(context, authProvider),
                ),
              ],
            ),

            if (provider.isLoading)
              SliverPadding(
                padding: const EdgeInsets.all(20),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (_, __) => const Padding(
                      padding: EdgeInsets.only(bottom: 16),
                      child: ShimmerBox(height: 80),
                    ),
                    childCount: 4,
                  ),
                ),
              )
            else ...[
              // Stats Grid
              SliverPadding(
                padding: const EdgeInsets.all(20),
                sliver: SliverGrid(
                  delegate: SliverChildListDelegate([
                    _StatCard(
                      icon: Icons.house_rounded,
                      label: 'Total Kamar',
                      value: '${provider.stats?.totalRooms ?? 0}',
                      color: AppColors.primary,
                    ),
                    _StatCard(
                      icon: Icons.person_rounded,
                      label: 'Kamar Terisi',
                      value: '${provider.stats?.occupiedRooms ?? 0}',
                      subtitle:
                          '${provider.stats?.occupancyRate.toStringAsFixed(0)}%',
                      color: AppColors.success,
                    ),
                    _StatCard(
                      icon: Icons.pending_actions_rounded,
                      label: 'Pengajuan Masuk',
                      value: '${provider.stats?.pendingReservations ?? 0}',
                      color: AppColors.warning,
                      onTap: () => context.go(AppRoutes.reservationManagement),
                    ),
                    _StatCard(
                      icon: Icons.build_circle_rounded,
                      label: 'Tiket Pending',
                      value: '${provider.stats?.pendingTickets ?? 0}',
                      color: AppColors.error,
                      onTap: () => context.go(AppRoutes.ownerTickets),
                    ),
                  ]),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.4,
                  ),
                ),
              ),

              // Recent Reservations Section
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Pengajuan Terbaru', style: AppTextStyles.h3),
                      TextButton(
                        onPressed: () =>
                            context.go(AppRoutes.reservationManagement),
                        child: const Text('Lihat Semua'),
                      ),
                    ],
                  ),
                ),
              ),

              if (provider.pendingReservations.isEmpty)
                SliverToBoxAdapter(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Center(
                      child: Text(
                        'Tidak ada pengajuan pending',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.grey500,
                        ),
                      ),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, i) {
                      final res = provider.pendingReservations[i];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
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
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: AppColors.primary.withValues(
                                alpha: 0.1,
                              ),
                              child: Text(
                                res.renterName.isNotEmpty
                                    ? res.renterName[0].toUpperCase()
                                    : 'A',
                                style: AppTextStyles.labelLarge.copyWith(
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    res.renterName,
                                    style: AppTextStyles.labelLarge,
                                  ),
                                  Text(
                                    res.isSplitBill
                                        ? 'Sewa Patungan (${res.splitMemberCount} orang)'
                                        : 'Sewa Solo',
                                    style: AppTextStyles.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                            if (res.isSplitBill)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.secondary.withValues(
                                    alpha: 0.1,
                                  ),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.people_rounded,
                                      size: 12,
                                      color: AppColors.secondary,
                                    ),
                                    const SizedBox(width: 3),
                                    Text(
                                      'Split',
                                      style: AppTextStyles.caption.copyWith(
                                        color: AppColors.secondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      );
                    }, childCount: provider.pendingReservations.take(3).length),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  void _confirmLogout(BuildContext context, AuthProvider authProvider) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Logout'),
        content: const Text('Apakah Anda yakin ingin keluar?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogCtx);
              await authProvider.logout();
              if (context.mounted) context.go(AppRoutes.login);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String? subtitle;
  final Color color;
  final VoidCallback? onTap;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    this.subtitle,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
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
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(value, style: AppTextStyles.h2.copyWith(color: color)),
                    if (subtitle != null) ...[
                      const SizedBox(width: 4),
                      Text(
                        subtitle!,
                        style: AppTextStyles.caption.copyWith(
                          color: color.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ],
                ),
                Text(label, style: AppTextStyles.bodySmall),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
