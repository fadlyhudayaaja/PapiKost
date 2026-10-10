# PapiKost Mobile — Dokumentasi UTS

> **Status Terakhir: ✅ 0 Error | ✅ 0 Warning | 62 file dart**

---

## A. Struktur Folder

```
lib/                                        62 file .dart
├── main.dart                               Root app, MultiProvider setup
├── core/
│   ├── constants/app_constants.dart        URL, role, status string constants
│   ├── network/
│   │   ├── mock_service.dart               Auth + kost mock (tanpa backend)
│   │   ├── dio_client.dart                 HTTP Dio client (untuk produksi)
│   │   └── api_endpoints.dart              Konstanta endpoint API
│   ├── router/app_router.dart              GoRouter + AppRoutes (semua rute)
│   ├── theme/
│   │   ├── app_colors.dart                 Palet warna lengkap
│   │   ├── app_text_styles.dart            Typography (Poppins)
│   │   └── app_theme.dart                  ThemeData Material 3
│   ├── utils/
│   │   ├── currency_utils.dart
│   │   ├── date_utils.dart
│   │   ├── snackbar_utils.dart
│   │   └── validators.dart
│   └── widgets/                            ← SHARED COMPONENTS
│       ├── app_button.dart                 Custom Primary Button (loading state)
│       ├── app_text_field.dart             Custom TextField dengan validasi
│       ├── empty_state.dart                EmptyState + ErrorState widget
│       ├── shimmer_loading.dart            ShimmerBox, KostCardShimmer, ListItemShimmer
│       ├── responsive_layout.dart          ResponsiveLayout, ContentConstrainedBox
│       └── status_badge.dart
├── data/
│   ├── models/
│   │   ├── kost_model.dart                 20 field, fromJson/toJson/Equatable
│   │   ├── ticket_model.dart               + TicketCategory enum
│   │   ├── reservation_model.dart          16 field termasuk split-bill
│   │   └── user_model.dart                 + field bio (in-memory sesi)
│   └── repositories/
│       ├── mock_repository.dart            ← LAYER REPOSITORY UTAMA
│       │                                   20 kost, 5 tiket, 3 admin pending
│       │                                   Future.delayed(700ms) + simulateError
│       ├── auth_repository.dart            (siap pakai saat backend tersedia)
│       ├── kost_repository.dart            (siap pakai saat backend tersedia)
│       └── ticket_repository.dart          (siap pakai saat backend tersedia)
└── features/
    ├── splash/                             Animated splash screen 4 fase
    ├── auth/                               Login, Register, AuthProvider
    ├── renter/                             ← PERSONA UTAMA UTS
    │   ├── catalog/
    │   │   ├── catalog_page.dart           Screen 1: Home/Katalog (4 states)
    │   │   └── kost_detail_page.dart       Screen 2: Detail Kost
    │   ├── reservation/
    │   │   ├── reservation_form_page.dart  Screen 3: Form Pemesanan
    │   │   └── reservation_success_page.dart  End Alur 1
    │   ├── ticket/
    │   │   ├── ticket_list_page.dart       Screen 4: Daftar Laporan (4 states)
    │   │   ├── ticket_form_page.dart       Screen 5: Form Buat/Edit (5 field)
    │   │   ├── ticket_detail_page.dart     Screen 6: Detail Laporan
    │   │   └── providers/renter_ticket_provider.dart  ViewState + CRUD
    │   └── profile/
    │       ├── renter_profile_page.dart    Screen 7: Profil Pengguna
    │       └── edit_profile_page.dart      Screen 8: Edit Profil + bio
    ├── owner/                              Dashboard + Reservasi + Tiket Owner
    ├── admin/                              Dashboard + Verifikasi Owner
    ├── papibot/                            AI Chatbot (Gemini + fallback)
    └── kost/                               Shell, riwayat reservasi (shared)
```

---

## B. 8 Layar Fungsional (Persona: Penyewa Kost)

