# Sistema de Erros CliSiTef com Enum

Este documento descreve o novo sistema de erros implementado no CliSiTef SDK, que utiliza enums para melhor organização e tratamento de códigos de erro específicos.

## 🎯 Objetivos do Sistema

### Problemas Resolvidos
- **Códigos de erro espalhados**: Agora centralizados em um enum
- **Tratamento inconsistente**: Padronização com factory methods
- **Dificuldade de manutenção**: Estrutura clara e extensível
- **Falta de tipagem**: Enum fornece type safety

### Benefícios Alcançados
- ✅ **Códigos centralizados** em um único local
- ✅ **Type safety** com enum
- ✅ **Factory methods** para criação fácil
- ✅ **Tratamento específico** para cancelamentos
- ✅ **Extensibilidade** para novos códigos
- ✅ **Documentação integrada** com descrições

## 🏗️ Arquitetura do Sistema

### 1. Enum CliSiTefErrorCode

```dart
enum CliSiTefErrorCode {
  // Códigos de cancelamento específicos
  operatorCancelled(-2, 'Operador cancelou a operação'),
  userCancelled(-6, 'Usuário cancelou a operação no pinpad'),
  automationCancelled(-15, 'Sistema cancelou automaticamente a operação'),

  // Códigos de erro gerais
  serviceNotInitialized(-1, 'Serviço não inicializado'),
  invalidConfiguration(-3, 'Configuração inválida'),
  connectionError(-4, 'Erro de conexão com o servidor'),
  timeoutError(-5, 'Timeout na operação'),
  // ... outros códigos
}
```

### 2. Exceção CliSiTefException

```dart
class CliSiTefException implements Exception {
  final CliSiTefErrorCode errorCode;
  final String message;
  final String? details;
  final dynamic originalError;

  // Factory methods para cancelamentos específicos
  factory CliSiTefException.operatorCancelled({...})
  factory CliSiTefException.userCancelled({...})
  factory CliSiTefException.automationCancelled({...})

  // Factory methods para erros gerais
  factory CliSiTefException.serviceNotInitialized({...})
  factory CliSiTefException.invalidConfiguration({...})
  factory CliSiTefException.connectionError({...})

  // Factory methods utilitários
  factory CliSiTefException.fromCode(int code, {...})
  factory CliSiTefException.fromErrorCode(CliSiTefErrorCode errorCode, {...})
}
```

## 📋 Códigos de Erro Disponíveis

### Códigos de Cancelamento Específicos

| Código | Enum | Descrição | Factory Method |
|--------|------|-----------|----------------|
| -2 | `operatorCancelled` | Operador cancelou a operação | `CliSiTefException.operatorCancelled()` |
| -6 | `userCancelled` | Usuário cancelou a operação no pinpad | `CliSiTefException.userCancelled()` |
| -15 | `automationCancelled` | Sistema cancelou automaticamente a operação | `CliSiTefException.automationCancelled()` |

### Códigos de Erro Gerais

| Código | Enum | Descrição | Factory Method |
|--------|------|-----------|----------------|
| -1 | `serviceNotInitialized` | Serviço não inicializado | `CliSiTefException.serviceNotInitialized()` |
| -3 | `invalidConfiguration` | Configuração inválida | `CliSiTefException.invalidConfiguration()` |
| -4 | `connectionError` | Erro de conexão com o servidor | `CliSiTefException.connectionError()` |
| -5 | `timeoutError` | Timeout na operação | `CliSiTefException.timeoutError()` |
| -7 | `invalidData` | Dados inválidos | `CliSiTefException.invalidData()` |
| -8 | `serverError` | Erro no servidor | `CliSiTefException.serverError()` |
| -9 | `transactionNotFound` | Transação não encontrada | `CliSiTefException.transactionNotFound()` |
| -10 | `sessionExpired` | Sessão expirada | `CliSiTefException.sessionExpired()` |
| -11 | `invalidSession` | Sessão inválida | `CliSiTefException.invalidSession()` |
| -12 | `operationNotAllowed` | Operação não permitida | `CliSiTefException.operationNotAllowed()` |
| -13 | `deviceNotAvailable` | Dispositivo não disponível | `CliSiTefException.deviceNotAvailable()` |
| -14 | `communicationError` | Erro de comunicação | `CliSiTefException.communicationError()` |
| -16 | `internalError` | Erro interno do sistema | `CliSiTefException.internalError()` |
| -99 | `unknownError` | Erro desconhecido | `CliSiTefException.fromCode(-99)` |

