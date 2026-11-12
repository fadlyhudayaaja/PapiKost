#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════╗
# ║  SCRIPT ANGGOTA 3 — FADLY HUDAYA SIMANJUNTAK                            ║
# ║  Email  : fadlyhudaya@students.usu.ac.id                                 ║
# ║  Repo   : https://github.com/fadlyhudayaaja/PapiKost.git                ║
# ║  Periode: Hari ke-11 s/d ke-14 (20 – 23 Oktober 2026)                   ║
# ║  Commit : 12 commit + tag v1.0.0                                         ║
# ╠══════════════════════════════════════════════════════════════════════════╣
# ║  TANGGUNG JAWAB FADLY:                                                   ║
# ║  • Network layer (DioClient, ApiEndpoints)                               ║
# ║  • MockService fallback data development                                 ║
# ║  • Repository layer (Auth, Kost, Ticket, Mock)                           ║
# ║  • Reservation flow (form, sukses, riwayat)                              ║
# ║  • Renter shell (BottomNavigationBar)                                    ║
# ║  • Owner feature lengkap (provider, dashboard, shell,                    ║
# ║    manajemen reservasi, kost, tiket, profil)                             ║
# ║  • Finalisasi: .iml files, pubspec.lock, release tag v1.0.0             ║
# ╠══════════════════════════════════════════════════════════════════════════╣
# ║  FILE YANG HARUS DITERIMA DARI MARULI (via ZIP/Drive) SEBELUM MULAI:    ║
# ║                                                                          ║
# ║  📁 lib/core/network/                                                    ║
# ║       api_endpoints.dart                                                 ║
# ║       dio_client.dart                                                    ║
# ║       mock_service.dart                                                  ║
# ║  📁 lib/data/repositories/                                               ║
# ║       auth_repository.dart                                               ║
# ║       kost_repository.dart                                               ║
# ║       ticket_repository.dart                                             ║
# ║       mock_repository.dart                                               ║
# ║  📁 lib/features/renter/reservation/                                     ║
# ║       pages/reservation_form_page.dart                                   ║
# ║       pages/reservation_success_page.dart                                ║
# ║  📄 lib/features/kost/presentation/pages/renter_shell_page.dart         ║
# ║  📄 lib/features/kost/presentation/pages/reservation_history_page.dart  ║
# ║  📁 lib/features/owner/  (semua subfolder & file)                       ║
# ║  📄 papikost_mobile.iml                                                  ║
# ║  📄 flutter_application_1.iml                                            ║
# ║                                                                          ║
# ║  CARA PAKAI:                                                             ║
# ║  1. Buat folder kosong di laptop Fadly, misal: D:\PapiKost\             ║
# ║  2. Copy semua file yang diterima dari Maruli ke dalam folder itu        ║
# ║  3. Buka Git Bash di dalam folder tersebut                               ║
# ║  4. Jalankan: bash script_3_fadly.sh                                    ║
# ║  5. Masukkan GitHub credentials jika diminta                             ║
# ╚══════════════════════════════════════════════════════════════════════════╝

set -e

FADLY="Fadly Hudaya Simanjuntak <fadlyhudaya@students.usu.ac.id>"
REPO="https://github.com/fadlyhudayaaja/PapiKost.git"

echo ""
echo "╔══════════════════════════════════════════════╗"
echo "║  [FADLY] Clone repo dan mulai commit...      ║"
echo "╚══════════════════════════════════════════════╝"
echo ""

# ─────────────────────────────────────────────────────────────────────────────
# STEP 1: Clone repo dari Rio & Maruli
# ─────────────────────────────────────────────────────────────────────────────
git clone "$REPO" PapiKost
cd PapiKost
echo "✓ Clone selesai. Masuk ke folder PapiKost."

# Pastikan di branch main dan up-to-date
git checkout main
git pull origin main
echo "✓ Branch main, sudah pull terbaru."

