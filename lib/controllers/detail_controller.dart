import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../data/repositories/pick_list_repository.dart';
import '../data/repositories/sync_repository.dart';
import '../data/qr_parser.dart';
import '../models/pick_list_model.dart';
import 'inbox_controller.dart';
import 'sync_controller.dart';

class DetailController extends GetxController {
  final PickListRepository _repository;
  final SyncRepository _syncRepository;

  DetailController({
    PickListRepository? repository,
    SyncRepository? syncRepository,
  })  : _repository = repository ?? const PickListRepository(),
        _syncRepository = syncRepository ?? const SyncRepository();

  late PickListModel pickList;
  final currentLineIndex = 0.obs;
  final isSubmitting = false.obs;
  final isLoading = false.obs;
  final error = Rxn<String>();
  final singleItemMode = false.obs;
  final singleItemIndex = 0.obs;

  // For quick scan
  final isScanning = false.obs;
  MobileScannerController? _scannerController;
  final Set<String> _scannedRaws = <String>{};
  int _lastScanTs = 0;

  @override
  void onInit() {
    super.onInit();
    pickList = Get.arguments as PickListModel;
    fetchDetails();

    // Initialize scanned raws
    for (final line in pickList.lines) {
      for (final scan in line.scans) {
        _scannedRaws.add(scan.raw);
      }
    }
  }

  @override
  void onClose() {
    _scannerController?.dispose();
    super.onClose();
  }

