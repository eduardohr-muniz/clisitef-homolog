/// SDK CliSiTef para totem de auto atendimento
/// Baseado na especificação oficial CliSiTef versão 248
library agente_clisitef;

// Core
export 'src/core/constants/clisitef_constants.dart';
export 'src/core/exceptions/clisitef_exception.dart';

// Models
export 'src/models/clisitef_config.dart';
export 'src/models/transaction_data.dart';
export 'src/models/transaction_response.dart';
export 'src/models/transaction_result.dart';

// Repositories
export 'src/repositories/clisitef_repository.dart';
export 'src/repositories/clisitef_repository_impl.dart';

// Services
export 'src/services/clisitef_core_service.dart';
export 'src/services/clisitef_pinpad_service.dart';
export 'src/services/clisitef_service_agente.dart';
