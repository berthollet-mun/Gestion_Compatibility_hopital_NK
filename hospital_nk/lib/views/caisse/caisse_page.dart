import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/caisse_controller.dart';
import '../../app/routes/app_routes.dart';
import '../../app/themes/app_theme.dart';
import '../../core/utils/helpers.dart';
import '../shared/widgets/loading_widget.dart';

class CaissePage extends StatelessWidget {
  const CaissePage({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.find<CaisseController>();

    return Scaffold(
      appBar: AppBar(title: const Text('Caisse')),
      floatingActionButton: Obx(() => c.sessionActive.value == null
          ? FloatingActionButton.extended(
              onPressed: () => _openCaisseDialog(c),
              icon: const Icon(Icons.lock_open),
              label: const Text('Ouvrir'),
            )
          : FloatingActionButton.extended(
              onPressed: () => Get.toNamed(AppRoutes.caisseTransactions),
              icon: const Icon(Icons.add),
              label: const Text('Transaction'),
            )),
      body: Obx(() {
        if (c.isLoading.value) return const LoadingWidget();

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Active session card
            if (c.sessionActive.value != null) ...[
              _buildActiveSession(c),
              const SizedBox(height: 16),
            ],
            // Session history
            const Text('Historique des sessions', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            if (c.sessions.isEmpty)
              const EmptyWidget(message: 'Aucune session', icon: Icons.point_of_sale)
            else
              ...c.sessions.map((s) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      color: (s.isOuverte ? AppTheme.successColor : Colors.grey).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(s.isOuverte ? Icons.lock_open : Icons.lock, color: s.isOuverte ? AppTheme.successColor : Colors.grey, size: 20),
                  ),
                  title: Text(s.reference, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
                  subtitle: Text('${AppHelpers.formatDate(s.dateOuverture)} • ${s.nbTransactions ?? 0} trans.', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                  trailing: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Text(AppHelpers.formatMontantCompact(s.soldeOuverture), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(color: AppHelpers.getStatutColor(s.statut).withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                      child: Text(s.statut, style: TextStyle(fontSize: 10, color: AppHelpers.getStatutColor(s.statut))),
                    ),
                  ]),
                  onTap: () => c.loadRapport(s.id),
                ),
              )),
          ],
        );
      }),
    );
  }

  Widget _buildActiveSession(CaisseController c) {
    final s = c.sessionActive.value!;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(gradient: AppTheme.successGradient, borderRadius: BorderRadius.circular(16)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Row(children: [
          Icon(Icons.point_of_sale, color: Colors.white, size: 20),
          SizedBox(width: 8),
          Text('Session Active', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16)),
        ]),
        const SizedBox(height: 12),
        Text(s.reference, style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 13)),
        const SizedBox(height: 8),
        Row(children: [
          _activeStat('Ouverture', AppHelpers.formatMontantCompact(s.soldeOuverture)),
          _activeStat('Entrées', '+${AppHelpers.formatMontantCompact(s.totalEntrees ?? 0)}'),
          _activeStat('Sorties', '-${AppHelpers.formatMontantCompact(s.totalSorties ?? 0)}'),
        ]),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => _closeCaisseDialog(c, s.id),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: AppTheme.successColor),
            child: const Text('Fermer la caisse'),
          ),
        ),
      ]),
    );
  }

  Widget _activeStat(String label, String val) {
    return Expanded(child: Column(children: [
      Text(val, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
      Text(label, style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 11)),
    ]));
  }

  void _openCaisseDialog(CaisseController c) {
    final ctrl = TextEditingController();
    Get.dialog(AlertDialog(
      title: const Text('Ouvrir la caisse'),
      content: TextField(controller: ctrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Solde d\'ouverture *')),
      actions: [
        TextButton(onPressed: () => Get.back(), child: const Text('Annuler')),
        ElevatedButton(onPressed: () async {
          final montant = double.tryParse(ctrl.text) ?? 0;
          if (montant > 0) { await c.ouvrirCaisse(soldeOuverture: montant); Get.back(); }
        }, child: const Text('Ouvrir')),
      ],
    ));
  }

  void _closeCaisseDialog(CaisseController c, int id) {
    final ctrl = TextEditingController();
    Get.dialog(AlertDialog(
      title: const Text('Fermer la caisse'),
      content: TextField(controller: ctrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Solde réel *')),
      actions: [
        TextButton(onPressed: () => Get.back(), child: const Text('Annuler')),
        ElevatedButton(onPressed: () async {
          final montant = double.tryParse(ctrl.text) ?? 0;
          if (montant >= 0) { await c.fermerCaisse(id, soldeReel: montant); Get.back(); }
        }, child: const Text('Fermer')),
      ],
    ));
  }
}
