import 'package:get/get.dart';
import '../controllers/login_controller.dart';
import '../controllers/inbox_controller.dart';
import '../controllers/detail_controller.dart';
import '../controllers/scanner_controller.dart';
import '../controllers/qr_gen_controller.dart';
import '../controllers/sync_controller.dart';
import '../controllers/pending_sync_detail_controller.dart';

class LoginBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<LoginController>(() => LoginController());
  }
}

class InboxBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<SyncController>()) {
      Get.put<SyncController>(SyncController(), permanent: true);
    }
    Get.lazyPut<InboxController>(() => InboxController());
  }
}

class DetailBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<DetailController>(() => DetailController());
  }
}

class ScannerBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ScannerController>(() => ScannerController());
  }
}

class QRGenBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<QRGenController>(() => QRGenController());
  }
}
class GateInBinding extends Bindings {
  @override
  void dependencies() {
  }
}

class PendingSyncDetailBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<PendingSyncDetailController>(
      () => PendingSyncDetailController(),
    );
  }
}