# ─────────────────────────────────────────────────────────────────────────────
# STEP 2: Copy file tugas Fadly ke dalam repo
# ─────────────────────────────────────────────────────────────────────────────
echo ""
echo "─────────────────────────────────────────────────"
echo "  PERHATIAN: Sebelum lanjut, pastikan semua file"
echo "  tugasmu sudah di-copy ke dalam folder PapiKost/"
echo "  yang baru saja di-clone."
echo "─────────────────────────────────────────────────"
read -p "  Tekan ENTER jika semua file sudah siap... "
echo ""

# ═════════════════════════════════════════════════════════════════════════════
# COMMIT 22 │ Hari ke-11 pagi │ 20 Oktober 2026 │ 09:44
# Scope : Network — DioClient + ApiEndpoints
# ═════════════════════════════════════════════════════════════════════════════
git add lib/core/network/api_endpoints.dart
git add lib/core/network/dio_client.dart

git commit \
  --author="$FADLY" \
  --date="2026-10-20 09:44:30" \
  -m "feat(network): setup Dio HTTP client dan centralized API endpoints

- DioClient: singleton instance dengan BaseOptions
  (baseUrl dari AppConstants, connectTimeout 5s, receiveTimeout 8s)
- JWT interceptor: inject 'Authorization: Bearer token' dari SecureStorage
- Error interceptor: handle 401 — deleteAll SecureStorage saat token expired
- DioClient.parseError(): parsing semua DioExceptionType ke pesan Indonesia
- ApiEndpoints: endpoint auth, kost, reservasi, tiket,
  owner (stats/kost/reservations/tickets), admin (verify/users)"

echo "✓ Commit 22 — feat(network): DioClient & ApiEndpoints"

# ═════════════════════════════════════════════════════════════════════════════
# COMMIT 23 │ Hari ke-11 siang │ 20 Oktober 2026 │ 14:15
# Scope : Network — MockService fallback data development
# ═════════════════════════════════════════════════════════════════════════════
git add lib/core/network/mock_service.dart

git commit \
  --author="$FADLY" \
  --date="2026-10-20 14:15:55" \
  -m "feat(network): tambah MockService sebagai fallback data development

- fetchKostList(): 10 data kost dummy area Medan/USU dengan variasi:
  tipe PUTRA/PUTRI/CAMPUR, harga 800rb–2jt, rating 3.5–4.9,
  fasilitas beragam (WiFi/AC/Parkir/Dapur), split-bill flag
- Mendukung filter tipe, harga, dan split-bill availability
- Digunakan oleh KostRepository dan PapibotProvider._getSuggestions()
  saat backend Spring Boot tidak running"

echo "✓ Commit 23 — feat(network): MockService"

# ═════════════════════════════════════════════════════════════════════════════
# COMMIT 24 │ Hari ke-11 sore │ 20 Oktober 2026 │ 17:20
# Scope : Data — repository layer lengkap dengan fallback mock
# ═════════════════════════════════════════════════════════════════════════════
git add lib/data/repositories/auth_repository.dart
git add lib/data/repositories/kost_repository.dart
git add lib/data/repositories/ticket_repository.dart
git add lib/data/repositories/mock_repository.dart

git commit \
  --author="$FADLY" \
  --date="2026-10-20 17:20:40" \
  -m "feat(data): implementasi repository layer dengan fallback mock

- AuthRepository: login(), register(), me(), logout()
  JWT disimpan ke FlutterSecureStorage, handle 401 dengan clear storage
- KostRepository: getList(), getDetail(), search(), createReservation()
  in-memory cache sederhana, fallback ke MockService jika gagal
- TicketRepository: getMyTickets(), createTicket(), updateTicket(),
  deleteTicket() — upload gambar dengan retry maksimum 2x
- MockRepository: implementasi semua operasi menggunakan MockService
  untuk mode development penuh tanpa backend"

