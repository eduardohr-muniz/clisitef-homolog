import 'dart:async';
import 'package:agente_clisitef/src/core/constants/clisitef_constants.dart';
import 'package:agente_clisitef/src/models/clisitef_config.dart';
import 'package:agente_clisitef/src/models/clisitef_response.dart';
import 'package:agente_clisitef/src/models/pending_transaction.dart';
import 'package:agente_clisitef/src/models/transaction_data.dart';
import 'package:agente_clisitef/src/models/transaction_response.dart';
import 'package:agente_clisitef/src/repositories/clisitef_repository.dart';
import 'package:agente_clisitef/src/repositories/clisitef_repository_impl.dart';
import 'package:agente_clisitef/src/services/clisitef_core_service.dart';
import 'package:agente_clisitef/src/services/clisitef_pinpad_service.dart';
import 'package:agente_clisitef/src/services/core/start_transaction_usecase.dart';

/// Serviço para transações pendentes de confirmação
/// Permite iniciar uma transação e decidir posteriormente se confirmar ou cancelar
class CliSiTefServicePending {
  late final CliSiTefRepository _repository;
  late final CliSiTefCoreService _coreService;
  late final CliSiTefPinPadService _pinpadService;

  final CliSiTefConfig _config;
  bool _isInitialized = false;
  String? _currentSessionId;

  CliSiTefServicePending({
    required CliSiTefConfig config,
    CliSiTefRepository? repository,
  }) : _config = config {
    _repository = repository ?? CliSiTefRepositoryImpl(config: config);
    _coreService = CliSiTefCoreService(
      repository: _repository,
      config: config,
    );
    _pinpadService = CliSiTefPinPadService(
      repository: _repository,
      config: config,
    );
  }

  /// Inicializa o serviço
  Future<bool> initialize() async {
    try {
      print('[CliSiTefPending] Inicializando serviço...');

      // Validar configuração
      final errors = _config.validate();
      if (errors.isNotEmpty) {
        print('[CliSiTefPending] Erros de validação: ${errors.join(', ')}');
        return false;
      }

      // Criar sessão
      print('[CliSiTefPending] Criando sessão...');
      final sessionResponse = await _repository.createSession();

      if (!sessionResponse.isServiceSuccess) {
        print('[CliSiTefPending] Erro ao criar sessão: ${sessionResponse.errorMessage}');
        return false;
      }

      _currentSessionId = sessionResponse.sessionId;
      _isInitialized = true;

      print('[CliSiTefPending] Serviço inicializado com sucesso. SessionId: $_currentSessionId');
      return true;
    } catch (e) {
      print('[CliSiTefPending] Erro ao inicializar serviço: $e');
      return false;
    }
  }

  /// Inicia uma transação e retorna um modelo pendente
  /// A transação NÃO é finalizada automaticamente
  Future<PendingTransaction?> startPendingTransaction(TransactionData data) async {
    try {
      if (!_isInitialized) {
        print('[CliSiTefPending] Serviço não inicializado');
        return null;
      }

      print('[CliSiTefPending] Iniciando transação pendente: ${data.functionId}');

      // Usar o use case para processar a transação
      final useCase = StartTransactionUseCase(_repository);
      final result = await useCase.execute(
        data: data,
        autoProcess: true,
        stopBeforeFinish: true, // Transação pendente para antes da finalização
      );

      if (!result.isSuccess) {
        print('[CliSiTefPending] Erro na transação: ${result.errorMessage}');
        return null;
      }

      // Criar transação pendente com os campos mapeados
      print('[CliSiTefPending] Transação pendente criada com sucesso');
      return PendingTransaction(
        sessionId: result.response.sessionId ?? _currentSessionId!,
        response: result.response,
        repository: _repository,
        clisitefFields: result.clisitefFields ?? CliSiTefResponse(),
      );
    } catch (e) {
      print('[CliSiTefPending] Erro inesperado na transação: $e');
      return null;
    }
  }

  /// Verifica se o serviço está inicializado
  bool get isInitialized => _isInitialized;

  /// Obtém o ID da sessão atual
  String? get currentSessionId => _currentSessionId;

  /// Obtém a configuração
  CliSiTefConfig get config => _config;

  /// Obtém o serviço core
  CliSiTefCoreService get coreService => _coreService;

  /// Obtém o serviço PinPad
  CliSiTefPinPadService get pinpadService => _pinpadService;

  /// Obtém a versão do SDK
  String get version => '1.0.0';

  /// Obtém o repositório (para controle manual do fluxo)
  CliSiTefRepository get repository => _repository;

  /// Verifica a conectividade com o servidor
  Future<bool> checkConnectivity() async {
    try {
      print('[CliSiTefPending] Verificando conectividade...');
      final response = await _repository.getState();
      final isConnected = response.isServiceSuccess;
      print('[CliSiTefPending] Conectividade: ${isConnected ? 'OK' : 'FALHA'}');
      return isConnected;
    } catch (e) {
      print('[CliSiTefPending] Erro ao verificar conectividade: $e');
      return false;
    }
  }

  /// Finaliza o serviço
  Future<void> dispose() async {
    try {
      print('[CliSiTefPending] Finalizando serviço...');

      if (_currentSessionId != null) {
        await _repository.deleteSession();
        _currentSessionId = null;
      }

      _isInitialized = false;
      print('[CliSiTefPending] Serviço finalizado');
    } catch (e) {
      print('[CliSiTefPending] Erro ao finalizar serviço: $e');
    }
  }
}
