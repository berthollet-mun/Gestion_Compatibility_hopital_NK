import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/plan_comptable_controller.dart';
import '../../app/themes/app_theme.dart';
import '../shared/widgets/loading_widget.dart';

class PlanComptablePage extends StatelessWidget {
  const PlanComptablePage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<PlanComptableController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Plan Comptable'),
        actions: [
          IconButton(icon: const Icon(Icons.search), onPressed: () => _showSearch(controller)),
          IconButton(icon: const Icon(Icons.account_tree), onPressed: controller.loadArborescence),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateDialog(context, controller),
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          // Classe filter
          Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Obx(() => ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _classChip('Tous', 0, controller),
                for (int i = 1; i <= 8; i++) _classChip('Classe $i', i, controller),
              ],
            )),
          ),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) return const LoadingWidget();
              if (controller.comptes.isEmpty) return const EmptyWidget(message: 'Aucun compte trouvé');
              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: controller.comptes.length,
                itemBuilder: (context, i) {
                  final c = controller.comptes[i];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 6),
                    child: ListTile(
                      leading: Container(
                        width: 48, height: 48,
                        decoration: BoxDecoration(
                          color: _classeColor(c.classe).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(child: Text(
                          '${c.classe}',
                          style: TextStyle(fontWeight: FontWeight.w700, color: _classeColor(c.classe), fontSize: 18),
                        )),
                      ),
                      title: Text(c.code, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      subtitle: Text(c.libelle, style: const TextStyle(fontSize: 12)),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(c.type, style: TextStyle(fontSize: 10, color: Colors.grey[500])),
                          Text(c.sensNormal, style: TextStyle(fontSize: 10, color: Colors.grey[400])),
                        ],
                      ),
                      dense: true,
                    ),
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _classChip(String label, int val, PlanComptableController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Obx(() {
        final selected = controller.classeFilter.value == val;
        return FilterChip(
          label: Text(label, style: TextStyle(fontSize: 12, color: selected ? Colors.white : null)),
          selected: selected,
          onSelected: (_) => controller.filterByClasse(val == 0 ? null : val),
          selectedColor: AppTheme.primaryColor,
          checkmarkColor: Colors.white,
        );
      }),
    );
  }

  Color _classeColor(int classe) {
    final colors = [Colors.blue, Colors.purple, Colors.teal, Colors.orange, Colors.green, Colors.red, Colors.indigo, Colors.brown];
    return classe >= 1 && classe <= 8 ? colors[classe - 1] : Colors.grey;
  }

  void _showSearch(PlanComptableController c) {
    final ctrl = TextEditingController(text: c.searchQuery.value);
    Get.dialog(AlertDialog(
      title: const Text('Rechercher un compte'),
      content: TextField(
        controller: ctrl, autofocus: true,
        decoration: const InputDecoration(hintText: 'Code ou libellé...'),
        onSubmitted: (v) { c.search(v); Get.back(); },
      ),
      actions: [
        TextButton(onPressed: () { c.search(''); Get.back(); }, child: const Text('Effacer')),
        ElevatedButton(onPressed: () { c.search(ctrl.text); Get.back(); }, child: const Text('Chercher')),
      ],
    ));
  }

  void _showCreateDialog(BuildContext ctx, PlanComptableController controller) {
    final codeCtrl = TextEditingController();
    final libelleCtrl = TextEditingController();
    Get.dialog(AlertDialog(
      title: const Text('Nouveau compte'),
      content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: codeCtrl, decoration: const InputDecoration(labelText: 'Code *')),
        const SizedBox(height: 12),
        TextField(controller: libelleCtrl, decoration: const InputDecoration(labelText: 'Libellé *')),
      ])),
      actions: [
        TextButton(onPressed: () => Get.back(), child: const Text('Annuler')),
        ElevatedButton(onPressed: () async {
          final success = await controller.createCompte({'code': codeCtrl.text, 'libelle': libelleCtrl.text});
          if (success) Get.back();
        }, child: const Text('Créer')),
      ],
    ));
  }
}
