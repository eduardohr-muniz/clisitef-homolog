import 'package:flutter/material.dart';
import 'package:agente_clisitef/agente_clisitef.dart';

/// Controller responsável por gerenciar o estado e lógica das transações pendentes
class PendingTransactionController extends ChangeNotifier {
  // Estados
  bool _isLoading = false;
  String _statusMessage = 'Pronto para transações pendentes';
  String _sessionId = '';
  CliSiTefServiceCapturaTardia? _service;
  PendingTransaction? _pendingTransaction;

  // Configurações
  final TextEditingController serverIPController = TextEditingController(text: 'intranet5.wbagestao.com');
  final TextEditingController storeIdController = TextEditingController(text: '00000000');
  final TextEditingController terminalIdController = TextEditingController(text: 'REST0001');
  final TextEditingController amountController = TextEditingController(text: '100');
  final TextEditingController cupomFiscalController = TextEditingController(text: '1234');
  final TextEditingController operatorController = TextEditingController(text: 'CAIXA');

  // Getters
  bool get isLoading => _isLoading;
  String get statusMessage => _statusMessage;
  String get sessionId => _sessionId;
  CliSiTefServiceCapturaTardia? get service => _service;
  PendingTransaction? get pendingTransaction => _pendingTransaction;
  bool get isServiceInitialized => _service?.isInitialized ?? false;
  bool get hasPendingTransaction => _pendingTransaction != null;
  bool get isTransactionFinalized => _pendingTransaction?.isFinalized ?? false;

  /// Inicializa o serviço de transação pendente
  Future<void> initializeService() async {
    _setLoading(true);
    _updateStatus('Inicializando serviço pendente...');

    try {
      final config = _createConfig();
      _service = CliSiTefServiceCapturaTardia(config: config);
      final initialized = await _service!.initialize();

      _setLoading(false);
      _updateStatus(initialized ? 'Serviço pendente inicializado com sucesso' : 'Erro ao inicializar serviço');
      _sessionId = _service?.currentSessionId ?? '';
    } catch (e) {
      _setLoading(false);
      _updateStatus('Erro ao inicializar: $e');
    }
  }

  /// Cria a configuração do CliSiTef
  CliSiTefConfig _createConfig() {
    return CliSiTefConfig(
      sitefIp: serverIPController.text,
      storeId: storeIdController.text,
      terminalId: terminalIdController.text,
      cashierOperator: operatorController.text,
      enableLogs: true,
    );
  }

  /// Obtém o código da função baseado no tipo de transação
  int getFunctionCode(String transactionType) {
    switch (transactionType.toUpperCase()) {
      case 'CREDITO':
        return 3;
      case 'DEBITO':
        return 4;
      case 'PIX':
        return 122;
      default:
        return 122;
    }
  }

  /// Inicia uma transação pendente
  Future<PendingTransaction?> startPendingTransaction(String transactionType) async {
    if (!_validateService()) return null;

    _setLoading(true);
    _updateStatus('Iniciando transação pendente $transactionType...');

    try {
      final transactionData = _createTransactionData(transactionType);
      final pendingTransaction = await _service!.startPendingTransaction(transactionData);

      if (pendingTransaction == null) {
        throw Exception('Erro ao iniciar transação pendente');
      }

      _pendingTransaction = pendingTransaction;
      _sessionId = pendingTransaction.sessionIdValue;
      _setLoading(false);
      _updateStatus('✅ Transação pendente iniciada!\nAguardando interação do usuário...');

      return pendingTransaction;
    } catch (e) {
      _setLoading(false);
      _updateStatus('Erro na transação pendente: $e');
      rethrow;
    }
  }

  /// Cria os dados da transação
  TransactionData _createTransactionData(String transactionType) {
    final functionCode = getFunctionCode(transactionType);
    const fiscalDate = '20180611';
    const fiscalTime = '170000';

    return TransactionData.payment(
      functionId: functionCode,
      trnAmount: amountController.text,
      taxInvoiceNumber: cupomFiscalController.text,
      taxInvoiceDate: fiscalDate,
      taxInvoiceTime: fiscalTime,
      cashierOperator: operatorController.text,
    );
  }