  Future<void> fetchDetails() async {
    if (pickList.pickListNo <= 0) return;
    try {
      isLoading.value = true;
      error.value = null;

      // Snapshot in-progress local scans so a refresh doesn't wipe scanning
      // done on other lines. Keyed by lineNum; only un-posted lines are kept.
      final priorScans = <int, ({int relQty, List<ScanResult> scans})>{
        for (final line in pickList.lines)
          if (line.scans.isNotEmpty)
            line.lineNum: (relQty: line.relQty, scans: List.of(line.scans)),
      };

      final details = await _repository.fetchPickListDetails(
        pickEntry: pickList.pickListNo,
      );

      final mergedLines = details.items;
      for (final line in mergedLines) {
        final prior = priorScans[line.lineNum];
        if (prior != null) {
          line.scans
            ..clear()
            ..addAll(prior.scans);
          line.relQty = prior.relQty;
        }
      }

      final header = details.header;
      pickList = pickList.copyWith(
        lines: mergedLines,
        customer: header.customerName.isNotEmpty
            ? header.customerName
            : pickList.customer,
        ref: header.refDocNum > 0 ? 'SO-${header.refDocNum}' : pickList.ref,
        pickDate: header.pickDate ?? pickList.pickDate,
      );
      update();
    } catch (e) {
      error.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> refreshDetails() => fetchDetails();

  int getTotalPicked() {
    return pickList.lines.fold<int>(0, (sum, line) => sum + line.relQty);
  }

  int getTotalRequired() {
    return pickList.lines.fold<int>(0, (sum, line) => sum + line.pickedQty);
  }

  bool get isComplete =>
      pickList.lines.isNotEmpty && getTotalPicked() >= getTotalRequired();

  bool isLineComplete(PickLineModel line) {
    return line.relQty >= line.pickedQty;
  }

  /// Indices of every line that has at least one scan. Posting always sends
  /// all scanned lines so multi-line pick lists post as separate base lines —
  /// single-item tap scanning no longer scopes the post to one line.
  List<int> scannedLineIndices() {
    return [
      for (var i = 0; i < pickList.lines.length; i++)
        if (pickList.lines[i].scans.isNotEmpty) i,
    ];
  }

  /// Clears local scans on the given line indices so a following refresh
  /// reflects server truth (used after those lines are posted).
  void _clearScans(List<int> indices) {
    for (final i in indices) {
      if (i >= 0 && i < pickList.lines.length) {
        pickList.lines[i].scans.clear();
      }
    }
  }

  Map<String, dynamic> _buildDocLine(PickLineModel line) {
    // Quantity is derived from what was actually scanned this session, NOT
    // line.relQty. relQty is pre-seeded from SAP's allocation total, so using
    // it would post a header Quantity larger than the scanned batch total and
    // SAP rejects the delivery with a "Batch total mismatch".
    final batchCounts = <String, int>{};
    for (final s in line.scans) {
      final b = s.batch;
      if (b == null || b.isEmpty) continue;
      batchCounts[b] = (batchCounts[b] ?? 0) + 1;
    }
    final batchTotal = batchCounts.values.fold<int>(0, (a, b) => a + b);
    // Batch-managed lines post the batch total; non-batch lines post the raw
    // scan count. Either way header Quantity == BatchNumbers total.
    final quantity = batchCounts.isNotEmpty ? batchTotal : line.scans.length;
    final doc = <String, dynamic>{
      'BaseEntry': pickList.pickListNo,
      'BaseLine': line.lineNum,
      'Quantity': quantity,
    };
    if (batchCounts.isNotEmpty) {
      doc['BatchNumbers'] = batchCounts.entries
          .map((e) => {'BatchNumber': e.key, 'Quantity': e.value})
          .toList();
    }
    return doc;
  }

  Map<String, dynamic> buildPostPayload() {
    final today = DateTime.now();
    final dateStr =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    final lines = [
      for (final i in scannedLineIndices()) _buildDocLine(pickList.lines[i]),
    ];
    return {
      'DocDate': dateStr,
      'DocDueDate': dateStr,
      'TaxDate': dateStr,
      'Comments': 'Created From PickList',
      'DocumentLines': lines,
    };
  }

  void updateScannedItems() {
    final indices = scannedLineIndices();
    if (indices.isEmpty) {
      Get.snackbar(
        'Nothing to Update',
        'Scan items before updating',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFFFFC107).withOpacity(0.9),
        colorText: Colors.white,
      );
      return;
    }
    Get.bottomSheet(
      _UpdateBottomSheet(controller: this, indices: indices),
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
    );
  }

  Future<void> submitUpdate() async {
    if (isSubmitting.value) return;
    if (!await _ensureNoPendingSync()) return;
    final postedIndices = scannedLineIndices();
    final payload = buildPostPayload();
    final documentLines =
        (payload['DocumentLines'] as List).cast<Map<String, dynamic>>();
    if (documentLines.isEmpty) {
      Get.snackbar(
        'Nothing to Update',
        'No scanned items to send',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFFFFC107).withOpacity(0.9),
        colorText: Colors.white,
      );
      return;
    }

    try {
      isSubmitting.value = true;
      error.value = null;

      debugPrint('[submitUpdate] sending ${documentLines.length} line(s) '
          'for PL-${pickList.pickListNo}');

      final result = await _syncRepository.updatePickedItems(
        pickListNo: pickList.pickListNo,
        documentLines: documentLines,
      );

      final sapSynced = result['sap_synced'] == true;
      final serverMessage = result['message']?.toString();

      debugPrint('[submitUpdate] response received: '
          'success=${result['success']} sap_synced=$sapSynced '
          'document_id=${result['document_id']} '
          'sap_error=${result['sap_error']} message=$serverMessage');

      Get.back();
      Get.snackbar(
        sapSynced ? 'Synced to SAP' : 'Saved Locally',
        serverMessage ??
            (sapSynced
                ? '${documentLines.length} line(s) saved and synced'
                : 'SAP sync failed — use sync button to retry'),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: (sapSynced
                ? const Color(0xFF4CAF50)
                : const Color(0xFFFFC107))
            .withOpacity(0.9),
        colorText: Colors.white,
        duration: Duration(seconds: sapSynced ? 2 : 4),
      );

      _clearScans(postedIndices);
      await fetchDetails();
      if (Get.isRegistered<SyncController>()) {
        await Get.find<SyncController>().refreshPending();
      }
      if (Get.isRegistered<InboxController>()) {
        Get.find<InboxController>().refreshPickLists();
      }
    } catch (e) {
      error.value = e.toString();

      // The backend may have already saved the document before crashing
      // (e.g. Laravel log error after insert). Refresh pending-sync first
      // to find out the real state, then decide which snackbar to show.
      final pendingBefore = Get.isRegistered<SyncController>()
          ? Get.find<SyncController>().pendingCount
          : 0;
      if (Get.isRegistered<SyncController>()) {
        await Get.find<SyncController>().refreshPending();
      }
      final pendingAfter = Get.isRegistered<SyncController>()
          ? Get.find<SyncController>().pendingCount
          : 0;
      final savedLocally = pendingAfter > pendingBefore;

      // Close the bottom sheet if it's still open so the user can see the
      // result and reach the sync queue.
      if (Get.isBottomSheetOpen ?? false) {
        Get.back();
      }

      if (savedLocally) {
        Get.snackbar(
          'Saved Locally',
          'Server error during sync, but document saved. '
              'Use sync button to retry.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: const Color(0xFFFFC107).withOpacity(0.9),
          colorText: Colors.white,
          duration: const Duration(seconds: 4),
        );
        _clearScans(postedIndices);
        await fetchDetails();
        if (Get.isRegistered<InboxController>()) {
          Get.find<InboxController>().refreshPickLists();
        }
      } else {
        Get.snackbar(
          'Update Failed',
          e.toString(),
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: const Color(0xFFE5322B).withOpacity(0.9),
          colorText: Colors.white,
          duration: const Duration(seconds: 4),
        );
      }
    } finally {
      isSubmitting.value = false;
    }
  }

