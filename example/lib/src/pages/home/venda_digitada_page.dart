// import 'package:example/src/compontens/field_actions_widget.dart';
// import 'package:flutter/material.dart';

// class VendaDigitadaPage extends StatefulWidget {
//   final TabController tabController;
//   const VendaDigitadaPage({
//     super.key,
//     required this.tabController,
//   });

//   @override
//   State<VendaDigitadaPage> createState() => _VendaDigitadaPageState();
// }

// class _VendaDigitadaPageState extends State<VendaDigitadaPage> {
//   String magneticoDigitado = '';
//   String numeroCartao = '';
//   String vencimento = '';
//   String codigoSeguranca = '';
//   String avista = '';

//   String currentMessage = '';
//   bool isWaitingForInput = false;
//   int currentFieldId = 0;

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
//                   if (currentMessage.isNotEmpty)
//                     Column(
//                       mainAxisSize: MainAxisSize.min,
//                       children: [
//                         Text(currentMessage),
//                         const SizedBox(height: 12),
//                       ],
//                     ),
//                   if (isWaitingForInput)
//                     const Column(
//                       mainAxisSize: MainAxisSize.min,
//                       children: [
//                         Text('Aguardando entrada do usuário...'),
//                         SizedBox(height: 12),
//                       ],
//                     ),
//                   const Text('Status da Transação'),
//                   const SizedBox(height: 12),
//                   FilledButton(
//                     onPressed: () {
//                       widget.tabController.animateTo(0);
//                     },
//                     child: const Text('Voltar para Configuração'),
//                   ),
//                 ],
//               ),
//             ),
//             Expanded(
//               child: Column(
//                 children: [
//                   Text(
//                     currentMessage.isNotEmpty ? currentMessage.toUpperCase() : 'Aguardando transação...',
//                     style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
//                   ),
//                   const SizedBox(height: 20),
//                   if (isWaitingForInput) ...[
//                     FieldActionsWidget(
//                       label: 'Magnetico: 1 | Digitado: 2',
//                       onContinue: () {
//                         _continueTransaction(magneticoDigitado);
//                       },
//                       onCancel: () {
//                         _cancelTransaction();
//                       },
//                       onChange: (value) {
//                         magneticoDigitado = value;
//                       },
//                     ),
//                     FieldActionsWidget(
//                       label: 'Forneça o número do cartão',
//                       onContinue: () {
//                         _continueTransaction(numeroCartao);
//                       },
//                       onCancel: () {
//                         _cancelTransaction();
//                       },
//                       onChange: (value) {
//                         numeroCartao = value;
//                       },
//                     ),
//                     FieldActionsWidget(
//                       label: 'Vencimento (MMAA)',
//                       onContinue: () {
//                         _continueTransaction(vencimento);
//                       },
//                       onCancel: () {
//                         _cancelTransaction();
//                       },
//                       onChange: (value) {
//                         vencimento = value;
//                       },
//                     ),
//                     FieldActionsWidget(
//                       label: 'Código de segurança (3 Dígitos)',
//                       onContinue: () {
//                         _continueTransaction(codigoSeguranca);
//                       },
//                       onCancel: () {
//                         _cancelTransaction();
//                       },
//                       onChange: (value) {
//                         codigoSeguranca = value;
//                       },
//                     ),
//                     FieldActionsWidget(
//                       label: '1. A vista',
//                       onContinue: () {
//                         _continueTransaction(avista);
//                       },
//                       onCancel: () {
//                         _cancelTransaction();
//                       },
//                       onChange: (value) {
//                         avista = value;
//                       },
//                     ),
//                   ],
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   void _continueTransaction(String data) {
//     setState(() {
//       isWaitingForInput = false;
//       currentMessage = 'Processando...';
//     });

//     // TODO: Implementar continuação da transação
//     // AgenteClisitef.core.continueInteractiveFunction(
//     //   data: data,
//     //   continueValue: 0,
//     // );
//   }

//   void _cancelTransaction() {
//     setState(() {
//       isWaitingForInput = false;
//       currentMessage = 'Transação cancelada';
//     });

//     // TODO: Implementar cancelamento da transação
//     // AgenteClisitef.core.finishInteractiveFunction(
//     //   confirmTransaction: false,
//     // );
//   }
// }
