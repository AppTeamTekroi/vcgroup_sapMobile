import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../data/repositories/sync_repository.dart';
import 'inbox_controller.dart';
import 'sync_controller.dart';

class PendingSyncDetailController extends GetxController {
  final SyncRepository _repository;

  PendingSyncDetailController({SyncRepository? repository})
      : _repository = repository ?? const SyncRepository();

  late int recordId;
  late int pickListNo;
  String? initialError;

  final isLoading = false.obs;
  final isMutating = false.obs;
  final data = Rxn<PendingPickListData>();
  final error = Rxn<String>();

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments as Map;
    recordId = args['recordId'] as int;
    pickListNo = (args['pickListNo'] as int?) ?? 0;
    initialError = args['error'] as String?;
    fetch();
  }

  Future<void> fetch() async {
    if (isLoading.value) return;
    try {
      isLoading.value = true;
      error.value = null;
      final result = await _repository.getPendingDetail(recordId);
      data.value = result;
    } catch (e) {
      error.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  String get displayError {
    final apiError = data.value?.errorMsg;
    if (apiError != null && apiError.isNotEmpty) return apiError;
    if (initialError != null && initialError!.isNotEmpty) return initialError!;
    return 'SAP rejected this pick list.';
  }

  Future<void> deleteAll() async {
    final ok = await _confirm(
      title: 'Delete pending document?',
      body: 'Remove the entire pending-sync record for PL-$pickListNo? '
          'The pick list itself stays.',
    );
    if (!ok) return;
    await _runMutation(
      action: () => _repository.deletePending(
        recordId: recordId,
        pickListNo: pickListNo,
      ),
      successMsg: 'Pending document deleted',
      popAfter: true,
    );
  }

  Future<void> deleteBatch(PendingLine line, PendingBatch batch) async {
    final ok = await _confirm(
      title: 'Delete batch?',
      body: 'Remove batch "${batch.batchNumber}" '
          '(qty ${batch.quantity}) from line ${line.baseLine}?',
    );
    if (!ok) return;
    final remainingBatchTotal = line.batches
        .where((b) => b.batchNumber != batch.batchNumber)
        .fold<int>(0, (sum, b) => sum + b.quantity);
    await _runMutation(
      action: () => _repository.deletePending(
        recordId: recordId,
        pickListNo: pickListNo,
        baseLine: line.baseLine,
        batch: batch.batchNumber,
        newQuantity: remainingBatchTotal,
      ),
      successMsg: 'Batch removed',
    );
  }

  Future<bool> _confirm({required String title, required String body}) async {
    final result = await Get.dialog<bool>(
      AlertDialog(
        title: Text(
          title,
          style: const TextStyle(
            fontFamily: 'Fredoka',
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(body, style: const TextStyle(fontFamily: 'Fredoka')),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE5322B),
              foregroundColor: Colors.white,
            ),
            onPressed: () => Get.back(result: true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _runMutation({
    required Future<Map<String, dynamic>> Function() action,
    required String successMsg,
    bool popAfter = false,
  }) async {
    if (isMutating.value) return;
    try {
      isMutating.value = true;
      await action();
      if (popAfter) {
        Get.back();
      }
      Get.snackbar(
        'Deleted',
        successMsg,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFF4CAF50).withOpacity(0.9),
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
      if (Get.isRegistered<SyncController>()) {
        unawaited(Get.find<SyncController>().refreshPending());
      }
      if (Get.isRegistered<InboxController>()) {
        Get.find<InboxController>().refreshPickLists();
      }
      if (!popAfter) {
        await fetch();
      }
    } catch (e) {
      Get.snackbar(
        'Delete Failed',
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFFE5322B).withOpacity(0.9),
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
      );
    } finally {
      isMutating.value = false;
    }
  }
}
