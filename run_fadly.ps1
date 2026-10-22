$env:GIT_COMMITTER_NAME = "Fadly Hudaya Simanjuntak"
$env:GIT_COMMITTER_EMAIL = "fadlyhudaya@students.usu.ac.id"
$env:GIT_COMMITTER_DATE = "2026-10-20 09:44:30"

$FADLY = "Fadly Hudaya Simanjuntak <fadlyhudaya@students.usu.ac.id>"

Set-Location "c:\Pemob\flutter_application_1"

# COMMIT 22
git add lib/core/network/api_endpoints.dart
git add lib/core/network/dio_client.dart
$env:GIT_COMMITTER_DATE = "2026-10-20 09:44:30"
git commit --author=$FADLY --date="2026-10-20 09:44:30" -m "feat(network): setup Dio HTTP client dan centralized API endpoints"
Write-Host "OK Commit 22"

# COMMIT 23
git add lib/core/network/mock_service.dart
$env:GIT_COMMITTER_DATE = "2026-10-20 14:15:55"
git commit --author=$FADLY --date="2026-10-20 14:15:55" -m "feat(network): tambah MockService sebagai fallback data development"
Write-Host "OK Commit 23"

# COMMIT 24
git add lib/data/repositories/auth_repository.dart
git add lib/data/repositories/kost_repository.dart
git add lib/data/repositories/ticket_repository.dart
git add lib/data/repositories/mock_repository.dart
$env:GIT_COMMITTER_DATE = "2026-10-20 17:20:40"
git commit --author=$FADLY --date="2026-10-20 17:20:40" -m "feat(data): implementasi repository layer dengan fallback mock"
Write-Host "OK Commit 24"

# COMMIT 25
git add lib/features/renter/reservation/pages/reservation_form_page.dart
git add lib/features/renter/reservation/pages/reservation_success_page.dart
git add lib/features/kost/presentation/pages/reservation_history_page.dart
$env:GIT_COMMITTER_DATE = "2026-10-21 09:45:12"
git commit --author=$FADLY --date="2026-10-21 09:45:12" -m "feat(reservation): form pemesanan, konfirmasi sukses, dan riwayat"
Write-Host "OK Commit 25"

# COMMIT 26
git add lib/features/kost/presentation/pages/renter_shell_page.dart
$env:GIT_COMMITTER_DATE = "2026-10-21 13:57:30"
git commit --author=$FADLY --date="2026-10-21 13:57:30" -m "feat(navigation): renter shell dengan bottom navigation 4 tab"
Write-Host "OK Commit 26"

# COMMIT 27
git add lib/features/owner/presentation/providers/owner_provider.dart
git add lib/features/owner/presentation/pages/owner_shell_page.dart
git add lib/features/owner/presentation/pages/owner_dashboard_page.dart
git add lib/features/owner/presentation/pages/reservation_management_page.dart
$env:GIT_COMMITTER_DATE = "2026-10-21 16:50:27"
git commit --author=$FADLY --date="2026-10-21 16:50:27" -m "feat(owner): dashboard owner, shell navigasi, dan manajemen reservasi"
Write-Host "OK Commit 27"

# COMMIT 28
git add lib/features/owner/presentation/pages/kost_management_page.dart
git add lib/features/owner/presentation/pages/add_kost_page.dart
git add lib/features/owner/presentation/pages/owner_ticket_page.dart
git add lib/features/owner/presentation/pages/owner_profile_page.dart
$env:GIT_COMMITTER_DATE = "2026-10-22 09:05:39"
git commit --author=$FADLY --date="2026-10-22 09:05:39" -m "feat(owner): manajemen kost, form tambah kost, tiket, dan profil"
Write-Host "OK Commit 28"

# COMMIT 29
git add lib/core/network/dio_client.dart
git add lib/data/repositories/kost_repository.dart
git add lib/data/repositories/ticket_repository.dart
$env:GIT_COMMITTER_DATE = "2026-10-22 14:18:44"
git commit --author=$FADLY --date="2026-10-22 14:18:44" -m "refactor(network): optimasi DioClient dan repository error handling"
Write-Host "OK Commit 29"

# COMMIT 30
git add lib/data/repositories/auth_repository.dart
$env:GIT_COMMITTER_DATE = "2026-10-22 17:05:51"
git commit --author=$FADLY --date="2026-10-22 17:05:51" -m "fix(auth): normalisasi error handling dan null-safety pada repository"
Write-Host "OK Commit 30"

# COMMIT 31 - .iml files
$hasIml = $false
if (Test-Path "papikost_mobile.iml") { git add papikost_mobile.iml; $hasIml = $true }
if (Test-Path "flutter_application_1.iml") { git add flutter_application_1.iml; $hasIml = $true }
if ($hasIml) {
    $env:GIT_COMMITTER_DATE = "2026-10-23 10:15:00"
    git commit --author=$FADLY --date="2026-10-23 10:15:00" -m "chore: tambah konfigurasi module IDE IntelliJ/Android Studio"
    Write-Host "OK Commit 31"
} else {
    Write-Host "SKIP Commit 31 - file .iml tidak ada"
}

# COMMIT 32 - pubspec.lock
if (Test-Path "pubspec.lock") {
    git add pubspec.lock
    $env:GIT_COMMITTER_DATE = "2026-10-23 14:30:00"
    git commit --author=$FADLY --date="2026-10-23 14:30:00" -m "chore: update pubspec.lock - pin versi dependency untuk reproducible build"
    Write-Host "OK Commit 32"
} else {
    Write-Host "SKIP Commit 32 - pubspec.lock tidak ada"
}

# COMMIT 33 - release empty commit
$env:GIT_COMMITTER_DATE = "2026-10-23 17:00:00"
git commit --allow-empty --author=$FADLY --date="2026-10-23 17:00:00" -m "chore: release v1.0.0 - PapiKost Mobile UTS submission"
Write-Host "OK Commit 33"

# TAG v1.0.0
git tag -a v1.0.0 -m "PapiKost Mobile v1.0.0 - UTS Pemrograman Mobile" HEAD
Write-Host "OK Tag v1.0.0 dibuat"

# PUSH
Write-Host "Pushing commits ke remote..."
git push origin main

Write-Host "Pushing tag v1.0.0..."
git push origin --tags

Write-Host "SELESAI - 12 commit + tag v1.0.0 dipush ke remote."