## 🔧 Como Usar

### 1. Criação de Exceções

#### Usando Factory Methods Específicos
```dart
// Cancelamentos
throw CliSiTefException.operatorCancelled(
  details: 'Operador pressionou cancelar durante coleta de dados',
);

throw CliSiTefException.userCancelled(
  details: 'Cliente pressionou cancelar no pinpad',
);

throw CliSiTefException.automationCancelled(
  details: 'Sistema cancelou devido a timeout',
);

// Erros gerais
throw CliSiTefException.serviceNotInitialized(
  details: 'Serviço não foi inicializado',
);

throw CliSiTefException.connectionError(
  details: 'Falha na conexão com o servidor',
);
```

#### Usando Factory Methods Utilitários
```dart
// A partir de código numérico
throw CliSiTefException.fromCode(
  -2,
  customMessage: 'Cancelamento personalizado',
  details: 'Detalhes do cancelamento',
);

// A partir de enum
throw CliSiTefException.fromErrorCode(
  CliSiTefErrorCode.userCancelled,
  customMessage: 'Cancelamento personalizado pelo usuário',
  details: 'Usuário cancelou no pinpad',
);
```

### 2. Tratamento de Exceções

#### Tratamento Básico
```dart
try {
  await service.startTransaction(data);
} catch (e) {
  if (e is CliSiTefException) {
    print('Erro: ${e.errorCode.description}');
    print('Código: ${e.errorCode.code}');
    print('Detalhes: ${e.details}');
  }
}
```

#### Tratamento Específico por Tipo
```dart
try {
  await service.startTransaction(data);
} catch (e) {
  if (e is CliSiTefException) {
    if (e.isCancellation) {
      // Tratamento específico para cancelamentos
      if (e.isOperatorCancellation) {
        print('Operador cancelou a operação');
      } else if (e.isUserCancellation) {
        print('Usuário cancelou no pinpad');
      } else if (e.isAutomationCancellation) {
        print('Sistema cancelou automaticamente');
      }
    } else {
      // Tratamento para outros tipos de erro
      switch (e.errorCode) {
        case CliSiTefErrorCode.connectionError:
          print('Erro de conexão - tentar reconectar');
          break;
        case CliSiTefErrorCode.serviceNotInitialized:
          print('Serviço não inicializado - reinicializar');
          break;
        default:
          print('Erro geral: ${e.message}');
      }
    }
  }
}
```

### 3. Verificação de Tipos de Erro

#### Verificar se é Cancelamento
```dart
// Usando propriedade da exceção
if (exception.isCancellation) {
  print('É um cancelamento');
}

// Usando método estático do enum
if (CliSiTefErrorCode.isCancellationCode(-2)) {
  print('Código -2 é de cancelamento');
}
```

#### Obter Enum a partir de Código
```dart
// Com fallback para unknownError
final errorCode = CliSiTefErrorCode.fromCode(-2);

// Sem fallback (retorna null se não encontrado)
final errorCode = CliSiTefErrorCode.tryFromCode(-2);
```

## 🚀 Integração com Serviços

### CliSiTefServiceCapturaTardia

O serviço foi atualizado para usar o novo sistema de erros:

