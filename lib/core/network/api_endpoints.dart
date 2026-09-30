/// Semua endpoint API terpusat di sini.
/// Ubah [base] sesuai environment (dev/staging/prod).
class ApiEndpoints {
  ApiEndpoints._();

  // ── Auth ──────────────────────────────────────────
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String me = '/auth/me';
  static const String refreshToken = '/auth/refresh';

  // ── Kost ──────────────────────────────────────────
  static const String kostList = '/kost';
  static String kostDetail(int id) => '/kost/$id';
  static const String kostSearch = '/kost/search';

  // ── Reservasi ─────────────────────────────────────
  static const String reservations = '/reservations';
  static const String myReservations = '/reservations/my';
  static String reservationById(int id) => '/reservations/$id';

  // ── Tiket ─────────────────────────────────────────
  static const String tickets = '/tickets';
  static const String myTickets = '/tickets/my';
  static String ticketById(int id) => '/tickets/$id';

  // ── Owner ─────────────────────────────────────────
  static const String ownerStats = '/owner/stats';
  static const String ownerKost = '/owner/kost';
  static const String ownerReservations = '/owner/reservations';
  static String ownerReservationAction(int id) => '/owner/reservations/$id';
  static const String ownerTickets = '/owner/tickets';
  static String ownerTicketAction(int id) => '/owner/tickets/$id';

  // ── Admin ─────────────────────────────────────────
  static const String adminPendingOwners = '/admin/owners/pending';
  static String adminVerifyOwner(int id) => '/admin/owners/$id/verify';
  static const String adminUsers = '/admin/users';
}