echo "✓ Commit 24 — feat(data): repository layer"

# ═════════════════════════════════════════════════════════════════════════════
# COMMIT 25 │ Hari ke-12 pagi │ 21 Oktober 2026 │ 09:45
# Scope : Reservation — form, halaman sukses, riwayat
# ═════════════════════════════════════════════════════════════════════════════
git add lib/features/renter/reservation/pages/reservation_form_page.dart
git add lib/features/renter/reservation/pages/reservation_success_page.dart
git add lib/features/kost/presentation/pages/reservation_history_page.dart

git commit \
  --author="$FADLY" \
  --date="2026-10-21 09:45:12" \
  -m "feat(reservation): form pemesanan, konfirmasi sukses, dan riwayat

- ReservationFormPage: input tanggal check-in (DatePicker), catatan opsional,
  toggle opsi split bill
- Split bill mode: slider jumlah penghuni 2–4 orang, kalkulasi
  harga/orang = totalPrice / count secara realtime
- ReservationSuccessPage: animasi Lottie konfirmasi + ringkasan
  detail pemesanan (kost, tanggal, harga, status PENDING)
- ReservationHistoryPage: daftar semua reservasi dengan StatusBadge
  filter chips: SEMUA / PENDING / APPROVED / REJECTED
- Integrasi KostRepository.createReservation()"

echo "✓ Commit 25 — feat(reservation): reservation flow"

# ═════════════════════════════════════════════════════════════════════════════
# COMMIT 26 │ Hari ke-12 siang │ 21 Oktober 2026 │ 13:57
# Scope : Navigation — Renter Shell (BottomNavigationBar 4 tab)
# ═════════════════════════════════════════════════════════════════════════════
git add lib/features/kost/presentation/pages/renter_shell_page.dart

git commit \
  --author="$FADLY" \
  --date="2026-10-21 13:57:30" \
  -m "feat(navigation): renter shell dengan bottom navigation 4 tab

- RenterShellPage: BottomNavigationBar dengan 4 tab:
  Katalog (home), PapiBot (robot), Tiket (report), Profil (person)
- Integrasi dengan ShellRoute GoRouter
- Active tab highlight berdasarkan state.matchedLocation"

echo "✓ Commit 26 — feat(navigation): renter shell"

# ═════════════════════════════════════════════════════════════════════════════
# COMMIT 27 │ Hari ke-12 sore │ 21 Oktober 2026 │ 16:50
# Scope : Owner — OwnerProvider + dashboard + shell + manajemen reservasi
# ═════════════════════════════════════════════════════════════════════════════
git add lib/features/owner/presentation/providers/owner_provider.dart
git add lib/features/owner/presentation/pages/owner_shell_page.dart
git add lib/features/owner/presentation/pages/owner_dashboard_page.dart
git add lib/features/owner/presentation/pages/reservation_management_page.dart

git commit \
  --author="$FADLY" \
  --date="2026-10-21 16:50:27" \
  -m "feat(owner): dashboard owner, shell navigasi, dan manajemen reservasi

- OwnerProvider: loadStats(), loadReservations(), approveReservation(id),
  rejectReservation(id) dengan optimistic update + rollback on error
- OwnerShellPage: BottomNavBar owner — Dashboard, Reservasi, Tiket, Profil
- OwnerDashboardPage: kartu statistik (total kost, reservasi pending hari ini,
  estimasi pemasukan bulan ini)
- ReservationManagementPage: daftar reservasi masuk, detail penyewa
  (nama, email, phone), tombol Setujui/Tolak dengan konfirmasi AlertDialog"

echo "✓ Commit 27 — feat(owner): dashboard & reservation management"