```dart
class CliSiTefServiceCapturaTardia {
  Future<bool> initialize() async {
    try {
      // Validação
      final errors = _config.validate();
      if (errors.isNotEmpty) {
        throw CliSiTefException.invalidConfiguration(
          details: 'Erros de validação: ${errors.join(', ')}',
        );
      }

      // Criação de sessão
      final sessionResponse = await _repository.createSession();
      if (!sessionResponse.isServiceSuccess) {
        throw CliSiTefException.fromCode(
          sessionResponse.clisitefStatus,
          details: 'Erro ao criar sessão: ${sessionResponse.errorMessage}',
        );
      }

      return true;
    } catch (e) {
      if (e is CliSiTefException) {
        rethrow;
      }
      throw CliSiTefException.internalError(
        details: 'Erro ao inicializar serviço: $e',
        originalError: e,
      );
    }
  }

  Future<PendingTransaction?> startPendingTransaction(TransactionData data) async {
    try {
      if (!_isInitialized) {
        throw CliSiTefException.serviceNotInitialized(
          details: 'Serviço não foi inicializado antes de iniciar transação',
        );
      }

      final result = await useCase.execute(data);
      if (!result.isSuccess) {
        // Verificar cancelamentos específicos
        final errorCode = result.response.clisitefStatus;
        if (CliSiTefErrorCode.isCancellationCode(errorCode)) {
          throw _createCancellationException(errorCode, result.errorMessage);
        }
        
        throw CliSiTefException.fromCode(
          errorCode,
          details: result.errorMessage,
        );
      }

      return PendingTransaction(...);
    } catch (e) {
      if (e is CliSiTefException) {
        rethrow;
      }
      throw CliSiTefException.internalError(
        details: 'Erro inesperado na transação: $e',
        originalError: e,
      );
    }
  }

  CliSiTefException _createCancellationException(int code, String? message) {
    switch (code) {
      case -2:
        return CliSiTefException.operatorCancelled(
          details: message ?? 'Operador cancelou a operação',
        );
      case -6:
        return CliSiTefException.userCancelled(
          details: message ?? 'Usuário cancelou a operação no pinpad',
        );
      case -15:
        return CliSiTefException.automationCancelled(
          details: message ?? 'Sistema cancelou automaticamente a operação',
        );
      default:
        return CliSiTefException.fromCode(
          code,
          details: message ?? 'Cancelamento desconhecido',
        );
    }
  }
}
```

### CliSiTefServiceAgente

Similar ao serviço de captura tardia, mas para transações normais:

```dart
class CliSiTefServiceAgente {
  Future<TransactionResult> executeTransaction(TransactionData data) async {
    try {
      if (!_isInitialized) {
        throw CliSiTefException.serviceNotInitialized(
          details: 'Serviço não foi inicializado antes de executar transação',
        );
      }

      final result = await useCase.execute(data);
      if (!result.isSuccess) {
        // Verificar cancelamentos específicos
        final errorCode = result.response.clisitefStatus;
        if (CliSiTefErrorCode.isCancellationCode(errorCode)) {
          throw _createCancellationException(errorCode, result.errorMessage);
        }
        
        return TransactionResult.fromResponse(result.response);
      }

      return TransactionResult.fromResponse(result.response);
    } catch (e) {
      if (e is CliSiTefException) {
        rethrow;
      }
      throw CliSiTefException.internalError(
        details: 'Erro inesperado na transação: $e',
        originalError: e,
      );
    }
  }
}
```

## 📊 Exemplo Completo

Veja o arquivo `lib/src/example_error_handling.dart` para um exemplo completo de uso:

```dart
void main() async {
  ErrorHandlingExample.demonstrateErrorHandling();
  await ErrorHandlingExample.demonstrateRealUsage();
}
```

## 🎯 Benefícios do Sistema

### 1. **Type Safety**
- Enum fornece verificação de tipos em tempo de compilação
- Elimina erros de digitação em códigos de erro

### 2. **Centralização**
- Todos os códigos de erro em um local
- Fácil manutenção e atualização

### 3. **Factory Methods**
- Criação fácil de exceções específicas
- API consistente e intuitiva

### 4. **Tratamento Específico**
- Identificação fácil de cancelamentos
- Tratamento diferenciado por tipo de erro

### 5. **Extensibilidade**
- Fácil adição de novos códigos de erro
- Backward compatibility mantida

### 6. **Documentação Integrada**
- Descrições legíveis para cada código
- Auto-documentação através do enum

## 🔄 Migração

### Antes (Código Antigo)
```dart
// Códigos espalhados
if (errorCode == -2) {
  print('Operador cancelou');
} else if (errorCode == -6) {
  print('Usuário cancelou');
}

// Exceções genéricas
throw Exception('Erro desconhecido: $errorCode');
```

### Depois (Novo Sistema)
```dart
// Enum centralizado
if (CliSiTefErrorCode.isCancellationCode(errorCode)) {
  final error = CliSiTefErrorCode.fromCode(errorCode);
  print(error.description);
}

// Exceções tipadas
throw CliSiTefException.fromCode(errorCode, details: 'Detalhes');
```

## 📈 Próximos Passos

1. **Testes Unitários**: Criar testes para todos os tipos de erro
2. **Documentação**: Expandir exemplos de uso
3. **Integração**: Aplicar em outros serviços do SDK
4. **Monitoramento**: Adicionar logs estruturados
5. **Métricas**: Coletar estatísticas de erros

---

O novo sistema de erros proporciona uma base sólida e extensível para o tratamento de erros no CliSiTef SDK, melhorando significativamente a experiência de desenvolvimento e manutenção. 