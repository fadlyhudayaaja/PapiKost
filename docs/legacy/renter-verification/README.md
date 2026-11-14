# Arsip halaman verifikasi berkas penyewa

Dua file `.dart.txt` di folder ini merupakan sumber asli halaman demo dari
`main` sebelum integrasi Firebase, commit `3a41a0f`:

- `renter_verification_page.dart.txt`: pemeriksaan berkas penyewa oleh admin.
- `owner_renter_files_page.dart.txt`: pemeriksaan berkas penyewa oleh pemilik.

Halaman tersebut menggunakan `RenterSubmission`, daftar contoh, dan metode
provider simulasi yang tidak tersedia pada implementasi Firebase terbaru.
Ekstensi `.txt` menyimpan sumber UI tanpa mengompilasinya sebagai aplikasi.
Data contoh serta keputusan dari halaman tersebut bukan data Firebase.

Alur aktif saat ini meliputi verifikasi pemilik/kamar, reservasi, laporan
kerusakan, dan daftar pengguna. Verifikasi dokumen penyewa memerlukan model,
repository, aturan akses, dan alur pengajuan tersendiri sebelum diaktifkan lagi.

Versi lengkap provider dan rute demo tetap tersedia di riwayat Git commit
`3a41a0f`.