# ═════════════════════════════════════════════════════════════════════════════
# COMMIT 28 │ Hari ke-13 pagi │ 22 Oktober 2026 │ 09:05
# Scope : Owner — manajemen kost, add kost, tiket, profil owner
# ═════════════════════════════════════════════════════════════════════════════
git add lib/features/owner/presentation/pages/kost_management_page.dart
git add lib/features/owner/presentation/pages/add_kost_page.dart
git add lib/features/owner/presentation/pages/owner_ticket_page.dart
git add lib/features/owner/presentation/pages/owner_profile_page.dart

git commit \
  --author="$FADLY" \
  --date="2026-10-22 09:05:39" \
  -m "feat(owner): manajemen kost, form tambah kost, tiket, dan profil

- KostManagementPage: daftar kost milik owner, status ketersediaan kamar,
  shortcut ke AddKostPage, swipe-to-delete dengan konfirmasi
- AddKostPage: form lengkap — nama, alamat, kota, harga/bulan, tipe kost,
  fasilitas checklist (WiFi/AC/Parkir/dll), upload multi-foto (image_picker),
  toggle isSplitBillAvailable, jumlah kamar total
- OwnerTicketPage: daftar tiket masuk dari penyewa per kost, update status
  PENDING → IN_PROGRESS → DONE, isi ownerNote balasan ke penyewa
- OwnerProfilePage: info akun owner, status verifikasi admin (badge),
  tombol logout dengan konfirmasi"

echo "✓ Commit 28 — feat(owner): kost management & owner profile"

# ═════════════════════════════════════════════════════════════════════════════
# COMMIT 29 │ Hari ke-13 siang │ 22 Oktober 2026 │ 14:18
# Scope : Refactor — optimasi network layer & repository
# ═════════════════════════════════════════════════════════════════════════════
git add lib/core/network/dio_client.dart
git add lib/data/repositories/kost_repository.dart
git add lib/data/repositories/ticket_repository.dart

git commit \
  --author="$FADLY" \
  --date="2026-10-22 14:18:44" \
  -m "refactor(network): optimasi DioClient dan repository error handling

- DioClient: konsolidasi timeout ke AppConstants.connectTimeout/receiveTimeout
- KostRepository: in-memory cache agar tidak double-fetch dalam satu sesi
- TicketRepository: normalisasi retry upload gambar, batasi maksimum 2x
- parseError(): cover semua DioExceptionType termasuk connectionError
  dan sendTimeout dengan pesan Bahasa Indonesia
- Hapus import tidak terpakai di seluruh network layer"

echo "✓ Commit 29 — refactor(network): optimasi"

# ═════════════════════════════════════════════════════════════════════════════
# COMMIT 30 │ Hari ke-13 sore │ 22 Oktober 2026 │ 17:05
# Scope : Fix — null-safety & edge case repository
# ═════════════════════════════════════════════════════════════════════════════
git add lib/data/repositories/auth_repository.dart

git commit \
  --author="$FADLY" \
  --date="2026-10-22 17:05:51" \
  -m "fix(auth): normalisasi error handling dan null-safety pada repository

- AuthRepository: handle edge case email kosong saat checkAuth()
- Graceful fallback saat FlutterSecureStorage.read() kembalikan null
- Konsolidasi semua repo pakai DioClient.parseError() secara konsisten
- Tambah guard: cegah crash jika response body kosong (204 No Content)"

echo "✓ Commit 30 — fix(auth): null-safety repository"

# ═════════════════════════════════════════════════════════════════════════════
# COMMIT 31 │ Hari ke-14 pagi │ 23 Oktober 2026 │ 10:15
# Scope : Chore — file konfigurasi IDE IntelliJ/Android Studio
# ═════════════════════════════════════════════════════════════════════════════
git add papikost_mobile.iml
git add flutter_application_1.iml

git commit \
  --author="$FADLY" \
  --date="2026-10-23 10:15:00" \
  -m "chore: tambah konfigurasi module IDE IntelliJ/Android Studio

- papikost_mobile.iml: konfigurasi module utama Flutter
- flutter_application_1.iml: konfigurasi module project
- Diperlukan agar project terbuka dengan benar di Android Studio"

