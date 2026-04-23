import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/caisse_controller.dart';
import '../../core/utils/validators.dart';
import '../../app/themes/app_theme.dart';

class CaisseTransactionPage extends StatefulWidget {
  const CaisseTransactionPage({super.key});

  @override
  State<CaisseTransactionPage> createState() => _CaisseTransactionPageState();
}

class _CaisseTransactionPageState extends State<CaisseTransactionPage> {
  final _formKey = GlobalKey<FormState>();
  final _montantCtrl = TextEditingController();
  final _motifCtrl = TextEditingController();
  final _beneficiaireCtrl = TextEditingController();
  String _type = 'ENTREE';

  @override
  void dispose() {
    _montantCtrl.dispose();
    _motifCtrl.dispose();
    _beneficiaireCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = Get.find<CaisseController>();

    return Scaffold(
      appBar: AppBar(title: const Text('Nouvelle Transaction')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            // Type
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Type de transaction', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(child: _typeButton('ENTREE', Icons.arrow_downward, AppTheme.successColor)),
                    const SizedBox(width: 12),
                    Expanded(child: _typeButton('SORTIE', Icons.arrow_upward, AppTheme.errorColor)),
                  ]),
                ]),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Détails', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _montantCtrl,
                    keyboardType: TextInputType.number,
                    validator: AppValidators.montant,
                    decoration: const InputDecoration(labelText: 'Montant *', prefixIcon: Icon(Icons.attach_money), suffixText: 'CDF'),
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _motifCtrl,
                    validator: (v) => AppValidators.required(v, fieldName: 'Le motif'),
                    decoration: const InputDecoration(labelText: 'Motif *', prefixIcon: Icon(Icons.description)),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _beneficiaireCtrl,
                    decoration: const InputDecoration(labelText: 'Bénéficiaire', prefixIcon: Icon(Icons.person_outline)),
                  ),
                ]),
              ),
            ),
            const SizedBox(height: 24),
            Obx(() => SizedBox(
              height: 52,
              child: ElevatedButton.icon(
                onPressed: c.isSubmitting.value ? null : _submit,
                icon: c.isSubmitting.value
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Icon(_type == 'ENTREE' ? Icons.arrow_downward : Icons.arrow_upward),
                label: Text(c.isSubmitting.value ? 'Enregistrement...' : 'Enregistrer'),
                style: ElevatedButton.styleFrom(backgroundColor: _type == 'ENTREE' ? AppTheme.successColor : AppTheme.errorColor),
              ),
            )),
          ]),
        ),
      ),
    );
  }

  Widget _typeButton(String type, IconData icon, Color color) {
    final selected = _type == type;
    return InkWell(
      onTap: () => setState(() => _type = type),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: selected ? color.withOpacity(0.1) : Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? color : Colors.grey[300]!, width: selected ? 2 : 1),
        ),
        child: Column(children: [
          Icon(icon, color: selected ? color : Colors.grey, size: 28),
          const SizedBox(height: 4),
          Text(type, style: TextStyle(fontWeight: FontWeight.w600, color: selected ? color : Colors.grey, fontSize: 13)),
        ]),
      ),
    );
  }

  void _submit() async {
    if (_formKey.currentState?.validate() ?? false) {
      final c = Get.find<CaisseController>();
      final success = await c.enregistrerTransaction({
        'type': _type,
        'montant': double.tryParse(_montantCtrl.text) ?? 0,
        'motif': _motifCtrl.text,
        'beneficiaire': _beneficiaireCtrl.text,
      });
      if (success) Get.back();
    }
  }
}
