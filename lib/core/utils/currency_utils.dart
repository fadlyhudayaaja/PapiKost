import 'package:intl/intl.dart';

class CurrencyUtils {
  CurrencyUtils._();

  static final NumberFormat _idrFormatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  static final NumberFormat _idrCompact = NumberFormat.compactCurrency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  /// Format angka ke Rupiah penuh: Rp 1.200.000
  static String format(double amount) => _idrFormatter.format(amount);

  /// Format angka ke Rupiah singkat: Rp 1,2 Jt
  static String formatCompact(double amount) => _idrCompact.format(amount);

  /// Hitung harga per orang untuk split bill
  static double splitPrice(double totalPrice, int memberCount) {
    if (memberCount <= 0) return totalPrice;
    return totalPrice / memberCount;
  }
}
