import '../../../../core/utils/image_url.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../data/models/ticket_model.dart';
import '../../../../data/models/reservation_model.dart';
import '../../../../data/repositories/ticket_repository.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/renter_ticket_provider.dart';

class TicketFormPage extends StatefulWidget {
  final TicketModel? existingTicket;
  const TicketFormPage({super.key, this.existingTicket});
  @override
  State<TicketFormPage> createState() => _TicketFormPageState();
}

class _TicketFormPageState extends State<TicketFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleCtrl, _descCtrl;
  late final List<TextEditingController> _photoControllers;
  String _category = 'LISTRIK';
  DateTime _incidentDate = DateTime.now();
  String? _uid, _reservationId;
  Future<List<ReservationModel>>? _choices;
  bool get _isEdit => widget.existingTicket != null;

  @override
  void initState() {
    super.initState();
    final ticket = widget.existingTicket;
    _titleCtrl = TextEditingController(text: ticket?.title ?? '');
    _descCtrl = TextEditingController(text: ticket?.description ?? '');
    _photoControllers = List.generate(
      3,
      (i) => TextEditingController(
        text: ticket != null && i < ticket.imageUrls.length
            ? ticket.imageUrls[i]
            : '',
      ),
    );
    if (ticket != null) {
      _category = ticket.category;
      _incidentDate = ticket.incidentDate;
      _reservationId = ticket.reservationId;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final uid = context.watch<AuthProvider>().currentUser?.id;
    if (_uid != uid) {
      _uid = uid;
      if (!_isEdit) {
        _reservationId = null;
        _choices = uid == null
            ? null
            : context.read<TicketRepository>().eligibleReservations(uid);
      }
    }
  }

  void _reloadChoices() {
    final uid = _uid;
    if (uid == null) return;
    setState(() {
      _choices = context.read<TicketRepository>().eligibleReservations(uid);
    });
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    for (final controller in _photoControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _selectDate() async {
    final now = DateTime.now();
    final first = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(const Duration(days: 365));
    final initial = _incidentDate.isBefore(first)
        ? first
        : (_incidentDate.isAfter(now) ? now : _incidentDate);
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: first,
      lastDate: now,
    );
    if (date != null && mounted) setState(() => _incidentDate = date);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final provider = context.read<RenterTicketProvider>();
    if (provider.isSubmitting) return;
    try {
      final photos = _photoControllers
          .map((controller) => controller.text.trim())
          .where((url) => url.isNotEmpty)
          .toList();
      final TicketModel? result;
      if (_isEdit) {
        result = await provider.updateTicket(
          id: widget.existingTicket!.id,
          title: _titleCtrl.text,
          description: _descCtrl.text,
          category: _category,
          incidentDate: _incidentDate,
          imageUrls: photos,
        );
      } else {
        if (_reservationId == null) return;
        result = await provider.createTicket(
          reservationId: _reservationId!,
          title: _titleCtrl.text,
          description: _descCtrl.text,
          category: _category,
          incidentDate: _incidentDate,
          imageUrls: photos,
        );
      }
      if (!mounted || result == null) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEdit
                ? 'Laporan berhasil diperbarui!'
                : 'Laporan berhasil dibuat!',
          ),
          backgroundColor: AppColors.success,
        ),
      );
      context.pop();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(TicketRepository.errorMessage(error)),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Widget _form(List<ReservationModel> choices) {
    final provider = context.watch<RenterTicketProvider>();
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_isEdit)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.home_outlined),
                title: Text(widget.existingTicket!.kostName),
                subtitle: const Text('Kost yang dilaporkan'),
              )
            else ...[
              DropdownButtonFormField<String>(
                key: ValueKey(_uid),
                initialValue: _reservationId,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Kost yang Disewa *',
                  prefixIcon: Icon(Icons.home_outlined),
                ),
                items: choices
                    .map(
                      (item) => DropdownMenuItem(
                        value: item.id,
                        child: Text(
                          item.kostName,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList(),
                onChanged: provider.isSubmitting
                    ? null
                    : (value) => setState(() => _reservationId = value),
                validator: (value) => value == null
                    ? 'Pilih kost dari reservasi yang sudah disetujui.'
                    : null,
              ),
              const SizedBox(height: 20),
            ],
            AppTextField(
              controller: _titleCtrl,
              label: 'Judul Laporan *',
              hint: 'Contoh: Lampu kamar tidak menyala',
              maxLength: 100,
              validator: (value) => (value?.trim().length ?? 0) < 5
                  ? 'Judul minimal 5 karakter.'
                  : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _category,
              decoration: const InputDecoration(
                labelText: 'Kategori Kerusakan *',
              ),
              items: TicketRepository.categoryLabels.entries
                  .map(
                    (item) => DropdownMenuItem(
                      value: item.key,
                      child: Text(item.value),
                    ),
                  )
                  .toList(),
              onChanged: provider.isSubmitting
                  ? null
                  : (value) => setState(() => _category = value!),
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_today_outlined),
              title: const Text('Tanggal Kejadian *'),
              subtitle: Text(
                DateFormat('dd MMMM yyyy', 'id_ID').format(_incidentDate),
              ),
              trailing: const Icon(Icons.edit_calendar_outlined),
              onTap: provider.isSubmitting ? null : _selectDate,
            ),
            const SizedBox(height: 16),
            AppTextField(
              controller: _descCtrl,
              label: 'Deskripsi Kerusakan *',
              hint: 'Jelaskan lokasi dan kondisi kerusakan',
              maxLines: 5,
              maxLength: 500,
              validator: (value) => (value?.trim().length ?? 0) < 15
                  ? 'Deskripsi minimal 15 karakter.'
                  : null,
            ),
            const SizedBox(height: 16),
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              title: const Text('Foto (opsional)'),
              subtitle: const Text('Maksimal 3 tautan foto HTTPS'),
              children: List.generate(
                3,
                (i) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: AppTextField(
                    controller: _photoControllers[i],
                    label: 'Tautan Foto ${i + 1}',
                    hint: 'https://...',
                    maxLength: 2048,
                    validator: (value) {
                      final url = ImageUrl.normalizeInput(value ?? '');
                      return url.isEmpty || ImageUrl.isValid(url)
                          ? null
                          : 'Masukkan tautan foto HTTPS yang valid.';
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(height: 28),
            AppButton(
              text: _isEdit ? 'Simpan Perubahan' : 'Kirim Laporan',
              isFullWidth: true,
              isLoading: provider.isSubmitting,
              onPressed: provider.isSubmitting ? null : _submit,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffold,
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit Laporan' : 'Buat Laporan Baru'),
      ),
      body: _uid == null
          ? const Center(child: Text('Silakan login sebagai penyewa.'))
          : _isEdit
          ? _form([])
          : FutureBuilder<List<ReservationModel>>(
              future: _choices,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return ErrorState(
                    message: TicketRepository.errorMessage(snapshot.error!),
                    onRetry: _reloadChoices,
                  );
                }
                final choices = snapshot.data ?? [];
                if (choices.isEmpty) {
                  return EmptyState(
                    icon: Icons.home_outlined,
                    title: 'Belum ada reservasi yang disetujui',
                    subtitle:
                        'Laporan dapat dibuat untuk kost setelah pemilik menyetujui reservasimu.',
                    buttonLabel: 'Muat Ulang',
                    onButtonTap: _reloadChoices,
                  );
                }
                return _form(choices);
              },
            ),
    );
  }
}
