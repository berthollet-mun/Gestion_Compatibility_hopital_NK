import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/dashboard_controller.dart';
import '../../app/routes/app_routes.dart';
import '../../app/themes/app_theme.dart';
import '../../core/utils/helpers.dart';
import '../shared/widgets/app_drawer.dart';
import '../shared/widgets/kpi_card.dart';
import '../shared/widgets/loading_widget.dart';
import '../shared/widgets/error_widget.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthController>();
    final dashboard = Get.find<DashboardController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tableau de Bord'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: dashboard.refresh,
          ),
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () => Get.toNamed(AppRoutes.profile),
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: Obx(() {
        if (dashboard.isLoading.value) {
          return const LoadingWidget(
              message: 'Chargement du tableau de bord...');
        }
        if (dashboard.hasError.value) {
          return AppErrorWidget(
            message: dashboard.errorMessage.value,
            onRetry: dashboard.refresh,
          );
        }

        return RefreshIndicator(
          onRefresh: dashboard.refresh,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Welcome
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bonjour, ${auth.userName} 👋',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      AppHelpers.getRoleDisplayName(auth.userRoleSlug),
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.85),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // KPI Cards Grid
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.5,
                children: [
                  KpiCard(
                    title: 'Recettes',
                    value: AppHelpers.formatMontantCompact(
                        dashboard.totalRecettes.value),
                    icon: Icons.trending_up,
                    color: AppTheme.successColor,
                  ),
                  KpiCard(
                    title: 'Dépenses',
                    value: AppHelpers.formatMontantCompact(
                        dashboard.totalDepenses.value),
                    icon: Icons.trending_down,
                    color: AppTheme.errorColor,
                  ),
                  KpiCard(
                    title: 'Résultat Net',
                    value: AppHelpers.formatMontantCompact(
                        dashboard.resultatNet.value),
                    icon: Icons.account_balance_wallet,
                    color: AppTheme.primaryColor,
                  ),
                  KpiCard(
                    title: 'Exéc. Budget',
                    value:
                        '${dashboard.tauxExecutionBudget.value.toStringAsFixed(1)}%',
                    icon: Icons.pie_chart,
                    color: AppTheme.warningColor,
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Quick info cards
              if (auth.canManageCaisse || auth.isAdmin) ...[
                _buildInfoCard(
                  'Solde Caisse',
                  AppHelpers.formatMontant(dashboard.soldeCaisse.value),
                  Icons.point_of_sale,
                  AppTheme.secondaryColor,
                ),
                const SizedBox(height: 8),
              ],

              if (auth.canValiderEcritures || auth.isAdmin) ...[
                _buildInfoCard(
                  'Écritures en attente',
                  '${dashboard.nbEcrituresEnAttente.value}',
                  Icons.pending_actions,
                  dashboard.nbEcrituresEnAttente.value > 0
                      ? AppTheme.warningColor
                      : AppTheme.successColor,
                  onTap: () => Get.toNamed(AppRoutes.ecritures),
                ),
                const SizedBox(height: 8),
              ],

              // Alertes
              if (dashboard.alertes.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Text(
                  'Alertes',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                ...dashboard.alertes.map((alerte) => Card(
                      child: ListTile(
                        leading: const Icon(
                          Icons.warning_amber_rounded,
                          color: AppTheme.warningColor,
                        ),
                        title: Text(
                          alerte['message'] ?? '',
                          style: const TextStyle(fontSize: 13),
                        ),
                        dense: true,
                      ),
                    )),
              ],
            ],
          ),
        );
      }),
    );
  }

  Widget _buildInfoCard(String title, String value, IconData icon, Color color,
      {VoidCallback? onTap}) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style:
                            TextStyle(fontSize: 13, color: Colors.grey[600])),
                    const SizedBox(height: 2),
                    Text(value,
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              if (onTap != null)
                const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
