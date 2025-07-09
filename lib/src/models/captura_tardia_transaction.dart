import 'package:agente_clisitef/src/core/utils/format_utils.dart';
import 'package:agente_clisitef/src/models/transaction_response.dart';
import 'package:agente_clisitef/src/models/clisitef_response.dart';
import 'package:agente_clisitef/src/repositories/clisitef_repository.dart';

/// Modelo para uma transação pendente de confirmação
class CapturaTardiaTransaction {
  /// ID da sessão da transação
  final String sessionId;

  /// Dados da transação
  final TransactionResponse response;

  /// Repositório para executar as ações
  final CliSiTefRepository repository;

  /// Campos mapeados do CliSiTef
  final CliSiTefResponse clisitefFields;

  final DateTime invoiceDate;

  final DateTime invoiceTime;

  /// Indica se a transação já foi finalizada
  bool _isFinalized = false;

  CapturaTardiaTransaction({
    required this.sessionId,
    required this.response,
    required this.repository,
    required this.clisitefFields,
    required this.invoiceDate,
    required this.invoiceTime,
  });

  /// Confirma a transação
  Future<TransactionResponse> confirm({
    String? taxInvoiceNumber,
    DateTime? taxInvoiceDate,
    DateTime? taxInvoiceTime,
  }) async {
    if (_isFinalized) {
      throw Exception('Transação já foi finalizada');
    }

    try {
      print('[PendingTransaction] Confirmando transação: $sessionId');

      final fiscalDate = FormatUtils.formatDate(taxInvoiceDate ?? invoiceDate);
      final fiscalTime = FormatUtils.formatTime(taxInvoiceTime ?? invoiceTime);

      final result = await repository.finishTransaction(
        sessionId: sessionId,
        confirm: true,
        taxInvoiceNumber: taxInvoiceNumber,
        taxInvoiceDate: fiscalDate,
        taxInvoiceTime: fiscalTime,
      );

      if (result.isServiceSuccess) {
        _isFinalized = true;
        print('[PendingTransaction] Transação confirmada com sucesso');
      } else {
        print('[PendingTransaction] Erro ao confirmar transação: ${result.errorMessage}');
      }

      return result;
    } catch (e) {
      print('[PendingTransaction] Erro inesperado ao confirmar: $e');
      rethrow;
    }
  }

  /// Cancela a transação
  Future<TransactionResponse> cancel({
    String? taxInvoiceNumber,
    DateTime? taxInvoiceDate,
    DateTime? taxInvoiceTime,
  }) async {
    if (_isFinalized) {
      throw Exception('Transação já foi finalizada');
    }

    try {
      print('[PendingTransaction] Cancelando transação: $sessionId');

      final fiscalDate = FormatUtils.formatDate(taxInvoiceDate ?? invoiceDate);
      final fiscalTime = FormatUtils.formatTime(taxInvoiceTime ?? invoiceTime);

      final result = await repository.finishTransaction(
        sessionId: sessionId,
        confirm: false,
        taxInvoiceNumber: taxInvoiceNumber,
        taxInvoiceDate: fiscalDate,
        taxInvoiceTime: fiscalTime,
      );

      if (result.isServiceSuccess) {
        _isFinalized = true;
        print('[PendingTransaction] Transação cancelada com sucesso');
      } else {
        print('[PendingTransaction] Erro ao cancelar transação: ${result.errorMessage}');
      }

      return result;
    } catch (e) {
      print('[PendingTransaction] Erro inesperado ao cancelar: $e');
      rethrow;
    }
  }

  /// Continua a transação com dados específicos
  Future<TransactionResponse> continueWithData({
    required int command,
    String? data,
  }) async {
    if (_isFinalized) {
      throw Exception('Transação já foi finalizada');
    }

    try {
      print('[PendingTransaction] Continuando transação: $sessionId com comando: $command');

      final result = await repository.continueTransaction(
        sessionId: sessionId,
        command: command,
        data: data,
      );

      return result;
    } catch (e) {
      print('[PendingTransaction] Erro inesperado ao continuar: $e');
      rethrow;
    }
  }

  /// Verifica se a transação foi finalizada
  bool get isFinalized => _isFinalized;

  /// Obtém o ID da sessão
  String get sessionIdValue => sessionId;

  /// Obtém a resposta original
  TransactionResponse get originalResponse => response;

  /// Obtém os campos mapeados do CliSiTef
  CliSiTefResponse get fields => clisitefFields;

  @override
  String toString() {
    return 'PendingTransaction('
        'sessionId: $sessionId, '
        'isFinalized: $_isFinalized, '
        'response: $response'
        ')';
  }
}
