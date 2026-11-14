import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'data/repositories/auth_repository.dart';
import 'data/repositories/admin_user_repository.dart';
import 'data/repositories/kost_repository.dart';
import 'data/repositories/owner_verification_repository.dart';
import 'data/repositories/reservation_repository.dart';
import 'data/repositories/ticket_repository.dart';
import 'features/admin/presentation/providers/admin_provider.dart';
import 'features/admin/presentation/providers/admin_users_provider.dart';
import 'features/auth/presentation/providers/auth_provider.dart';
import 'features/kost/presentation/providers/kost_provider.dart';
import 'features/owner/presentation/providers/owner_provider.dart';
import 'features/papibot/presentation/providers/papibot_provider.dart';
import 'features/renter/ticket/providers/renter_ticket_provider.dart';

Future<void> main() => runPapiKost();

Future<void> runPapiKost({
  AuthRepository? authRepository,
  KostRepository? kostRepository,
  ReservationRepository? reservationRepository,
  TicketRepository? ticketRepository,
  OwnerVerificationRepository? ownerVerificationRepository,
  AdminUserRepository? adminUserRepository,
}) async {
  WidgetsFlutterBinding.ensureInitialized();

  // Android membaca konfigurasi dari android/app/google-services.json.
  // Platform lain perlu didaftarkan di Firebase sebelum diaktifkan.
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    await Firebase.initializeApp();
  }

  // Siapkan format tanggal sebelum provider, router, dan halaman dibuat.
  await initializeDateFormatting('id_ID');
  Intl.defaultLocale = 'id_ID';

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // AuthProvider dibuat sekali di luar widget tree
  // agar GoRouter bisa pakai instance yang sama
  final authProvider = AuthProvider(repository: authRepository);

  runApp(
    MultiProvider(
      providers: [
        Provider<OwnerVerificationRepository>.value(
          value:
              ownerVerificationRepository ??
              OwnerVerificationRepository.instance,
        ),
        ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
        Provider<KostRepository>.value(
          value: kostRepository ?? KostRepository.instance,
        ),
        Provider<ReservationRepository>.value(
          value: reservationRepository ?? ReservationRepository.instance,
        ),
        Provider<TicketRepository>.value(
          value: ticketRepository ?? TicketRepository.instance,
        ),
        ChangeNotifierProvider(
          create: (context) =>
              KostProvider(repository: context.read<KostRepository>()),
        ),
        ChangeNotifierProvider(create: (_) => PapibotProvider()),
        ChangeNotifierProxyProvider<AuthProvider, OwnerProvider>(
          create: (context) => OwnerProvider(
            repository: context.read<KostRepository>(),
            reservationRepository: context.read<ReservationRepository>(),
            ticketRepository: context.read<TicketRepository>(),
          ),
          update: (_, auth, owner) => owner!..bindUser(auth.currentUser),
        ),
        // Provider untuk CRUD Laporan Kerusakan (Renter UTS)
        ChangeNotifierProxyProvider<AuthProvider, RenterTicketProvider>(
          create: (context) => RenterTicketProvider(
            repository: context.read<TicketRepository>(),
          ),
          update: (_, auth, tickets) => tickets!..bindUser(auth.currentUser),
        ),
        // Provider untuk Admin (verifikasi berkas)
        ChangeNotifierProxyProvider<AuthProvider, AdminUsersProvider>(
          create: (_) => AdminUsersProvider(repository: adminUserRepository),
          update: (_, auth, users) => users!..bindUser(auth.currentUser),
        ),
        ChangeNotifierProxyProvider<AuthProvider, AdminProvider>(
          create: (_) => AdminProvider(repository: ownerVerificationRepository),
          update: (_, auth, admin) => admin!..bindUser(auth.currentUser),
        ),
      ],
      child: PapiKostApp(authProvider: authProvider),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Root widget — router dibuat SEKALI di initState, tidak rebuild
// ─────────────────────────────────────────────────────────────────────────────
class PapiKostApp extends StatefulWidget {
  final AuthProvider authProvider;
  const PapiKostApp({super.key, required this.authProvider});

  @override
  State<PapiKostApp> createState() => _PapiKostAppState();
}

class _PapiKostAppState extends State<PapiKostApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    // Router dibuat satu kali — refreshListenable mendeteksi semua
    // perubahan AuthStatus (login, logout, checkAuth) otomatis
    _router = createRouter(widget.authProvider);
  }

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'PapiKost',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: _router,
    );
  }
}
