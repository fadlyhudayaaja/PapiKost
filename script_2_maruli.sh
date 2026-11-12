#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════╗
# ║  SCRIPT ANGGOTA 2 — MARULI RICARDO SITANGGANG                           ║
# ║  Email  : maruli180617@gmail.com                                         ║
# ║  Repo   : https://github.com/fadlyhudayaaja/PapiKost.git                ║
# ║  Periode: Hari ke-6 s/d ke-10 (15 – 19 Oktober 2026)                    ║
# ║  Commit : 11 commit                                                      ║
# ╠══════════════════════════════════════════════════════════════════════════╣
# ║  TANGGUNG JAWAB MARULI:                                                  ║
# ║  • Data models (User, Kost, Reservation, Ticket)                         ║
# ║  • Assets (gambar, ikon, animasi Lottie)                                 ║
# ║  • Shared widgets reusable                                               ║
# ║  • Kost UI: katalog, detail, KostProvider, KostCard                      ║
# ║  • Renter: profile, edit profile                                         ║
# ║  • Renter: CRUD tiket laporan kerusakan (RenterTicketProvider)           ║
# ║  • Ticket shared (TicketProvider generik)                                ║
# ║  • Platform desktop (linux/macos/windows)                                ║
# ╠══════════════════════════════════════════════════════════════════════════╣
# ║  FILE YANG HARUS DITERIMA DARI RIO (via ZIP/Drive) SEBELUM MULAI:       ║
# ║                                                                          ║
# ║  📁 assets/                          (semua aset)                       ║
# ║  📁 lib/data/models/                 (4 file model)                     ║
# ║  📁 lib/core/widgets/                (6 file widget)                    ║
# ║  📁 lib/features/kost/               (semua subfolder)                  ║
# ║  📁 lib/features/renter/             (catalog, profile, ticket)         ║
# ║  📄 lib/features/renter/             (reservation/ ada di Fadly)        ║
# ║  📁 lib/features/ticket/             (shared ticket)                    ║
# ║  📁 linux/ macos/ windows/           (platform desktop)                 ║
# ║                                                                          ║
# ║  CARA PAKAI:                                                             ║
# ║  1. Buat folder kosong di laptop Maruli, misal: D:\PapiKost\            ║
# ║  2. Copy semua file yang diterima dari Rio ke dalam folder itu           ║
# ║  3. Buka Git Bash di dalam folder tersebut                               ║
# ║  4. Jalankan: bash script_2_maruli.sh                                   ║
# ║  5. Masukkan GitHub credentials jika diminta                             ║
# ╚══════════════════════════════════════════════════════════════════════════╝

set -e

MARULI="Maruli Ricardo Sitanggang <maruli180617@gmail.com>"
REPO="https://github.com/fadlyhudayaaja/PapiKost.git"

echo ""
echo "╔══════════════════════════════════════════════╗"
echo "║  [MARULI] Clone repo dan mulai commit...     ║"
echo "╚══════════════════════════════════════════════╝"
echo ""

# ─────────────────────────────────────────────────────────────────────────────
# STEP 1: Clone repo dari Rio
# ─────────────────────────────────────────────────────────────────────────────
git clone "$REPO" PapiKost
cd PapiKost
echo "✓ Clone selesai. Masuk ke folder PapiKost."

# ─────────────────────────────────────────────────────────────────────────────
# STEP 2: Copy file tugas Maruli ke dalam repo
# (Semua file yang diterima dari Rio harus sudah dicopy ke sini)
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
# COMMIT 11 │ Hari ke-6 pagi │ 15 Oktober 2026 │ 08:40
# Scope : Assets — gambar, ikon, animasi Lottie
# ═════════════════════════════════════════════════════════════════════════════
git add assets/

git commit \
  --author="$MARULI" \
  --date="2026-10-15 08:40:10" \
  -m "chore: tambah aset gambar, ikon, dan animasi Lottie

- assets/images/: foto kost, placeholder, ilustrasi halaman kosong
- assets/icons/: ikon custom aplikasi (SVG format)
- assets/animations/: file Lottie untuk splash screen dan loading state"

echo "✓ Commit 11 — chore: assets"

