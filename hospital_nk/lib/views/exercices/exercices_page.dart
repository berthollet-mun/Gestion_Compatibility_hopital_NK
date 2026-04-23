import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/exercice_controller.dart';
import '../../app/themes/app_theme.dart';
import '../../core/utils/helpers.dart';
import '../shared/widgets/loading_widget.dart';

class ExercicesPage extends StatelessWidget {
  const ExercicesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ExerciceController>();

    return Scaffold(
      appBar: AppBar(title: const Text('Exercices Fiscaux')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateDialog(context, controller),
        icon: const Icon(Icons.add),
        label: const Text('Nouveau'),
      ),
      body: Obx(() {
        if (controller.isLoading.value) return const LoadingWidget();
        if (controller.exercices.isEmpty) {
          return const EmptyWidget(message: 'Aucun exercice trouvé', icon: Icons.calendar_today);
        }
        return RefreshIndicator(
          onRefresh: controller.loadExercices,
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: controller.exercices.length,
            itemBuilder: (context, index) {
              final ex = controller.exercices[index];
              final isCurrent = controller.currentExercice.value?.id == ex.id;
              return Card(
                shape: isCurrent
                    ? RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: const BorderSide(color: AppTheme.primaryColor, width: 2),
                      )
                    : null,
                child: ListTile(
                  leading: Container(
                    width: 48, height: 48,
                    decoration: BoxDecoration(
                      color: isCurrent ? AppTheme.primaryColor.withOpacity(0.1) : Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.calendar_today,
                      color: isCurrent ? AppTheme.primaryColor : Colors.grey,
                    ),
                  ),
                  title: Text('Exercice ${ex.annee}', style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppHelpers.getStatutColor(ex.statut).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          ex.statut,
                          style: TextStyle(fontSize: 11, color: AppHelpers.getStatutColor(ex.statut), fontWeight: FontWeight.w500),
                        ),
                      ),
                      if (isCurrent) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text('Actuel', style: TextStyle(fontSize: 11, color: AppTheme.primaryColor, fontWeight: FontWeight.w500)),
                        ),
                      ],
                    ],
                  ),
                  trailing: ex.statut == 'OUVERT'
                      ? PopupMenuButton<String>(
                          onSelected: (val) {
                            if (val == 'cloturer') controller.cloturerExercice(ex.id);
                            if (val == 'select') controller.selectExercice(ex);
                          },
                          itemBuilder: (_) => [
                            if (!isCurrent) const PopupMenuItem(value: 'select', child: Text('Sélectionner')),
                            const PopupMenuItem(value: 'cloturer', child: Text('Clôturer', style: TextStyle(color: Colors.orange))),
                          ],
                        )
                      : null,
                ),
              );
            },
          ),
        );
      }),
    );
  }

  void _showCreateDialog(BuildContext context, ExerciceController controller) {
    final anneeCtrl = TextEditingController(text: '${DateTime.now().year}');
    Get.dialog(
      AlertDialog(
        title: const Text('Nouvel exercice'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: anneeCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Année'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () async {
              final success = await controller.createExercice({'annee': int.tryParse(anneeCtrl.text) ?? DateTime.now().year});
              if (success) Get.back();
            },
            child: const Text('Créer'),
          ),
        ],
      ),
    );
  }
}
