import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/users_controller.dart';
import '../../core/utils/validators.dart';

class UserCreatePage extends StatefulWidget {
  const UserCreatePage({super.key});

  @override
  State<UserCreatePage> createState() => _UserCreatePageState();
}

class _UserCreatePageState extends State<UserCreatePage> {
  final _formKey = GlobalKey<FormState>();
  final _nomCtrl = TextEditingController();
  final _prenomCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _matriculeCtrl = TextEditingController();
  final _telephoneCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  int? _selectedRoleId;
  int? _selectedServiceId;

  @override
  void dispose() {
    _nomCtrl.dispose();
    _prenomCtrl.dispose();
    _emailCtrl.dispose();
    _matriculeCtrl.dispose();
    _telephoneCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<UsersController>();

    return Scaffold(
      appBar: AppBar(title: const Text('Nouvel Utilisateur')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Informations personnelles',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _matriculeCtrl,
                        validator: (v) =>
                            AppValidators.required(v, fieldName: 'Matricule'),
                        decoration: const InputDecoration(
                            labelText: 'Matricule *',
                            prefixIcon: Icon(Icons.badge)),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _prenomCtrl,
                              validator: (v) => AppValidators.required(v,
                                  fieldName: 'Prénom'),
                              decoration:
                                  const InputDecoration(labelText: 'Prénom *'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _nomCtrl,
                              validator: (v) =>
                                  AppValidators.required(v, fieldName: 'Nom'),
                              decoration:
                                  const InputDecoration(labelText: 'Nom *'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        validator: AppValidators.email,
                        decoration: const InputDecoration(
                            labelText: 'Email *',
                            prefixIcon: Icon(Icons.email_outlined)),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _telephoneCtrl,
                        keyboardType: TextInputType.phone,
                        validator: AppValidators.telephone,
                        decoration: const InputDecoration(
                            labelText: 'Téléphone',
                            prefixIcon: Icon(Icons.phone_outlined)),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Rôle & Service',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 16),
                      Obx(() => DropdownButtonFormField<int>(
                            initialValue: _selectedRoleId,
                            decoration: const InputDecoration(
                                labelText: 'Rôle *',
                                prefixIcon: Icon(Icons.admin_panel_settings)),
                            validator: (v) =>
                                v == null ? 'Sélectionnez un rôle' : null,
                            items: controller.roles
                                .map((r) => DropdownMenuItem(
                                    value: r.id, child: Text(r.nom)))
                                .toList(),
                            onChanged: (v) =>
                                setState(() => _selectedRoleId = v),
                          )),
                      const SizedBox(height: 12),
                      Obx(() => DropdownButtonFormField<int>(
                            initialValue: _selectedServiceId,
                            decoration: const InputDecoration(
                                labelText: 'Service',
                                prefixIcon: Icon(Icons.business)),
                            items: controller.services
                                .map((s) => DropdownMenuItem(
                                    value: s.id, child: Text(s.nom)))
                                .toList(),
                            onChanged: (v) =>
                                setState(() => _selectedServiceId = v),
                          )),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Mot de passe',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _passwordCtrl,
                        obscureText: true,
                        validator: AppValidators.password,
                        decoration: const InputDecoration(
                            labelText: 'Mot de passe *',
                            prefixIcon: Icon(Icons.lock_outline)),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Obx(() => SizedBox(
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: controller.isSubmitting.value ? null : _submit,
                      icon: controller.isSubmitting.value
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.save),
                      label: Text(controller.isSubmitting.value
                          ? 'Création...'
                          : 'Créer l\'utilisateur'),
                    ),
                  )),
            ],
          ),
        ),
      ),
    );
  }

  void _submit() async {
    if (_formKey.currentState?.validate() ?? false) {
      final controller = Get.find<UsersController>();
      final success = await controller.createUser({
        'matricule': _matriculeCtrl.text,
        'nom': _nomCtrl.text,
        'prenom': _prenomCtrl.text,
        'email': _emailCtrl.text,
        'telephone': _telephoneCtrl.text,
        'role_id': _selectedRoleId,
        'service_id': _selectedServiceId,
        'password': _passwordCtrl.text,
      });
      if (success) Get.back();
    }
  }
}
