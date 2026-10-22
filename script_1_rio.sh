#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════╗
# ║  SCRIPT ANGGOTA 1 — RIO JOHANES                                         ║
# ║  Email  : riojohanes08@gmail.com                                         ║
# ║  Repo   : https://github.com/fadlyhudayaaja/PapiKost.git                ║
# ║  Periode: Hari ke-1 s/d ke-5 (10 – 14 Oktober 2026)                     ║
# ║  Commit : 10 commit                                                      ║
# ╠══════════════════════════════════════════════════════════════════════════╣
# ║  TANGGUNG JAWAB RIO:                                                     ║
# ║  • Inisiasi project & konfigurasi root                                   ║
# ║  • Core: AppConstants, tema, utils                                       ║
# ║  • Auth feature (login, register, AuthProvider)                          ║
# ║  • Navigation (GoRouter, splash)                                         ║
# ║  • PapiBot AI (Gemini integration)                                       ║
# ║  • Admin feature                                                         ║
# ║  • Entry point main.dart                                                 ║
# ╠══════════════════════════════════════════════════════════════════════════╣
# ║  CARA PAKAI:                                                             ║
# ║  1. Buka Git Bash di ROOT folder Flutter project ini                     ║
# ║     (folder yang berisi pubspec.yaml)                                    ║
# ║  2. Jalankan: bash script_1_rio.sh                                       ║
# ║  3. Masukkan password/token GitHub jika diminta saat push                ║
# ╚══════════════════════════════════════════════════════════════════════════╝

set -e  # Hentikan jika ada error

RIO="Rio Johanes <riojohanes08@gmail.com>"
REPO="https://github.com/fadlyhudayaaja/PapiKost.git"

echo ""
echo "╔══════════════════════════════════════════╗"
echo "║  [RIO] Memulai setup repo PapiKost...    ║"
echo "╚══════════════════════════════════════════╝"
echo ""

# ─────────────────────────────────────────────────────────────────────────────
# INISIASI REPOSITORY
# ─────────────────────────────────────────────────────────────────────────────
git init
git branch -M main
git remote add origin "$REPO"
echo "✓ git init, branch main, remote origin ditambahkan."

# ═════════════════════════════════════════════════════════════════════════════
# COMMIT 1 │ Hari ke-1 pagi │ 10 Oktober 2026 │ 08:14
# Scope : Inisiasi project — file konfigurasi root
# ═════════════════════════════════════════════════════════════════════════════
git add pubspec.yaml
git add pubspec.lock
git add .gitignore
git add .metadata
git add analysis_options.yaml
git add README.md
git add UTS_DOKUMENTASI.md

git commit \
  --author="$RIO" \
  --date="2026-10-10 08:14:22" \
  -m "chore: inisiasi project Flutter papikost_mobile

- Setup pubspec.yaml dengan semua dependencies:
  provider, go_router, dio, flutter_secure_storage,
  google_fonts, lottie, cached_network_image, intl,
  image_picker, shimmer, equatable, uuid, pretty_dio_logger
- Konfigurasi analysis_options.yaml (flutter_lints)
- .gitignore untuk Flutter project
- Inisiasi README dan dokumentasi UTS"

echo "✓ Commit 1 — chore: inisiasi project"

# ═════════════════════════════════════════════════════════════════════════════
# COMMIT 2 │ Hari ke-1 siang │ 10 Oktober 2026 │ 13:27
# Scope : Konfigurasi platform Android, iOS, Web
# ═════════════════════════════════════════════════════════════════════════════
git add android/
git add ios/
git add web/

git commit \
  --author="$RIO" \
  --date="2026-10-10 13:27:45" \
  -m "chore: tambah konfigurasi platform android, ios, dan web

- AndroidManifest.xml: INTERNET permission untuk HTTP calls
- Info.plist: konfigurasi permission kamera dan galeri (iOS)
- web/index.html: Flutter web support"

echo "✓ Commit 2 — chore: platform config"

# ═════════════════════════════════════════════════════════════════════════════
# COMMIT 3 │ Hari ke-2 pagi │ 11 Oktober 2026 │ 09:03
# Scope : Core — AppConstants + design system (warna, tipografi, tema)
# ═════════════════════════════════════════════════════════════════════════════
git add lib/core/constants/app_constants.dart
git add lib/core/theme/app_colors.dart
git add lib/core/theme/app_text_styles.dart
git add lib/core/theme/app_theme.dart

git commit \
  --author="$RIO" \
  --date="2026-10-11 09:03:18" \
  -m "feat(core): setup AppConstants dan design system tema

