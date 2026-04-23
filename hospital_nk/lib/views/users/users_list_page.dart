import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/users_controller.dart';
import '../../app/routes/app_routes.dart';
import '../../app/themes/app_theme.dart';
import '../../core/utils/helpers.dart';
import '../shared/widgets/loading_widget.dart';

class UsersListPage extends StatelessWidget {
  const UsersListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<UsersController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Utilisateurs'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => _showSearchDialog(context, controller),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Get.toNamed(AppRoutes.userCreate),
        icon: const Icon(Icons.person_add),
        label: const Text('Nouveau'),
      ),
      body: Column(
        children: [
          // Filters
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Obx(() => SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('Tous', '', controller.selectedStatut.value, (v) => controller.filterByStatut(v)),
                  const SizedBox(width: 8),
                  _buildFilterChip('Actifs', 'ACTIF', controller.selectedStatut.value, (v) => controller.filterByStatut(v)),
                  const SizedBox(width: 8),
                  _buildFilterChip('Inactifs', 'INACTIF', controller.selectedStatut.value, (v) => controller.filterByStatut(v)),
                  const SizedBox(width: 8),
                  _buildFilterChip('Suspendus', 'SUSPENDU', controller.selectedStatut.value, (v) => controller.filterByStatut(v)),
                ],
              ),
            )),
          ),
          // Count
          Obx(() => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                Text(
                  '${controller.totalItems.value} utilisateur(s)',
                  style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                ),
                const Spacer(),
                Text(
                  'Page ${controller.currentPage.value}/${controller.totalPages.value}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                ),
              ],
            ),
          )),
          // List
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) return const LoadingWidget();
              if (controller.users.isEmpty) {
                return const EmptyWidget(
                  message: 'Aucun utilisateur trouvé',
                  icon: Icons.people_outline,
                );
              }
              return RefreshIndicator(
                onRefresh: () => controller.loadUsers(reset: true),
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: controller.users.length,
                  itemBuilder: (context, index) {
                    final user = controller.users[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppHelpers.getRoleColor(user.role.slug).withOpacity(0.15),
                          child: Text(
                            user.initials,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: AppHelpers.getRoleColor(user.role.slug),
                              fontSize: 14,
                            ),
                          ),
                        ),
                        title: Text(
                          user.fullName,
                          style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(user.email, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppHelpers.getRoleColor(user.role.slug).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    AppHelpers.getRoleDisplayName(user.role.slug),
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: AppHelpers.getRoleColor(user.role.slug),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  width: 8, height: 8,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppHelpers.getStatutColor(user.statut),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(user.statut, style: TextStyle(fontSize: 10, color: Colors.grey[500])),
                              ],
                            ),
                          ],
                        ),
                        trailing: PopupMenuButton<String>(
                          onSelected: (val) => _handleUserAction(val, user, controller),
                          itemBuilder: (_) => [
                            const PopupMenuItem(value: 'edit', child: Text('Modifier')),
                            const PopupMenuItem(value: 'reset', child: Text('Réinitialiser MDP')),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Text('Supprimer', style: TextStyle(color: Colors.red)),
                            ),
                          ],
                        ),
                        isThreeLine: true,
                      ),
                    );
                  },
                ),
              );
            }),
          ),
          // Pagination
          Obx(() => controller.totalPages.value > 1
              ? Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        onPressed: controller.currentPage.value > 1 ? controller.prevPage : null,
                        icon: const Icon(Icons.chevron_left),
                      ),
                      Text('${controller.currentPage.value} / ${controller.totalPages.value}'),
                      IconButton(
                        onPressed: controller.currentPage.value < controller.totalPages.value
                            ? controller.nextPage : null,
                        icon: const Icon(Icons.chevron_right),
                      ),
                    ],
                  ),
                )
              : const SizedBox.shrink()),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, String current, Function(String?) onTap) {
    final selected = current == value;
    return FilterChip(
      label: Text(label, style: TextStyle(fontSize: 12, color: selected ? Colors.white : null)),
      selected: selected,
      onSelected: (_) => onTap(value.isEmpty ? null : value),
      selectedColor: AppTheme.primaryColor,
      checkmarkColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 4),
    );
  }

  void _handleUserAction(String action, dynamic user, UsersController controller) {
    switch (action) {
      case 'edit':
        Get.toNamed(AppRoutes.userEdit, arguments: user);
        break;
      case 'reset':
        _showResetPasswordDialog(user.id, controller);
        break;
      case 'delete':
        controller.deleteUser(user.id);
        break;
    }
  }

  void _showSearchDialog(BuildContext context, UsersController controller) {
    final searchCtrl = TextEditingController(text: controller.searchQuery.value);
    Get.dialog(
      AlertDialog(
        title: const Text('Rechercher'),
        content: TextField(
          controller: searchCtrl,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Nom, email, matricule...'),
          onSubmitted: (val) {
            controller.search(val);
            Get.back();
          },
        ),
        actions: [
          TextButton(onPressed: () { controller.search(''); Get.back(); }, child: const Text('Effacer')),
          ElevatedButton(onPressed: () { controller.search(searchCtrl.text); Get.back(); }, child: const Text('Chercher')),
        ],
      ),
    );
  }

  void _showResetPasswordDialog(int userId, UsersController controller) {
    final pwdCtrl = TextEditingController();
    Get.dialog(
      AlertDialog(
        title: const Text('Réinitialiser mot de passe'),
        content: TextField(controller: pwdCtrl, obscureText: true, decoration: const InputDecoration(labelText: 'Nouveau mot de passe')),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () async {
              if (pwdCtrl.text.length >= 8) {
                await controller.resetPassword(userId, pwdCtrl.text);
                Get.back();
              }
            },
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );
  }
}
