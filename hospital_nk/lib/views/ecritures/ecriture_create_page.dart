import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/ecriture_controller.dart';
import '../../core/utils/validators.dart';
import '../../app/themes/app_theme.dart';

class EcritureCreatePage extends StatefulWidget {
  const EcritureCreatePage({super.key});

  @override
  State<EcritureCreatePage> createState() => _EcritureCreatePageState();
}

class _EcritureCreatePageState extends State<EcritureCreatePage> {
  final _formKey = GlobalKey<FormState>();
  final _libelleCtrl = TextEditingController();
  final _dateCtrl = TextEditingController();
  int? _journalId;

  final List<Map<String, dynamic>> _lignes = [
    {
      'compte_id': null,
      'debit': TextEditingController(),
      'credit': TextEditingController()
    },
    {
      'compte_id': null,
      'debit': TextEditingController(),
      'credit': TextEditingController()
    },
  ];

  @override
  void initState() {
    super.initState();
    _dateCtrl.text = DateTime.now().toString().split(' ')[0];
  }

  @override
  void dispose() {
    _libelleCtrl.dispose();
    _dateCtrl.dispose();
    for (final l in _lignes) {
      (l['debit'] as TextEditingController).dispose();
      (l['credit'] as TextEditingController).dispose();
    }
    super.dispose();
  }

  double get _totalDebit => _lignes.fold(
      0.0,
      (s, l) =>
          s +
          (double.tryParse((l['debit'] as TextEditingController).text) ?? 0));
  double get _totalCredit => _lignes.fold(
      0.0,
      (s, l) =>
          s +
          (double.tryParse((l['credit'] as TextEditingController).text) ?? 0));
  bool get _isEquilibree =>
      _totalDebit > 0 && (_totalDebit - _totalCredit).abs() < 0.01;

  @override
  Widget build(BuildContext context) {
    final c = Get.find<EcritureController>();

    return Scaffold(
      appBar: AppBar(title: const Text('Nouvelle Écriture')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Header
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Informations',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 12),
                    Obx(() => DropdownButtonFormField<int>(
                          initialValue: _journalId,
                          decoration: const InputDecoration(
                              labelText: 'Journal *',
                              prefixIcon: Icon(Icons.menu_book)),
                          validator: (v) =>
                              v == null ? 'Sélectionnez un journal' : null,
                          items: c.journaux
                              .map((j) => DropdownMenuItem(
                                  value: j.id,
                                  child: Text('${j.code} - ${j.nom}')))
                              .toList(),
                          onChanged: (v) => setState(() => _journalId = v),
                        )),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _dateCtrl,
                      validator: (v) =>
                          AppValidators.date(v, fieldName: 'La date'),
                      decoration: const InputDecoration(
                          labelText: 'Date *',
                          prefixIcon: Icon(Icons.calendar_today)),
                      onTap: () async {
                        final d = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2030));
                        if (d != null) {
                          _dateCtrl.text = d.toString().split(' ')[0];
                        }
                      },
                      readOnly: true,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _libelleCtrl,
                      validator: (v) =>
                          AppValidators.required(v, fieldName: 'Le libellé'),
                      decoration: const InputDecoration(
                          labelText: 'Libellé *',
                          prefixIcon: Icon(Icons.description)),
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Lignes
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text('Lignes comptables',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w600)),
                        const Spacer(),
                        TextButton.icon(
                          onPressed: () => setState(() => _lignes.add({
                                'compte_id': null,
                                'debit': TextEditingController(),
                                'credit': TextEditingController(),
                              })),
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Ajouter',
                              style: TextStyle(fontSize: 13)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    for (int i = 0; i < _lignes.length; i++) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.grey[200]!),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Text('Ligne ${i + 1}',
                                    style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.grey[600])),
                                const Spacer(),
                                if (_lignes.length > 2)
                                  InkWell(
                                    onTap: () =>
                                        setState(() => _lignes.removeAt(i)),
                                    child: Icon(Icons.close,
                                        size: 18, color: Colors.red[300]),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Obx(() => DropdownButtonFormField<int>(
                                  initialValue: _lignes[i]['compte_id'],
                                  decoration: const InputDecoration(
                                      labelText: 'Compte', isDense: true),
                                  items: c.comptes
                                      .map((cp) => DropdownMenuItem(
                                          value: cp.id,
                                          child: Text(
                                              '${cp.code} ${cp.libelle}',
                                              overflow: TextOverflow.ellipsis)))
                                      .toList(),
                                  onChanged: (v) => setState(
                                      () => _lignes[i]['compte_id'] = v),
                                  isExpanded: true,
                                )),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _lignes[i]['debit'],
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(
                                        labelText: 'Débit', isDense: true),
                                    onChanged: (_) => setState(() {}),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: TextField(
                                    controller: _lignes[i]['credit'],
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(
                                        labelText: 'Crédit', isDense: true),
                                    onChanged: (_) => setState(() {}),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],

                    // Totaux
                    const Divider(),
                    Row(
                      children: [
                        const Text('Total Débit:',
                            style: TextStyle(fontWeight: FontWeight.w500)),
                        const Spacer(),
                        Text(_totalDebit.toStringAsFixed(2),
                            style:
                                const TextStyle(fontWeight: FontWeight.w600)),
                      ],
                    ),
                    Row(
                      children: [
                        const Text('Total Crédit:',
                            style: TextStyle(fontWeight: FontWeight.w500)),
                        const Spacer(),
                        Text(_totalCredit.toStringAsFixed(2),
                            style:
                                const TextStyle(fontWeight: FontWeight.w600)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Text('Écart:',
                            style: TextStyle(fontWeight: FontWeight.w500)),
                        const Spacer(),
                        Text(
                          (_totalDebit - _totalCredit).toStringAsFixed(2),
                          style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: _isEquilibree
                                  ? AppTheme.successColor
                                  : AppTheme.errorColor),
                        ),
                      ],
                    ),
                    if (!_isEquilibree && _totalDebit > 0)
                      const Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: Text('⚠️ L\'écriture n\'est pas équilibrée',
                            style: TextStyle(
                                fontSize: 12, color: AppTheme.warningColor)),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            Obx(() => SizedBox(
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed:
                        c.isSubmitting.value || !_isEquilibree ? null : _submit,
                    icon: c.isSubmitting.value
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.save),
                    label: Text(c.isSubmitting.value
                        ? 'Enregistrement...'
                        : 'Enregistrer l\'écriture'),
                  ),
                )),
          ],
        ),
      ),
    );
  }

  void _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final c = Get.find<EcritureController>();
    final lignes = _lignes
        .where((l) => l['compte_id'] != null)
        .map((l) => {
              'compte_id': l['compte_id'],
              'debit':
                  double.tryParse((l['debit'] as TextEditingController).text) ??
                      0,
              'credit': double.tryParse(
                      (l['credit'] as TextEditingController).text) ??
                  0,
            })
        .toList();

    final success = await c.createEcriture({
      'journal_id': _journalId,
      'date_ecriture': _dateCtrl.text,
      'libelle': _libelleCtrl.text,
      'lignes': lignes,
    });
    if (success) Get.back();
  }
}
