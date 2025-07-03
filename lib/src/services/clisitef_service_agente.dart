import 'dart:async';
import 'package:agente_clisitef/src/core/constants/clisitef_constants.dart';
import 'package:agente_clisitef/src/models/clisitef_config.dart';
import 'package:agente_clisitef/src/models/transaction_data.dart';
import 'package:agente_clisitef/src/models/transaction_response.dart';
import 'package:agente_clisitef/src/models/transaction_result.dart';
import 'package:agente_clisitef/src/repositories/clisitef_repository.dart';
import 'package:agente_clisitef/src/repositories/clisitef_repository_impl.dart';
import 'package:agente_clisitef/src/services/clisitef_core_service.dart';
import 'package:agente_clisitef/src/services/clisitef_pinpad_service.dart';

/// Serviço principal do CliSiTef para integração com AgenteCliSiTef
class CliSiTefServiceAgente {
  late final CliSiTefRepository _repository;
  late final CliSiTefCoreService _coreService;
  late final CliSiTefPinPadService _pinpadService;

  final CliSiTefConfig _config;
  bool _isInitialized = false;
  String? _currentSessionId;

  CliSiTefServiceAgente({
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
      print('[CliSiTefAgente] Inicializando serviço...');

      // Validar configuração
      final errors = _config.validate();
      if (errors.isNotEmpty) {
        print('[CliSiTefAgente] Erros de validação: ${errors.join(', ')}');
        return false;
      }

      // Criar sessão
      print('[CliSiTefAgente] Criando sessão...');
      final sessionResponse = await _repository.createSession();

      if (!sessionResponse.isServiceSuccess) {
        print('[CliSiTefAgente] Erro ao criar sessão: ${sessionResponse.errorMessage}');
        return false;
      }

      _currentSessionId = sessionResponse.sessionId;
      _isInitialized = true;

      print('[CliSiTefAgente] Serviço inicializado com sucesso. SessionId: $_currentSessionId');
      return true;
    } catch (e) {
      print('[CliSiTefAgente] Erro ao inicializar serviço: $e');
      return false;
    }
  }

  /// Executa uma transação completa
  Future<TransactionResult> executeTransaction(TransactionData data) async {
    try {
      if (!_isInitialized) {
        print('[CliSiTefAgente] Serviço não inicializado');
        return TransactionResult.error(
          statusCode: CliSiTefConstants.TRANSACTION_NOT_INITIALIZED,
          message: 'Serviço não inicializado',
        );
      }

      print('[CliSiTefAgente] Executando transação: ${data.functionId}');

      // Iniciar transação
      final startResponse = await _repository.startTransaction(data);

      if (!startResponse.isServiceSuccess) {
        print('[CliSiTefAgente] Erro ao iniciar transação: ${startResponse.errorMessage}');
        return TransactionResult.fromResponse(startResponse);
      }

      // Processar fluxo iterativo se necessário
      if (startResponse.shouldContinue) {
        print('[CliSiTefAgente] Transação iniciada, processando fluxo iterativo...');
        final continueResult = await _processIterativeFlow(startResponse);
        return continueResult;
      }

      // Transação concluída com sucesso
      print('[CliSiTefAgente] Transação executada com sucesso');
      return TransactionResult.fromResponse(startResponse);
    } catch (e) {
      print('[CliSiTefAgente] Erro inesperado na transação: $e');
      return TransactionResult.error(
        statusCode: CliSiTefConstants.TRANSACTION_INTERNAL_ERROR,
        message: 'Erro interno: $e',
      );
    }
  }

