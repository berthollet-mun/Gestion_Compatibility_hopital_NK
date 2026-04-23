import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/employe_controller.dart';
import '../../app/themes/app_theme.dart';
import '../../core/utils/helpers.dart';
import '../shared/widgets/loading_widget.dart';

class EmployesPage extends StatelessWidget {
  const EmployesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.find<EmployeController>();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Employés & Paie'),
          bottom: const TabBar(
            indicatorColor: Colors.white,
            tabs: [Tab(text: 'Employés'), Tab(text: 'Bulletins')],
          ),
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
        body: TabBarView(children: [
          // Tab Employés
          Obx(() {
            if (c.isLoading.value) return const LoadingWidget();
            if (c.employes.isEmpty) return const EmptyWidget(message: 'Aucun employé', icon: Icons.groups);
            return RefreshIndicator(
              onRefresh: () => c.loadEmployes(reset: true),
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: c.employes.length,
                itemBuilder: (ctx, i) {
                  final emp = c.employes[i];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                        child: Text(
                          '${emp.prenom.isNotEmpty ? emp.prenom[0] : ''}${emp.nom.isNotEmpty ? emp.nom[0] : ''}',
                          style: const TextStyle(fontWeight: FontWeight.w600, color: AppTheme.primaryColor),
                        ),
                      ),
                      title: Text(emp.fullName, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
                      subtitle: Text('${emp.poste ?? '-'} • ${emp.serviceNom}', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                      trailing: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: [
                        Text(AppHelpers.formatMontantCompact(emp.salaireBase), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                        Container(
                          width: 8, height: 8,
                          decoration: BoxDecoration(shape: BoxShape.circle, color: AppHelpers.getStatutColor(emp.statut)),
                        ),
                      ]),
                    ),
                  );
                },
              ),
            );
          }),
          // Tab Bulletins
          Obx(() {
            if (c.bulletins.isEmpty && !c.isLoading.value) {
              c.loadBulletins();
              return const LoadingWidget();
            }
            if (c.isLoading.value) return const LoadingWidget();
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: c.bulletins.length,
              itemBuilder: (ctx, i) {
                final b = c.bulletins[i];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: Container(
                      width: 44, height: 44,
                      decoration: BoxDecoration(color: AppTheme.secondaryColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                      child: const Icon(Icons.receipt, color: AppTheme.secondaryColor, size: 22),
                    ),
                    title: Text(b.employeNom, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
                    subtitle: Text('Période: ${b.periode}', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                    trailing: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: [
                      Text(AppHelpers.formatMontantCompact(b.salaireNet), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppTheme.successColor)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(color: AppHelpers.getStatutColor(b.statut).withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                        child: Text(b.statut, style: TextStyle(fontSize: 10, color: AppHelpers.getStatutColor(b.statut))),
                      ),
                    ]),
                  ),
                );
              },
            );
          }),
        ]),
      ),
    );
  }
}
