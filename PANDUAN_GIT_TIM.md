# Panduan Distribusi Git — PapiKost Mobile

**Repo:** https://github.com/fadlyhudayaaja/PapiKost.git

---

## Urutan Eksekusi (WAJIB berurutan)

```
Rio dulu → Maruli setelah Rio push → Fadly setelah Maruli push
```

---

## Anggota & Script

| Anggota           | Email                          | Script               | Periode                | Commit          |
| ----------------- | ------------------------------ | -------------------- | ---------------------- | --------------- |
| Rio Johanes       | riojohanes08@gmail.com         | `script_1_rio.sh`    | Hari 1–5 (10–14 Okt)   | 10 commit       |
| Maruli Sitanggang | maruli180617@gmail.com         | `script_2_maruli.sh` | Hari 6–10 (15–19 Okt)  | 11 commit       |
| Fadly Simanjuntak | fadlyhudaya@students.usu.ac.id | `script_3_fadly.sh`  | Hari 11–14 (20–23 Okt) | 12 commit + tag |

---

## Pembagian File (ZIP/Drive)

### 📦 Rio → Maruli kirimkan:

```
assets/
lib/data/models/
  ├── user_model.dart
  ├── kost_model.dart
  ├── reservation_model.dart
  └── ticket_model.dart
lib/core/widgets/
  ├── app_button.dart
  ├── app_text_field.dart
  ├── shimmer_loading.dart
  ├── empty_state.dart
  ├── status_badge.dart
  └── responsive_layout.dart
lib/features/kost/
lib/features/renter/catalog/
lib/features/renter/profile/
lib/features/renter/ticket/
lib/features/ticket/
linux/
macos/
windows/
```

### 📦 Maruli → Fadly kirimkan:

```
lib/core/network/
  ├── api_endpoints.dart
  ├── dio_client.dart
  └── mock_service.dart
lib/data/repositories/
  ├── auth_repository.dart
  ├── kost_repository.dart
  ├── ticket_repository.dart
  └── mock_repository.dart
lib/features/renter/reservation/
  └── pages/
      ├── reservation_form_page.dart
      └── reservation_success_page.dart
lib/features/kost/presentation/pages/
  ├── renter_shell_page.dart
  └── reservation_history_page.dart
lib/features/owner/
papikost_mobile.iml
flutter_application_1.iml
```

---

## Cara Jalankan Script

> **PENTING: Gunakan Git Bash** (bukan CMD atau PowerShell biasa).
> Git Bash sudah termasuk dalam instalasi Git for Windows.

### Rio (laptop Rio):

```bash
# Buka Git Bash di ROOT folder Flutter project (yang ada pubspec.yaml)
bash script_1_rio.sh
```

### Maruli (laptop Maruli):

```bash
# 1. Buat folder kosong, misal D:\PapiKost\
# 2. Copy semua file yang diterima dari Rio ke D:\PapiKost\
# 3. Buka Git Bash di D:\PapiKost\
bash script_2_maruli.sh
# Script akan clone dulu, lalu minta kamu copy file sebelum commit
```

### Fadly (laptop Fadly):

```bash
# 1. Buat folder kosong, misal D:\PapiKost\
# 2. Copy semua file yang diterima dari Maruli ke D:\PapiKost\
# 3. Buka Git Bash di D:\PapiKost\
bash script_3_fadly.sh
# Script akan clone + pull dulu, lalu minta kamu copy file sebelum commit
```

---

## Verifikasi Hasil Akhir

Setelah Fadly selesai push, cek dari GitHub atau jalankan:

```bash
git log --oneline --decorate --graph
git shortlog -sn       # lihat jumlah commit per orang
git tag -l             # pastikan tag v1.0.0 muncul
```

Hasil yang diharapkan:

```
33 commit total
  13  Rio Johanes
  11  Maruli Ricardo Sitanggang
   9  Fadly Hudaya Simanjuntak
tag: v1.0.0
```

---

## Troubleshooting

**Error: `! [rejected] main -> main (fetch first)`**

```bash
git pull origin main --rebase
git push origin main
```

**Error: `fatal: remote origin already exists`**

```bash
git remote set-url origin https://github.com/fadlyhudayaaja/PapiKost.git
```

**Error: authentication failed (HTTPS)**

- Gunakan Personal Access Token GitHub sebagai password
- Atau setup SSH key: `ssh-keygen -t ed25519 -C "email@gmail.com"`
  lalu ubah REPO_URL di script menjadi `git@github.com:fadlyhudayaaja/PapiKost.git`
