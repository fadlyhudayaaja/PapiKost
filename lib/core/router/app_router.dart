import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/splash/presentation/pages/splash_page.dart';

// ── Renter Shell & shared ──
import '../../features/kost/presentation/pages/renter_shell_page.dart';
import '../../features/papibot/presentation/pages/papibot_page.dart';

// ── Renter Catalog ──
import '../../features/renter/catalog/pages/catalog_page.dart';
import '../../features/renter/catalog/pages/kost_detail_page.dart';

// ── Renter Reservation ──
import '../../features/renter/reservation/pages/reservation_form_page.dart';
import '../../features/renter/reservation/pages/reservation_success_page.dart';
import '../../features/kost/presentation/pages/reservation_history_page.dart';

// ── Renter Ticket (CRUD) ──
import '../../features/renter/ticket/pages/ticket_list_page.dart'
    as renter_ticket;
import '../../features/renter/ticket/pages/ticket_form_page.dart';
import '../../features/renter/ticket/pages/ticket_detail_page.dart';

// ── Renter Profile ──
import '../../features/renter/profile/pages/renter_profile_page.dart';
import '../../features/renter/profile/pages/edit_profile_page.dart';

// ── Owner ──
import '../../features/owner/presentation/pages/owner_shell_page.dart';
import '../../features/owner/presentation/pages/owner_dashboard_page.dart';
import '../../features/owner/presentation/pages/owner_profile_page.dart';
import '../../features/owner/presentation/pages/reservation_management_page.dart';
import '../../features/owner/presentation/pages/owner_ticket_page.dart';
import '../../features/owner/presentation/pages/add_kost_page.dart';

// ── Admin ──
import '../../features/admin/presentation/pages/admin_dashboard_page.dart';
import '../../features/admin/presentation/pages/owner_verification_page.dart';

import '../../core/constants/app_constants.dart';
import '../../data/models/kost_model.dart';
import '../../data/models/reservation_model.dart';
import '../../data/models/ticket_model.dart';

// ═══════════════════════════════════════════════════════════════════════════
// ROUTE CONSTANTS
// ═══════════════════════════════════════════════════════════════════════════
class AppRoutes {
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';

  // ── Renter Shell tabs ──────────────────────────────────────────────────────
  static const String renterHome = '/renter';
  static const String papibot = '/papibot';
  static const String renterTickets = '/tickets';
  static const String renterProfile = '/renter/profile';

  // ── Renter full-screen pages ──────────────────────────────────────────────
  static const String kostDetail = '/kost/:id';
  static const String reservationForm = '/reservation/form';
  static const String reservationSuccess = '/reservation/success';
  static const String renterReservations = '/renter/reservations';

  // ── Ticket CRUD ───────────────────────────────────────────────────────────
  static const String createTicketRenter = '/tickets/create';
  static const String editTicketRenter = '/tickets/edit';
  static const String ticketDetailRenter = '/tickets/detail';

  // ── Profile ───────────────────────────────────────────────────────────────
  static const String editProfileRenter = '/renter/profile/edit';

  // ── Owner ─────────────────────────────────────────────────────────────────
  static const String ownerDashboard = '/owner';
  static const String ownerProfile = '/owner/profile';
  static const String ownerAddKost = '/owner/kost/add';
  static const String reservationManagement = '/owner/reservations';
  static const String ownerTickets = '/owner/tickets';

  // ── Admin ─────────────────────────────────────────────────────────────────
  static const String adminDashboard = '/admin';
  static const String adminVerifyOwners = '/admin/verify-owners';
}

