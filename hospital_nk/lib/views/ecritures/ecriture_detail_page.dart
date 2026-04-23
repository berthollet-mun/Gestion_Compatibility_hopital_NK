import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/ecriture_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../app/themes/app_theme.dart';
import '../../core/utils/helpers.dart';
import '../shared/widgets/loading_widget.dart';

class EcritureDetailPage extends StatelessWidget {
  const EcritureDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.find<EcritureController>();
    final auth = Get.find<AuthController>();
    final ecritureId = Get.arguments as int?;
    if (ecritureId != null) c.loadEcriture(ecritureId);

    return Scaffold(
      appBar: AppBar(title: const Text('Détail Écriture')),
      body: Obx(() {
        if (c.isLoading.value) return const LoadingWidget();
        final e = c.selectedEcriture.value;
        if (e == null) return const Center(child: Text('Écriture non trouvée'));

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildHeader(e),
            const SizedBox(height: 12),
            _buildLignes(e),
            const SizedBox(height: 16),
            _buildActions(e, c, auth),
          ],
        );
      }),
    );
  }

  Widget _buildHeader(dynamic e) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text(e.reference, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600))),
            _statutBadge(e.statut),
          ]),
          const SizedBox(height: 12),
          Text(e.libelle, style: TextStyle(fontSize: 14, color: Colors.grey[700])),
          const SizedBox(height: 12),
          _row(Icons.calendar_today, 'Date', AppHelpers.formatDate(e.dateEcriture)),
          _row(Icons.menu_book, 'Journal', e.journal?.nom ?? '-'),
          _row(Icons.attach_money, 'Montant', AppHelpers.formatMontant(e.montantTotal)),
        ]),
      ),
    );
  }

  Widget _buildLignes(dynamic e) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Lignes comptables', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          if (e.lignes != null)
            ...e.lignes!.map<Widget>((l) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(8)),
              child: Row(children: [
                Expanded(child: Text('${l.compte?.code ?? ''} - ${l.compte?.libelle ?? ''}', style: const TextStyle(fontSize: 12))),
                if (l.debit > 0) Text('D: ${AppHelpers.formatMontant(l.debit)}', style: const TextStyle(fontSize: 12, color: Colors.blue)),
                if (l.credit > 0) Text('C: ${AppHelpers.formatMontant(l.credit)}', style: const TextStyle(fontSize: 12, color: Colors.green)),
              ]),
            )),
        ]),
      ),
    );
  }

  Widget _buildActions(dynamic e, EcritureController c, AuthController auth) {
    if (e.statut == 'BROUILLON') {
      return ElevatedButton.icon(
        onPressed: () => c.soumettreEcriture(e.id),
        icon: const Icon(Icons.send),
        label: const Text('Soumettre'),
        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.warningColor, minimumSize: const Size.fromHeight(48)),
      );
    }
    if (e.statut == 'SOUMIS' && auth.canValiderEcritures) {
      return Row(children: [
        Expanded(child: ElevatedButton.icon(
          onPressed: () => c.validerEcriture(e.id),
          icon: const Icon(Icons.check),
          label: const Text('Valider'),
          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.successColor, minimumSize: const Size.fromHeight(48)),
        )),
        const SizedBox(width: 12),
        Expanded(child: OutlinedButton.icon(
          onPressed: () => _rejectDialog(c, e.id),
          icon: const Icon(Icons.close, color: Colors.red),
          label: const Text('Rejeter', style: TextStyle(color: Colors.red)),
          style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.red), minimumSize: const Size.fromHeight(48)),
        )),
      ]);
    }
    return const SizedBox.shrink();
  }

  Widget _statutBadge(String statut) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: AppHelpers.getStatutColor(statut).withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
      child: Text(statut, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppHelpers.getStatutColor(statut))),
    );
  }

  Widget _row(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(children: [
        Icon(icon, size: 16, color: Colors.grey[400]),
        const SizedBox(width: 8),
        Text('$label: ', style: TextStyle(fontSize: 13, color: Colors.grey[500])),
        Expanded(child: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500))),
      ]),
    );
  }

  void _rejectDialog(EcritureController c, int id) {
    final ctrl = TextEditingController();
    Get.dialog(AlertDialog(
      title: const Text('Rejeter'),
      content: TextField(controller: ctrl, maxLines: 3, decoration: const InputDecoration(labelText: 'Motif *')),
      actions: [
        TextButton(onPressed: () => Get.back(), child: const Text('Annuler')),
        ElevatedButton(
          onPressed: () { if (ctrl.text.isNotEmpty) { c.rejeterEcriture(id, commentaire: ctrl.text); Get.back(); } },
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          child: const Text('Rejeter'),
        ),
      ],
    ));
  }
}
