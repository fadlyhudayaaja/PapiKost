import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/providers/auth_provider.dart';
import 'features/kost/presentation/providers/kost_provider.dart';
import 'features/owner/presentation/providers/owner_provider.dart';
import 'features/papibot/presentation/providers/papibot_provider.dart';
import 'features/renter/ticket/providers/renter_ticket_provider.dart';
import 'features/ticket/presentation/providers/ticket_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

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
  final authProvider = AuthProvider();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
        ChangeNotifierProvider(create: (_) => KostProvider()),
        ChangeNotifierProvider(create: (_) => PapibotProvider()),
        ChangeNotifierProvider(create: (_) => TicketProvider()),
        ChangeNotifierProvider(create: (_) => OwnerProvider()),
        // Provider untuk CRUD Laporan Kerusakan (Renter UTS)
        ChangeNotifierProvider(create: (_) => RenterTicketProvider()),
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
