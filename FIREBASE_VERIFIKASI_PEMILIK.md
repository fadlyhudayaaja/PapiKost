# Verifikasi pemilik oleh admin

Fitur ini menggunakan Firebase Auth dan Firestore, dengan satu dokumen
`ownerVerifications/{uidPemilik}` per pemilik. Data contoh pada halaman admin
sudah diganti dengan stream Firestore.

## Verifikasi kamar setelah ditambahkan owner

Penambahan kamar menyimpan pengajuan langsung di `kost/{idKost}` dengan
`verificationStatus: "PROSES"`. Halaman admin **Verifikasi Pemilik & Kamar**
menggabungkan pengajuan identitas dari `ownerVerifications` dan pengajuan kamar
dari `kost`, serta memperbarui daftar ketika ada perubahan Firestore. Tidak
perlu mengisi verifikasi identitas untuk membuat pengajuan kamar muncul.

1. Owner menambah kamar melalui Manajemen Kamar. Pesan berhasil menyatakan
   bahwa kamar menunggu verifikasi admin.
2. Admin membuka Verifikasi Pemilik & Kamar → Proses. Entri kamar ditandai
   **Pengajuan Kamar**. Detail menampilkan properti, harga, jumlah kamar,
   fasilitas, patungan, deskripsi, dan foto jika tersedia.
3. Admin memilih ACC atau Tolak dengan alasan 10–300 karakter. Keputusan,
   UID admin, dan waktu server disimpan pada dokumen kamar. Persetujuan kamar
   tidak mengubah `users.isVerified`, yang merupakan verifikasi identitas.
4. Hanya kamar berstatus ACC tampil di katalog dan bisa menerima reservasi
   baru. Kamar lama tanpa `verificationStatus` masuk Proses dan perlu
   disetujui admin juga; tidak perlu dibuat ulang. Reservasi lama tetap ada.
5. Owner dapat memuat ulang Manajemen Kamar untuk melihat keputusan dan alasan
   penolakan. Menyimpan edit kamar mengirim ulang pengajuan ke Proses dan
   membersihkan keputusan sebelumnya, termasuk jika kamar sebelumnya ACC.

Aturan Firestore mengharuskan kamar baru masuk Proses, membatasi keputusan
kepada admin, serta melarang admin mengubah harga atau kepemilikan saat
memutuskan. Reservasi kamar yang belum ACC juga ditolak oleh rules.
Publikasikan `firestore.rules` terbaru dan jalankan ulang aplikasi Flutter;
mengubah rules saja tidak menambahkan alur verifikasi kamar pada aplikasi lama.

## Mengaktifkan

1. Gunakan aplikasi Android yang sudah memiliki `android/app/google-services.json`.
   Inisialisasi Firebase di proyek ini saat ini hanya diaktifkan untuk Android.
2. Salin isi `firestore.rules` ke Firebase Console → Firestore Database → Rules,
   lalu Publish. Pengujian lokal tidak menerbitkan aturan tersebut.
3. Untuk akun admin, buat akun melalui Firebase Authentication dan siapkan profil
   `users/{uid}` melalui Firebase Console dengan field berikut. Gunakan UID akun
   dari Authentication sebagai ID dokumen, dan tipe timestamp untuk `createdAt`.

   ```text
   name: "Admin PapiKost"        (string)
   email: email akun admin       (string)
   phone: nomor admin            (string)
   role: "ADMIN"                (string)
   isVerified: false             (boolean)
   createdAt: waktu pembuatan    (timestamp)
   avatarUrl: null
   bio: null
   ```

   Pendaftaran melalui aplikasi hanya menerima `RENTER` dan `OWNER`.
   Pengguna tidak bisa memberi dirinya peran admin.

## Menggunakan

