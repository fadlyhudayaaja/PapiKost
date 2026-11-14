# Status backend saat commit 14 November 2026

Kode aplikasi saat ini menggunakan Firebase Auth untuk sesi dan Firestore untuk
profil, katalog/pengelolaan kost, reservasi, laporan, verifikasi, serta daftar
pengguna admin. Firebase diinisialisasi pada Android; platform lainnya belum
dikonfigurasi untuk backend produksi.

Foto kamar, laporan, dan dokumen verifikasi masih menggunakan URL HTTPS.
Pemilihan foto dari galeri/kamera dan unggahan Supabase belum diimplementasikan.
`firebase.json` hanya mengonfigurasi Firestore. `storage.rules` adalah referensi
lama dan tidak digunakan oleh alur aplikasi saat ini.

Validasi ulang sebelum commit:

- `flutter test --no-pub --reporter expanded`: **143 tes lulus**.
- `npm run test:emulator` di `firebase_tests`: **92 tes Firestore lulus**.
- `flutter analyze --no-pub`: **69 info lint**, tanpa error atau warning;
  perintah tetap mengembalikan exit code 1 karena info lint tersebut.
- `git diff --check`: lulus.

Validasi ini memakai mock dan emulator lokal. Konfigurasi server, billing,
aturan yang terpasang, dan alur produksi tidak diperiksa ulang pada 14 November.
Pembuatan commit tidak menerbitkan aturan atau mengubah data Firebase.

Panduan yang berlaku: [foto URL](FIREBASE_UPLOAD_DOKUMEN.md),
[reservasi](FIREBASE_RESERVASI.md), [laporan](FIREBASE_LAPORAN.md), dan
[verifikasi](FIREBASE_VERIFIKASI_PEMILIK.md).

## Audit historis

Catatan di bawah dipertahankan sebagai riwayat pemeriksaan sebelumnya. Referensi
repository unggahan, tes Storage, dan langkah aktivasi Storage di bawah tidak
menggambarkan kode aplikasi saat commit ini.

> Pembaruan 13 November 2026: foto kamar dan dokumen verifikasi kini memakai URL HTTPS.
> Implementasi unggahan Storage di bawah merupakan catatan historis dan sudah diganti.
> Lihat [panduan URL foto](FIREBASE_UPLOAD_DOKUMEN.md) untuk alur yang berlaku.

# Audit backend PapiKost

Tanggal pemeriksaan: 13 November 2026. Proyek Firebase: `papikost-913c2`.

Kesimpulan: backend inti sudah memiliki implementasi Firebase dan tes, tetapi
seluruh fitur aplikasi belum selesai serta unggahan produksi belum aktif.

## Status fitur

| Fitur | Status hasil audit | Bukti utama |
| --- | --- | --- |
| Daftar, login, logout, dan profil | Implementasi Firebase Auth/Firestore tersedia dan diuji. Login email/password aktif di server. | `lib/data/repositories/auth_repository.dart`, tes auth |
| Katalog dan pengelolaan kost | Repository Firestore aktif: baca, tambah, ubah, hapus, pembatasan pemilik, dan validasi kamar/harga. | `lib/data/repositories/kost_repository.dart`, tes katalog/kost |
| Reservasi dan patungan | Implementasi Firestore tersedia; persetujuan dan pengurangan kamar atomik. Patungan menghitung pembagian biaya. | `lib/data/repositories/reservation_repository.dart`, tes reservasi |
| Laporan kerusakan | Buat/ubah/hapus laporan menunggu, pemrosesan oleh pemilik, serta pembatasan sesuai reservasi tersedia. | `lib/data/repositories/ticket_repository.dart`, tes laporan |
| Verifikasi pemilik | Pengajuan, persetujuan, penolakan, alasan, audit admin, dan pembaruan status profil tersedia. | `lib/data/repositories/owner_verification_repository.dart`, tes verifikasi |
| Manajemen pengguna admin | Daftar, pencarian, filter, dan detail profil tersedia. Perubahan peran, penonaktifan, dan penghapusan akun belum disediakan. | `lib/data/repositories/admin_user_repository.dart`, `lib/features/admin/presentation/pages/admin_users_page.dart` |
| Unggah dokumen verifikasi | Kode kamera/galeri, unggah privat, pratinjau, coba ulang, dan pembacaan oleh admin selesai serta diuji lokal. Layanan Storage produksi belum aktif. | `lib/data/repositories/verification_document_repository.dart`, `storage.rules` |
| Unggah foto kost | Setelah perbaikan formulir, foto dipilih lewat kamera/galeri, dipratinjau, dan diunggah saat menyimpan kamar. Aktivasi Storage produksi masih diperlukan. | `lib/features/owner/presentation/pages/kost_management_page.dart`, `lib/data/repositories/kost_photo_repository.dart` |
| Unggah foto laporan | Formulir masih menerima tautan HTTPS. Belum terhubung ke unggah berkas langsung. | `lib/features/renter/ticket/pages/ticket_form_page.dart` |
| PapiBot | Rekomendasi mengambil data kost dari Firestore. Respons AI masih fallback karena API key tetap placeholder; riwayat percakapan hanya berada di memori provider. | `lib/features/papibot/presentation/providers/papibot_provider.dart`, `lib/core/constants/app_constants.dart` |
| Notifikasi dan Bantuan | Menu pada profil pemilik/penyewa masih memakai callback kosong. Belum ada alur layanan yang terhubung. | `lib/features/owner/presentation/pages/owner_profile_page.dart`, `lib/features/renter/profile/pages/renter_profile_page.dart` |
| Firebase untuk platform lain | Inisialisasi Firebase saat ini hanya dijalankan pada Android. Web, iOS, dan desktop belum dikonfigurasi oleh alur startup ini. | `lib/main.dart` |

