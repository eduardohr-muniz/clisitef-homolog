import 'package:flutter/material.dart';
import 'package:agente_clisitef/agente_clisitef.dart';

class PendingTransactionPage extends StatefulWidget {
  const PendingTransactionPage({super.key});

  @override
  State<PendingTransactionPage> createState() => _PendingTransactionPageState();
}

class _PendingTransactionPageState extends State<PendingTransactionPage> {
  bool _isLoading = false;
  String _statusMessage = 'Pronto para transações pendentes';
  String _sessionId = '';
  CliSiTefServicePending? _service;
  PendingTransaction? _pendingTransaction;

  // Controllers para os campos
  final _serverIPController = TextEditingController(text: 'intranet5.wbagestao.com');
  final _storeIdController = TextEditingController(text: '00000000');
  final _terminalIdController = TextEditingController(text: 'REST0001');
  final _amountController = TextEditingController(text: '100');
  final _cupomFiscalController = TextEditingController(text: '1234');
  final _operatorController = TextEditingController(text: 'CAIXA');

  // Tipo de transação selecionado
  String _selectedTransactionType = 'PIX';

  @override
  void initState() {
    super.initState();
    _initializeService();
  }

  @override
  void dispose() {
    _service?.dispose();
    super.dispose();
  }

  Future<void> _initializeService() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Inicializando serviço pendente...';
    });

    try {
      final config = CliSiTefConfig(
        sitefIp: _serverIPController.text,
        storeId: _storeIdController.text,
        terminalId: _terminalIdController.text,
        cashierOperator: _operatorController.text,
        enableLogs: true,
      );

      _service = CliSiTefServicePending(config: config);
      final initialized = await _service!.initialize();

      setState(() {
        _isLoading = false;
        _statusMessage = initialized ? 'Serviço pendente inicializado com sucesso' : 'Erro ao inicializar serviço';
        _sessionId = _service?.currentSessionId ?? '';
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = 'Erro ao inicializar: $e';
      });
    }
  }

  int _getFunctionCode(String transactionType) {
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

  Future<void> _startPendingTransaction() async {
    if (_service == null || !_service!.isInitialized) {
      _showMessage('Serviço não inicializado');
      return;
    }

    setState(() {
      _isLoading = true;
      _statusMessage = 'Iniciando transação pendente $_selectedTransactionType...';
    });

    try {
      final functionCode = _getFunctionCode(_selectedTransactionType);
      final amount = _amountController.text;
      final cupomFiscal = _cupomFiscalController.text;
      final operator = _operatorController.text;

      const fiscalDate = '20180611';
      const fiscalTime = '170000';

      final transactionData = TransactionData.payment(
        functionId: functionCode,
        trnAmount: amount,
        taxInvoiceNumber: cupomFiscal,
        taxInvoiceDate: fiscalDate,
        taxInvoiceTime: fiscalTime,
        cashierOperator: operator,
      );

      final pendingTransaction = await _service!.startPendingTransaction(transactionData);

      if (pendingTransaction == null) {
        throw Exception('Erro ao iniciar transação pendente');
      }

      setState(() {
        _pendingTransaction = pendingTransaction;
        _sessionId = pendingTransaction.sessionIdValue;
        _isLoading = false;
        _statusMessage = '✅ Transação pendente iniciada!\nAguardando interação do usuário...';
      });

      _showMessage('Transação pendente iniciada!\nSessionId: ${pendingTransaction.sessionIdValue}');

      // Verificar se precisa de interação do usuário
      final response = pendingTransaction.originalResponse;
      if (response.command != null && response.shouldContinue) {
        _showInteractionDialog(response);
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = 'Erro na transação pendente: $e';
      });
      _showMessage('Erro: $e');
    }
  }

  void _showInteractionDialog(TransactionResponse response) {
    String title = 'Interação Necessária';
    String message = 'A transação requer sua interação.';
    String? userInput;

    switch (response.command) {
      case 21: // Menu
        title = 'Selecione uma Opção';
        message = response.buffer ?? 'Escolha uma opção:';
        break;
      case 20: // Confirmação
        title = 'Confirmação';
        message = response.buffer ?? 'Confirma a operação?';
        break;
      default:
        title = 'Entrada Necessária';
        message = response.buffer ?? 'Digite os dados solicitados:';
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message),
            if (response.command == 21) ...[
              const SizedBox(height: 16),
              const Text('1: Pix\n2: Pix Troco'),
            ],
          ],
        ),
        actions: [
          if (response.command == 20) ...[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _continueTransaction('0'); // Não
              },
              child: const Text('Não'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _continueTransaction('1'); // Sim
              },
              child: const Text('Sim'),
            ),
          ] else if (response.command == 21) ...[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _continueTransaction('1'); // Pix
              },
              child: const Text('Pix'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _continueTransaction('2'); // Pix Troco
              },
              child: const Text('Pix Troco'),
            ),
          ] else ...[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _continueTransaction(userInput ?? '');
              },
              child: const Text('OK'),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _continueTransaction(String data) async {
    if (_pendingTransaction == null) return;

    setState(() {
      _isLoading = true;
      _statusMessage = 'Processando interação do usuário...';
    });

    try {
      final response = _pendingTransaction!.originalResponse;
      final result = await _pendingTransaction!.continueWithData(
        command: response.command!,
        data: data,
      );

      if (result.isServiceSuccess) {
        if (result.shouldContinue) {
          // Ainda precisa de mais interação
          setState(() {
            _isLoading = false;
            _statusMessage = 'Aguardando mais interação...';
          });
          _showInteractionDialog(result);
        } else {
          // Transação concluída, pronta para confirmação
          setState(() {
            _isLoading = false;
            _statusMessage = '✅ Transação processada com sucesso!\nPronta para confirmação.';
          });
          _showMessage('Transação processada! Agora você pode confirmar.');
        }
      } else {
        setState(() {
          _isLoading = false;
          _statusMessage = '❌ Erro ao processar: ${result.errorMessage}';
        });
        _showMessage('Erro: ${result.errorMessage}');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = 'Erro ao processar: $e';
      });
      _showMessage('Erro: $e');
    }
  }

  Future<void> _confirmTransaction() async {
    if (_pendingTransaction == null) {
      _showMessage('Nenhuma transação pendente para confirmar');
      return;
    }

    if (_pendingTransaction!.isFinalized) {
      _showMessage('Transação já foi finalizada');
      return;
    }

    setState(() {
      _isLoading = true;
      _statusMessage = 'Confirmando transação...';
    });

    try {
      final result = await _pendingTransaction!.confirm(
        taxInvoiceNumber: _cupomFiscalController.text,
        taxInvoiceDate: '20180611',
        taxInvoiceTime: '170000',
      );

      setState(() {
        _isLoading = false;
        if (result.isServiceSuccess) {
          _statusMessage = '✅ Transação confirmada com sucesso!\nStatus: ${result.clisitefStatus}';
        } else {
          _statusMessage = '❌ Erro ao confirmar: ${result.errorMessage}';
        }
      });

      if (result.isServiceSuccess) {
        _showMessage('Transação confirmada com sucesso!');
      } else {
        _showMessage('Erro ao confirmar: ${result.errorMessage}');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = 'Erro ao confirmar: $e';
      });
      _showMessage('Erro: $e');
    }
  }

  Future<void> _cancelTransaction() async {
    if (_pendingTransaction == null) {
      _showMessage('Nenhuma transação pendente para cancelar');
      return;
    }

    if (_pendingTransaction!.isFinalized) {
      _showMessage('Transação já foi finalizada');
      return;
    }

    setState(() {
      _isLoading = true;
      _statusMessage = 'Cancelando transação...';
    });

    try {
      final result = await _pendingTransaction!.cancel(
        taxInvoiceNumber: _cupomFiscalController.text,
        taxInvoiceDate: '20180611',
        taxInvoiceTime: '170000',
      );

      setState(() {
        _isLoading = false;
        if (result.isServiceSuccess) {
          _statusMessage = '✅ Transação cancelada com sucesso!\nStatus: ${result.clisitefStatus}';
        } else {
          _statusMessage = '❌ Erro ao cancelar: ${result.errorMessage}';
        }
      });

      if (result.isServiceSuccess) {
        _showMessage('Transação cancelada com sucesso!');
      } else {
        _showMessage('Erro ao cancelar: ${result.errorMessage}');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = 'Erro ao cancelar: $e';
      });
      _showMessage('Erro: $e');
    }
  }

  Future<void> _simulateCupomEmission() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Simulando emissão de cupom fiscal...';
    });

    // Simula tempo de emissão do cupom
    await Future.delayed(const Duration(seconds: 2));

    setState(() {
      _isLoading = false;
      _statusMessage = '✅ Cupom fiscal emitido com sucesso!\nAgora você pode confirmar a transação.';
    });

    _showMessage('Cupom fiscal emitido! Agora você pode confirmar a transação.');
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transações Pendentes'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Status do Serviço',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text('Status: $_statusMessage'),
                    if (_sessionId.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text('SessionId: $_sessionId'),
                    ],
                    if (_pendingTransaction != null) ...[
                      const SizedBox(height: 4),
                      Text('Transação Finalizada: ${_pendingTransaction!.isFinalized ? "Sim" : "Não"}'),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Campos Mapeados do CliSiTef
            if (_pendingTransaction != null) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Campos Mapeados do CliSiTef',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      if (_pendingTransaction!.fields.nsuTef.isNotEmpty) Text('NSU TEF: ${_pendingTransaction!.fields.nsuTef}'),
                      if (_pendingTransaction!.fields.nsuHost.isNotEmpty) Text('NSU Host: ${_pendingTransaction!.fields.nsuHost}'),
                      if (_pendingTransaction!.fields.codigoAutorizacao.isNotEmpty)
                        Text('Código Autorização: ${_pendingTransaction!.fields.codigoAutorizacao}'),
                      if (_pendingTransaction!.fields.instituicao.isNotEmpty) Text('Instituição: ${_pendingTransaction!.fields.instituicao}'),
                      if (_pendingTransaction!.fields.codigoBandeiraPadrao.isNotEmpty)
                        Text('Bandeira: ${_pendingTransaction!.fields.codigoBandeiraPadrao}'),
                      if (_pendingTransaction!.fields.valorPagamento > 0)
                        Text('Valor: R\$ ${_pendingTransaction!.fields.valorPagamento.toStringAsFixed(2)}'),
                      if (_pendingTransaction!.fields.dataHoraTransacao.isNotEmpty)
                        Text('Data/Hora: ${_pendingTransaction!.fields.dataHoraTransacao}'),
                      if (_pendingTransaction!.fields.viaCliente.isNotEmpty) Text('Via Cliente: ${_pendingTransaction!.fields.viaCliente}'),
                      if (_pendingTransaction!.fields.viaEstabelecimento.isNotEmpty)
                        Text('Via Estabelecimento: ${_pendingTransaction!.fields.viaEstabelecimento}'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Configurações
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Configurações',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _serverIPController,
                            decoration: const InputDecoration(
                              labelText: 'IP do Servidor',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _storeIdController,
                            decoration: const InputDecoration(
                              labelText: 'ID da Loja',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _terminalIdController,
                      decoration: const InputDecoration(
                        labelText: 'ID do Terminal',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Dados da Transação
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Dados da Transação',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _selectedTransactionType,
                            decoration: const InputDecoration(
                              labelText: 'Tipo',
                              border: OutlineInputBorder(),
                            ),
                            items: const [
                              DropdownMenuItem(value: 'PIX', child: Text('PIX')),
                              DropdownMenuItem(value: 'CREDITO', child: Text('Crédito')),
                              DropdownMenuItem(value: 'DEBITO', child: Text('Débito')),
                            ],
                            onChanged: (value) {
                              setState(() {
                                _selectedTransactionType = value!;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _amountController,
                            decoration: const InputDecoration(
                              labelText: 'Valor (R\$)',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _cupomFiscalController,
                            decoration: const InputDecoration(
                              labelText: 'Cupom Fiscal',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _operatorController,
                            decoration: const InputDecoration(
                              labelText: 'Operador',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Botões de Ação
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Ações',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),

                    // Iniciar Transação Pendente
                    ElevatedButton.icon(
                      onPressed: _isLoading ? null : _startPendingTransaction,
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('1. Iniciar Transação Pendente'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.all(16),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Simular Emissão de Cupom
                    ElevatedButton.icon(
                      onPressed: _pendingTransaction == null || _isLoading ? null : _simulateCupomEmission,
                      icon: const Icon(Icons.receipt),
                      label: const Text('2. Simular Emissão de Cupom'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.all(16),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Confirmar Transação
                    ElevatedButton.icon(
                      onPressed: _pendingTransaction == null || _pendingTransaction!.isFinalized || _isLoading ? null : _confirmTransaction,
                      icon: const Icon(Icons.check_circle),
                      label: const Text('3. Confirmar Transação'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.all(16),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Cancelar Transação
                    ElevatedButton.icon(
                      onPressed: _pendingTransaction == null || _pendingTransaction!.isFinalized || _isLoading ? null : _cancelTransaction,
                      icon: const Icon(Icons.cancel),
                      label: const Text('4. Cancelar Transação'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.all(16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Instruções
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Como Usar',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '1. Configure os dados do servidor\n'
                      '2. Preencha os dados da transação\n'
                      '3. Clique em "Iniciar Transação Pendente"\n'
                      '4. Simule a emissão do cupom fiscal\n'
                      '5. Confirme ou cancele a transação',
                    ),
                  ],
                ),
              ),
            ),

            if (_isLoading) ...[
              const SizedBox(height: 16),
              const Center(
                child: CircularProgressIndicator(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