| #   | Screen                 | File                         | Fitur Utama                                                     |
| --- | ---------------------- | ---------------------------- | --------------------------------------------------------------- |
| 1   | Katalog Kost           | `catalog_page.dart`          | Search, filter, 4 state UI, 20 data, simulateError toggle       |
| 2   | Detail Kost            | `kost_detail_page.dart`      | Foto carousel, fasilitas chip, tombol Sewa Solo/Patungan        |
| 3   | Form Pemesanan         | `reservation_form_page.dart` | DatePicker, split-bill calculator real-time, anti double-submit |
| 4   | Daftar Laporan         | `ticket_list_page.dart`      | 4 state UI, dialog hapus konfirmasi, edit/hapus per item        |
| 5   | Form Buat/Edit Laporan | `ticket_form_page.dart`      | 5 field, 3 jenis input, validasi lengkap, ImagePicker           |
| 6   | Detail Laporan         | `ticket_detail_page.dart`    | Read + tombol Edit, catatan owner                               |
| 7   | Profil Pengguna        | `renter_profile_page.dart`   | Info akun + bio, menu navigasi, logout                          |
| 8   | Edit Profil            | `edit_profile_page.dart`     | Update nama/HP/bio in-memory, loading di tombol                 |

---

## C. 3 Alur Pengguna Tanpa Dead-End

### Alur 1 — Eksplorasi & Reservasi

```
Login → /renter (Katalog)
  → tap kost → /kost/1 (Detail)
  → tap "Sewa Patungan" → /reservation/form
  → atur anggota 2-4 orang, lihat harga real-time
  → tap "Ajukan Sewa Patungan" → loading di tombol
  → /reservation/success ✓ (Selesai)
  → kembali ke /renter atau lihat riwayat
```

### Alur 2 — CRUD Laporan Kerusakan

```
/tickets (Daftar — 4 states)
  → FAB "Buat Laporan" → /tickets/create
    · isi 5 field (judul, kategori, tanggal, deskripsi, foto)
    · validasi → Submit → Snackbar Sukses ✓
  → tap laporan → /tickets/detail (Read)
  → tap "Edit Laporan" → /tickets/edit (Update)
    · Submit → Snackbar Sukses ✓
  → tap 🗑 di daftar → Dialog Konfirmasi Hapus
    · Konfirmasi → Snackbar "Berhasil Dihapus" ✓
```

### Alur 3 — Kelola Profil

```
/renter/profile (Profil)
  → tap "Edit Profil" → /renter/profile/edit
  → ubah Nama / Nomor HP / Bio
  → tap "Simpan" → loading di tombol (isSubmitting guard)
  → Snackbar Sukses → kembali ke Profil
  → bio muncul di kartu "Informasi Akun" ✓ (state in-memory sesi)
```

---

## D. Repository Pattern & Mock Data

**`lib/data/repositories/mock_repository.dart`** — Singleton

| Method                 | Delay | simulateError | Keterangan                          |
| ---------------------- | ----- | ------------- | ----------------------------------- |
| `getKostList()`        | 700ms | ✅            | Filter search/type/maxPrice         |
| `getKostById()`        | 700ms | ✅            | Throw jika tidak ditemukan          |
| `createReservation()`  | 700ms | ✅            | Simpan ke `_reservationDb`          |
| `getMyTickets()`       | 700ms | ✅            | Sort by createdAt desc              |
| `getTicketById()`      | 700ms | ✅            |                                     |
| `createTicket()`       | 700ms | ✅            | Auto-increment ID                   |
| `updateTicket()`       | 700ms | ✅            | Update in-place                     |
| `deleteTicket()`       | 700ms | ✅            | Remove dari list                    |
| `getProfile()`         | 700ms | ✅            |                                     |
| `updateProfile()`      | 700ms | ✅            | Simpan nama/HP/bio ke `_activeUser` |
| `fetchPendingOwners()` | 700ms | ✅            | 3 data awal                         |
| `verifyOwner()`        | 700ms | ✅            | Remove dari `_pendingOwnerDb`       |

**Data seed:**

