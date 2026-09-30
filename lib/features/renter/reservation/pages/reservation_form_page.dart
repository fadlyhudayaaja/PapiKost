import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../data/models/kost_model.dart';
import '../../../../data/repositories/mock_repository.dart';

class ReservationFormPage extends StatefulWidget {
  final KostModel kost;
  final bool isSplitBill;

  const ReservationFormPage({
    super.key,
    required this.kost,
    required this.isSplitBill,
  });

  @override
  State<ReservationFormPage> createState() => _ReservationFormPageState();
}

class _ReservationFormPageState extends State<ReservationFormPage> {
  final _repo = MockRepository.instance;
  final _notesCtrl = TextEditingController();
  final _dateFmt = DateFormat('dd MMMM yyyy', 'id_ID');
  final _currFmt = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  int _memberCount = 2;
  DateTime _checkInDate = DateTime.now().add(const Duration(days: 7));
  bool _isSubmitting = false;

  double get _pricePerPerson => widget.kost.pricePerMonth / _memberCount;

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _checkInDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _checkInDate = picked);
  }

  Future<void> _submit() async {
    if (_isSubmitting) return; // cegah double submit
    setState(() => _isSubmitting = true);
    try {
      final reservation = await _repo.createReservation(
        kostId: widget.kost.id,
        isSplitBill: widget.isSplitBill,
        splitMemberCount: widget.isSplitBill ? _memberCount : null,
        checkInDate: _checkInDate,
        notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      );
      if (!mounted) return;
      context.go(AppRoutes.reservationSuccess, extra: reservation);
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
        title: Text(widget.isSplitBill ? 'Sewa Patungan' : 'Sewa Solo'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Info kost
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.grey200),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.home_rounded,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.kost.name,
                            style: AppTextStyles.labelLarge,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            widget.kost.address,
                            style: AppTextStyles.bodySmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ── Split Bill Member Selector ──────────────────────────
              if (widget.isSplitBill) ...[
                Text('Jumlah Anggota Patungan', style: AppTextStyles.h4),
                const SizedBox(height: 4),
                Text(
                  'Pilih berapa orang yang akan berbagi biaya (2–4 orang)',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.grey500,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _CounterBtn(
                      icon: Icons.remove_rounded,
                      enabled: _memberCount > AppConstants.minSplitMembers,
                      onTap: () => setState(() => _memberCount--),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 28),
                      child: Column(
                        children: [
                          Text(
                            '$_memberCount',
                            style: AppTextStyles.displayLarge.copyWith(
                              color: AppColors.primary,
                            ),
                          ),
                          Text('orang', style: AppTextStyles.bodySmall),
                        ],
                      ),
                    ),
                    _CounterBtn(
                      icon: Icons.add_rounded,
                      enabled: _memberCount < AppConstants.maxSplitMembers,
                      onTap: () => setState(() => _memberCount++),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Breakdown harga real-time
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.secondary.withValues(alpha: 0.08),
                        AppColors.secondary.withValues(alpha: 0.03),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.secondary.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Column(
                    children: [
                      _PriceRow(
                        label: 'Total Sewa/Bulan',
                        value: _currFmt.format(widget.kost.pricePerMonth),
                      ),
                      const Divider(height: 14),
                      _PriceRow(label: 'Dibagi $_memberCount orang', value: ''),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Per Orang/Bulan',
                            style: AppTextStyles.labelLarge.copyWith(
                              color: AppColors.secondary,
                            ),
                          ),
                          Text(
                            _currFmt.format(_pricePerPerson),
                            style: AppTextStyles.priceLarge.copyWith(
                              color: AppColors.secondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ] else ...[
                // Solo price
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.15),
                    ),
                  ),
                  child: _PriceRow(
                    label: 'Total Sewa/Bulan',
                    value: _currFmt.format(widget.kost.pricePerMonth),
                    isTotal: true,
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // ── Tanggal Check-in ────────────────────────────────────
              Text('Tanggal Mulai Sewa *', style: AppTextStyles.labelLarge),
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
                        _dateFmt.format(_checkInDate),
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

              // ── Catatan ─────────────────────────────────────────────
              Text('Catatan (Opsional)', style: AppTextStyles.labelLarge),
              const SizedBox(height: 8),
              TextField(
                controller: _notesCtrl,
                maxLines: 3,
                style: AppTextStyles.bodyMedium,
                decoration: InputDecoration(
                  hintText: 'Tuliskan pesan untuk pemilik kost...',
                  hintStyle: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.grey400,
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // ── Submit ──────────────────────────────────────────────
              AppButton(
                text: widget.isSplitBill
                    ? 'Ajukan Sewa Patungan'
                    : 'Ajukan Sewa',
                backgroundColor: widget.isSplitBill
                    ? AppColors.secondary
                    : AppColors.primary,
                isFullWidth: true,
                isLoading: _isSubmitting,
                onPressed: _isSubmitting ? null : _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CounterBtn extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  const _CounterBtn({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: enabled ? AppColors.primary : AppColors.grey200,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: AppColors.white, size: 22),
      ),
    );
  }
}

class _PriceRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isTotal;

  const _PriceRow({
    required this.label,
    required this.value,
    this.isTotal = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: isTotal ? AppTextStyles.labelLarge : AppTextStyles.bodyMedium,
        ),
        if (value.isNotEmpty)
          Text(
            value,
            style: isTotal ? AppTextStyles.price : AppTextStyles.bodyMedium,
          ),
      ],
    );
  }
}
