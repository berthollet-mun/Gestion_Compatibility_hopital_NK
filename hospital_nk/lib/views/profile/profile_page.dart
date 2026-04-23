import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/theme_controller.dart';
import '../../core/utils/helpers.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthController>();
    final theme = Get.find<ThemeController>();

    return Scaffold(
      appBar: AppBar(title: const Text('Mon Profil')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Avatar card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(children: [
                CircleAvatar(
                  radius: 42,
                  backgroundColor: AppHelpers.getRoleColor(auth.userRoleSlug)
                      .withOpacity(0.15),
                  child: Text(
                    auth.currentUser.value?.initials ?? 'U',
                    style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w600,
                        color: AppHelpers.getRoleColor(auth.userRoleSlug)),
                  ),
                ),
                const SizedBox(height: 12),
                Text(auth.userName,
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppHelpers.getRoleColor(auth.userRoleSlug)
                        .withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    AppHelpers.getRoleDisplayName(auth.userRoleSlug),
                    style: TextStyle(
                        fontSize: 13,
                        color: AppHelpers.getRoleColor(auth.userRoleSlug),
                        fontWeight: FontWeight.w500),
                  ),
                ),
                const SizedBox(height: 4),
                Text(auth.currentUser.value?.email ?? '',
                    style: TextStyle(fontSize: 13, color: Colors.grey[500])),
              ]),
            ),
          ),
          const SizedBox(height: 16),

          // Settings
          Card(
            child: Column(children: [
              Obx(() => SwitchListTile(
                    title: const Text('Mode sombre'),
                    subtitle: const Text('Changer l\'apparence'),
                    secondary: const Icon(Icons.dark_mode),
                    value: theme.isDarkMode,
                    onChanged: (_) => theme.toggleTheme(),
                  )),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.lock_outline),
                title: const Text('Changer le mot de passe'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _changePasswordDialog(auth),
              ),
            ]),
          ),
          const SizedBox(height: 16),

          // Info
          Card(
            child: Column(children: [
              _infoTile(Icons.badge, 'Matricule',
                  auth.currentUser.value?.matricule ?? '-'),
              const Divider(height: 1),
              _infoTile(Icons.phone, 'Téléphone',
                  auth.currentUser.value?.telephone ?? '-'),
              const Divider(height: 1),
              _infoTile(
                  Icons.access_time,
                  'Dernière connexion',
                  AppHelpers.formatDateRelative(
                      auth.currentUser.value?.derniereConnexion)),
            ]),
          ),
          const SizedBox(height: 24),

          // Logout
          SizedBox(
            height: 52,
            child: OutlinedButton.icon(
              onPressed: auth.logout,
              icon: const Icon(Icons.logout, color: Colors.red),
              label: const Text('Se déconnecter',
                  style: TextStyle(color: Colors.red, fontSize: 15)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.red),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Center(
              child: Text('Version 1.0.0',
                  style: TextStyle(fontSize: 12, color: Colors.grey[400]))),
        ],
      ),
    );
  }

  Widget _infoTile(IconData icon, String label, String value) {
    return ListTile(
      leading: Icon(icon, color: Colors.grey[500]),
      title:
          Text(label, style: TextStyle(fontSize: 13, color: Colors.grey[500])),
      trailing: Text(value,
          style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
    );
  }

  void _changePasswordDialog(AuthController auth) {
    final currentCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    Get.dialog(AlertDialog(
      title: const Text('Changer le mot de passe'),
      content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(
            controller: currentCtrl,
            obscureText: true,
            decoration:
                const InputDecoration(labelText: 'Mot de passe actuel')),
        const SizedBox(height: 8),
        TextField(
            controller: newCtrl,
            obscureText: true,
            decoration:
                const InputDecoration(labelText: 'Nouveau mot de passe')),
        const SizedBox(height: 8),
        TextField(
            controller: confirmCtrl,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Confirmer')),
      ])),
      actions: [
        TextButton(onPressed: () => Get.back(), child: const Text('Annuler')),
        ElevatedButton(
            onPressed: () async {
              if (newCtrl.text.length >= 8 &&
                  newCtrl.text == confirmCtrl.text) {
                await auth.changePassword(
                    currentCtrl.text, newCtrl.text, confirmCtrl.text);
                Get.back();
              } else {
                AppHelpers.showError('Vérifiez les champs');
              }
            },
            child: const Text('Confirmer')),
      ],
    ));
  }
}
