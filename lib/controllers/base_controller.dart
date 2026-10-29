import 'package:get/get.dart';

/// Base controller class for all controllers
abstract class BaseController extends GetxController {
  final isLoading = false.obs;
  final error = Rxn<String>();

  @override
  void onInit() {
    super.onInit();
  }

  @override
  void onReady() {
    super.onReady();
  }

  @override
  void onClose() {
    super.onClose();
  }

  void setLoading(bool value) {
    isLoading.value = value;
  }

  void setError(String? message) {
    error.value = message;
  }
}