  /// Processa o fluxo iterativo da transação
  Future<TransactionResult> _processIterativeFlow(TransactionResponse initialResponse) async {
    try {
      TransactionResponse currentResponse = initialResponse;
      String? sessionId = currentResponse.sessionId ?? _currentSessionId;

      if (sessionId == null) {
        return TransactionResult.error(
          statusCode: CliSiTefConstants.ERROR_MISSING_PARAMETER,
          message: 'SessionId não encontrado',
        );
      }

      // Loop de processamento iterativo
      while (currentResponse.shouldContinue) {
        print('[CliSiTefAgente] Processando comando: ${currentResponse.command}');

        // Se não há comando específico, continuar sem dados
        if (currentResponse.command == null) {
          print('[CliSiTefAgente] Continuando transação sem comando específico...');
          currentResponse = await _repository.continueTransaction(
            sessionId: sessionId,
            command: CliSiTefConstants.COMMAND_DISPLAY_MESSAGE,
          );
        } else {
          // Processar comando específico
          final commandResult = await _processCommand(currentResponse, sessionId);

          if (commandResult != null) {
            // Enviar dados coletados
            currentResponse = await _repository.continueTransaction(
              sessionId: sessionId,
              command: currentResponse.command!,
              data: commandResult,
            );
          } else {
            // Comando não processado, continuar sem dados
            currentResponse = await _repository.continueTransaction(
              sessionId: sessionId,
              command: currentResponse.command!,
            );
          }
        }

        if (!currentResponse.isServiceSuccess) {
          print('[CliSiTefAgente] Erro no fluxo iterativo: ${currentResponse.errorMessage}');
          return TransactionResult.fromResponse(currentResponse);
        }
      }

      // Finalizar transação
      final finishResponse = await _repository.finishTransaction(
        sessionId: sessionId,
        confirm: true,
      );

      if (!finishResponse.isServiceSuccess) {
        print('[CliSiTefAgente] Erro ao finalizar transação: ${finishResponse.errorMessage}');
        return TransactionResult.fromResponse(finishResponse);
      }

      print('[CliSiTefAgente] Transação finalizada com sucesso');
      return TransactionResult.fromResponse(finishResponse);
    } catch (e) {
      print('[CliSiTefAgente] Erro no fluxo iterativo: $e');
      return TransactionResult.error(
        statusCode: CliSiTefConstants.ERROR_ITERATIVE_EXECUTION,
        message: 'Erro no fluxo iterativo: $e',
      );
    }
  }

