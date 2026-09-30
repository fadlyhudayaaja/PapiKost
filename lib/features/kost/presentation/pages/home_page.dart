import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/shimmer_loading.dart';
import '../../../../data/models/kost_model.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';
import '../providers/kost_provider.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _searchCtrl = TextEditingController();
  final _currencyFmt = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<KostProvider>().fetchKostList();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final kostProvider = context.watch<KostProvider>();

    return Scaffold(
      backgroundColor: AppColors.scaffold,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () => kostProvider.fetchKostList(),
          child: CustomScrollView(
            slivers: [
              // App Header
              SliverToBoxAdapter(
                child: _buildHeader(
                  authProvider.currentUser?.name ?? 'Pengguna',
                ),
              ),

              // Search Bar
              SliverToBoxAdapter(child: _buildSearchBar(kostProvider)),

              // Filter Chips
              SliverToBoxAdapter(child: _buildFilterChips(kostProvider)),

              // Promo Banner
              SliverToBoxAdapter(child: _buildPromoBanner()),

              // Section Title
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Kost Tersedia', style: AppTextStyles.h3),
                      Text(
                        '${kostProvider.filteredList.length} properti',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.grey500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Kost List
              if (kostProvider.isLoading)
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (_, __) => const KostCardShimmer(),
                      childCount: 3,
                    ),
                  ),
                )
              else if (kostProvider.filteredList.isEmpty)
                SliverFillRemaining(child: _buildEmptyState())
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      return _KostCard(
                        kost: kostProvider.filteredList[index],
                        currencyFmt: _currencyFmt,
                        onTap: () => context.push(
                          '/kost/${kostProvider.filteredList[index].id}',
                        ),
                      );
                    }, childCount: kostProvider.filteredList.length),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(String userName) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Halo, $userName 👋',
                      style: AppTextStyles.h3.copyWith(color: AppColors.white),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_rounded,
                          color: AppColors.secondaryLight,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Medan, Sumatera Utara',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.white.withValues(alpha: 0.9),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              CircleAvatar(
                radius: 22,
                backgroundColor: AppColors.white.withValues(alpha: 0.2),
                child: const Icon(
                  Icons.person_rounded,
                  color: AppColors.white,
                  size: 26,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(KostProvider provider) {
    return Container(
      color: AppColors.primary,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: TextField(
          controller: _searchCtrl,
          style: AppTextStyles.bodyMedium,
          onChanged: (val) {
            provider.setSearch(val);
            if (val.isEmpty || val.length >= 3) {
              provider.fetchKostList(search: val);
            }
          },
          decoration: InputDecoration(
            hintText: 'Cari kost dekat USU, Fasilkom...',
            hintStyle: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.grey400,
            ),
            prefixIcon: const Icon(
              Icons.search_rounded,
              color: AppColors.grey400,
            ),
            suffixIcon: _searchCtrl.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(
                      Icons.clear_rounded,
                      color: AppColors.grey400,
                    ),
                    onPressed: () {
                      _searchCtrl.clear();
                      provider.setSearch('');
                      provider.fetchKostList();
                    },
                  )
                : null,
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            filled: false,
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChips(KostProvider provider) {
    final filters = [
      {'value': 'ALL', 'label': 'Semua'},
      {'value': 'PUTRA', 'label': 'Putra'},
      {'value': 'PUTRI', 'label': 'Putri'},
      {'value': 'CAMPUR', 'label': 'Campur'},
    ];

    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final filter = filters[i];
          final isSelected = provider.filterType == filter['value'];
          return FilterChip(
            label: Text(filter['label']!),
            selected: isSelected,
            onSelected: (_) => provider.setFilter(filter['value']!),
            selectedColor: AppColors.primary,
            backgroundColor: AppColors.white,
            labelStyle: AppTextStyles.labelMedium.copyWith(
              color: isSelected ? AppColors.white : AppColors.grey700,
            ),
            side: BorderSide(
              color: isSelected ? AppColors.primary : AppColors.grey300,
            ),
            checkmarkColor: AppColors.white,
          );
        },
      ),
    );
  }

  Widget _buildPromoBanner() {
    return Container(
      height: 140,
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0097A7), Color(0xFF00BCD4)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            bottom: -20,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.white.withValues(alpha: 0.1),
              ),
            ),
          ),
          Positioned(
            right: 20,
            top: -10,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.white.withValues(alpha: 0.08),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'FITUR BARU',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Sewa Patungan\nBareng Teman!',
                  style: AppTextStyles.h3.copyWith(
                    color: AppColors.white,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Split biaya, hemat lebih banyak',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.white.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.search_off_rounded,
            size: 64,
            color: AppColors.grey300,
          ),
          const SizedBox(height: 16),
          Text('Tidak ada kost ditemukan', style: AppTextStyles.h4),
          const SizedBox(height: 8),
          Text(
            'Coba ubah kata kunci pencarian',
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.grey500),
          ),
        ],
      ),
    );
  }
}