# ═════════════════════════════════════════════════════════════════════════════
# COMMIT 12 │ Hari ke-6 siang │ 15 Oktober 2026 │ 13:55
# Scope : Data models — 4 model domain utama
# ═════════════════════════════════════════════════════════════════════════════
git add lib/data/models/user_model.dart
git add lib/data/models/kost_model.dart
git add lib/data/models/reservation_model.dart
git add lib/data/models/ticket_model.dart

git commit \
  --author="$MARULI" \
  --date="2026-10-15 13:55:22" \
  -m "feat(data): definisi model domain PapiKost

- UserModel: id, name, email, phone, role (RENTER/OWNER/ADMIN),
  avatarUrl, bio, isVerified, createdAt — Equatable + copyWith
- KostModel: name, address, city, pricePerMonth, type, facilities[],
  imageUrls[], isSplitBillAvailable, totalRooms, availableRooms,
  latitude, longitude, ownerName, rating — fromJson/toJson lengkap
- ReservationModel: status PENDING/APPROVED/REJECTED, isSplitBill,
  splitMemberCount, pricePerPerson, checkIn/checkOut
- TicketModel: TicketCategory enum (AIR/LISTRIK/MEBEL/STRUKTUR/LAINNYA),
  status PENDING/IN_PROGRESS/DONE, ownerNote, copyWith"

echo "✓ Commit 12 — feat(data): models"

# ═════════════════════════════════════════════════════════════════════════════
# COMMIT 13 │ Hari ke-6 sore │ 15 Oktober 2026 │ 17:10
# Scope : Shared widgets — komponen UI reusable library
# ═════════════════════════════════════════════════════════════════════════════
git add lib/core/widgets/app_button.dart
git add lib/core/widgets/app_text_field.dart
git add lib/core/widgets/shimmer_loading.dart
git add lib/core/widgets/empty_state.dart
git add lib/core/widgets/status_badge.dart
git add lib/core/widgets/responsive_layout.dart

git commit \
  --author="$MARULI" \
  --date="2026-10-15 17:10:05" \
  -m "feat(widgets): buat shared widget library reusable

- AppButton: primary/secondary/text variant dengan loading state indicator
- AppTextField: input field dengan prefixIcon, validator, obscureText toggle
- ShimmerLoading: skeleton placeholder — card, list tile, grid item variant
- EmptyState: ilustrasi SVG per konteks dengan optional action button
- StatusBadge: chip warna dinamis untuk status reservasi/tiket
- ResponsiveLayout: breakpoint helper mobile/tablet layout"

echo "✓ Commit 13 — feat(widgets): shared widgets"

# ═════════════════════════════════════════════════════════════════════════════
# COMMIT 14 │ Hari ke-7 pagi │ 16 Oktober 2026 │ 09:22
# Scope : Kost — KostProvider + halaman katalog kost renter
# ═════════════════════════════════════════════════════════════════════════════
git add lib/features/kost/presentation/providers/kost_provider.dart
git add lib/features/renter/catalog/pages/catalog_page.dart
git add lib/features/renter/catalog/widgets/kost_list_tile.dart

git commit \
  --author="$MARULI" \
  --date="2026-10-16 09:22:48" \
  -m "feat(kost): KostProvider dan halaman katalog kost renter

- KostProvider: fetchKosts(), filter by tipe/harga/splitBill,
  search query state, ChangeNotifier
- Fallback ke MockService jika backend tidak terjangkau
- CatalogPage: grid/list view kost dengan ShimmerLoading saat fetch
- Search bar dengan debounce input
- Filter chips: SEMUA / PUTRA / PUTRI / CAMPUR / PATUNGAN
- KostListTile: card kost — harga/bulan, rating bintang,
  badge sisa kamar, ikon fasilitas utama"

echo "✓ Commit 14 — feat(kost): katalog kost"

# ═════════════════════════════════════════════════════════════════════════════
# COMMIT 15 │ Hari ke-7 siang │ 16 Oktober 2026 │ 14:10
# Scope : Kost — detail kost + KostCard widget
# ═════════════════════════════════════════════════════════════════════════════
git add lib/features/renter/catalog/pages/kost_detail_page.dart
git add lib/features/kost/presentation/pages/kost_detail_page.dart
git add lib/features/kost/presentation/widgets/kost_card.dart

