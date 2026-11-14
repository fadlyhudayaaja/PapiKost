import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/admin_users_provider.dart';

String _roleLabel(String role) => switch (role) {
  'OWNER' => 'Pemilik',
  'RENTER' => 'Penyewa',
  'ADMIN' => 'Admin',
  _ => role,
};

class AdminUsersPage extends StatefulWidget {
  const AdminUsersPage({super.key});

  @override
  State<AdminUsersPage> createState() => _AdminUsersPageState();
}

class _AdminUsersPageState extends State<AdminUsersPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<AdminUsersProvider>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdminUsersProvider>();
    final users = provider.users;
    return Scaffold(
      backgroundColor: AppColors.scaffold,
      appBar: AppBar(
        title: const Text('Manajemen Pengguna'),
        actions: [
          IconButton(
            tooltip: 'Muat ulang',
            onPressed: provider.state == UsersLoadState.loading
                ? null
                : provider.load,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              onChanged: provider.search,
              decoration: const InputDecoration(
                hintText: 'Cari nama, email, nomor HP, atau UID',
                prefixIcon: Icon(Icons.search_rounded),
              ),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                for (final role in <String?>[null, 'RENTER', 'OWNER', 'ADMIN'])
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(role == null ? 'Semua' : _roleLabel(role)),
                      selected: provider.role == role,
                      onSelected: (_) => provider.filterRole(role),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              provider.state == UsersLoadState.loaded
                  ? '${users.length} dari ${provider.total} pengguna'
                  : 'Daftar pengguna terdaftar',
            ),
          ),
          Expanded(
            child: switch (provider.state) {
              UsersLoadState.initial || UsersLoadState.loading => const Center(
                child: CircularProgressIndicator(),
              ),
              UsersLoadState.error => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.cloud_off_rounded,
                        size: 48,
                        color: AppColors.grey400,
                      ),
                      const SizedBox(height: 16),
                      Text(provider.error!, textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: provider.load,
                        child: const Text('Coba Lagi'),
                      ),
                    ],
                  ),
                ),
              ),
              UsersLoadState.loaded =>
                users.isEmpty
                    ? Center(
                        child: Text(
                          provider.total == 0
                              ? 'Belum ada pengguna terdaftar.'
                              : 'Tidak ada pengguna yang cocok.',
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: provider.load,
                        child: ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                          itemCount: users.length,
                          itemBuilder: (context, index) {
                            final user = users[index];
                            return Card(
                              child: ListTile(
                                leading: CircleAvatar(
                                  child: Text(
                                    user.name.isEmpty
                                        ? '?'
                                        : user.name[0].toUpperCase(),
                                  ),
                                ),
                                title: Text(user.name),
                                subtitle: Text(
                                  '${user.email}\n${_roleLabel(user.role)}${user.role == 'OWNER' && user.isVerified ? ' • Terverifikasi' : ''}',
                                ),
                                isThreeLine: true,
                                trailing: const Icon(
                                  Icons.chevron_right_rounded,
                                ),
                                onTap: () => _showUser(context, user.id),
                              ),
                            );
                          },
                        ),
                      ),
            },
          ),
        ],
      ),
    );
  }

  void _showUser(BuildContext context, String id) {
    final provider = context.read<AdminUsersProvider>();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => ChangeNotifierProvider.value(
        value: provider,
        child: _UserDetails(id: id),
      ),
    );
  }
}

class _UserDetails extends StatelessWidget {
  const _UserDetails({required this.id});
  final String id;

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AdminUsersProvider>().userById(id);
    if (user == null) {
      return const SafeArea(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text('Data pengguna tidak tersedia.'),
        ),
      );
    }
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Detail Pengguna',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            for (final entry in <String, String>{
              'Nama': user.name,
              'Email': user.email,
              'Nomor HP': user.phone,
              'Peran': _roleLabel(user.role),
              'UID': user.id,
              if (user.role == 'OWNER')
                'Verifikasi': user.isVerified
                    ? 'Terverifikasi'
                    : 'Belum terverifikasi',
              'Terdaftar': user.createdAt == null
                  ? 'Belum tersedia'
                  : DateFormat(
                      'dd MMM yyyy HH:mm',
                      'id_ID',
                    ).format(user.createdAt!),
              if (user.bio?.isNotEmpty == true) 'Bio': user.bio!,
            }.entries) ...[
              Text(entry.key, style: const TextStyle(color: AppColors.grey500)),
              SelectableText(entry.value),
              const SizedBox(height: 12),
            ],
            if (user.role == 'OWNER')
              ElevatedButton.icon(
                icon: const Icon(Icons.verified_user_outlined),
                label: const Text('Buka Verifikasi Pemilik'),
                onPressed: () {
                  // Ambil router sebelum bottom sheet dilepas dari tree.
                  final router = GoRouter.of(context);
                  Navigator.pop(context);
                  router.push(AppRoutes.adminVerifyOwners);
                },
              ),
          ],
        ),
      ),
    );
  }
}
