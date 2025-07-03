import 'package:agente_clisitef/src/core/constants/clisitef_constants.dart';

/// Exceção personalizada para erros do CliSiTef
class CliSiTefException implements Exception {
  final int errorCode;
  final String message;
  final String? details;
  final dynamic originalError;

  const CliSiTefException({
    required this.errorCode,
    required this.message,
    this.details,
    this.originalError,
  });

  /// Cria uma exceção baseada no código de erro do CliSiTef
  factory CliSiTefException.fromCode(int code, {String? details, dynamic originalError}) {
    String message;
    switch (code) {
      case CliSiTefConstants.SUCCESS:
        message = 'Operação realizada com sucesso';
        break;
      case CliSiTefConstants.TRANSACTION_NOT_INITIALIZED:
        message = 'Módulo não inicializado';
        break;
      case CliSiTefConstants.TRANSACTION_INTERNAL_ERROR:
        message = 'Erro interno do módulo';
        break;
      case CliSiTefConstants.ERROR_MISSING_PARAMETER:
        message = 'Parâmetro obrigatório não foi passado';
        break;
      case CliSiTefConstants.ERROR_ITERATIVE_EXECUTION:
        message = 'Erro na execução da rotina iterativa';
        break;
      case CliSiTefConstants.ERROR_DOCUMENT_NOT_FOUND:
        message = 'Documento fiscal não encontrado';
        break;
      case CliSiTefConstants.ERROR_OPERATION_CANCELLED:
        message = 'Operação cancelada';
        break;
      case CliSiTefConstants.ERROR_INVALID_PARAMETER:
        message = 'Parâmetro inválido passado para a função';
        break;
      case CliSiTefConstants.ERROR_FORBIDDEN_WORD:
        message = 'Utilizada uma palavra proibida';
        break;
      case CliSiTefConstants.ERROR_BANK_CORRESPONDENT:
        message = 'Erro no Correspondente Bancário: Deve realizar sangria';
        break;
      case CliSiTefConstants.ERROR_FILE_ACCESS:
        message = 'Erro de acesso ao arquivo';
        break;
      case CliSiTefConstants.ERROR_SITEF_DENIED:
        message = 'Transação negada pelo servidor SiTef';
        break;
      case CliSiTefConstants.ERROR_INVALID_DATA:
        message = 'Dados inválidos';
        break;
      case CliSiTefConstants.ERROR_PINPAD_EXECUTION:
        message = 'Problema na execução de alguma das rotinas no pinpad';
        break;
      case CliSiTefConstants.ERROR_UNSAFE_TRANSACTION:
        message = 'Transação não segura';
        break;
      default:
        if (code > 0) {
          message = 'Negada pelo autorizador (código: $code)';
        } else {
          message = 'Erro detectado internamente (código: $code)';
        }
    }
    return CliSiTefException(
      errorCode: code,
      message: message,
      details: details,
      originalError: originalError,
    );
  }

  @override
  String toString() {
    final buffer = StringBuffer();
    buffer.write('CliSiTefException: ');
    buffer.write('Código: $errorCode, ');
    buffer.write('Mensagem: $message');
    if (details != null) {
      buffer.write(', Detalhes: $details');
    }
    if (originalError != null) {
      buffer.write(', Erro Original: $originalError');
    }
    return buffer.toString();
  }
}
