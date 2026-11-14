# Laporan kerusakan di Firebase

Proyek: `papikost-913c2`, Firestore database `(default)`.

## Aktifkan Rules terbaru

Salin seluruh isi `firestore.rules` ke Firebase Console → Firestore Database → Rules, lalu klik **Publish**. Aturan ini mencakup profil, kost, reservasi, dan laporan. Tunggu sekitar satu menit lalu buka ulang aplikasi. Menjalankan aplikasi atau tes emulator tidak memublikasikan aturan.

## Uji alurnya

1. Pastikan akun **RENTER** memiliki reservasi yang sudah **APPROVED**. Jika belum, ajukan reservasi lalu setujui menggunakan akun pemilik kost tersebut.
2. Login sebagai penyewa, buka **Laporan Kerusakan → Buat Laporan**.
3. Pilih kost dari reservasi yang disetujui. Isi judul, kategori, tanggal kejadian, dan deskripsi.
4. Foto opsional: maksimal tiga tautan HTTPS. Foto menggunakan URL langsung tanpa Firebase Storage. Jangan memasukkan lokasi file lokal HP.
5. Kirim laporan. Data muncul di koleksi `tickets` dengan UID `renterId`, `ownerId` dan ID `reservationId`, `kostId` sesuai data Firebase.
6. Selama status **Menunggu**, penyewa dapat mengedit atau menghapus laporan sendiri.
7. Login sebagai **OWNER** pemilik kost tersebut, buka **Pusat Tiket Kerusakan**. Ketuk status laporan, pilih **Diproses**, isi catatan opsional, lalu **Simpan**.
8. Setelah perbaikan selesai, ubah **Diproses → Selesai**. Status dan catatan muncul di daftar serta detail laporan penyewa.

Status berjalan satu arah: `PENDING → IN_PROGRESS → DONE`. Penyewa tidak dapat mengubah atau menghapus laporan yang sudah diproses. Pemilik mengubah status dan catatan, sementara isi laporan asli tetap milik penyewa. Akun lain tidak dapat membaca atau mengubah laporan tersebut.

Tanggal kejadian disimpan terpisah dari waktu laporan dibuat. Pilih tanggal kejadian dalam satu tahun terakhir hingga hari ini.

Jika akses ditolak, periksa Rules yang dipublikasikan, status reservasi, dan akun pemilik yang digunakan. Buka ulang aplikasi setelah Publish. Jangan membuka akses publik ke koleksi laporan.

## Validasi lokal

```sh
flutter analyze --no-pub --no-fatal-infos lib test
flutter test --no-pub
cd firebase_tests
npm run test:emulator
```

Tes emulator memakai `demo-papikost` dan tidak menulis ke database aplikasi.
