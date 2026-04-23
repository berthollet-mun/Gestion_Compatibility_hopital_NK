import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/stock_controller.dart';
import '../../app/themes/app_theme.dart';
import '../../core/utils/helpers.dart';
import '../shared/widgets/loading_widget.dart';

class StockPage extends StatelessWidget {
  const StockPage({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.find<StockController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion de Stock'),
        actions: [
          Obx(() => c.totalAlertes > 0
              ? Badge(
                  label: Text('${c.totalAlertes}'),
                  child: IconButton(
                      icon: const Icon(Icons.warning_amber), onPressed: () {}),
                )
              : const SizedBox.shrink()),
          IconButton(
              icon: const Icon(Icons.search), onPressed: () => _search(c)),
        ],
      ),
      floatingActionButton: Column(mainAxisSize: MainAxisSize.min, children: [
        FloatingActionButton.small(
          heroTag: 'mvt',
          onPressed: () => _mouvementDialog(c),
          child: const Icon(Icons.swap_vert),
        ),
        const SizedBox(height: 8),
        FloatingActionButton.extended(
          heroTag: 'add',
          onPressed: () => _createProduitDialog(c),
          icon: const Icon(Icons.add),
          label: const Text('Produit'),
        ),
      ]),
      body: Obx(() {
        if (c.isLoading.value) return const LoadingWidget();
        if (c.produits.isEmpty) {
          return const EmptyWidget(
              message: 'Aucun produit', icon: Icons.inventory_2);
        }
        return RefreshIndicator(
          onRefresh: () => c.loadProduits(reset: true),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: c.produits.length,
            itemBuilder: (ctx, i) {
              final p = c.produits[i];
              final stockColor = p.isEnRupture
                  ? AppTheme.errorColor
                  : p.isStockFaible
                      ? AppTheme.warningColor
                      : AppTheme.successColor;
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                        color: stockColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12)),
                    child: Icon(Icons.inventory_2, color: stockColor, size: 22),
                  ),
                  title: Text(p.nom,
                      style: const TextStyle(
                          fontWeight: FontWeight.w500, fontSize: 14)),
                  subtitle: Text('Code: ${p.code} • ${p.unite ?? 'unité'}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                  trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('${p.stockActuel}',
                            style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 18,
                                color: stockColor)),
                        Text(AppHelpers.formatMontant(p.prixUnitaire),
                            style: TextStyle(
                                fontSize: 11, color: Colors.grey[500])),
                      ]),
                ),
              );
            },
          ),
        );
      }),
    );
  }

  void _search(StockController c) {
    final ctrl = TextEditingController(text: c.searchQuery.value);
    Get.dialog(AlertDialog(
      title: const Text('Rechercher'),
      content: TextField(
          controller: ctrl,
          autofocus: true,
          onSubmitted: (v) {
            c.search(v);
            Get.back();
          }),
      actions: [
        TextButton(
            onPressed: () {
              c.search('');
              Get.back();
            },
            child: const Text('Effacer')),
        ElevatedButton(
            onPressed: () {
              c.search(ctrl.text);
              Get.back();
            },
            child: const Text('Chercher')),
      ],
    ));
  }

  void _createProduitDialog(StockController c) {
    final codeCtrl = TextEditingController();
    final nomCtrl = TextEditingController();
    final prixCtrl = TextEditingController();
    final stockCtrl = TextEditingController();
    Get.dialog(AlertDialog(
      title: const Text('Nouveau produit'),
      content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(
            controller: codeCtrl,
            decoration: const InputDecoration(labelText: 'Code *')),
        const SizedBox(height: 8),
        TextField(
            controller: nomCtrl,
            decoration: const InputDecoration(labelText: 'Nom *')),
        const SizedBox(height: 8),
        TextField(
            controller: prixCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Prix unitaire *')),
        const SizedBox(height: 8),
        TextField(
            controller: stockCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Stock initial')),
      ])),
      actions: [
        TextButton(onPressed: () => Get.back(), child: const Text('Annuler')),
        ElevatedButton(
            onPressed: () async {
              final s = await c.createProduit({
                'code': codeCtrl.text,
                'nom': nomCtrl.text,
                'prix_unitaire': double.tryParse(prixCtrl.text) ?? 0,
                'stock_actuel': int.tryParse(stockCtrl.text) ?? 0,
              });
              if (s) Get.back();
            },
            child: const Text('Créer')),
      ],
    ));
  }

  void _mouvementDialog(StockController c) {
    final qtyCtrl = TextEditingController();
    final motifCtrl = TextEditingController();
    int? produitId;
    String type = 'ENTREE';
    Get.dialog(StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
              title: const Text('Mouvement de stock'),
              content: SingleChildScrollView(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                Obx(() => DropdownButtonFormField<int>(
                      initialValue: produitId,
                      decoration: const InputDecoration(labelText: 'Produit *'),
                      items: c.produits
                          .map((p) =>
                              DropdownMenuItem(value: p.id, child: Text(p.nom)))
                          .toList(),
                      onChanged: (v) => setS(() => produitId = v),
                    )),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: type,
                  decoration: const InputDecoration(labelText: 'Type'),
                  items: ['ENTREE', 'SORTIE']
                      .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                      .toList(),
                  onChanged: (v) => setS(() => type = v ?? 'ENTREE'),
                ),
                const SizedBox(height: 8),
                TextField(
                    controller: qtyCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Quantité *')),
                const SizedBox(height: 8),
                TextField(
                    controller: motifCtrl,
                    decoration: const InputDecoration(labelText: 'Motif')),
              ])),
              actions: [
                TextButton(
                    onPressed: () => Get.back(), child: const Text('Annuler')),
                ElevatedButton(
                    onPressed: () async {
                      if (produitId != null) {
                        final s = await c.enregistrerMouvement({
                          'produit_id': produitId,
                          'type': type,
                          'quantite': int.tryParse(qtyCtrl.text) ?? 0,
                          'motif': motifCtrl.text,
                        });
                        if (s) Get.back();
                      }
                    },
                    child: const Text('Enregistrer')),
              ],
            )));
  }
}