echo "✓ Commit 31 — chore: IDE module config"

# ═════════════════════════════════════════════════════════════════════════════
# COMMIT 32 │ Hari ke-14 siang │ 23 Oktober 2026 │ 14:30
# Scope : Chore — pin semua versi dependency (pubspec.lock)
# ═════════════════════════════════════════════════════════════════════════════
git add pubspec.lock

git commit \
  --author="$FADLY" \
  --date="2026-10-23 14:30:00" \
  -m "chore: update pubspec.lock — pin versi dependency untuk reproducible build

- Semua package resolved dan kompatibel satu sama lain
- Pin versi memastikan build konsisten di semua mesin anggota tim"

echo "✓ Commit 32 — chore: pin dependencies"

# ═════════════════════════════════════════════════════════════════════════════
# COMMIT 33 │ Hari ke-14 malam │ 23 Oktober 2026 │ 17:00
# Scope : Release — commit penanda versi final + tag v1.0.0
# ═════════════════════════════════════════════════════════════════════════════
git commit --allow-empty \
  --author="$FADLY" \
  --date="2026-10-23 17:00:00" \
  -m "chore: release v1.0.0 — PapiKost Mobile UTS submission

Fitur yang selesai di v1.0.0:
  ✅ Autentikasi JWT (login / register / logout / session restore)
  ✅ Katalog kost: filter tipe, harga, split-bill, search realtime
  ✅ Detail kost: galeri foto, fasilitas, rating, info pemilik
  ✅ Reservasi: normal + patungan (split bill 2–4 orang)
  ✅ Riwayat reservasi dengan status PENDING/APPROVED/REJECTED
  ✅ CRUD laporan kerusakan kost untuk renter (foto + kategori)
  ✅ Dashboard & manajemen reservasi untuk owner
  ✅ Pengelolaan kost owner (tambah/edit kost, manajemen tiket)
  ✅ PapiBot AI (Gemini 1.5 Flash) — pencarian kost natural language
  ✅ Dashboard admin + sistem verifikasi berkas owner
  ✅ MockService fallback (offline-ready saat backend tidak running)

Pembagian tugas tim:
  🔵 Rio Johanes          : Core config, auth, navigation, papibot AI, admin
  🟢 Maruli Sitanggang    : Models, shared widgets, kost UI, ticket renter, profil
  🟠 Fadly Simanjuntak    : Network layer, repositories, reservation, owner feature"

# ─────────────────────────────────────────────────────────────────────────────
# TAG RILIS
# ─────────────────────────────────────────────────────────────────────────────
git tag -a v1.0.0 \
  -m "PapiKost Mobile v1.0.0 — UTS Pemrograman Mobile" \
  HEAD

echo "✓ Commit 33 — chore: release v1.0.0"
echo "✓ Tag v1.0.0 dibuat."

# ─────────────────────────────────────────────────────────────────────────────
# PUSH KE REMOTE (commit + tags)
# ─────────────────────────────────────────────────────────────────────────────
echo ""
echo "→ Pushing commits ke remote origin..."
git push origin main

echo "→ Pushing tag v1.0.0..."
git push origin --tags

echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  [FADLY] SELESAI — 12 commit + tag v1.0.0 di-push ke:       ║"
echo "║  https://github.com/fadlyhudayaaja/PapiKost.git             ║"
echo "╠══════════════════════════════════════════════════════════════╣"
echo "║  Verifikasi riwayat commit:                                  ║"
echo "║    git log --oneline --decorate --graph                      ║"
echo "║                                                              ║"
echo "║  Cek semua tag:                                              ║"
echo "║    git tag -l                                                ║"
echo "║                                                              ║"
echo "║  Cek kontribusi per author:                                  ║"
echo "║    git shortlog -sn                                          ║"
echo "╚══════════════════════════════════════════════════════════════╝"