class _KostCard extends StatelessWidget {
  final KostModel kost;
  final NumberFormat currencyFmt;
  final VoidCallback onTap;

  const _KostCard({
    required this.kost,
    required this.currencyFmt,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.07),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image dengan Badges
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                  child: kost.imageUrls.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: kost.imageUrls.first,
                          height: 180,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => const ShimmerBox(height: 180),
                          errorWidget: (_, __, ___) => Container(
                            height: 180,
                            color: AppColors.grey200,
                            child: const Icon(
                              Icons.home_outlined,
                              size: 48,
                              color: AppColors.grey400,
                            ),
                          ),
                        )
                      : Container(
                          height: 180,
                          color: AppColors.grey200,
                          child: const Icon(
                            Icons.home_outlined,
                            size: 48,
                            color: AppColors.grey400,
                          ),
                        ),
                ),

                // Type Badge
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: _getTypeColor(kost.type),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Kost ${kost.type}',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.white,
                      ),
                    ),
                  ),
                ),

                // Split Bill Badge
                if (kost.isSplitBillAvailable)
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.secondary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.people_rounded,
                            color: AppColors.white,
                            size: 12,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Patungan',
                            style: AppTextStyles.labelSmall.copyWith(
                              color: AppColors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name & Rating
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          kost.name,
                          style: AppTextStyles.h4,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (kost.rating != null) ...[
                        const Icon(
                          Icons.star_rounded,
                          color: Color(0xFFFFB300),
                          size: 16,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          kost.rating!.toStringAsFixed(1),
                          style: AppTextStyles.labelMedium,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),

                  // Address
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        size: 14,
                        color: AppColors.grey500,
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
                  const SizedBox(height: 10),

                  // Facilities
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: kost.facilities
                        .take(3)
                        .map((f) => _FacilityTag(label: f))
                        .toList(),
                  ),
                  const SizedBox(height: 12),

                  // Price & Availability
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            currencyFmt.format(kost.pricePerMonth),
                            style: AppTextStyles.price,
                          ),
                          Text('/bulan', style: AppTextStyles.caption),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: kost.availableRooms > 0
                              ? AppColors.successLight
                              : AppColors.errorLight,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          kost.availableRooms > 0
                              ? '${kost.availableRooms} kamar tersedia'
                              : 'Penuh',
                          style: AppTextStyles.labelSmall.copyWith(
                            color: kost.availableRooms > 0
                                ? AppColors.success
                                : AppColors.error,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'PUTRA':
        return const Color(0xFF1565C0);
      case 'PUTRI':
        return const Color(0xFFAD1457);
      default:
        return const Color(0xFF2E7D32);
    }
  }
}

class _FacilityTag extends StatelessWidget {
  final String label;
  const _FacilityTag({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.primaryLight.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: AppTextStyles.caption.copyWith(color: AppColors.primaryLight),
      ),
    );
  }
}
