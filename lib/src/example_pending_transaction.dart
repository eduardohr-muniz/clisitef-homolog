import 'package:agente_clisitef/src/models/clisitef_config.dart';
import 'package:agente_clisitef/src/models/transaction_data.dart';
import 'package:agente_clisitef/src/models/pending_transaction.dart';
import 'package:agente_clisitef/src/services/clisitef_service_pending.dart';

/// Exemplo prático de uso do CliSiTefServicePending
/// Demonstra como iniciar uma transação e confirmar/cancelar posteriormente
class ExamplePendingTransaction {
  /// Exemplo básico de transação pendente
  static Future<void> exemploBasico() async {
    print('=== Exemplo Básico - Transação Pendente ===');

    // 1. Configurar o serviço
    final config = CliSiTefConfig.development(
      sitefIp: '127.0.0.1',
      storeId: '00000000',
      terminalId: 'T001',
    );

    final service = CliSiTefServicePending(config: config);

    try {
      // 2. Inicializar o serviço
      print('\n1. Inicializando serviço...');
      final initialized = await service.initialize();
      if (!initialized) {
        print('❌ Erro: Não foi possível inicializar o serviço');
        return;
      }
      print('✅ Serviço inicializado com sucesso');

      // 3. Criar dados da transação
      final transactionData = TransactionData.payment(
        functionId: 1, // Função de pagamento
        trnAmount: '10,00', // R$ 10,00
        taxInvoiceNumber: '123456',
        taxInvoiceDate: '20241201',
        taxInvoiceTime: '1430',
        cashierOperator: 'CAIXA',
      );

      // 4. Iniciar transação pendente
      print('\n2. Iniciando transação pendente...');
      final pendingTransaction = await service.startPendingTransaction(transactionData);

      if (pendingTransaction == null) {
        print('❌ Erro: Não foi possível iniciar a transação');
        return;
      }
      print('✅ Transação iniciada e pendente de confirmação');
      print('   SessionId: ${pendingTransaction.sessionIdValue}');

      // 5. Simular emissão de cupom fiscal
      print('\n3. Simulando emissão de cupom fiscal...');
      await Future.delayed(const Duration(seconds: 2)); // Simula tempo de emissão
      print('✅ Cupom fiscal emitido');

      // 6. Decidir se confirmar ou cancelar a transação
      print('\n4. Decidindo sobre a transação...');

      // Simular decisão baseada em algum critério (ex: cupom emitido com sucesso)
      const shouldConfirm = true; // Em produção, seria baseado na lógica do negócio

      if (shouldConfirm) {
        print('Decisão: CONFIRMAR transação');

        // Confirmar a transação com dados do cupom fiscal
        final confirmResult = await pendingTransaction.confirm(
          taxInvoiceNumber: '123456',
          taxInvoiceDate: '20241201',
          taxInvoiceTime: '1430',
        );

        if (confirmResult.isServiceSuccess) {
          print('✅ Transação confirmada com sucesso!');
          print('   Status: ${confirmResult.clisitefStatus}');
          print('   Mensagem: ${confirmResult.errorMessage}');
        } else {
          print('❌ Erro ao confirmar transação: ${confirmResult.errorMessage}');
        }
      } else {
        print('Decisão: CANCELAR transação');

        // Cancelar a transação
        final cancelResult = await pendingTransaction.cancel();

        if (cancelResult.isServiceSuccess) {
          print('✅ Transação cancelada com sucesso!');
          print('   Status: ${cancelResult.clisitefStatus}');
          print('   Mensagem: ${cancelResult.errorMessage}');
        } else {
          print('❌ Erro ao cancelar transação: ${cancelResult.errorMessage}');
        }
      }

      // 7. Verificar se a transação foi finalizada
      print('\n5. Verificando status da transação...');
      if (pendingTransaction.isFinalized) {
        print('✅ Transação foi finalizada');
      } else {
        print('⚠️ Transação ainda está pendente');
      }
    } catch (e) {
      print('❌ Erro inesperado: $e');
    } finally {
      // 8. Finalizar o serviço
      print('\n6. Finalizando serviço...');
      await service.dispose();
      print('✅ Serviço finalizado');
    }

    print('\n=== Exemplo concluído ===');
  }

  /// Exemplo de uso em um cenário real de PDV
  static Future<void> exemploPDV() async {
    print('=== Exemplo PDV - Transação Pendente ===');

    final config = CliSiTefConfig.development(
      sitefIp: '127.0.0.1',
      storeId: '00000000',
      terminalId: 'PDV001',
    );

    final service = CliSiTefServicePending(config: config);

    try {
      // Inicializar
      if (!await service.initialize()) {
        throw Exception('Falha na inicialização');
      }

      // Processar venda
      final venda = TransactionData.payment(
        functionId: 1,
        trnAmount: '50,00', // R$ 50,00
        taxInvoiceNumber: 'VDA001',
        taxInvoiceDate: '20241201',
        taxInvoiceTime: '1430',
        cashierOperator: 'OPERADOR1',
      );

      print('Iniciando transação de pagamento...');
      final transacaoPendente = await service.startPendingTransaction(venda);

      if (transacaoPendente == null) {
        throw Exception('Falha ao iniciar transação');
      }

      print('Transação iniciada. Aguardando confirmação...');

      // Simular fluxo do PDV
      // 1. Cliente insere cartão
      // 2. Cliente digita senha
      // 3. Transação é autorizada
      // 4. PDV emite cupom fiscal

      await Future.delayed(const Duration(seconds: 3));
      print('Cupom fiscal emitido com sucesso!');

      // Confirmar transação após emissão do cupom
      final resultado = await transacaoPendente.confirm(
        taxInvoiceNumber: 'VDA001',
        taxInvoiceDate: '20241201',
        taxInvoiceTime: '1430',
      );

      if (resultado.isServiceSuccess) {
        print('✅ Venda finalizada com sucesso!');
        print('   Comprovante: ${resultado.errorMessage}');
      } else {
        print('❌ Erro na finalização: ${resultado.errorMessage}');
      }
    } catch (e) {
      print('❌ Erro no processo: $e');
    } finally {
      await service.dispose();
    }
  }