- 20 KostModel (PUTRA/PUTRI/CAMPUR, harga 690rb–2jt, rating 3.7–4.9)
- 5 TicketModel awal (PENDING, IN_PROGRESS, DONE)
- 5 kategori referensi: LISTRIK, AIR, MEBEL, STRUKTUR, LAINNYA
- 3 pending owner untuk admin

---

## E. Penanganan 4 State UI

| State       | Widget                                               | Halaman                                 |
| ----------- | ---------------------------------------------------- | --------------------------------------- |
| **Loading** | `ShimmerBox` / `KostCardShimmer` / `ListItemShimmer` | Katalog, Daftar Laporan, Detail, Profil |
| **Empty**   | `EmptyState` (icon + title + subtitle + button)      | Katalog kosong, Daftar Laporan kosong   |
| **Error**   | `ErrorState` (icon + pesan + tombol "Coba Lagi")     | Semua halaman utama                     |
| **Success** | Data tampil                                          | Semua halaman                           |

**Anti Double-Submit:**

- `isSubmitting` di `RenterTicketProvider` & `_isSubmitting` lokal di form
- Tombol `onPressed: isSubmitting ? null : _submit` — otomatis disabled
- `CircularProgressIndicator` di dalam `AppButton` saat loading

---

## F. Form Ticket — Validasi Lengkap

| Field            | Tipe Input                  | Validasi                                 |
| ---------------- | --------------------------- | ---------------------------------------- |
| Judul Kerusakan  | TextField                   | Wajib, min 5 karakter, max 100 karakter  |
| Kategori         | Dropdown (`initialValue`)   | Wajib dipilih, tidak boleh null          |
| Tanggal Kejadian | DatePicker                  | Wajib, range: 365 hari lalu s/d hari ini |
| Deskripsi        | TextArea (5 baris)          | Wajib, min 15 karakter, max 500 karakter |
| Foto Kerusakan   | ImagePicker (kamera/galeri) | Opsional, maks 3 foto, preview lokal     |

---

## G. Responsivitas

- Semua teks pakai `maxLines` + `TextOverflow.ellipsis`
- Layout pakai `Expanded` / `Flexible` — tidak ada hardcoded width berbahaya
- `ResponsiveLayout` widget tersedia di `core/widgets/responsive_layout.dart`
- Breakpoints: mobile <768, tablet 768–1279, desktop ≥1280
- Nama yang panjang pada card terpotong dengan ellipsis

---

## H. Demo Akun

| Role                | Email               | Password |
| ------------------- | ------------------- | -------- |
| Penyewa (Utama UTS) | renter@papikost.com | 123456   |
| Pemilik Kost        | owner@papikost.com  | 123456   |
| Admin               | admin@papikost.com  | 123456   |

### Cara Demo Error State

Di `CatalogPage`, ada tombol 🐛 di pojok kanan atas header.
Tap → `simulateError = true` → loading → Error State → "Coba Lagi".

---

## I. Perbaikan yang Dilakukan (Audit)

| File                       | Perubahan                                                             |
| -------------------------- | --------------------------------------------------------------------- |
| `user_model.dart`          | Tambah field `bio` + update `fromJson`, `toJson`, `copyWith`, `props` |
| `mock_repository.dart`     | `updateProfile()` simpan `bio` ke `_activeUser`                       |
| `mock_repository.dart`     | Tambah `fetchPendingOwners()` + `verifyOwner()` + `_pendingOwnerDb`   |
| `ticket_form_page.dart`    | Ganti `value:` → `initialValue:` pada `DropdownButtonFormField`       |
| `edit_profile_page.dart`   | Load `bio` dari profile saat halaman dibuka                           |
| `renter_profile_page.dart` | Tampilkan `bio` di kartu Informasi Akun jika tidak kosong             |
| `register_page.dart`       | Tambah block `{}` pada `if` statement (lint fix)                      |
| `add_kost_page.dart`       | Ganti `activeColor` → `activeThumbColor` pada Switch (deprecated fix) |