  Future<void> postPickList() async {
    if (isSubmitting.value) return;
    if (!await _ensureNoPendingSync()) return;
    try {
      isSubmitting.value = true;
      error.value = null;

      final payload = buildPostPayload();
      final documentLines =
          (payload['DocumentLines'] as List).cast<Map<String, dynamic>>();

      if (documentLines.isEmpty) {
        throw Exception('No items picked to deliver');
      }

      final result = await _syncRepository.updatePickedItems(
        pickListNo: pickList.pickListNo,
        documentLines: documentLines,
      );

      singleItemMode.value = false;

      if (Get.isRegistered<SyncController>()) {
        await Get.find<SyncController>().refreshPending();
      }
      if (Get.isRegistered<InboxController>()) {
        Get.find<InboxController>().refreshPickLists();
      }

      Get.toNamed('/success', arguments: {'pickList': pickList, 'result': result});
    } catch (e) {
      error.value = e.toString();
      Get.snackbar(
        'Post Failed',
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFFE5322B).withOpacity(0.9),
        colorText: Colors.white,
      );
    } finally {
      isSubmitting.value = false;
    }
  }

  void selectLine(int index) {
    currentLineIndex.value = index;
  }

  Future<void> scanSingleItem(int index) async {
    if (index < 0 || index >= pickList.lines.length) return;
    // Pending-sync guard intentionally skipped here: the pending entry is
    // almost always this same pick list, and the user explicitly tapped a
    // partially-picked line to add more units.
    singleItemMode.value = true;
    singleItemIndex.value = index;
    Get.toNamed(
      '/scanner',
      arguments: {
        'pickList': pickList,
        'lineIndex': index,
        'singleItemMode': true,
      },
    )?.then((_) => update());
  }

  Future<bool> _ensureNoPendingSync() async {
    if (!Get.isRegistered<SyncController>()) return true;
    return Get.find<SyncController>().guardScan(pickListNo: pickList.pickListNo);
  }

  Future<void> quickScan() async {
    if (isScanning.value) return;
    if (!await _ensureNoPendingSync()) return;
    isScanning.value = true;
    _scannerController = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
      formats: const [BarcodeFormat.qrCode],
    );

    Get.to(() => _QuickScanOverlay(controller: this))?.then((_) {
      _scannerController?.dispose();
      _scannerController = null;
      isScanning.value = false;
    });
  }

  void _onQuickDetect(BarcodeCapture capture) {
    if (capture.barcodes.isEmpty) return;
    final raw = capture.barcodes.first.rawValue;
    if (raw == null || raw.isEmpty) return;

    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - _lastScanTs < 800) return;
    _lastScanTs = now;

    _processQuickScan(raw);
  }

  void _processQuickScan(String raw) {
    if (_scannedRaws.contains(raw)) {
      Get.snackbar(
        'Duplicate',
        'QR already scanned',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFFE5322B).withOpacity(0.8),
        colorText: Colors.white,
      );
      return;
    }

    final parsed = parseQR(raw);
    if (parsed == null) {
      Get.snackbar(
        'Invalid QR',
        'Unrecognised QR format',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFFE5322B).withOpacity(0.8),
        colorText: Colors.white,
      );
      return;
    }

    final matchingIndex = pickList.lines.indexWhere(
      (l) => l.itemCode == parsed.itemCode && l.relQty < l.pickedQty,
    );
    if (matchingIndex < 0) {
      final msg = pickList.lines.any((l) => l.itemCode == parsed.itemCode)
          ? 'Item ${parsed.itemCode} already complete'
          : 'Item ${parsed.itemCode} not in this pick list';
      Get.snackbar(
        'Not Found',
        msg,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFFE5322B).withOpacity(0.8),
        colorText: Colors.white,
      );
      return;
    }

    final line = pickList.lines[matchingIndex];
    if (line.manageBatch && (parsed.batch == null || parsed.batch!.isEmpty)) {
      Get.snackbar(
        'Batch Required',
        'This item requires batch/serial info',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFFFFC107).withOpacity(0.8),
        colorText: Colors.white,
      );
      return;
    }

    line.relQty += 1;
    line.scans.add(parsed);
    _scannedRaws.add(raw);
    update();

    final remaining = line.pickedQty - line.relQty;
    final message = remaining > 0
        ? '${line.itemCode} | WHS: ${line.whs} | $remaining left'
        : '✓ ${line.itemCode} complete';

    Get.snackbar(
      'Scanned',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: const Color(0xFF4CAF50).withOpacity(0.8),
      colorText: Colors.white,
      duration: const Duration(seconds: 1),
    );

    // Close scanner after successful scan
    Get.back();
  }
}