// ═══════════════════════════════════════════════════════════════════════════
// ROUTER
// ═══════════════════════════════════════════════════════════════════════════
GoRouter createRouter(AuthProvider authProvider) {
  return GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: authProvider,
    redirect: (BuildContext context, GoRouterState state) {
      final status = authProvider.status;
      final location = state.matchedLocation;

      if (status == AuthStatus.initial || status == AuthStatus.loading) {
        return null;
      }

      final isAuth = status == AuthStatus.authenticated;
      final isOnSplash = location == AppRoutes.splash;
      final isOnAuth =
          location == AppRoutes.login || location == AppRoutes.register;

      if (isOnSplash) {
        if (isAuth) return _dashboardFor(authProvider.userRole);
        return AppRoutes.login;
      }
      if (!isAuth && !isOnAuth) return AppRoutes.login;
      if (isAuth && isOnAuth) {
        return _dashboardFor(authProvider.userRole);
      }

      // Role guard
      if (isAuth) {
        final role = authProvider.userRole;
        final inOwner = location.startsWith('/owner');
        final inRenter =
            location.startsWith('/renter') ||
            location.startsWith('/papibot') ||
            location.startsWith('/tickets') ||
            location.startsWith('/kost') ||
            location.startsWith('/reservation');
        final inAdmin = location.startsWith('/admin');

        if (role == AppConstants.roleOwner && inRenter) {
          return AppRoutes.ownerDashboard;
        }
        if (role == AppConstants.roleRenter && inOwner) {
          return AppRoutes.renterHome;
        }
        if (role == AppConstants.roleAdmin && (inOwner || inRenter)) {
          return AppRoutes.adminDashboard;
        }
        if (role != AppConstants.roleAdmin && inAdmin) {
          return _dashboardFor(role);
        }
      }
      return null;
    },

    routes: [
      // ── Splash ─────────────────────────────────────────────────────────────
      GoRoute(path: AppRoutes.splash, builder: (_, __) => const SplashPage()),

      // ── Auth ───────────────────────────────────────────────────────────────
      GoRoute(path: AppRoutes.login, builder: (_, __) => const LoginPage()),
      GoRoute(
        path: AppRoutes.register,
        builder: (_, __) => const RegisterPage(),
      ),

      // ── Renter Shell (BottomNav) ────────────────────────────────────────────
      ShellRoute(
        builder: (_, __, child) => RenterShellPage(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.renterHome,
            builder: (_, __) => const CatalogPage(),
          ),
          GoRoute(
            path: AppRoutes.papibot,
            builder: (_, __) => const PapibotPage(),
          ),
          GoRoute(
            path: AppRoutes.renterTickets,
            builder: (_, __) => const renter_ticket.RenterTicketListPage(),
          ),
          GoRoute(
            path: AppRoutes.renterProfile,
            builder: (_, __) => const RenterProfilePage(),
          ),
        ],
      ),

      // ── Kost Detail ────────────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.kostDetail,
        builder: (_, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '0') ?? 0;
          return RenterKostDetailPage(kostId: id);
        },
      ),

      // ── Reservation ────────────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.reservationForm,
        builder: (_, state) {
          final extra = state.extra as Map<String, dynamic>;
          return ReservationFormPage(
            kost: extra['kost'] as KostModel,
            isSplitBill: extra['isSplit'] as bool,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.reservationSuccess,
        builder: (_, state) => ReservationSuccessPage(
          reservation: state.extra as ReservationModel,
        ),
      ),
      GoRoute(
        path: AppRoutes.renterReservations,
        builder: (_, __) => const ReservationHistoryPage(),
      ),

      // ── Ticket CRUD ────────────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.createTicketRenter,
        builder: (_, __) => const TicketFormPage(),
      ),
      GoRoute(
        path: AppRoutes.editTicketRenter,
        builder: (_, state) =>
            TicketFormPage(existingTicket: state.extra as TicketModel),
      ),
      GoRoute(
        path: AppRoutes.ticketDetailRenter,
        builder: (_, state) => TicketDetailPage(ticketId: state.extra as int),
      ),

      // ── Profile ────────────────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.editProfileRenter,
        builder: (_, __) => const EditProfilePage(),
      ),

      // ── Admin ──────────────────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.adminDashboard,
        builder: (_, __) => const AdminDashboardPage(),
      ),
      GoRoute(
        path: AppRoutes.adminVerifyOwners,
        builder: (_, __) => const OwnerVerificationPage(),
      ),

      // ── Owner Shell ────────────────────────────────────────────────────────
      ShellRoute(
        builder: (_, __, child) => OwnerShellPage(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.ownerDashboard,
            builder: (_, __) => const OwnerDashboardPage(),
          ),
          GoRoute(
            path: AppRoutes.reservationManagement,
            builder: (_, __) => const ReservationManagementPage(),
          ),
          GoRoute(
            path: AppRoutes.ownerTickets,
            builder: (_, __) => const OwnerTicketPage(),
          ),
          GoRoute(
            path: AppRoutes.ownerProfile,
            builder: (_, __) => const OwnerProfilePage(),
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.ownerAddKost,
        builder: (_, __) => const AddKostPage(),
      ),
    ],
  );
}

String _dashboardFor(String role) {
  return switch (role) {
    AppConstants.roleOwner => AppRoutes.ownerDashboard,
    AppConstants.roleAdmin => AppRoutes.adminDashboard,
    _ => AppRoutes.renterHome,
  };
}
