import 'package:agente_clisitef/src/core/constants/clisitef_constants.dart';

/// Utilitários de formatação para o CliSiTef
class FormatUtils {
  /// Formata valor monetário para o padrão CliSiTef (com vírgula como separador decimal)
  static String formatAmount(double amount) {
    return amount.toStringAsFixed(2).replaceAll('.', ',');
  }

  /// Formata valor monetário para o padrão CliSiTef (com vírgula como separador decimal)
  static String formatAmountString(String amount) {
    final cleanAmount = amount.replaceAll(RegExp(r'[^\d,\.]'), '');
    if (cleanAmount.contains('.')) {
      final parts = cleanAmount.split('.');
      if (parts.length == 2) {
        return '${parts[0]},${parts[1].padRight(2, '0').substring(0, 2)}';
      }
    }
    if (cleanAmount.contains(',')) {
      final parts = cleanAmount.split(',');
      if (parts.length == 2) {
        return '${parts[0]},${parts[1].padRight(2, '0').substring(0, 2)}';
      }
    }
    return '$cleanAmount,00';
  }

  /// Formata data para o padrão CliSiTef (AAAAMMDD)
  static String formatDate(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}'
        '${date.month.toString().padLeft(2, '0')}'
        '${date.day.toString().padLeft(2, '0')}';
  }

  /// Formata horário para o padrão CliSiTef (HHMMSS)
  static String formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}'
        '${time.minute.toString().padLeft(2, '0')}'
        '${time.second.toString().padLeft(2, '0')}';
  }

  /// Formata número do cupom fiscal (máximo 20 caracteres)
  static String formatFiscalCupon(String cupon) {
    if (cupon.length > CliSiTefConstants.MAX_CUPOM_LENGTH) {
      return cupon.substring(0, CliSiTefConstants.MAX_CUPOM_LENGTH);
    }
    return cupon.padLeft(CliSiTefConstants.MAX_CUPOM_LENGTH, '0');
  }

  /// Formata identificação do operador (máximo 20 caracteres)
  static String formatOperator(String operator) {
    if (operator.length > CliSiTefConstants.MAX_OPERATOR_LENGTH) {
      return operator.substring(0, CliSiTefConstants.MAX_OPERATOR_LENGTH);
    }
    return operator;
  }
}
