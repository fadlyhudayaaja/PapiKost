# Commit backend PapiKost

Rangkaian ini menyimpan kondisi terbaru proyek utama sebelum integrasi unggah
Supabase. Repository tujuan: https://github.com/fadlyhudayaaja/PapiKost.git.

Sebelas commit awal dibuat di `feat/firebase-backend`, berangkat dari commit
lokal `2e2d877`. Rangkaian tersebut kemudian digabungkan ke `main` yang berada
di `3a41a0f`, dengan mempertahankan riwayat kedua branch melalui merge commit.
Konflik model, repository, provider, dan navigasi diselesaikan memakai
implementasi Firebase terbaru yang sudah diuji.

Dua halaman verifikasi penyewa dari `main` masih bergantung pada data/provider
simulasi. Sumber aslinya dipertahankan tanpa perubahan dalam
`docs/legacy/renter-verification/` sebagai arsip di luar kode aplikasi aktif.
Integrasi backend verifikasi berkas penyewa belum termasuk perubahan ini.

## Urutan commit

| No. | Pesan commit | Cakupan |
| --- | --- | --- |
| 1 | `chore(firebase): siapkan dependensi dan konfigurasi platform` | Dependensi, Firebase Android, template desktop, aset, dan pengecualian folder salinan. |
| 2 | `feat(core): tambahkan model domain dan komponen pendukung gambar` | Model, widget bersama, jaringan, normalisasi/resolusi URL gambar, dan tes gambar. |
| 3 | `feat(auth): integrasikan Firebase Auth dan profil Firestore` | Repository autentikasi, sesi, login, splash, profil penyewa, dan tes. |
| 4 | `feat(kost): hubungkan katalog dan pengelolaan kost ke Firestore` | Repository kost, katalog, formulir pemilik, data rekomendasi PapiBot, dan tes. |
| 5 | `feat(reservation): tambahkan reservasi dan persetujuan atomik` | Repository, pengajuan, riwayat, keputusan pemilik, dan tes. |
| 6 | `feat(ticket): integrasikan laporan kerusakan penyewa dan pemilik` | Repository, formulir/daftar/detail laporan, pemrosesan pemilik, tes, dan panduan. |
| 7 | `feat(verification): tambahkan pengajuan dan keputusan verifikasi pemilik` | Model pengajuan, repository, formulir, pemeriksaan admin, tes, dan panduan. |
| 8 | `feat(admin): tambahkan daftar pencarian dan detail pengguna` | Repository, provider, halaman pengguna, dashboard admin, dan tes. |
| 9 | `feat(security): tambahkan aturan Firestore indeks dan tes emulator` | Aturan, indeks, konfigurasi emulator, dan tes akses Firestore. |
| 10 | `feat(app): hubungkan startup router dan provider berdasarkan sesi` | Startup, navigasi, provider pemilik, shell/dashboard/profil, dan tes integrasi. |
| 11 | `docs(backend): perbarui status implementasi dan panduan commit` | Status audit terbaru, panduan reservasi/foto, dan dokumen ini. |

Tes fitur disertakan pada kelompok fiturnya. Validasi keseluruhan dijalankan
pada kondisi akhir proyek; setiap commit perantara belum diuji secara terpisah.

## Hasil validasi

- Flutter: **143 tes lulus**.
- Firestore Emulator: **92 tes lulus**, memakai project `demo-papikost`.
- Analisis Flutter: **69 info lint**, tanpa error atau warning. Info lint
  membuat `flutter analyze --no-pub` mengembalikan exit code 1.

Setelah merge ke `main`, 143 tes Flutter dijalankan ulang dan lulus.
`flutter analyze --no-pub --no-fatal-infos` juga lulus dengan 69 info lint
yang sama. Sumber rules dan tes Firestore identik dengan branch backend yang
telah lolos 92 tes emulator.
`flutter build apk --debug --no-pub` juga berhasil menghasilkan
`build/app/outputs/flutter-apk/app-debug.apk` setelah merge.

Tidak ada deployment Firebase dalam proses commit. Foto tetap memakai URL;
implementasi Supabase belum termasuk rangkaian ini.

Isi folder salinan lokal, arsip ZIP, dependency lokal, dan log pengujian
dikecualikan dari rangkaian backend. Referensi Git `PapiKost` serta panduan
distribusi tim yang sudah tercatat di `main` dipertahankan saat merge. Skrip
rilis lama tetap disimpan di lokal, di luar rangkaian backend ini.