class _QuickScanOverlay extends StatelessWidget {
  final DetailController controller;

  const _QuickScanOverlay({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(
            controller: controller._scannerController!,
            onDetect: controller._onQuickDetect,
            fit: BoxFit.cover,
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black.withOpacity(0.9), Colors.transparent],
                ),
              ),
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 14,
                left: 18,
                right: 18,
                bottom: 14,
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Get.back(),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.15),
                        border: Border.all(color: Colors.white.withOpacity(0.3)),
                      ),
                      child: const Center(
                        child: Text(
                          '×',
                          style: TextStyle(color: Colors.white, fontSize: 18),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Quick Scan Pick List',
                      style: TextStyle(
                        fontFamily: 'Fredoka',
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Center(
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFFFCD2E), width: 2),
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withOpacity(0.95)],
                ),
              ),
              padding: EdgeInsets.only(
                top: 16,
                left: 12,
                right: 12,
                bottom: 12 + MediaQuery.of(context).padding.bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Items to pick list
                  Container(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.25,
                    ),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: controller.pickList.lines.length,
                      itemBuilder: (context, index) {
                        final line = controller.pickList.lines[index];
                        final isComplete = line.pickedQty >= line.relQty;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isComplete
                                ? const Color(0xFF4CAF50).withOpacity(0.25)
                                : Colors.white.withOpacity(0.08),
                            border: Border.all(
                              color: isComplete
                                  ? const Color(0xFF4CAF50)
                                  : Colors.white.withOpacity(0.2),
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      line.itemCode,
                                      style: const TextStyle(
                                        fontFamily: 'JetBrains Mono',
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFFFFCD2E),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      line.itemName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontFamily: 'Fredoka',
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'WHS: ${line.whs}',
                                      style: const TextStyle(
                                        fontFamily: 'JetBrains Mono',
                                        fontSize: 9,
                                        color: Color(0xFFB0BEC5),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '${line.relQty}/${line.pickedQty}',
                                    style: TextStyle(
                                      fontFamily: 'Fredoka',
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: isComplete
                                          ? const Color(0xFF4CAF50)
                                          : Colors.white,
                                    ),
                                  ),
                                  if (isComplete)
                                    const Icon(
                                      Icons.check_circle,
                                      color: Color(0xFF4CAF50),
                                      size: 16,
                                    ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Align QR code within the frame to scan',
                    style: TextStyle(
                      fontFamily: 'Fredoka',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFB0BEC5),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _UpdateBottomSheet extends StatelessWidget {
  final DetailController controller;
  final List<int> indices;

  const _UpdateBottomSheet({
    required this.controller,
    required this.indices,
  });

  @override
  Widget build(BuildContext context) {
    final mediaBottom = MediaQuery.of(context).padding.bottom;
    final maxHeight = MediaQuery.of(context).size.height * 0.8;

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 10, bottom: 6),
            width: 38,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFE0D6C7),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
            child: Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Updating Items',
                        style: TextStyle(
                          fontFamily: 'Fredoka',
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF2A1B10),
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Review scanned items and batch breakdown',
                        style: TextStyle(
                          fontFamily: 'Fredoka',
                          fontSize: 12,
                          color: Color(0xFF8C7A6B),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF6D9),
                    border: Border.all(color: const Color(0xFFFFCD2E)),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '${indices.length} line${indices.length == 1 ? '' : 's'}',
                    style: const TextStyle(
                      fontFamily: 'JetBrains Mono',
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF2A1B10),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 18, color: Color(0xFFF1E4D0)),
          Flexible(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              shrinkWrap: true,
              itemCount: indices.length,
              itemBuilder: (context, i) {
                final lineIdx = indices[i];
                final line = controller.pickList.lines[lineIdx];
                return _UpdateLineRow(line: line);
              },
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + mediaBottom),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Get.back(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: Color(0xFFE0D6C7)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                        fontFamily: 'Fredoka',
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF5D4836),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Obx(() {
                    final busy = controller.isSubmitting.value;
                    return ElevatedButton(
                      onPressed: busy ? null : () => controller.submitUpdate(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF075A7A),
                        disabledBackgroundColor:
                            const Color(0xFF075A7A).withOpacity(0.6),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: busy
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.4,
                                valueColor:
                                    AlwaysStoppedAnimation(Colors.white),
                              ),
                            )
                          : const Text(
                              'Submit Update',
                              style: TextStyle(
                                fontFamily: 'Fredoka',
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                    );
                  }),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _UpdateLineRow extends StatelessWidget {
  final PickLineModel line;

  const _UpdateLineRow({required this.line});

  @override
  Widget build(BuildContext context) {
    // Mirror _buildDocLine: group all scans by batch. The posted Quantity is
    // the batch total (or scan count for non-batch lines), so the preview
    // shows exactly what will be sent.
    final batches = <String, int>{};
    for (final s in line.scans) {
      final b = s.batch;
      if (b == null || b.isEmpty) continue;
      batches[b] = (batches[b] ?? 0) + 1;
    }
    final batchTotal = batches.values.fold<int>(0, (a, b) => a + b);
    final postedQty = batches.isNotEmpty ? batchTotal : line.scans.length;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFF1E4D0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF6D9),
                            border: Border.all(color: const Color(0xFFFFCD2E)),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            'LINE ${line.lineNum}',
                            style: const TextStyle(
                              fontFamily: 'JetBrains Mono',
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF2A1B10),
                              letterSpacing: 0.1,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          line.itemCode,
                          style: const TextStyle(
                            fontFamily: 'JetBrains Mono',
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFE5322B),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      line.itemName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Fredoka',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2A1B10),
                      ),
                    ),
                    if (line.whs.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        'WHS: ${line.whs}',
                        style: const TextStyle(
                          fontFamily: 'JetBrains Mono',
                          fontSize: 10,
                          color: Color(0xFF8C7A6B),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$postedQty',
                    style: const TextStyle(
                      fontFamily: 'Fredoka',
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF2A1B10),
                    ),
                  ),
                  Text(
                    'of ${line.pickedQty}',
                    style: const TextStyle(
                      fontFamily: 'JetBrains Mono',
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF8C7A6B),
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (batches.isNotEmpty) ...[
            const SizedBox(height: 10),
            const Divider(height: 1, color: Color(0xFFF1E4D0)),
            const SizedBox(height: 8),
            const Text(
              'BATCHES',
              style: TextStyle(
                fontFamily: 'JetBrains Mono',
                fontSize: 9,
                fontWeight: FontWeight.w800,
                color: Color(0xFF8C7A6B),
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(height: 6),
            Column(
              children: [
                for (final entry in batches.entries)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            entry.key,
                            style: const TextStyle(
                              fontFamily: 'JetBrains Mono',
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF2A1B10),
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE0F2FB),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${entry.value}',
                            style: const TextStyle(
                              fontFamily: 'JetBrains Mono',
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF075A7A),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ] else if (line.manageBatch) ...[
            const SizedBox(height: 10),
            const Divider(height: 1, color: Color(0xFFF1E4D0)),
            const SizedBox(height: 8),
            const Text(
              'No batch info captured',
              style: TextStyle(
                fontFamily: 'Fredoka',
                fontSize: 12,
                color: Color(0xFFE5322B),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
