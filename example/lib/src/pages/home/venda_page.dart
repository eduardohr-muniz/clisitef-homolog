// import 'package:example/src/compontens/c_text_form_field.dart';
// import 'package:flutter/material.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:agente_clisitef/agente_clisitef.dart';

// class VendaPage extends StatefulWidget {
//   final SharedPreferences preferences;
//   final TabController tabController;
//   const VendaPage({
//     super.key,
//     required this.preferences,
//     required this.tabController,
//   });

//   @override
//   State<VendaPage> createState() => _VendaPageState();
// }

// class _VendaPageState extends State<VendaPage> {
//   String siTefIP = '127.0.0.1';
//   String storeId = '00000000';
//   String terminalId = 'XX000000';
//   String additionalParams = '';
//   double amount = 10.00;
//   String fiscalCupon = '123456';
//   String operator = '001';

//   @override
//   void initState() {
//     super.initState();
//     _loadPreferences();
//   }

//   void _loadPreferences() {
//     setState(() {
//       siTefIP = widget.preferences.getString('siTefIP') ?? '127.0.0.1';
//       storeId = widget.preferences.getString('storeId') ?? '00000000';
//       terminalId = widget.preferences.getString('terminalId') ?? 'XX000000';
//       additionalParams = widget.preferences.getString('additionalParams') ?? '';
//       amount = widget.preferences.getDouble('amount') ?? 10.00;
//       fiscalCupon = widget.preferences.getString('fiscalCupon') ?? '123456';
//       operator = widget.preferences.getString('operator') ?? '001';
//     });
//   }

//   void _savePreferences() {
//     widget.preferences.setString('siTefIP', siTefIP);
//     widget.preferences.setString('storeId', storeId);
//     widget.preferences.setString('terminalId', terminalId);
//     widget.preferences.setString('additionalParams', additionalParams);
//     widget.preferences.setDouble('amount', amount);
//     widget.preferences.setString('fiscalCupon', fiscalCupon);
//     widget.preferences.setString('operator', operator);
//   }

//   CliSiTefConfig _createConfig() {
//     final additionalParameters = <String, String>{};
//     if (additionalParams.isNotEmpty) {
//       final params = additionalParams.split(';');
//       for (final param in params) {
//         final parts = param.split('=');
//         if (parts.length == 2) {
//           additionalParameters[parts[0].trim()] = parts[1].trim();
//         }
//       }
//     }

//     return CliSiTefConfig(
//       siTefIP: siTefIP,
//       storeId: storeId,
//       terminalId: terminalId,
//       additionalParameters: additionalParameters,
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return SingleChildScrollView(
//       child: Padding(
//         padding: const EdgeInsets.all(20),
//         child: Column(
//           children: [
//             CTextFormField(
//               labelText: 'IP SiTef',
//               initialValue: siTefIP,
//               onChanged: (value) {
//                 setState(() {
//                   siTefIP = value;
//                   _savePreferences();
//                 });
//               },
//             ),
//             const SizedBox(height: 12),
//             CTextFormField(
//               labelText: 'Código da Loja',
//               initialValue: storeId,
//               onChanged: (value) {
//                 setState(() {
//                   storeId = value;
//                   _savePreferences();
//                 });
//               },
//             ),
//             const SizedBox(height: 12),
//             CTextFormField(
//               labelText: 'Código do Terminal',
//               initialValue: terminalId,
//               onChanged: (value) {
//                 setState(() {
//                   terminalId = value;
//                   _savePreferences();
//                 });
//               },
//             ),
//             const SizedBox(height: 12),
//             CTextFormField(
//               labelText: 'Parâmetros Adicionais (chave=valor;chave2=valor2)',
//               initialValue: additionalParams,
//               onChanged: (value) {
//                 setState(() {
//                   additionalParams = value;
//                   _savePreferences();
//                 });
//               },
//             ),
//             const SizedBox(height: 12),
//             CTextFormField(
//               labelText: 'Valor da Transação',
//               initialValue: amount.toString(),
//               onChanged: (value) {
//                 setState(() {
//                   amount = double.tryParse(value) ?? 0.0;
//                   _savePreferences();
//                 });
//               },
//             ),
//             const SizedBox(height: 12),
//             CTextFormField(
//               labelText: 'Cupom Fiscal',
//               initialValue: fiscalCupon,
//               onChanged: (value) {
//                 setState(() {
//                   fiscalCupon = value;
//                   _savePreferences();
//                 });
//               },
//             ),
//             const SizedBox(height: 12),
//             CTextFormField(
//               labelText: 'Operador',
//               initialValue: operator,
//               onChanged: (value) {
//                 setState(() {
//                   operator = value;
//                   _savePreferences();
//                 });
//               },
//             ),
//             const SizedBox(height: 40),
//             FilledButton(
//               onPressed: () async {
//                 try {
//                   final config = _createConfig();
//                   await AgenteClisitef.initialize(config);

//                   final result = await AgenteClisitef.pinpad.venda(
//                     valor: amount,
//                     cupomFiscal: fiscalCupon,
//                     operador: operator,
//                   );

//                   if (mounted) {
//                     final messenger = ScaffoldMessenger.of(context);
//                     messenger.showSnackBar(
//                       SnackBar(
//                         content: Text('Transação iniciada: ${result.isSuccess ? "Sucesso" : "Erro"}'),
//                       ),
//                     );
//                     widget.tabController.animateTo(2);
//                   }
//                 } catch (e) {
//                   if (mounted) {
//                     ScaffoldMessenger.of(context).showSnackBar(
//                       SnackBar(
//                         content: Text('Erro: $e'),
//                         backgroundColor: Colors.red,
//                       ),
//                     );
//                   }
//                 }
//               },
//               child: const Text('INICIAR VENDA PINPAD'),
//             ),
//             const SizedBox(height: 12),
//             FilledButton(
//               onPressed: () async {
//                 try {
//                   final config = _createConfig();
//                   await AgenteClisitef.initialize(config);

//                   final result = await AgenteClisitef.core.executeTransaction(
//                     functionCode: CliSiTefConstants.FUNCTION_DIGITAL_WALLET_SALE,
//                     amount: amount,
//                     fiscalCupon: fiscalCupon,
//                     operator: operator,
//                   );

//                   if (mounted) {
//                     final messenger = ScaffoldMessenger.of(context);
//                     messenger.showSnackBar(
//                       SnackBar(
//                         content: Text('Transação executada: ${result.isSuccess ? "Sucesso" : "Erro"}'),
//                       ),
//                     );
//                     widget.tabController.animateTo(1);
//                   }
//                 } catch (e) {
//                   if (mounted) {
//                     ScaffoldMessenger.of(context).showSnackBar(
//                       SnackBar(
//                         content: Text('Erro: $e'),
//                         backgroundColor: Colors.red,
//                       ),
//                     );
//                   }
//                 }
//               },
//               child: const Text('INICIAR VENDA CORE'),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
