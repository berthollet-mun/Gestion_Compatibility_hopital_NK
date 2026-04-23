import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/services/storage_service.dart';
import '../routes/app_routes.dart';

class AuthMiddleware extends GetMiddleware {
  @override
  int? get priority => 1;

  @override
  RouteSettings? redirect(String? route) {
    final storage = Get.find<StorageService>();

    // Pages publiques (pas besoin d'auth)
    final publicRoutes = [
      AppRoutes.splash,
      AppRoutes.login,
      AppRoutes.welcome,
    ];

    if (publicRoutes.contains(route)) {
      // Si déjà connecté et qu'on essaie d'accéder au login, redirect vers dashboard
      if (storage.isLoggedIn && (route == AppRoutes.login || route == AppRoutes.welcome)) {
        return const RouteSettings(name: '/dashboard');
      }
      return null;
    }

    // Pages protégées : vérifier l'auth
    if (!storage.isLoggedIn) {
      return const RouteSettings(name: '/login');
    }

    // Vérifier les permissions par rôle pour certaines routes
    final roleSlug = storage.userRoleSlug ?? '';
    if (_isRouteRestricted(route, roleSlug)) {
      return const RouteSettings(name: '/dashboard');
    }

    return null;
  }

  bool _isRouteRestricted(String? route, String roleSlug) {
    if (route == null) return false;

    // Routes admin seulement
    final adminOnlyRoutes = [
      AppRoutes.users,
      AppRoutes.userCreate,
      AppRoutes.userEdit,
      AppRoutes.exercices,
      AppRoutes.exerciceCreate,
    ];
    if (adminOnlyRoutes.contains(route) && roleSlug != 'admin') {
      return true;
    }

    // Routes caissier seulement (et admin)
    final caisseRoutes = [
      AppRoutes.caisseOuvrir,
      AppRoutes.caisseTransactions,
    ];
    if (caisseRoutes.contains(route) &&
        roleSlug != 'admin' &&
        roleSlug != 'caissier') {
      return true;
    }

    // Routes stock seulement (et admin)
    final stockRoutes = [
      AppRoutes.stockProduitCreate,
      AppRoutes.stockMovements,
    ];
    if (stockRoutes.contains(route) &&
        roleSlug != 'admin' &&
        roleSlug != 'gestionnaire-stock') {
      return true;
    }

    return false;
  }
}
