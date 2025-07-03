// import 'package:agente_clisitef/agente_clisitef.dart';
// import 'package:flutter/material.dart';

// class VendaPinpadPage extends StatefulWidget {
//   final TabController tabController;
//   const VendaPinpadPage({
//     super.key,
//     required this.tabController,
//   });

//   @override
//   State<VendaPinpadPage> createState() => _VendaPinpadPageState();
// }

// class _VendaPinpadPageState extends State<VendaPinpadPage> {
//   String operatorMessage = '';
//   String userMessage = '';

//   @override
//   void initState() {
//     super.initState();
//     _listenToMessages();
//   }

//   void _listenToMessages() {
//     // Escuta mensagens do operador
//     AgenteClisitef.pinpad.operatorMessage.addListener(() {
//       final message = AgenteClisitef.pinpad.operatorMessage.value;
//       if (message != null) {
//         setState(() {
//           operatorMessage = message.message;
//         });
//       }
//     });

//     // Escuta mensagens do usuário
//     AgenteClisitef.pinpad.userMessage.addListener(() {
//       final message = AgenteClisitef.pinpad.userMessage.value;
//       if (message != null) {
//         setState(() {
//           userMessage = message.message;
//         });
//       }
//     });
//   }

//   @override
//   void dispose() {
//     AgenteClisitef.pinpad.operatorMessage.removeListener(() {});
//     AgenteClisitef.pinpad.userMessage.removeListener(() {});
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return SingleChildScrollView(
//       child: Padding(
//         padding: const EdgeInsets.all(20),
//         child: Row(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             SizedBox(
//               width: 300,
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 mainAxisAlignment: MainAxisAlignment.start,
//                 children: [
//                   if (operatorMessage.isNotEmpty)
//                     Column(
//                       mainAxisSize: MainAxisSize.min,
//                       children: [
//                         const Text('Mensagem para Operador:'),
//                         Text(operatorMessage),
//                         const SizedBox(height: 12),
//                       ],
//                     ),
//                   if (userMessage.isNotEmpty)
//                     Column(
//                       mainAxisSize: MainAxisSize.min,
//                       children: [
//                         const Text('Mensagem para Usuário:'),
//                         Text(userMessage),
//                         const SizedBox(height: 12),
//                       ],
//                     ),
//                   const Text('Status da Transação PinPad'),
//                   const SizedBox(height: 12),
//                   FilledButton(
//                     onPressed: () {
//                       widget.tabController.animateTo(0);
//                     },
//                     child: const Text('Voltar para Configuração'),
//                   ),
//                   const SizedBox(height: 12),
//                   FilledButton(
//                     onPressed: () async {
//                       try {
//                         final result = await AgenteClisitef.pinpad.cancelar(
//                           cupomFiscal: '123456',
//                           operador: '001',
//                         );

//                         if (mounted) {
//                           ScaffoldMessenger.of(context).showSnackBar(
//                             SnackBar(
//                               content: Text('Cancelamento: ${result.isSuccess ? "Sucesso" : "Erro"}'),
//                             ),
//                           );
//                         }
//                       } catch (e) {
//                         if (mounted) {
//                           ScaffoldMessenger.of(context).showSnackBar(
//                             SnackBar(
//                               content: Text('Erro no cancelamento: $e'),
//                               backgroundColor: Colors.red,
//                             ),
//                           );
//                         }
//                       }
//                     },
//                     child: const Text('Cancelar Transação'),
//                   ),
//                 ],
//               ),
//             ),
//             Expanded(
//               child: Column(
//                 children: [
//                   Text(
//                     userMessage.isNotEmpty ? userMessage.toUpperCase() : 'Aguardando transação PinPad...',
//                     style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
//                   ),
//                   const SizedBox(height: 20),
//                   const Text(
//                     'Transação PinPad em andamento...\n'
//                     'Aguarde as instruções no dispositivo.',
//                     textAlign: TextAlign.center,
//                     style: TextStyle(fontSize: 16),
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
