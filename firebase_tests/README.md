# Tes aturan Firestore

Jalankan dari folder ini dengan Node.js dan Java tersedia di PATH:

```sh
npm ci
npm run test:emulator
```

Tes memakai Firestore Emulator dengan project `demo-papikost`. Kasus yang diuji mencakup akses katalog, kepemilikan properti, perubahan jumlah kamar, penghapusan, URL foto, rating, dan akses profil pengguna. Tes reservasi mencakup privasi penyewa/pemilik, harga dari kost, patungan, tanggal, pencegahan duplikasi, penolakan, serta persetujuan atomik termasuk perebutan kamar terakhir.

Tes laporan mencakup kaitan ke reservasi yang disetujui, privasi UID, validasi formulir/foto, edit dan hapus selama menunggu, catatan pemilik, serta status satu arah hingga selesai.

Tes verifikasi pemilik mencakup pengajuan dan pengajuan ulang, privasi dokumen,
validasi identitas/foto, akses khusus admin, alasan penolakan, audit keputusan,
persetujuan atomik dengan status profil, serta dua admin yang memproses bersamaan.

`npm run test:emulator` hanya menjalankan Firestore Emulator. Aplikasi saat ini
menyimpan URL HTTPS gambar, sehingga Firebase Storage dan tes Storage tidak
digunakan. File `../storage.rules` merupakan referensi implementasi lama dan
tidak diterbitkan oleh konfigurasi `firebase.json` saat ini.

Aturan yang diuji berasal dari `../firestore.rules`. Menjalankan tes tidak menerbitkan aturan ke project Firebase aplikasi. Untuk mengaktifkan perubahan pada aplikasi, salin file tersebut ke Firebase Console → Firestore → Rules, lalu klik Publish.

Tes verifikasi kamar mencakup kamar baru di antrean admin, status awal wajib
Proses, keputusan khusus admin, audit server, alasan penolakan, pengajuan ulang,
dukungan kamar lama tanpa status, dan larangan reservasi sebelum ACC.