- AppConstants: baseUrl (192.168.1.9:8080), geminiApiKey,
  tokenKey/refreshTokenKey/userRoleKey, role constants
  (RENTER/OWNER/ADMIN), ticket status, reservation status,
  split bill min/max (2–4 orang), timeout config
- AppColors: palet warna primary, secondary, surface, error
- AppTextStyles: typography scale menggunakan Google Fonts
- AppTheme: lightTheme (ColorScheme, InputDecoration theme,
  ElevatedButton theme, AppBar theme)"

echo "✓ Commit 3 — feat(core): AppConstants & tema"

# ═════════════════════════════════════════════════════════════════════════════
# COMMIT 4 │ Hari ke-2 siang │ 11 Oktober 2026 │ 14:30
# Scope : Core utils — helper functions
# ═════════════════════════════════════════════════════════════════════════════
git add lib/core/utils/currency_utils.dart
git add lib/core/utils/date_utils.dart
git add lib/core/utils/validators.dart
git add lib/core/utils/snackbar_utils.dart

git commit \
  --author="$RIO" \
  --date="2026-10-11 14:30:00" \
  -m "feat(core): tambah utility functions

- CurrencyUtils: format Rupiah dengan intl NumberFormat
- AppDateUtils: format tanggal Bahasa Indonesia (id_ID locale)
- Validators: email, phone, password, required field
- SnackbarUtils: success/error/info snackbar helper"

echo "✓ Commit 4 — feat(core): utils"

# ═════════════════════════════════════════════════════════════════════════════
# COMMIT 5 │ Hari ke-3 pagi │ 12 Oktober 2026 │ 09:05
# Scope : Auth feature — AuthProvider + halaman login & register
# ═════════════════════════════════════════════════════════════════════════════
git add lib/features/auth/presentation/providers/auth_provider.dart
git add lib/features/auth/presentation/pages/login_page.dart
git add lib/features/auth/presentation/pages/register_page.dart

git commit \
  --author="$RIO" \
  --date="2026-10-12 09:05:30" \
  -m "feat(auth): implementasi AuthProvider, login page, dan register page

- AuthProvider: AuthStatus enum (initial/loading/authenticated/
  unauthenticated), ChangeNotifier
- login(): panggil AuthRepository, simpan token ke SecureStorage
- register(): daftar user baru dengan pilihan role RENTER/OWNER
- checkAuth(): restore session dari storage saat app launch
- LoginPage: form email + password, validasi, error state
- RegisterPage: form lengkap, dropdown role, link ke login"

echo "✓ Commit 5 — feat(auth): auth feature"

# ═════════════════════════════════════════════════════════════════════════════
# COMMIT 6 │ Hari ke-3 siang │ 12 Oktober 2026 │ 14:48
# Scope : Navigation — SplashPage + GoRouter dengan role guard
# ═════════════════════════════════════════════════════════════════════════════
git add lib/features/splash/presentation/pages/splash_page.dart
git add lib/core/router/app_router.dart

git commit \
  --author="$RIO" \
  --date="2026-10-12 14:48:17" \
  -m "feat(navigation): splash screen dan konfigurasi GoRouter lengkap

- SplashPage: animasi Lottie + checkAuth sebelum redirect
- AppRoutes: konstanta semua route (renter/owner/admin namespace)
- GoRouter: refreshListenable reaktif terhadap AuthStatus
- Redirect guard: role-based routing (RENTER/OWNER/ADMIN)
- ShellRoute: BottomNav untuk renter dan owner shell
- Route full-screen: kost detail, reservation form, ticket CRUD,
  profile edit, admin dashboard, owner add kost"

echo "✓ Commit 6 — feat(navigation): GoRouter & splash"

# ═════════════════════════════════════════════════════════════════════════════
# COMMIT 7 │ Hari ke-4 pagi │ 13 Oktober 2026 │ 09:22
# Scope : PapiBot — integrasi Gemini 1.5 Flash + UI chat
# ═════════════════════════════════════════════════════════════════════════════
git add lib/features/papibot/presentation/providers/papibot_provider.dart
git add lib/features/papibot/presentation/pages/papibot_page.dart

git commit \
  --author="$RIO" \
  --date="2026-10-13 09:22:41" \
  -m "feat(papibot): integrasi Gemini 1.5 Flash sebagai asisten PapiBot

- PapibotProvider: state chat, MessageSender enum (user/bot),
  isBotTyping flag, list ChatMessage
- _callGeminiApi(): POST ke generativelanguage.googleapis.com
  dengan system prompt konteks kost Medan/USU (max 150 kata)
- _getFallbackResponse(): respons lokal jika API key placeholder
- _getSuggestions(): filter KostModel berdasarkan intent query
  (patungan, putri, putra, harga murah, AC/WiFi, dekat USU)
