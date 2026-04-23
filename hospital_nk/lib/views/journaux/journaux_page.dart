import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/services/journal_service.dart';
import '../../data/models/journal_model.dart';
import '../../app/themes/app_theme.dart';
import '../../core/utils/helpers.dart';
import '../shared/widgets/loading_widget.dart';

class JournauxPage extends StatefulWidget {
  const JournauxPage({super.key});

  @override
  State<JournauxPage> createState() => _JournauxPageState();
}

class _JournauxPageState extends State<JournauxPage> {
  final JournalService _service = Get.find<JournalService>();
  List<JournalModel> _journaux = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final result = await _service.getJournaux();
    if (result['success'] == true) {
      _journaux = (result['data'] as List)
          .map((j) => JournalModel.fromJson(j))
          .toList();
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Journaux Comptables')),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateDialog,
        child: const Icon(Icons.add),
      ),
      body: _isLoading
          ? const LoadingWidget()
          : _journaux.isEmpty
              ? const EmptyWidget(
                  message: 'Aucun journal', icon: Icons.menu_book)
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _journaux.length,
                    itemBuilder: (context, i) {
                      final j = _journaux[i];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                                child: Text(
                              j.code,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.primaryColor,
                                  fontSize: 12),
                            )),
                          ),
                          title: Text(j.nom,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w500, fontSize: 14)),
                          subtitle: Text(
                              'Type: ${j.type} • ${j.nbEcritures ?? 0} écritures',
                              style: TextStyle(
                                  fontSize: 12, color: Colors.grey[500])),
                          trailing: Icon(
                            j.isActif ? Icons.check_circle : Icons.cancel,
                            color:
                                j.isActif ? AppTheme.successColor : Colors.grey,
                            size: 20,
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }

  void _showCreateDialog() {
    final codeCtrl = TextEditingController();
    final nomCtrl = TextEditingController();
    String type = 'ACHAT';
    Get.dialog(AlertDialog(
      title: const Text('Nouveau journal'),
      content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(
            controller: codeCtrl,
            decoration: const InputDecoration(labelText: 'Code *')),
        const SizedBox(height: 12),
        TextField(
            controller: nomCtrl,
            decoration: const InputDecoration(labelText: 'Nom *')),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          initialValue: type,
          decoration: const InputDecoration(labelText: 'Type'),
          items: ['ACHAT', 'VENTE', 'BANQUE', 'CAISSE', 'OPERATIONS_DIVERSES']
              .map((t) => DropdownMenuItem(value: t, child: Text(t)))
              .toList(),
          onChanged: (v) => type = v ?? 'ACHAT',
        ),
      ])),
      actions: [
        TextButton(onPressed: () => Get.back(), child: const Text('Annuler')),
        ElevatedButton(
            onPressed: () async {
              final result = await _service.createJournal(
                  {'code': codeCtrl.text, 'nom': nomCtrl.text, 'type': type});
              if (result['success'] == true) {
                Get.back();
                _load();
                AppHelpers.showSuccess('Journal créé');
              }
            },
            child: const Text('Créer')),
      ],
    ));
  }
}
