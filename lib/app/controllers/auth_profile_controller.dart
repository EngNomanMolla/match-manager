import 'package:get/get.dart';
import 'package:uuid/uuid.dart';
import '../data/models/user_model.dart';
import '../data/services/storage_service.dart';

class AuthProfileController extends GetxController {
  final StorageService _storageService = Get.find<StorageService>();

  final Rx<UserModel?> user = Rx<UserModel?>(null);
  final RxBool isInitialized = false.obs;

  @override
  void onInit() {
    super.onInit();
    _loadOrCreateUser();
  }

  void _loadOrCreateUser() {
    final existingUser = _storageService.getUser();
    if (existingUser != null) {
      user.value = existingUser;
    } else {
      // Default profile
      final newUser = UserModel(
        id: const Uuid().v4(),
        name: 'নোমান হোসেন',
        phone: '01700000000',
        preferredRole: 'manager',
      );
      user.value = newUser;
      _storageService.saveUser(newUser);
    }
    isInitialized.value = true;
  }

  void updateProfile({required String name, String phone = '', String preferredRole = 'manager'}) {
    if (user.value == null) return;
    final updated = user.value!.copyWith(
      name: name.trim(),
      phone: phone.trim(),
      preferredRole: preferredRole,
    );
    user.value = updated;
    _storageService.saveUser(updated);
  }

  void toggleRole() {
    if (user.value == null) return;
    final newRole = user.value!.preferredRole == 'manager' ? 'member' : 'manager';
    updateProfile(
      name: user.value!.name,
      phone: user.value!.phone,
      preferredRole: newRole,
    );
  }
}
