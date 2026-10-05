import 'package:get/get.dart';
import '../controllers/auth_profile_controller.dart';
import '../controllers/bazar_controller.dart';
import '../controllers/board_controller.dart';
import '../controllers/chat_controller.dart';
import '../controllers/language_controller.dart';
import '../controllers/meal_controller.dart';
import '../controllers/navigation_controller.dart';
import '../data/services/storage_service.dart';

class InitialBinding extends Bindings {
  @override
  void dependencies() {
    Get.put<StorageService>(StorageService(), permanent: true);
    Get.put<LanguageController>(LanguageController(), permanent: true);
    Get.put<AuthProfileController>(AuthProfileController(), permanent: true);
    Get.put<BoardController>(BoardController(), permanent: true);
    Get.put<MealController>(MealController(), permanent: true);
    Get.put<BazarController>(BazarController(), permanent: true);
    Get.put<ChatController>(ChatController(), permanent: true);
    Get.put<NavigationController>(NavigationController(), permanent: true);
  }
}
