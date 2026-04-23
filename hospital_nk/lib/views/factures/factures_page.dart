import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/facture_controller.dart';
import '../../app/themes/app_theme.dart';
import '../../core/utils/helpers.dart';
import '../shared/widgets/loading_widget.dart';

class FacturesPage extends StatelessWidget {
  const FacturesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.find<FactureController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Factures'),
        actions: [
          IconButton(icon: const Icon(Icons.search), onPressed: () {
            final ctrl = TextEditingController(text: c.searchQuery.value);
            Get.dialog(AlertDialog(
              title: const Text('Rechercher'),
              content: TextField(controller: ctrl, autofocus: true, onSubmitted: (v) { c.search(v); Get.back(); }),
              actions: [
                TextButton(onPressed: () { c.search(''); Get.back(); }, child: const Text('Effacer')),
                ElevatedButton(onPressed: () { c.search(ctrl.text); Get.back(); }, child: const Text('Chercher')),
              ],
            ));
          }),
        ],
      ),
      body: Column(children: [
        Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Obx(() => ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _chip('Toutes', '', c.typeFilter.value, (v) => c.typeFilter.value = v ?? '', c),
              _chip('Ventes', 'VENTE', c.typeFilter.value, (v) { c.typeFilter.value = v ?? ''; c.loadFactures(reset: true); }, c),
              _chip('Achats', 'ACHAT', c.typeFilter.value, (v) { c.typeFilter.value = v ?? ''; c.loadFactures(reset: true); }, c),
            ],
          )),
        ),
        Expanded(
          child: Obx(() {
            if (c.isLoading.value) return const LoadingWidget();
            if (c.factures.isEmpty) return const EmptyWidget(message: 'Aucune facture', icon: Icons.receipt_long);
            return RefreshIndicator(
              onRefresh: () => c.loadFactures(reset: true),
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: c.factures.length,
                itemBuilder: (ctx, i) {
                  final f = c.factures[i];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: f.type == 'VENTE' ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(f.type, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: f.type == 'VENTE' ? Colors.green : Colors.orange)),
                          ),
                          const SizedBox(width: 8),
                          Expanded(child: Text(f.numero, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14))),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(color: AppHelpers.getStatutColor(f.statut).withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                            child: Text(f.statut, style: TextStyle(fontSize: 10, color: AppHelpers.getStatutColor(f.statut), fontWeight: FontWeight.w500)),
                          ),
                        ]),
                        const SizedBox(height: 8),
                        Text(f.tiersNom ?? '-', style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                        const SizedBox(height: 6),
                        Row(children: [
                          Text(AppHelpers.formatDate(f.dateFacture), style: TextStyle(fontSize: 12, color: Colors.grey[400])),
                          const Spacer(),
                          Text(AppHelpers.formatMontant(f.montantTotal), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppTheme.primaryColor)),
                        ]),
                      ]),
                    ),
                  );
                },
              ),
            );
          }),
        ),
      ]),
    );
  }

  Widget _chip(String label, String val, String current, Function(String?) fn, FactureController c) {
    final selected = current == val;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: FilterChip(
        label: Text(label, style: TextStyle(fontSize: 12, color: selected ? Colors.white : null)),
        selected: selected,
        onSelected: (_) => fn(val.isEmpty ? null : val),
        selectedColor: AppTheme.primaryColor,
        checkmarkColor: Colors.white,
      ),
    );
  }
}
