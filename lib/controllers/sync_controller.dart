import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../data/repositories/sync_repository.dart';

class SyncController extends GetxController {
  final SyncRepository _repository;

  SyncController({SyncRepository? repository})
      : _repository = repository ?? const SyncRepository();

  final pendingItems = <PendingSyncItem>[].obs;
  final isLoading = false.obs;
  final isSyncing = false.obs;
  final lastError = Rxn<String>();

  int get pendingCount => pendingItems.length;
  bool get hasPending => pendingItems.isNotEmpty;

  Set<int> get pendingPickListNos =>
      pendingItems.map((e) => e.pickListNo).where((n) => n > 0).toSet();

  bool isPending(int pickListNo) =>
      pickListNo > 0 && pendingPickListNos.contains(pickListNo);

  @override
  void onInit() {
    super.onInit();
    refreshPending();
  }

  Future<void> refreshPending() async {
    if (isLoading.value) return;
    try {
      isLoading.value = true;
      lastError.value = null;
      final items = await _repository.getPendingSync();
      pendingItems.assignAll(items);
    } catch (e) {
      lastError.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  /// Manually push all pending pick lists to SAP.
  Future<bool> syncAll() async {
    if (isSyncing.value) return false;
    try {
      isSyncing.value = true;
      lastError.value = null;
      await _repository.syncAllPending();
      await refreshPending();
      final ok = !hasPending;
      _toast(
        ok ? 'Sync complete' : 'Some items still pending',
        success: ok,
      );
      return ok;
    } catch (e) {
      lastError.value = e.toString();
      _toast('Sync failed: $e', success: false);
      return false;
    } finally {
      isSyncing.value = false;
    }
  }

  /// Retry a specific pending pick list.
  // Future<bool> retry(int pickListNo) async {
  //   try {
  //     lastError.value = null;
  //     await _repository.retrySync(pickListNo: pickListNo);
  //     await refreshPending();
  //     _toast('Retry triggered for PL-$pickListNo', success: true);
  //     return true;
  //   } catch (e) {
  //     lastError.value = e.toString();
  //     _toast('Retry failed: $e', success: false);
  //     return false;
  //   }
  // }

  /// Returns true if the user may proceed to scanning this pick list.
  ///
  /// Only blocks when [pickListNo] itself is already in the pending-sync
  /// queue — other pick lists remain workable while one is pending.
  Future<bool> guardScan({required int pickListNo}) async {
    await refreshPending();
    if (!isPending(pickListNo)) return true;

    final proceed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text(
          'Pending Sync',
          style: TextStyle(
            fontFamily: 'Fredoka',
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          'PL-$pickListNo is still pending sync to SAP. '
          'Sync it before scanning more items on this pick list. '
          'Other pick lists can still be worked on.',
          style: const TextStyle(fontFamily: 'Fredoka'),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF075A7A),
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              final ok = await syncAll();
              Get.back(result: ok);
            },
            child: const Text('Sync Now'),
          ),
        ],
      ),
      barrierDismissible: false,
    );
    return proceed ?? false;
  }

  void _toast(String message, {required bool success}) {
    Get.snackbar(
      success ? 'Sync' : 'Sync Error',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor:
          (success ? const Color(0xFF4CAF50) : const Color(0xFFE5322B))
              .withOpacity(0.9),
      colorText: Colors.white,
      duration: const Duration(seconds: 2),
    );
  }
}
