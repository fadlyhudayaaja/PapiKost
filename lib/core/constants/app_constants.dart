class AppConstants {
  AppConstants._();

  // App Info
  static const String appName = 'PapiKost';
  static const String appVersion = '1.0.0';

  // ─── API Base URL ───────────────────────────────────────────────────────────
  // Gunakan IP komputer di jaringan WiFi yang sama dengan device fisik
  static const String baseUrl = 'http://192.168.1.9:8080/api';

  // Untuk Android Emulator: static const String baseUrl = 'http://10.0.2.2:8080/api';
  // Untuk iOS Simulator:    static const String baseUrl = 'http://localhost:8080/api';
  // ───────────────────────────────────────────────────────────────────────────

  // Gemini API — ganti dengan API key Anda dari https://aistudio.google.com
  static const String geminiApiKey = 'YOUR_GEMINI_API_KEY';
  static const String geminiBaseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent';

  // Storage Keys
  static const String tokenKey = 'auth_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userRoleKey = 'user_role';
  static const String userIdKey = 'user_id';
  static const String userNameKey = 'user_name';

  // User Roles
  static const String roleRenter = 'RENTER';
  static const String roleOwner = 'OWNER';
  static const String roleAdmin = 'ADMIN';

  // Pagination
  static const int defaultPageSize = 10;

  // Timeouts
  static const int connectTimeout = 5000;
  static const int receiveTimeout = 8000;

  // Ticket Status
  static const String ticketStatusPending = 'PENDING';
  static const String ticketStatusInProgress = 'IN_PROGRESS';
  static const String ticketStatusDone = 'DONE';

  // Reservation Status
  static const String reservationStatusPending = 'PENDING';
  static const String reservationStatusApproved = 'APPROVED';
  static const String reservationStatusRejected = 'REJECTED';

  // Split Bill
  static const int minSplitMembers = 2;
  static const int maxSplitMembers = 4;
}
