import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/ecriture_controller.dart';
import '../../app/routes/app_routes.dart';
import '../../app/themes/app_theme.dart';
import '../../core/utils/helpers.dart';
import '../shared/widgets/loading_widget.dart';

class EcrituresPage extends StatelessWidget {
  const EcrituresPage({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.find<EcritureController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Écritures Comptables'),
        actions: [
          IconButton(icon: const Icon(Icons.search), onPressed: () => _showSearch(c)),
          IconButton(icon: const Icon(Icons.filter_list), onPressed: () => _showFilters(c)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Get.toNamed(AppRoutes.ecritureCreate),
        icon: const Icon(Icons.add),
        label: const Text('Saisir'),
      ),
      body: Column(
        children: [
          // Statut filter chips
          Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Obx(() => ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _chip('Tous', '', c.statutFilter.value, c),
                _chip('Brouillon', 'BROUILLON', c.statutFilter.value, c),
                _chip('Soumis', 'SOUMIS', c.statutFilter.value, c),
                _chip('Validé', 'VALIDE', c.statutFilter.value, c),
                _chip('Rejeté', 'REJETE', c.statutFilter.value, c),
              ],
            )),
          ),
          Expanded(
            child: Obx(() {
              if (c.isLoading.value) return const LoadingWidget();
              if (c.ecritures.isEmpty) return const EmptyWidget(message: 'Aucune écriture', icon: Icons.edit_note);
              return RefreshIndicator(
                onRefresh: () => c.loadEcritures(reset: true),
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: c.ecritures.length,
                  itemBuilder: (ctx, i) {
                    final e = c.ecritures[i];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: InkWell(
                        onTap: () => Get.toNamed(AppRoutes.ecritureDetail, arguments: e.id),
                        borderRadius: BorderRadius.circular(16),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(e.reference, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: AppHelpers.getStatutColor(e.statut).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      e.statut,
                                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: AppHelpers.getStatutColor(e.statut)),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(e.libelle, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(Icons.calendar_today, size: 14, color: Colors.grey[400]),
                                  const SizedBox(width: 4),
                                  Text(AppHelpers.formatDate(e.dateEcriture), style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                                  const Spacer(),
                                  Text(
                                    AppHelpers.formatMontant(e.montantTotal),
                                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppTheme.primaryColor),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, String val, String current, EcritureController c) {
    final selected = current == val;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: FilterChip(
        label: Text(label, style: TextStyle(fontSize: 12, color: selected ? Colors.white : null)),
        selected: selected,
        onSelected: (_) => c.filterByStatut(val.isEmpty ? null : val),
        selectedColor: AppTheme.primaryColor,
        checkmarkColor: Colors.white,
      ),
    );
  }

  void _showSearch(EcritureController c) {
    final ctrl = TextEditingController(text: c.searchQuery.value);
    Get.dialog(AlertDialog(
      title: const Text('Rechercher'),
      content: TextField(controller: ctrl, autofocus: true, decoration: const InputDecoration(hintText: 'Référence, libellé...'), onSubmitted: (v) { c.search(v); Get.back(); }),
      actions: [
        TextButton(onPressed: () { c.search(''); Get.back(); }, child: const Text('Effacer')),
        ElevatedButton(onPressed: () { c.search(ctrl.text); Get.back(); }, child: const Text('Chercher')),
      ],
    ));
  }

  void _showFilters(EcritureController c) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Filtrer par journal', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            Obx(() => Wrap(
              spacing: 8,
              children: [
                ChoiceChip(label: const Text('Tous'), selected: c.journalFilter.value == 0, onSelected: (_) { c.filterByJournal(null); Get.back(); }),
                ...c.journaux.map((j) => ChoiceChip(
                  label: Text(j.code),
                  selected: c.journalFilter.value == j.id,
                  onSelected: (_) { c.filterByJournal(j.id); Get.back(); },
                )),
              ],
            )),
          ],
        ),
      ),
    );
  }
}