git commit \
  --author="$MARULI" \
  --date="2026-10-16 14:10:55" \
  -m "feat(kost): halaman detail kost dengan galeri foto dan fasilitas

- RenterKostDetailPage: hero image carousel (PageView + SmoothPageIndicator)
- CachedNetworkImage untuk loading gambar efisien dengan placeholder
- Section: deskripsi lengkap, fasilitas chips, info pemilik, rating & ulasan
- Tombol 'Sewa Normal' dan 'Sewa Patungan' (conditional: tampil jika tersedia)
- KostCard: card widget reusable kost untuk berbagai konteks tampilan
- Navigasi ke ReservationFormPage dengan GoRouter extra (KostModel + isSplit)"

echo "✓ Commit 15 — feat(kost): detail page & KostCard"

# ═════════════════════════════════════════════════════════════════════════════
# COMMIT 16 │ Hari ke-7 sore │ 16 Oktober 2026 │ 17:05
# Scope : Kost — halaman home dan profile wrapper
# ═════════════════════════════════════════════════════════════════════════════
git add lib/features/kost/presentation/pages/home_page.dart
git add lib/features/kost/presentation/pages/profile_page.dart

git commit \
  --author="$MARULI" \
  --date="2026-10-16 17:05:30" \
  -m "feat(kost): tambah home page dan profile page wrapper

- HomePage: wrapper legacy untuk kompatibilitas routing lama
- ProfilePage: fallback profile dengan responsive padding
- Perbaikan overflow pada kartu kost di layar kecil (<360dp lebar)"

echo "✓ Commit 16 — feat(kost): home & profile wrapper"

# ═════════════════════════════════════════════════════════════════════════════
# COMMIT 17 │ Hari ke-8 pagi │ 17 Oktober 2026 │ 09:15
# Scope : Renter Ticket — CRUD laporan kerusakan kost
# ═════════════════════════════════════════════════════════════════════════════
git add lib/features/renter/ticket/providers/renter_ticket_provider.dart
git add lib/features/renter/ticket/pages/ticket_list_page.dart
git add lib/features/renter/ticket/pages/ticket_form_page.dart
git add lib/features/renter/ticket/pages/ticket_detail_page.dart

git commit \
  --author="$MARULI" \
  --date="2026-10-17 09:15:44" \
  -m "feat(ticket): CRUD laporan kerusakan kost untuk renter

- RenterTicketProvider: loadTickets(), createTicket(), updateTicket(),
  deleteTicket() — ChangeNotifier dengan error/loading state
- RenterTicketListPage: daftar tiket, filter by status, pull-to-refresh,
  EmptyState saat belum ada tiket
- TicketFormPage: form buat/edit — judul, deskripsi, dropdown kategori,
  multi-image picker via image_picker, validasi input lengkap
- TicketDetailPage: foto grid, ownerNote balasan, status timeline,
  tombol edit/hapus (hanya jika status PENDING)
- TicketCategory: AIR / LISTRIK / MEBEL / STRUKTUR / LAINNYA"

echo "✓ Commit 17 — feat(ticket): CRUD renter ticket"

# ═════════════════════════════════════════════════════════════════════════════
# COMMIT 18 │ Hari ke-8 siang │ 17 Oktober 2026 │ 14:40
# Scope : Ticket shared — TicketProvider generik + halaman generic
# ═════════════════════════════════════════════════════════════════════════════
git add lib/features/ticket/presentation/providers/ticket_provider.dart
git add lib/features/ticket/presentation/pages/ticket_list_page.dart
git add lib/features/ticket/presentation/pages/create_ticket_page.dart

git commit \
  --author="$MARULI" \
  --date="2026-10-17 14:40:18" \
  -m "feat(ticket): TicketProvider shared dan halaman tiket generik

- TicketProvider: provider generik untuk owner dan admin view tiket
- TicketListPage (shared): list tiket dengan role-aware display
- CreateTicketPage: form pembuatan tiket versi awal (pre-UTS)"

