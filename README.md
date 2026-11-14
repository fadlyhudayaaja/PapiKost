# PapiKost

Aplikasi Flutter untuk pencarian dan pengelolaan kost. Backend aktif memakai
Firebase Auth dan Cloud Firestore. Konfigurasi Firebase saat ini tersedia untuk
Android, dengan project `papikost-913c2`.

## Menjalankan aplikasi Android

Siapkan Flutter dengan Dart minimal 3.10.7, Android Studio/Android SDK, serta
emulator atau HP Android yang terhubung. Periksa lingkungan dengan
`flutter doctor`.

```sh
git clone https://github.com/fadlyhudayaaja/PapiKost.git
cd PapiKost
git switch main
flutter pub get
flutter devices
flutter run
```

Jika repository sudah ada di komputer:

```sh
git switch main
git pull --ff-only origin main
flutter pub get
flutter run
```

Jalankan perintah dari folder yang memiliki `pubspec.yaml` di root repository.
`android/app/google-services.json` sudah disertakan. `android/local.properties`
dan dependency dibuat di komputer masing-masing oleh Flutter/Android Studio.
Gunakan koneksi internet untuk mengakses Firebase. Daftar akun melalui aplikasi;
data pengguna dan kost mengikuti data project Firebase tersebut.

## Fitur dan foto

- Login, pendaftaran, sesi, dan profil pengguna.
- Katalog, pengelolaan kost, serta verifikasi pemilik dan kamar oleh admin.
- Reservasi, patungan, persetujuan pemilik, dan riwayat.
- Laporan kerusakan penyewa dan pemrosesan oleh pemilik.
- Daftar, pencarian, filter, dan detail pengguna untuk admin.

Foto masih menggunakan URL HTTPS. Unggah langsung melalui Supabase belum
diimplementasikan. PapiBot memiliki fallback rekomendasi; respons Gemini nyata
memerlukan konfigurasi API tersendiri. Halaman demo verifikasi dokumen penyewa
disimpan di [arsip UI](docs/legacy/renter-verification/README.md).

## Struktur pengujian

Folder `test` tetap menjadi lokasi pengujian Flutter. Tes dikelompokkan
berdasarkan bagian yang diperiksa:

| Folder | Isi |
| --- | --- |
| `test/backend/repositories/` | Tes akses Firebase Auth dan Firestore melalui repository. |
| `test/providers/` | Tes state dan perilaku provider. |
| `test/widgets/` | Tes tampilan, dikelompokkan menurut fitur. |
| `test/core/` | Tes utilitas dan resolusi URL gambar. |
| `test/app/` | Tes startup dan navigasi aplikasi. |
| `test/support/` | Data contoh, mock, pengujian gambar, dan helper font. |

`test/support` dibagi menjadi `fixtures`, `images`, dan `helpers`. Semua folder
ini masih berada dalam satu package Flutter. Kode aplikasi untuk mengakses
Firebase berada di `lib/data/repositories/`; aturan akses server berada di
`firestore.rules`, sedangkan tes aturannya berada di `firebase_tests/`.

## Validasi lokal

```sh
flutter analyze --no-pub --no-fatal-infos
flutter test --no-pub
```

Untuk menjalankan tes repository backend saja:

```sh
flutter test --no-pub test/backend
```

Tes aturan Firestore memakai Node.js, Java, dan emulator lokal:

```sh
cd firebase_tests
npm ci
npm run test:emulator
```

Tes tidak menerbitkan rules atau mengubah data Firebase produksi.

## Pengaturan Firebase

Login email/password harus aktif di Firebase Authentication. Profil di koleksi
`users` menggunakan UID Firebase dan peran `RENTER`, `OWNER`, atau `ADMIN`.
Kamar baru harus disetujui admin sebelum muncul di katalog dan dapat dipesan.
Persetujuan reservasi oleh pemilik mengurangi satu kamar tersedia; laporan
kerusakan hanya dapat dibuat untuk reservasi yang sudah disetujui.

Pengelola Firebase dapat menerbitkan `firestore.rules` dan
`firestore.indexes.json` memakai konfigurasi `firebase.json`. Jalankan dari
folder `firebase_tests` setelah `npm ci`:

```sh
npx firebase login
npx firebase deploy --only firestore --project papikost-913c2 --config ../firebase.json
```

Foto kamar bersifat opsional, dokumen verifikasi pemilik memerlukan tiga URL
gambar, dan laporan menerima maksimal tiga URL foto. Akses berkas mengikuti
layanan asalnya; rules Firestore melindungi data, bukan berkas pada URL luar.
KTP dan sertifikat perlu akses terbatas yang dapat dibuka oleh admin.
