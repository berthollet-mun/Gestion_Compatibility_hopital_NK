import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class AppHelpers {
  AppHelpers._();

  // ─── SNACKBARS ──────────────────────────────────────────────────
  static void showSuccess(String message) {
    if (Get.isSnackbarOpen) Get.closeCurrentSnackbar();
    Get.snackbar(
      'Succès',
      message,
      backgroundColor: const Color(0xFF2E7D32),
      colorText: Colors.white,
      snackPosition: SnackPosition.TOP,
      duration: const Duration(seconds: 3),
      margin: const EdgeInsets.all(12),
      borderRadius: 12,
      icon: const Icon(Icons.check_circle, color: Colors.white),
    );
  }

  static void showError(String message) {
    if (Get.isSnackbarOpen) Get.closeCurrentSnackbar();
    Get.snackbar(
      'Erreur',
      message,
      backgroundColor: const Color(0xFFC62828),
      colorText: Colors.white,
      snackPosition: SnackPosition.TOP,
      duration: const Duration(seconds: 4),
      margin: const EdgeInsets.all(12),
      borderRadius: 12,
      icon: const Icon(Icons.error_outline, color: Colors.white),
    );
  }

  static void showWarning(String message) {
    if (Get.isSnackbarOpen) Get.closeCurrentSnackbar();
    Get.snackbar(
      'Attention',
      message,
      backgroundColor: const Color(0xFFF57F17),
      colorText: Colors.white,
      snackPosition: SnackPosition.TOP,
      duration: const Duration(seconds: 3),
      margin: const EdgeInsets.all(12),
      borderRadius: 12,
      icon: const Icon(Icons.warning_amber_rounded, color: Colors.white),
    );
  }

  static void showInfo(String message) {
    if (Get.isSnackbarOpen) Get.closeCurrentSnackbar();
    Get.snackbar(
      'Info',
      message,
      backgroundColor: const Color(0xFF1565C0),
      colorText: Colors.white,
      snackPosition: SnackPosition.TOP,
      duration: const Duration(seconds: 3),
      margin: const EdgeInsets.all(12),
      borderRadius: 12,
      icon: const Icon(Icons.info_outline, color: Colors.white),
    );
  }

  // ─── DIALOGS ────────────────────────────────────────────────────
  static Future<bool?> showConfirmDialog({
    required String title,
    required String content,
    String confirmText = 'Confirmer',
    String cancelText = 'Annuler',
    Color? confirmColor,
  }) async {
    return Get.dialog<bool>(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: Text(cancelText, style: TextStyle(color: Colors.grey[600])),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            style: ElevatedButton.styleFrom(
              backgroundColor: confirmColor ?? const Color(0xFF1565C0),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(confirmText),
          ),
        ],
      ),
      barrierDismissible: false,
    );
  }

  // ─── LOADING OVERLAY ─────────────────────────────────────────────
  static void showLoading({String message = 'Chargement...'}) {
    Get.dialog(
      WillPopScope(
        onWillPop: () async => false,
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(strokeWidth: 3),
                const SizedBox(height: 16),
                Text(message, style: const TextStyle(fontSize: 14, decoration: TextDecoration.none, color: Colors.black87)),
              ],
            ),
          ),
        ),
      ),
      barrierDismissible: false,
    );
  }

  static void hideLoading() {
    if (Get.isDialogOpen ?? false) Get.back();
  }

  // ─── FORMATAGE ──────────────────────────────────────────────────
  static String formatMontant(double montant, {String devise = 'CDF'}) {
    final formatter = NumberFormat('#,##0.00', 'fr_FR');
    return '${formatter.format(montant)} $devise';
  }

  static String formatMontantCompact(double montant) {
    if (montant >= 1000000000) {
      return '${(montant / 1000000000).toStringAsFixed(1)}B';
    } else if (montant >= 1000000) {
      return '${(montant / 1000000).toStringAsFixed(1)}M';
    } else if (montant >= 1000) {
      return '${(montant / 1000).toStringAsFixed(1)}K';
    }
    return montant.toStringAsFixed(0);
  }

  static String formatDate(String? dateStr, {String format = 'dd/MM/yyyy'}) {
    if (dateStr == null || dateStr.isEmpty) return '-';
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat(format, 'fr_FR').format(date);
    } catch (e) {
      return dateStr;
    }
  }

  static String formatDateTime(String? dateStr) {
    return formatDate(dateStr, format: 'dd/MM/yyyy HH:mm');
  }

  static String formatDateRelative(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '-';
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final diff = now.difference(date);

      if (diff.inMinutes < 1) return 'À l\'instant';
      if (diff.inMinutes < 60) return 'Il y a ${diff.inMinutes}min';
      if (diff.inHours < 24) return 'Il y a ${diff.inHours}h';
      if (diff.inDays < 7) return 'Il y a ${diff.inDays}j';
      return formatDate(dateStr);
    } catch (e) {
      return dateStr;
    }
  }

  // ─── STATUT HELPERS ─────────────────────────────────────────────
  static Color getStatutColor(String statut) {
    switch (statut.toUpperCase()) {
      case 'ACTIF':
      case 'OUVERT':
      case 'VALIDE':
      case 'APPROUVE':
      case 'PAYEE':
      case 'NORMAL':
        return const Color(0xFF2E7D32);
      case 'BROUILLON':
        return const Color(0xFF757575);
      case 'SOUMIS':
      case 'EN_ATTENTE':
        return const Color(0xFFF57F17);
      case 'REJETE':
      case 'INACTIF':
      case 'SUSPENDU':
      case 'ANNULE':
        return const Color(0xFFC62828);
      case 'CLOTURE':
      case 'FERMEE':
        return const Color(0xFF1565C0);
      case 'ALERTE':
      case 'RUPTURE':
        return const Color(0xFFE65100);
      default:
        return const Color(0xFF757575);
    }
  }

  static IconData getStatutIcon(String statut) {
    switch (statut.toUpperCase()) {
      case 'ACTIF':
      case 'OUVERT':
      case 'VALIDE':
      case 'APPROUVE':
        return Icons.check_circle;
      case 'BROUILLON':
        return Icons.edit_note;
      case 'SOUMIS':
      case 'EN_ATTENTE':
        return Icons.hourglass_bottom;
      case 'REJETE':
        return Icons.cancel;
      case 'INACTIF':
      case 'SUSPENDU':
        return Icons.block;
      case 'CLOTURE':
      case 'FERMEE':
        return Icons.lock;
      default:
        return Icons.circle;
    }
  }

  // ─── ROLE HELPERS ───────────────────────────────────────────────
  static String getRoleDisplayName(String slug) {
    switch (slug) {
      case 'admin':
        return 'Super Administrateur';
      case 'directeur':
      case 'directeur-financier':
        return 'Directeur Général';
      case 'chef-comptable':
      case 'comptable-chef':
        return 'Chef Comptable';
      case 'auditeur-interne':
        return 'Auditeur Interne';
      case 'comptable':
        return 'Comptable';
      case 'caissier':
        return 'Caissier';
      case 'gestionnaire-stock':
        return 'Gestionnaire de Stock';
      default:
        return slug;
    }
  }

  static IconData getRoleIcon(String slug) {
    switch (slug) {
      case 'admin':
        return Icons.admin_panel_settings;
      case 'directeur':
      case 'directeur-financier':
        return Icons.business;
      case 'chef-comptable':
      case 'comptable-chef':
        return Icons.account_balance;
      case 'auditeur-interne':
        return Icons.search;
      case 'comptable':
        return Icons.calculate;
      case 'caissier':
        return Icons.point_of_sale;
      case 'gestionnaire-stock':
        return Icons.inventory_2;
      default:
        return Icons.person;
    }
  }

  static Color getRoleColor(String slug) {
    switch (slug) {
      case 'admin':
        return const Color(0xFFD32F2F);
      case 'directeur':
      case 'directeur-financier':
        return const Color(0xFF1565C0);
      case 'chef-comptable':
      case 'comptable-chef':
        return const Color(0xFF6A1B9A);
      case 'auditeur-interne':
        return const Color(0xFF00695C);
      case 'comptable':
        return const Color(0xFF2E7D32);
      case 'caissier':
        return const Color(0xFFE65100);
      case 'gestionnaire-stock':
        return const Color(0xFF4E342E);
      default:
        return const Color(0xFF757575);
    }
  }
}