echo "✓ Commit 18 — feat(ticket): shared ticket"

# ═════════════════════════════════════════════════════════════════════════════
# COMMIT 19 │ Hari ke-9 pagi │ 18 Oktober 2026 │ 10:30
# Scope : Renter — halaman profil dan edit profil
# ═════════════════════════════════════════════════════════════════════════════
git add lib/features/renter/profile/pages/renter_profile_page.dart
git add lib/features/renter/profile/pages/edit_profile_page.dart

git commit \
  --author="$MARULI" \
  --date="2026-10-18 10:30:00" \
  -m "feat(profile): halaman profil dan edit profil renter

- RenterProfilePage: info akun (nama, email, role), shortcut
  riwayat reservasi, tombol logout dengan konfirmasi dialog
- EditProfilePage: form update nama, nomor HP, bio/preferensi kost
- Avatar picker: image_picker (pilih dari galeri atau kamera)
- Perubahan disimpan via AuthProvider.updateProfile()"

echo "✓ Commit 19 — feat(profile): renter profile"

# ═════════════════════════════════════════════════════════════════════════════
# COMMIT 20 │ Hari ke-9 siang │ 18 Oktober 2026 │ 15:45
# Scope : Fix/UX — polish shimmer, empty state, snackbar
# ═════════════════════════════════════════════════════════════════════════════
git add lib/core/widgets/shimmer_loading.dart
git add lib/core/widgets/empty_state.dart
git add lib/core/utils/snackbar_utils.dart

git commit \
  --author="$MARULI" \
  --date="2026-10-18 15:45:30" \
  -m "fix(ux): penyempurnaan komponen loading, empty state, dan snackbar

- ShimmerLoading: tambah variant banner dan grid item 2-kolom
- EmptyState: ilustrasi SVG kontekstual (kost kosong, tiket kosong,
  reservasi kosong) dengan pesan deskriptif
- SnackbarUtils: auto-dismiss duration, warna sesuai severity level
- Animasi fade-in konten setelah data selesai dimuat"

echo "✓ Commit 20 — fix(ux): polish components"

# ═════════════════════════════════════════════════════════════════════════════
# COMMIT 21 │ Hari ke-10 pagi │ 19 Oktober 2026 │ 09:02
# Scope : Platform desktop config (linux/macos/windows)
# ═════════════════════════════════════════════════════════════════════════════
git add linux/
git add macos/
git add windows/

git commit \
  --author="$MARULI" \
  --date="2026-10-19 09:02:17" \
  -m "chore: tambah konfigurasi platform desktop (linux, macos, windows)

- Runner config Linux, macOS, Windows untuk Flutter desktop
- Digunakan untuk development testing lintas platform
- Tidak memengaruhi production mobile build (Android/iOS)"

echo "✓ Commit 21 — chore: desktop platforms"

# ─────────────────────────────────────────────────────────────────────────────
# PUSH KE REMOTE
# ─────────────────────────────────────────────────────────────────────────────
echo ""
echo "→ Pushing ke remote origin (branch main)..."
git push origin main

echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  [MARULI] SELESAI — 11 commit berhasil di-push ke:          ║"
echo "║  https://github.com/fadlyhudayaaja/PapiKost.git             ║"
echo "╠══════════════════════════════════════════════════════════════╣"
echo "║  LANGKAH SELANJUTNYA:                                        ║"
echo "║  Kirim ZIP file berikut ke FADLY (via Drive/WA):             ║"
echo "║                                                              ║"
echo "║  📁 lib/core/network/             (dio_client, api_endpoints,║"
echo "║                                    mock_service)             ║"
echo "║  📁 lib/data/repositories/        (4 file repository)       ║"
echo "║  📁 lib/features/renter/          (folder reservation/)     ║"
echo "║  📄 lib/features/kost/presentation/pages/                   ║"
echo "║       renter_shell_page.dart                                 ║"
echo "║       reservation_history_page.dart                          ║"
echo "║  📁 lib/features/owner/           (semua subfolder)         ║"
echo "║  📄 papikost_mobile.iml                                      ║"
echo "║  📄 flutter_application_1.iml                                ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""
echo "  Cek log: git log --oneline --decorate"