  /// Continua a transação com dados do usuário
  Future<TransactionResponse?> continueTransaction(String data) async {
    if (!_validatePendingTransaction()) return null;

    _setLoading(true);
    _updateStatus('Processando interação do usuário...');

    try {
      final response = _pendingTransaction!.originalResponse;
      final result = await _pendingTransaction!.continueWithData(
        command: response.command!,
        data: data,
      );

      _setLoading(false);

      if (result.isServiceSuccess) {
        if (result.shouldContinue) {
          _updateStatus('Aguardando mais interação...');
        } else {
          _updateStatus('✅ Transação processada com sucesso!\nPronta para confirmação.');
        }
        return result;
      } else {
        _updateStatus('❌ Erro ao processar: ${result.errorMessage}');
        return result;
      }
    } catch (e) {
      _setLoading(false);
      _updateStatus('Erro ao processar: $e');
      rethrow;
    }
  }

  /// Confirma a transação pendente
  Future<TransactionResponse?> confirmTransaction() async {
    if (!_validatePendingTransaction()) return null;
    if (_isTransactionFinalized()) return null;

    _setLoading(true);
    _updateStatus('Confirmando transação...');

    try {
      final result = await _pendingTransaction!.confirm(
        taxInvoiceNumber: cupomFiscalController.text,
        taxInvoiceDate: '20180611',
        taxInvoiceTime: '170000',
      );

      _setLoading(false);

      if (result.isServiceSuccess) {
        _updateStatus('✅ Transação confirmada com sucesso!\nStatus: ${result.clisitefStatus}');
      } else {
        _updateStatus('❌ Erro ao confirmar: ${result.errorMessage}');
      }

      return result;
    } catch (e) {
      _setLoading(false);
      _updateStatus('Erro ao confirmar: $e');
      rethrow;
    }
  }

  /// Cancela a transação pendente
  Future<TransactionResponse?> cancelTransaction() async {
    if (!_validatePendingTransaction()) return null;
    if (_isTransactionFinalized()) return null;

    _setLoading(true);
    _updateStatus('Cancelando transação...');

    try {
      final result = await _pendingTransaction!.cancel(
        taxInvoiceNumber: cupomFiscalController.text,
        taxInvoiceDate: '20180611',
        taxInvoiceTime: '170000',
      );

      _setLoading(false);

      if (result.isServiceSuccess) {
        _updateStatus('✅ Transação cancelada com sucesso!\nStatus: ${result.clisitefStatus}');
      } else {
        _updateStatus('❌ Erro ao cancelar: ${result.errorMessage}');
      }

      return result;
    } catch (e) {
      _setLoading(false);
      _updateStatus('Erro ao cancelar: $e');
      rethrow;
    }
  }

  /// Simula a emissão de cupom fiscal
  Future<void> simulateCupomEmission() async {
    _setLoading(true);
    _updateStatus('Simulando emissão de cupom fiscal...');

    // Simula tempo de emissão do cupom
    await Future.delayed(const Duration(seconds: 2));

    _setLoading(false);
    _updateStatus('✅ Cupom fiscal emitido com sucesso!\nAgora você pode confirmar a transação.');
  }

  /// Valida se o serviço está inicializado
  bool _validateService() {
    if (_service == null || !_service!.isInitialized) {
      _updateStatus('Serviço não inicializado');
      return false;
    }
    return true;
  }

  /// Valida se há uma transação pendente
  bool _validatePendingTransaction() {
    if (_pendingTransaction == null) {
      _updateStatus('Nenhuma transação pendente');
      return false;
    }
    return true;
  }

  /// Verifica se a transação está finalizada
  bool _isTransactionFinalized() {
    if (_pendingTransaction!.isFinalized) {
      _updateStatus('Transação já foi finalizada');
      return true;
    }
    return false;
  }

  /// Atualiza o estado de loading
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  /// Atualiza a mensagem de status
  void _updateStatus(String message) {
    _statusMessage = message;
    notifyListeners();
  }

  /// Limpa o estado da transação
  void clearTransaction() {
    _pendingTransaction = null;
    _sessionId = '';
    _updateStatus('Pronto para transações pendentes');
  }

  /// Libera recursos
  @override
  void dispose() {
    _service?.dispose();
    super.dispose();
  }
}
