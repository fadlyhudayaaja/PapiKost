# Mengaktifkan reservasi Firebase

Proyek aplikasi: `papikost-913c2`, database Firestore `(default)`.

## Publikasikan Rules terbaru

1. Buka `firestore.rules` di folder yang sama dengan `pubspec.yaml` aplikasi ini.
2. Salin seluruh isinya ke Firebase Console → proyek `papikost-913c2` → Firestore Database → Rules.
3. Klik **Publish**. Tunggu sekitar satu menit, kemudian buka ulang aplikasi.

Mengubah file lokal atau menjalankan aplikasi tidak memublikasikan Rules. Tes emulator juga tidak mengubah database aplikasi.

## Coba alur penyewa dan pemilik

1. Login sebagai **OWNER**, tambahkan kost dengan kamar tersedia. Aktifkan patungan jika diperlukan. Login sebagai **ADMIN** untuk menyetujui pengajuan kamar tersebut sebelum mencoba katalog penyewa.
2. Logout, lalu login sebagai **RENTER** memakai akun lain.
3. Pilih kost di katalog, pilih sewa solo atau patungan, isi tanggal masuk dan kirim pengajuan.
4. Buka **Profil → Riwayat Reservasi**. Pengajuan harus berstatus **Menunggu**.
5. Login sebagai pemilik kost tersebut, lalu buka **Manajemen Reservasi**.
6. Tekan **Setujui** atau **Tolak**. Setelah disetujui, jumlah kamar tersedia berkurang satu. Penolakan tidak mengurangi kamar.
7. Login kembali sebagai penyewa. Status di riwayat mengikuti keputusan pemilik.

Data berada di koleksi `reservations`. `ownerId` dan `renterId` memakai UID Firebase. Pencegahan reservasi ganda disimpan di `users/{uid}/reservationLocks/{kostId}`. Pengajuan yang masih menunggu atau sudah disetujui mencegah pengajuan lain untuk kost yang sama; pengajuan yang ditolak dapat diajukan ulang dan riwayat lama tetap ada.

Harga dan identitas diambil dari data Firebase saat pengajuan. Satu pengajuan, termasuk patungan 2–4 orang, memakai satu kamar setelah disetujui. Patungan saat ini membagi tampilan biaya; pembayaran, pembatalan dan checkout belum diimplementasikan.

Jika muncul **Akses reservasi ditolak**, pastikan Rules terbaru sudah dipublikasikan pada proyek yang benar dan akun penyewa/pemilik memiliki peran `RENTER`/`OWNER` pada dokumen profilnya. Jangan mengganti Rules menjadi akses terbuka.

## Validasi lokal

```sh
flutter analyze --no-pub --no-fatal-infos lib test
flutter test --no-pub
cd firebase_tests
npm run test:emulator
```

Tes emulator memakai proyek demo terpisah `demo-papikost` dan membutuhkan Node.js serta Java di PATH.
