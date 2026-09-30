import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/shimmer_loading.dart';
import '../../../../data/models/kost_model.dart';
import '../../../../data/repositories/mock_repository.dart';

// ─── ViewState enum lokal ────────────────────────────────────────────────────
enum _CatalogState { loading, empty, error, success }

class CatalogPage extends StatefulWidget {
  const CatalogPage({super.key});

  @override
  State<CatalogPage> createState() => _CatalogPageState();
}

class _CatalogPageState extends State<CatalogPage> {
  final _repo = MockRepository.instance;
  final _searchCtrl = TextEditingController();
  final _fmt = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  _CatalogState _state = _CatalogState.loading;
  List<KostModel> _kostList = [];
  String _error = '';
  String _filterType = 'ALL';
  bool _simulateError = false;

  final List<Map<String, String>> _filters = const [
    {'value': 'ALL', 'label': 'Semua'},
    {'value': 'PUTRA', 'label': 'Putra'},
    {'value': 'PUTRI', 'label': 'Putri'},
    {'value': 'CAMPUR', 'label': 'Campur'},
  ];

  @override
  void initState() {
    super.initState();
    _loadKost();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadKost({String? search}) async {
    setState(() {
      _state = _CatalogState.loading;
      _error = '';
    });
    try {
      final data = await _repo.getKostList(
        search: search,
        type: _filterType == 'ALL' ? null : _filterType,
        simulateError: _simulateError,
      );
      setState(() {
        _kostList = data;
        _state = data.isEmpty ? _CatalogState.empty : _CatalogState.success;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _state = _CatalogState.error;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffold,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildFilterBar(),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
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
                      'Temukan Kost',
                      style: AppTextStyles.h2.copyWith(color: AppColors.white),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_rounded,
                          color: AppColors.secondaryLight,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Medan, Sumatera Utara',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.white.withValues(alpha: 0.85),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Toggle error simulation (demo)
              GestureDetector(
                onTap: () {
                  setState(() => _simulateError = !_simulateError);
                  _loadKost();
                },
                child: Tooltip(
                  message: _simulateError ? 'Mode Error ON' : 'Mode Normal',
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _simulateError
                          ? AppColors.error.withValues(alpha: 0.3)
                          : AppColors.white.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _simulateError
                          ? Icons.bug_report_rounded
                          : Icons.bug_report_outlined,
                      color: AppColors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Search bar
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: TextField(
              controller: _searchCtrl,
              style: AppTextStyles.bodyMedium,
              onChanged: (v) => _loadKost(search: v.isEmpty ? null : v),
              decoration: InputDecoration(
                hintText: 'Cari nama kost atau alamat...',
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
                          _loadKost();
                        },
                      )
                    : null,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      height: 52,
      color: AppColors.scaffold,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: _filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final f = _filters[i];
          final isSelected = _filterType == f['value'];
          return FilterChip(
            label: Text(f['label']!),
            selected: isSelected,
            onSelected: (_) {
              setState(() => _filterType = f['value']!);
              _loadKost(
                search: _searchCtrl.text.isEmpty ? null : _searchCtrl.text,
              );
            },
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

  Widget _buildBody() {
    switch (_state) {
      case _CatalogState.loading:
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: 5,
          itemBuilder: (_, __) => const Padding(
            padding: EdgeInsets.only(bottom: 16),
            child: KostCardShimmer(),
          ),
        );

      case _CatalogState.empty:
        return EmptyState(
          icon: Icons.search_off_rounded,
          title: 'Kost Tidak Ditemukan',
          subtitle: 'Coba ubah kata kunci atau filter pencarian.',
          buttonLabel: 'Reset Pencarian',
          onButtonTap: () {
            _searchCtrl.clear();
            setState(() => _filterType = 'ALL');
            _loadKost();
          },
        );

      case _CatalogState.error:
        return ErrorState(message: _error, onRetry: _loadKost);

      case _CatalogState.success:
        return RefreshIndicator(
          color: AppColors.primary,
          onRefresh: _loadKost,
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            itemCount: _kostList.length + 1,
            itemBuilder: (ctx, i) {
              if (i == 0) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12, top: 4),
                  child: Text(
                    '${_kostList.length} properti ditemukan',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.grey500,
                    ),
                  ),
                );
              }
              final kost = _kostList[i - 1];
              return _KostCard(
                kost: kost,
                currencyFmt: _fmt,
                onTap: () => context.push('/kost/${kost.id}'),
              );
            },
          ),
        );
    }
  }
}

// ─── KostCard ────────────────────────────────────────────────────────────────
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
            // Image
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
                          errorWidget: (_, __, ___) => _imagePlaceholder(),
                        )
                      : _imagePlaceholder(),
                ),
                Positioned(
                  top: 12,
                  left: 12,
                  child: _TypeBadge(type: kost.type),
                ),
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
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: kost.facilities
                        .take(3)
                        .map((f) => _FacilityTag(label: f))
                        .toList(),
                  ),
                  const SizedBox(height: 12),
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
                              ? '${kost.availableRooms} tersedia'
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

  Widget _imagePlaceholder() => Container(
    height: 180,
    color: AppColors.grey200,
    child: const Center(
      child: Icon(Icons.home_outlined, size: 48, color: AppColors.grey400),
    ),
  );
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        'Kost $type',
        style: AppTextStyles.labelSmall.copyWith(color: AppColors.white),
      ),
    );
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
