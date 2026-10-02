import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../data/services/storage_service.dart';

class LanguageController extends GetxController {
  final StorageService _storageService = Get.find<StorageService>();

  final Rx<Locale> currentLocale = const Locale('bn', 'BD').obs;

  @override
  void onInit() {
    super.onInit();
    final savedCode = _storageService.getLanguageCode();
    if (savedCode == 'en') {
      currentLocale.value = const Locale('en', 'US');
    } else {
      currentLocale.value = const Locale('bn', 'BD');
    }
    Get.updateLocale(currentLocale.value);
  }

  bool get isBangla => currentLocale.value.languageCode == 'bn';

  void toggleLanguage() {
    if (isBangla) {
      setLanguage('en');
    } else {
      setLanguage('bn');
    }
  }

  void setLanguage(String code) {
    if (code == 'bn') {
      currentLocale.value = const Locale('bn', 'BD');
      _storageService.saveLanguageCode('bn');
    } else {
      currentLocale.value = const Locale('en', 'US');
      _storageService.saveLanguageCode('en');
    }
    Get.updateLocale(currentLocale.value);
  }
}
