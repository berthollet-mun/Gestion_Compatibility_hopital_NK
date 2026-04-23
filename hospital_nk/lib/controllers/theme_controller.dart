import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../core/services/storage_service.dart';

class ThemeController extends GetxController {
  final StorageService _storage = Get.find<StorageService>();
  final Rx<ThemeMode> themeMode = ThemeMode.light.obs;

  @override
  void onInit() {
    super.onInit();
    _loadTheme();
  }

  void _loadTheme() {
    final saved = _storage.themeMode;
    themeMode.value = saved == 'dark' ? ThemeMode.dark : ThemeMode.light;
  }

  void toggleTheme() {
    if (themeMode.value == ThemeMode.light) {
      themeMode.value = ThemeMode.dark;
      Get.changeThemeMode(ThemeMode.dark);
      _storage.saveTheme('dark');
    } else {
      themeMode.value = ThemeMode.light;
      Get.changeThemeMode(ThemeMode.light);
      _storage.saveTheme('light');
    }
  }

  bool get isDarkMode => themeMode.value == ThemeMode.dark;
}
