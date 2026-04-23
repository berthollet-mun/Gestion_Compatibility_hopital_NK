import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/auth_controller.dart';
import '../../../app/routes/app_routes.dart';
import '../../../app/themes/app_theme.dart';
import '../../../core/utils/helpers.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthController>();

    return Drawer(
      child: Column(
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 20,
              bottom: 20,
              left: 20,
              right: 20,
            ),
            decoration: const BoxDecoration(gradient: AppTheme.primaryGradient),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: Colors.white.withOpacity(0.2),
                  child: Text(
                    auth.currentUser.value?.initials ?? 'U',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  auth.userName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    AppHelpers.getRoleDisplayName(auth.userRoleSlug),
                    style: const TextStyle(fontSize: 11, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),

          // Menu items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                _buildMenuItem(
                  icon: Icons.dashboard_rounded,
                  title: 'Tableau de bord',
                  route: AppRoutes.dashboard,
                ),
                if (auth.canManageUsers) ...[
                  const _SectionTitle('Administration'),
                  _buildMenuItem(
                    icon: Icons.people_outline,
                    title: 'Utilisateurs',
                    route: AppRoutes.users,
                  ),
                  _buildMenuItem(
                    icon: Icons.badge_outlined,
                    title: 'Rôles',
                    route: AppRoutes.roles,
                  ),
                ],
                if (auth.canManageExercices) ...[
                  _buildMenuItem(
                    icon: Icons.calendar_today,
                    title: 'Exercices fiscaux',
                    route: AppRoutes.exercices,
                  ),
                  _buildMenuItem(
                    icon: Icons.business,
                    title: 'Services',
                    route: AppRoutes.services,
                  ),
                ],

                const _SectionTitle('Comptabilité'),
                if (auth.canManagePlanComptable || auth.isAuditeur) ...[
                  _buildMenuItem(
                    icon: Icons.account_tree,
                    title: 'Plan comptable',
                    route: AppRoutes.planComptable,
                  ),
                ],
                if (auth.canManageJournaux) ...[
                  _buildMenuItem(
                    icon: Icons.menu_book,
                    title: 'Journaux',
                    route: AppRoutes.journaux,
                  ),
                ],
                if (auth.canSaisirEcritures || auth.isAuditeur) ...[
                  _buildMenuItem(
                    icon: Icons.edit_note,
                    title: 'Écritures',
                    route: AppRoutes.ecritures,
                  ),
                ],
                if (auth.canViewFactures) ...[
                  _buildMenuItem(
                    icon: Icons.receipt_long,
                    title: 'Factures',
                    route: AppRoutes.factures,
                  ),
                ],

                if (auth.canManageBudget || auth.isAuditeur) ...[
                  const _SectionTitle('Finance'),
                  _buildMenuItem(
                    icon: Icons.pie_chart_outline,
                    title: 'Budgets',
                    route: AppRoutes.budgets,
                  ),
                ],
                if (auth.canViewCaisse) ...[
                  _buildMenuItem(
                    icon: Icons.point_of_sale,
                    title: 'Caisse',
                    route: AppRoutes.caisseSessions,
                  ),
                ],

                if (auth.canViewBulletinsPaie) ...[
                  const _SectionTitle('RH & Paie'),
                  _buildMenuItem(
                    icon: Icons.groups_outlined,
                    title: 'Employés',
                    route: AppRoutes.employes,
                  ),
                  _buildMenuItem(
                    icon: Icons.payments_outlined,
                    title: 'Salaires',
                    route: AppRoutes.salaires,
                  ),
                ],

                if (auth.canViewStock) ...[
                  const _SectionTitle('Logistique'),
                  _buildMenuItem(
                    icon: Icons.inventory_2_outlined,
                    title: 'Stock',
                    route: AppRoutes.stockProduits,
                  ),
                ],

                if (auth.canViewRapports) ...[
                  const _SectionTitle('Rapports'),
                  _buildMenuItem(
                    icon: Icons.analytics_outlined,
                    title: 'Rapports',
                    route: AppRoutes.rapportDashboard,
                  ),
                ],
              ],
            ),
          ),

          // Footer
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: const Text('Mon profil'),
            dense: true,
            onTap: () {
              Get.back();
              Get.toNamed(AppRoutes.profile);
            },
          ),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Déconnexion', style: TextStyle(color: Colors.red)),
            dense: true,
            onTap: () {
              Get.back();
              auth.logout();
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required String route,
    int? badge,
  }) {
    final isActive = Get.currentRoute == route;
    return ListTile(
      leading: Icon(
        icon,
        color: isActive ? AppTheme.primaryColor : Colors.grey[600],
        size: 22,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
          color: isActive ? AppTheme.primaryColor : null,
        ),
      ),
      trailing: badge != null && badge > 0
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.errorColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text('$badge', style: const TextStyle(color: Colors.white, fontSize: 11)),
            )
          : null,
      selected: isActive,
      selectedTileColor: AppTheme.primaryColor.withOpacity(0.08),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
      dense: true,
      onTap: () {
        Get.back();
        if (!isActive) Get.toNamed(route);
      },
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Colors.grey[400],
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}