  /// Exemplo com tratamento de erro e cancelamento
  static Future<void> exemploComTratamentoErro() async {
    print('=== Exemplo com Tratamento de Erro ===');

    final config = CliSiTefConfig.development(
      sitefIp: '127.0.0.1',
      storeId: '00000000',
      terminalId: 'T002',
    );

    final service = CliSiTefServicePending(config: config);
    PendingTransaction? transacaoPendente;

    try {
      // Inicializar
      await service.initialize();

      // Iniciar transação
      final transactionData = TransactionData.payment(
        functionId: 1,
        trnAmount: '25,00',
        taxInvoiceNumber: 'ERR001',
        taxInvoiceDate: '20241201',
        taxInvoiceTime: '1430',
        cashierOperator: 'CAIXA',
      );

      transacaoPendente = await service.startPendingTransaction(transactionData);

      if (transacaoPendente == null) {
        throw Exception('Falha ao iniciar transação');
      }

      print('Transação iniciada. Processando...');

      // Simular erro na emissão do cupom
      await Future.delayed(const Duration(seconds: 1));
      throw Exception('Erro na impressora - não foi possível emitir cupom');
    } catch (e) {
      print('❌ Erro detectado: $e');

      // Sempre tentar cancelar a transação em caso de erro
      if (transacaoPendente != null && !transacaoPendente.isFinalized) {
        print('Cancelando transação devido ao erro...');
        try {
          final cancelResult = await transacaoPendente.cancel();
          if (cancelResult.isServiceSuccess) {
            print('✅ Transação cancelada com sucesso');
          } else {
            print('⚠️ Erro ao cancelar transação: ${cancelResult.errorMessage}');
          }
        } catch (cancelError) {
          print('❌ Erro ao cancelar transação: $cancelError');
        }
      }
    } finally {
      await service.dispose();
    }
  }

  /// Exemplo de transação com confirmação do usuário
  static Future<void> exemploComConfirmacaoUsuario() async {
    print('=== Exemplo com Confirmação do Usuário ===');

    final config = CliSiTefConfig.development(
      sitefIp: '127.0.0.1',
      storeId: '00000000',
      terminalId: 'TOTEM001',
    );

    final service = CliSiTefServicePending(config: config);

    try {
      await service.initialize();

      final transactionData = TransactionData.payment(
        functionId: 1,
        trnAmount: '15,00',
        taxInvoiceNumber: 'TOTEM001',
        taxInvoiceDate: '20241201',
        taxInvoiceTime: '1430',
        cashierOperator: 'TOTEM',
      );

      final transacaoPendente = await service.startPendingTransaction(transactionData);

      if (transacaoPendente == null) {
        throw Exception('Falha ao iniciar transação');
      }

      print('Transação iniciada. Aguardando confirmação do usuário...');

      // Simular interface do usuário
      await Future.delayed(const Duration(seconds: 2));

      // Simular escolha do usuário (em produção seria input real)
      const usuarioConfirmou = true; // Sim/Não do usuário

      if (usuarioConfirmou) {
        print('Usuário confirmou a transação');
        final resultado = await transacaoPendente.confirm();

        if (resultado.isServiceSuccess) {
          print('✅ Transação confirmada pelo usuário!');
        } else {
          print('❌ Erro na confirmação: ${resultado.errorMessage}');
        }
      } else {
        print('Usuário cancelou a transação');
        final resultado = await transacaoPendente.cancel();

        if (resultado.isServiceSuccess) {
          print('✅ Transação cancelada pelo usuário!');
        } else {
          print('❌ Erro no cancelamento: ${resultado.errorMessage}');
        }
      }
    } catch (e) {
      print('❌ Erro: $e');
    } finally {
      await service.dispose();
    }
  }

  /// Função principal para executar todos os exemplos
  static Future<void> executarTodosExemplos() async {
    print('🚀 Iniciando exemplos do CliSiTefServicePending\n');

    await exemploBasico();
    print('\n${'=' * 50}\n');

    await exemploPDV();
    print('\n${'=' * 50}\n');

    await exemploComTratamentoErro();
    print('\n${'=' * 50}\n');

    await exemploComConfirmacaoUsuario();

    print('\n🎉 Todos os exemplos foram executados!');
  }
}
