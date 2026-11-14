# Foto menggunakan URL HTTPS

Aplikasi Android sekarang menyimpan URL foto di Firestore. Aplikasi tidak
mengunggah, membaca, atau menghapus berkas melalui Firebase Storage.
Firebase Storage dan paket Blaze tidak diperlukan untuk alur foto ini.

## Cara menggunakan

1. Simpan gambar di layanan penyimpanan yang dipilih, lalu salin URL HTTPS
   gambar. Link file Google Drive seperti /file/d/ID/view?usp=drive_link juga
   diterima; aplikasi mencoba endpoint gambar dan unduhan secara otomatis.
2. Pada Tambah/Edit Kamar, isi URL Foto Kamar. Foto kamar opsional; kosongkan
   kolom untuk menghapus referensi foto dari kamar.
3. Pada Verifikasi Pemilik, isi URL Foto KTP, URL Sertifikat Properti, dan
   URL Foto Kost. Ketiganya wajib diisi. Pratinjau dan halaman detail admin
   memuat gambar dari link tersebut.
4. Foto laporan tetap memakai maksimal tiga URL HTTPS.
5. Tekan simpan/kirim. Firestore menyimpan URL, bukan isi berkas gambar.

URL maksimal 2048 karakter, tanpa spasi atau kredensial dalam URL. Parameter
query (misalnya token akses) diperbolehkan. Link tidak harus berakhiran .jpg
atau .png; server harus mengembalikan gambar yang dapat dibaca Flutter.
Pratinjau yang gagal tidak menghapus input. Periksa link sebelum mengirim.

Akses berkas mengikuti pengaturan layanan asal. Rules Firestore melindungi
akses ke data pengajuan, tetapi tidak melindungi berkas pada URL eksternal.
Untuk KTP/sertifikat, gunakan akses terbatas yang dapat dibuka admin.
Menghapus atau mengganti URL di aplikasi tidak menghapus berkas asal.

## Link berbagi Google Gambar

Link share.google dan halaman Google Images /imgres bukan berkas gambar.
Aplikasi menelusuri redirect HTTPS dan mengambil alamat gambar dari parameter
imgurl/mediaurl, lalu memuat gambar asli. Contoh yang sudah diperiksa:
https://share.google/Br7ug1JpcsJ2VECzw mengarah ke gambar pada images.rukita.co.

Link asli tetap disimpan di Firestore. Gambar lama dari link berbagi Google juga
memakai resolver yang sama pada pratinjau, katalog, detail dan laporan.
Resolusi sukses disimpan sementara selama 5 menit. Muat Ulang menyegarkan
resolusi dan cache gambar. Redirect berulang atau halaman tanpa target gambar
menampilkan instruksi untuk menyalin alamat gambar langsung.

## Link Google Drive

Untuk foto kamar yang memang akan tampil di katalog, buka file di Drive >
Bagikan > Akses umum > Siapa saja yang memiliki link > Pelihat. Salin link
file lengkap, bukan link folder. Uji di jendela Incognito tanpa login Google.
Aplikasi tidak menggunakan sesi Google Drive dari browser perangkat.

Pengaturan publik tersebut khusus gambar katalog yang boleh dibagikan.
Jangan menjadikan KTP atau sertifikat pribadi publik. Dokumen sensitif perlu
URL akses terbatas dari penyedia yang sesuai, yang dapat dimuat aplikasi tanpa
halaman login. Mengubah format URL tidak memberikan izin akses ke file privat.

Link asli dan resourcekey tetap disimpan di Firestore. Resolusi gambar diterapkan
saat menampilkan pratinjau, daftar kamar, katalog, detail, laporan, dan Papibot,
sehingga link Drive lama juga bisa dimuat tanpa migrasi. Jika thumbnail gagal,
aplikasi mencoba unduhan gambar. Jika tetap gagal, periksa izin, tipe berkas,
koneksi, atau pembatasan Google Drive, lalu gunakan Muat Ulang.

## Mengaktifkan aturan Firestore

Dari root proyek, jalankan:

    .\firebase_tests\node_modules\.bin\firebase.cmd login
    .\firebase_tests\node_modules\.bin\firebase.cmd deploy --only firestore:rules --project papikost-913c2

Alternatif: salin isi firestore.rules ke Firebase Console > Firestore Database >
Rules, lalu Publish. Tidak perlu membuat bucket atau menerbitkan Storage Rules.

Tutup dan jalankan ulang aplikasi setelah perubahan dependency:

    flutter pub get
    flutter run

URL HTTPS pada data lama tetap dapat ditampilkan. Referensi lama berbentuk
verificationDocuments/... tidak lagi dibaca oleh aplikasi dan perlu diganti
URL gambar. Pengajuan yang ditolak dapat diperbaiki lewat formulir pemilik.
Jangan mengubah status atau isVerified saat mengganti referensi data lama.

## Pengujian

    flutter test

Aturan URL serta pembatasan akses diuji dengan Firestore Emulator.
Implementasi dan pengujian lokal tidak otomatis menerbitkan aturan produksi.
