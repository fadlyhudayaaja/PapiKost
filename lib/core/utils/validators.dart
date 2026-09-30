/// Kumpulan validator form yang dipakai ulang di seluruh aplikasi
class Validators {
  Validators._();

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) return 'Email wajib diisi';
    final regex = RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,}$');
    if (!regex.hasMatch(value.trim())) return 'Format email tidak valid';
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) return 'Password wajib diisi';
    if (value.length < 6) return 'Password minimal 6 karakter';
    return null;
  }

  static String? confirmPassword(String? value, String original) {
    if (value == null || value.isEmpty)
      return 'Konfirmasi password wajib diisi';
    if (value != original) return 'Password tidak cocok';
    return null;
  }

  static String? required(String? value, {String fieldName = 'Field'}) {
    if (value == null || value.trim().isEmpty) return '$fieldName wajib diisi';
    return null;
  }

  static String? minLength(
    String? value,
    int min, {
    String fieldName = 'Field',
  }) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName wajib diisi';
    }
    if (value.trim().length < min) {
      return '$fieldName minimal $min karakter';
    }
    return null;
  }

  static String? phone(String? value) {
    if (value == null || value.trim().isEmpty) return 'Nomor HP wajib diisi';
    if (value.trim().length < 10) return 'Nomor HP tidak valid';
    return null;
  }

  static String? positiveNumber(String? value, {String fieldName = 'Angka'}) {
    if (value == null || value.trim().isEmpty) return '$fieldName wajib diisi';
    final num = double.tryParse(value.replaceAll('.', ''));
    if (num == null) return '$fieldName harus berupa angka';
    if (num <= 0) return '$fieldName harus lebih dari 0';
    return null;
  }
}