  /// Processa um comando específico
  Future<String?> _processCommand(TransactionResponse response, String sessionId) async {
    try {
      // Se não há comando, não há nada para processar
      if (response.command == null) {
        print('[CliSiTefAgente] Nenhum comando para processar');
        return null;
      }

      switch (response.command) {
        case CliSiTefConstants.COMMAND_DISPLAY_MESSAGE:
          print('[CliSiTefAgente] Exibindo mensagem: ${response.message}');
          // Em um totem real, exibir a mensagem na tela
          return null; // Não precisa retornar dados

        case CliSiTefConstants.COMMAND_COLLECT_AMOUNT:
          print('[CliSiTefAgente] Coletando valor monetário: ${response.message}');
          // Em um totem real, exibir campo monetário
          return '10,00'; // Mock - em produção seria input do usuário

        case CliSiTefConstants.COMMAND_COLLECT_OPERATOR:
          print('[CliSiTefAgente] Coletando operador: ${response.message}');
          // Em um totem real, exibir campo de operador
          return 'CAIXA'; // Mock - em produção seria input do usuário

        case CliSiTefConstants.COMMAND_COLLECT_CUPOM:
          print('[CliSiTefAgente] Coletando cupom fiscal: ${response.message}');
          // Em um totem real, exibir campo de cupom
          return '123456'; // Mock - em produção seria input do usuário

        case CliSiTefConstants.COMMAND_COLLECT_DATE:
          print('[CliSiTefAgente] Coletando data: ${response.message}');
          // Em um totem real, exibir campo de data
          return '20241201'; // Mock - em produção seria input do usuário

        case CliSiTefConstants.COMMAND_COLLECT_TIME:
          print('[CliSiTefAgente] Coletando hora: ${response.message}');
          // Em um totem real, exibir campo de hora
          return '1430'; // Mock - em produção seria input do usuário

        case CliSiTefConstants.COMMAND_COLLECT_PASSWORD:
          print('[CliSiTefAgente] Coletando senha: ${response.message}');
          // Em um totem real, exibir campo de senha
          return '1234'; // Mock - em produção seria input do usuário

        case CliSiTefConstants.COMMAND_COLLECT_CARD:
          print('[CliSiTefAgente] Coletando cartão: ${response.message}');
          // Em um totem real, exibir instruções para cartão
          return null; // Não precisa retornar dados

        case CliSiTefConstants.COMMAND_COLLECT_YES_NO:
          print('[CliSiTefAgente] Coletando confirmação: ${response.message}');
          // Em um totem real, exibir opções Sim/Não
          return 'S'; // Mock - em produção seria seleção do usuário

        case CliSiTefConstants.COMMAND_COLLECT_MENU:
          print('[CliSiTefAgente] Coletando opção do menu: ${response.message}');
          // Em um totem real, exibir menu de opções
          return '1'; // Mock - em produção seria seleção do usuário

        case CliSiTefConstants.COMMAND_COLLECT_FLOAT:
          print('[CliSiTefAgente] Coletando valor com ponto flutuante: ${response.message}');
          // Em um totem real, exibir campo com ponto flutuante
          return '10.50'; // Mock - em produção seria input do usuário

        case CliSiTefConstants.COMMAND_COLLECT_CARD_READER:
          print('[CliSiTefAgente] Coletando dados do leitor de cartão: ${response.message}');
          // Em um totem real, aguardar leitura do cartão
          return null; // Não precisa retornar dados

        case CliSiTefConstants.COMMAND_COLLECT_YES_NO_EXTENDED:
          print('[CliSiTefAgente] Coletando confirmação estendida: ${response.message}');
          // Em um totem real, exibir opções Sim/Não
          return 'S'; // Mock - em produção seria seleção do usuário

        default:
          print('[CliSiTefAgente] Comando desconhecido: ${response.command}');
          return null; // Comando não reconhecido
      }
    } catch (e) {
      print('[CliSiTefAgente] Erro ao processar comando: $e');
      return null; // Indica erro no processamento
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

  /// Inicia uma transação manualmente
  Future<TransactionResponse> startTransaction(TransactionData data) async {
    if (!_isInitialized) {
      throw Exception('Serviço não inicializado');
    }
    return await _repository.startTransaction(data);
  }

  /// Continua uma transação manualmente
  Future<TransactionResponse> continueTransaction({
    required String sessionId,
    required int command,
    String? data,
  }) async {
    if (!_isInitialized) {
      throw Exception('Serviço não inicializado');
    }
    return await _repository.continueTransaction(
      sessionId: sessionId,
      command: command,
      data: data,
    );
  }

  /// Finaliza uma transação manualmente
  Future<TransactionResponse> finishTransaction({
    required String sessionId,
    required bool confirm,
    String? taxInvoiceNumber,
    String? taxInvoiceDate,
    String? taxInvoiceTime,
  }) async {
    if (!_isInitialized) {
      throw Exception('Serviço não inicializado');
    }
    return await _repository.finishTransaction(
      sessionId: sessionId,
      confirm: confirm,
      taxInvoiceNumber: taxInvoiceNumber,
      taxInvoiceDate: taxInvoiceDate,
      taxInvoiceTime: taxInvoiceTime,
    );
  }

  /// Verifica a conectividade com o servidor
  Future<bool> checkConnectivity() async {
    try {
      print('[CliSiTefAgente] Verificando conectividade...');
      final response = await _repository.getState();
      final isConnected = response.isServiceSuccess;
      print('[CliSiTefAgente] Conectividade: ${isConnected ? 'OK' : 'FALHA'}');
      return isConnected;
    } catch (e) {
      print('[CliSiTefAgente] Erro ao verificar conectividade: $e');
      return false;
    }
  }

  /// Finaliza o serviço
  Future<void> dispose() async {
    try {
      print('[CliSiTefAgente] Finalizando serviço...');

      if (_currentSessionId != null) {
        await _repository.deleteSession();
        _currentSessionId = null;
      }

      _isInitialized = false;
      print('[CliSiTefAgente] Serviço finalizado');
    } catch (e) {
      print('[CliSiTefAgente] Erro ao finalizar serviço: $e');
    }
  }
}