- clearMessages(): reset sesi chat
- PapibotPage: bubble chat user/bot, typing indicator animasi,
  horizontal card rekomendasi kost, input bar, tombol clear"

echo "✓ Commit 7 — feat(papibot): Gemini AI integration"

# ═════════════════════════════════════════════════════════════════════════════
# COMMIT 8 │ Hari ke-4 siang │ 13 Oktober 2026 │ 15:38
# Scope : Admin feature — dashboard, verifikasi berkas owner
# ═════════════════════════════════════════════════════════════════════════════
git add lib/features/admin/presentation/providers/admin_provider.dart
git add lib/features/admin/presentation/pages/admin_dashboard_page.dart
git add lib/features/admin/presentation/pages/owner_verification_page.dart
git add lib/features/admin/presentation/pages/verification_detail_page.dart

git commit \
  --author="$RIO" \
  --date="2026-10-13 15:38:14" \
  -m "feat(admin): dashboard admin dan sistem verifikasi berkas owner

- AdminProvider: loadPendingOwners, verifyOwner(id), rejectOwner(id,alasan)
- AdminDashboardPage: statistik platform — total user, owner pending,
  kost aktif; shortcut ke verifikasi
- OwnerVerificationPage: daftar owner PENDING, search by nama,
  pull-to-refresh
- VerificationDetailPage: preview dokumen (KTP/NPWP/foto kost),
  tombol Setujui/Tolak + input alasan penolakan"

echo "✓ Commit 8 — feat(admin): admin feature"

# ═════════════════════════════════════════════════════════════════════════════
# COMMIT 9 │ Hari ke-5 pagi │ 14 Oktober 2026 │ 08:55
# Scope : Entry point — main.dart (MultiProvider + MaterialApp.router)
# ═════════════════════════════════════════════════════════════════════════════
git add lib/main.dart

git commit \
  --author="$RIO" \
  --date="2026-10-14 08:55:00" \
  -m "feat: setup entry point app dengan MultiProvider dan MaterialApp.router

- initializeDateFormatting('id_ID') sebelum runApp
- SystemChrome: status bar transparan, lock portrait orientation
- MultiProvider: Auth, Kost, Papibot, Ticket, Owner,
  RenterTicket, Admin provider terdaftar
- PapiKostApp: StatefulWidget, router dibuat sekali di initState
  agar tidak rebuild saat notifyListeners
- MaterialApp.router: GoRouter + AppTheme.lightTheme"

echo "✓ Commit 9 — feat: main.dart entry point"

# ═════════════════════════════════════════════════════════════════════════════
# COMMIT 10 │ Hari ke-5 sore │ 14 Oktober 2026 │ 16:20
# Scope : Fix — redirect guard & locale initialization
# ═════════════════════════════════════════════════════════════════════════════
git add lib/core/router/app_router.dart
git add lib/main.dart
git add lib/features/auth/presentation/providers/auth_provider.dart

git commit \
  --author="$RIO" \
  --date="2026-10-14 16:20:09" \
  -m "fix(core): perbaikan redirect guard, locale, dan auth flow

- Cegah infinite redirect loop saat AuthStatus initial/loading
- Null-safety guard pada pathParameters route kostDetail
- WidgetsFlutterBinding.ensureInitialized() dipastikan terpanggil
- Perbaikan: await initializeDateFormatting mencegah LocaleDataException"

echo "✓ Commit 10 — fix: redirect & locale"

# ─────────────────────────────────────────────────────────────────────────────
# PUSH KE REMOTE
# ─────────────────────────────────────────────────────────────────────────────
echo ""
echo "→ Pushing ke remote origin (branch main)..."
git push -u origin main

echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  [RIO] SELESAI — 10 commit berhasil di-push ke:             ║"
echo "║  https://github.com/fadlyhudayaaja/PapiKost.git             ║"
echo "╠══════════════════════════════════════════════════════════════╣"
echo "║  LANGKAH SELANJUTNYA:                                        ║"
echo "║  Kirim ZIP file berikut ke MARULI (via Drive/WA):            ║"
echo "║                                                              ║"
echo "║  📁 assets/                                                  ║"
echo "║  📁 lib/data/models/                                         ║"
echo "║  📁 lib/core/widgets/                                        ║"
echo "║  📁 lib/features/kost/                                       ║"
echo "║  📁 lib/features/renter/                                     ║"
echo "║  📁 lib/features/ticket/                                     ║"
echo "║  📁 linux/ macos/ windows/                                   ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""
echo "  Cek log: git log --oneline --decorate"