1. Masuk sebagai pemilik → Profil → Verifikasi Pemilik.
2. Isi nomor KTP 16 angka, data properti, serta URL HTTPS foto KTP, sertifikat,
   dan foto kost. Gunakan link langsung ke gambar yang dapat diakses admin.
   Lihat [panduan URL foto](FIREBASE_UPLOAD_DOKUMEN.md). Firebase Storage tidak diperlukan.
3. Kirim pengajuan. Status `PROSES` tampil di akun pemilik dan tab Proses admin.
4. Masuk sebagai admin → Verifikasi Pemilik Kost → pilih pengajuan.
   Admin dapat memeriksa foto (ketuk untuk memperbesar), memilih ACC, atau
   menolak dengan alasan 10–300 karakter.
5. Persetujuan menyimpan status `ACC` dan `users/{uid}.isVerified = true` dalam
   satu transaksi. Penolakan menyimpan `TOLAK`, alasan, dan status belum
   terverifikasi. UID admin dan waktu keputusan dicatat dari sesi/server.
6. Pemilik melihat keputusan identitas secara langsung di halaman verifikasi. Setelah
   kembali ke Profil, status profil dimuat ulang. Pengajuan yang ditolak bisa
   diperbaiki dan dikirim ulang; keputusan yang disetujui tidak bisa diubah.

Firestore menyimpan ketiga URL gambar saat pengajuan dikirim. Pratinjau dan
halaman detail admin membaca gambar melalui URL. Link lama yang berbentuk
verificationDocuments/... perlu diganti URL HTTPS. Akses ke berkas gambar
diatur layanan penyimpanan asal, bukan oleh rules Firestore.

Pengajuan hanya bisa dibaca pemilik bersangkutan dan admin. Admin hanya dapat
mengubah field keputusan; dokumen dan identitas pemilik tidak dapat diubah saat
persetujuan. Jika dua admin memproses pengajuan bersamaan, hanya keputusan
pertama yang dapat disimpan. Status verifikasi tidak mengubah kebijakan akses
kelola kost yang sudah ada.

## Manajemen pengguna dan koneksi

Dashboard Admin → Manajemen Pengguna menampilkan profil dari koleksi `users`.
Admin dapat mencari nama/email/nomor HP/UID, memfilter peran, membaca detail akun,
dan membuka daftar verifikasi dari detail pemilik. Daftar diperbarui langsung
ketika profil berubah. Menu ini menyediakan pencarian dan pemeriksaan akun;
perubahan peran serta penghapusan akun Auth belum disediakan dari aplikasi.

Aturan terbaru memberikan akses baca daftar profil khusus `ADMIN`; pemilik dan
penyewa tetap hanya dapat membaca profil sendiri. Aturan perlu dipublikasikan
lagi setelah menambahkan fitur manajemen pengguna.

Pengambilan awal daftar pengguna dan pengajuan sekarang meminta data server
dengan batas waktu 20 detik sebelum berlangganan perubahan. Koneksi gagal atau
akses ditolak tampil sebagai kesalahan yang bisa dicoba ulang, bukan daftar
kosong dari cache.

Konfigurasi Android dan `.firebaserc` mengarah ke `papikost-913c2`. Untuk
menerbitkan aturan dari terminal proyek, gunakan CLI yang sudah tersedia:

```powershell
.\firebase_tests\node_modules\.bin\firebase.cmd login
.\firebase_tests\node_modules\.bin\firebase.cmd deploy --only firestore:rules --project papikost-913c2
```

Masuk dengan akun Google yang memiliki akses ke proyek tersebut. Alternatifnya,
publikasikan `firestore.rules` melalui Firebase Console. Koneksi web belum
dikonfigurasi; gunakan Android untuk menguji Firebase pada proyek ini.

## Pengujian

```powershell
flutter test
flutter analyze --no-fatal-infos
cd firebase_tests
npm run test:emulator
```

Tes emulator memakai project lokal `demo-papikost`, bukan data Firebase produksi.
Node.js dan Java 21 atau lebih baru perlu tersedia untuk menjalankan emulator.
