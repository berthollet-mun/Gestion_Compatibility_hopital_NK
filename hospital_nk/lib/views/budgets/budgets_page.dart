import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/budget_controller.dart';
import '../../app/themes/app_theme.dart';
import '../../core/utils/helpers.dart';
import '../shared/widgets/loading_widget.dart';

class BudgetsPage extends StatelessWidget {
  const BudgetsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.find<BudgetController>();

    return Scaffold(
      appBar: AppBar(title: const Text('Budgets')),
      body: Obx(() {
        if (c.isLoading.value) return const LoadingWidget();
        if (c.budgets.isEmpty) return const EmptyWidget(message: 'Aucun budget', icon: Icons.pie_chart_outline);
        return RefreshIndicator(
          onRefresh: () => c.loadBudgets(reset: true),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: c.budgets.length,
            itemBuilder: (ctx, i) {
              final b = c.budgets[i];
              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Container(
                        width: 44, height: 44,
                        decoration: BoxDecoration(color: AppTheme.primaryColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                        child: const Icon(Icons.pie_chart, color: AppTheme.primaryColor, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(b.libelle, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                        Text('Service: ${b.service?['nom'] ?? '-'}', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                      ])),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(color: AppHelpers.getStatutColor(b.statut).withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                        child: Text(b.statut, style: TextStyle(fontSize: 11, color: AppHelpers.getStatutColor(b.statut), fontWeight: FontWeight.w500)),
                      ),
                    ]),
                    const SizedBox(height: 12),
                    Row(children: [
                      _kpi('Prévu', AppHelpers.formatMontantCompact(b.montantTotal), Colors.blue),
                      _kpi('Réalisé', AppHelpers.formatMontantCompact(b.montantRealise ?? 0), Colors.green),
                      _kpi('Taux', '${(b.tauxExecution ?? 0).toStringAsFixed(1)}%', b.tauxExecution != null && b.tauxExecution! > 100 ? Colors.red : Colors.orange),
                    ]),
                    if (b.statut == 'SOUMIS') ...[
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => c.approuverBudget(b.id),
                          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.successColor),
                          child: const Text('Approuver'),
                        ),
                      ),
                    ],
                  ]),
                ),
              );
            },
          ),
        );
      }),
    );
  }

  Widget _kpi(String label, String value, Color color) {
    return Expanded(child: Column(children: [
      Text(value, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: color)),
      Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[500])),
    ]));
  }
}