## Pemeriksaan langsung server

- Konfigurasi Authentication berhasil dibaca: login email aktif dan password
  diperlukan.
- Sumber aturan Firestore yang dipublikasikan sama dengan `firestore.rules`
  lokal, termasuk akses admin dan referensi dokumen privat.
- Billing proyek masih tidak aktif (`billingEnabled: false`).
- API Cloud Storage for Firebase masih belum digunakan/aktif (respons 403).
- Bucket `papikost-913c2.firebasestorage.app` belum ada (respons 404).

Jadi kode unggahan belum berarti layanan unggahan online sudah siap. Aktivasi
Storage memerlukan tindakan pemilik proyek sesuai
[panduan unggahan](FIREBASE_UPLOAD_DOKUMEN.md).

## Pengujian yang dijalankan ulang

- `flutter test --reporter expanded`: **118 tes lulus**.
- Tes Firestore dan Storage Emulator: **96 tes lulus**.
- Log lokal: `build/backend-audit-tests.log` dan
  `build/backend-audit-emulators.log`.

Tes emulator memakai project demo lokal. Hasil ini memvalidasi kode dan aturan;
bukan bukti bahwa semua alur sudah diuji menyeluruh dengan akun nyata di HP
dan layanan produksi. Uji unggahan produksi belum bisa dilakukan selama
Storage belum aktif. File `test/admin_users_test.dart` hanya mencakup bagian
manajemen pengguna; tes backend lainnya berada di file terpisah.

## Catatan kode lama

`mock_repository.dart`, `mock_service.dart`, dan beberapa halaman lama masih ada,
tetapi audit rute serta provider aktif tidak menemukan pemakaian dua repository
mock itu untuk alur backend utama. TODO pada halaman detail kost lama tidak
berarti reservasi aktif masih simulasi: router memakai halaman detail dari
`features/renter/catalog` dan repository reservasi Firebase.

## Urutan penyelesaian

1. Aktifkan Storage, buat bucket, publikasikan `storage.rules`, lalu uji unggahan
   pemilik → pemeriksaan foto admin dengan akun nyata pada Android.
2. Hubungkan unggahan foto untuk laporan kerusakan dan uji foto kost pada Storage produksi.
3. Lengkapi layanan PapiBot jika respons AI nyata termasuk kebutuhan aplikasi.
4. Implementasikan Notifikasi dan Bantuan yang masih berupa menu kosong.
5. Tambahkan operasi pengelolaan akun admin dan platform lain jika diperlukan
   dalam cakupan aplikasi, lalu lakukan uji menyeluruh sebelum rilis.

Audit ini tidak mengubah kode fitur, aturan server, paket billing, atau data
pengguna produksi.
