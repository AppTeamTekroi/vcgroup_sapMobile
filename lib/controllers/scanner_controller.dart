import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../data/qr_parser.dart';
import '../models/pick_list_model.dart';

class ScannerController extends GetxController {
  late PickListModel pickList;
  late int lineIndex;
  late PickLineModel currentLine;
  late bool singleItemMode;

  late final MobileScannerController cameraController;

  final statusMessage = Rxn<String>();
  final statusType = Rxn<String>();
  final scanCount = 0.obs;
  final flashKind = Rxn<String>();
  final torchEnabled = false.obs;

  int _lastScanTs = 0;
  final Set<String> _scannedRaws = <String>{};

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments as Map;
    pickList = args['pickList'] as PickListModel;
    lineIndex = args['lineIndex'] as int;
    singleItemMode = args['singleItemMode'] as bool? ?? false;
    currentLine = pickList.lines[lineIndex];
    scanCount.value = currentLine.relQty;

    // Seed duplicate-detection with QRs already scanned in previous sessions
    // on any line of this pick list, so closing and re-opening the scanner
    // still rejects repeat scans of the same QR.
    for (final line in pickList.lines) {
      for (final scan in line.scans) {
        _scannedRaws.add(scan.raw);
      }
    }

    cameraController = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
      formats: const [BarcodeFormat.qrCode],
    );
  }

  @override
  void onClose() {
    cameraController.dispose();
    super.onClose();
  }

  bool get isComplete => currentLine.relQty >= scanCount.value;

  bool get isPickListComplete =>
      pickList.lines.isNotEmpty && pickList.lines.every((l) => l.relQty >= l.pickedQty);

  int _nextIncompleteIndex() {
    return pickList.lines.indexWhere((l) => l.relQty < l.pickedQty);
  }

  void _advanceToNextIncompleteLine() {
    final next = _nextIncompleteIndex();
    if (next >= 0) {
      lineIndex = next;
      currentLine = pickList.lines[lineIndex];
      scanCount.value = currentLine.relQty;
      update();
    }
  }

  void onDetect(BarcodeCapture capture) {
    if (capture.barcodes.isEmpty) return;
    final raw = capture.barcodes.first.rawValue;
    if (raw == null || raw.isEmpty) return;

    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - _lastScanTs < 800) return;
    _lastScanTs = now;

    if (_scannedRaws.contains(raw)) {
      _signal('warn', 'Duplicate scan ignored');
      return;
    }

    _processScan(raw);
  }

  void _processScan(String raw) {
    final parsed = parseQR(raw);
    if (parsed == null) {
      _signal('error', 'Unrecognised QR format');
      return;
    }

    if (parsed.itemCode != currentLine.itemCode) {
      if (singleItemMode) {
        _signal('error', 'Wrong item — expected ${currentLine.itemCode}');
        return;
      }
      final matchingIndex = pickList.lines.indexWhere(
            (l) => l.itemCode == parsed.itemCode && l.relQty < l.pickedQty,
      );
      if (matchingIndex >= 0) {
        lineIndex = matchingIndex;
        currentLine = pickList.lines[lineIndex];
        scanCount.value = currentLine.relQty;
        update();
        _signal('warn', 'Switched to line #${lineIndex + 1}');
      } else {
        final suggestIdx = pickList.lines.indexWhere((l) => l.itemCode == parsed.itemCode);
        final msg = suggestIdx >= 0
            ? 'Item ${parsed.itemCode} already complete'
            : 'Item ${parsed.itemCode} not in this list';
        _signal('error', msg);
        return;
      }
    }

    if (currentLine.relQty >= currentLine.pickedQty) {
      _signal('warn', 'Line fully picked');
      return;
    }

    if (parsed.batch == null || parsed.batch!.isEmpty) {
      _signal('error', 'Batch required — QR missing batch info');
      return;
    }

    // After matching the item to a line, ensure each batch is added uniquely
    // per line — scanning a different QR with the same batch number on the
    // same line is rejected, since one batch = one unit in this flow.
    if (currentLine.scans.any((s) => s.batch == parsed.batch)) {
      _signal('warn',
          'Batch ${parsed.batch} already added for ${currentLine.itemCode}');
      _scannedRaws.add(raw);
      return;
    }

    currentLine.relQty += 1;
    scanCount.value = currentLine.relQty;
    currentLine.scans.add(parsed);
    _scannedRaws.add(raw);

    final remaining = currentLine.pickedQty - currentLine.relQty;
    if (remaining == 0) {
      if (singleItemMode) {
        // Item complete — return to detail screen. Posting is manual: the
        // user must tap Post / Update on the detail screen to send to SAP.
        _signal('success', 'Item complete ✓');
        Future.delayed(const Duration(milliseconds: 800), () {
          if (Get.isRegistered<ScannerController>()) closeScan();
        });
      } else if (isPickListComplete) {
        _signal('success', 'Pick list complete ✓');
        Future.delayed(const Duration(milliseconds: 800), () {
          if (Get.isRegistered<ScannerController>()) closeScan();
        });
      } else {
        _signal('success', 'Line complete ✓ scanning next item');
        _advanceToNextIncompleteLine();
      }
    } else {
      _signal('success', 'Picked +1 · $remaining remaining');
    }
  }

  void _signal(String kind, String message) {
    statusMessage.value = message;
    statusType.value = kind;
    flashKind.value = kind;
    HapticFeedback.lightImpact();

    Future.delayed(const Duration(milliseconds: 200), () {
      flashKind.value = null;
    });
    Future.delayed(const Duration(seconds: 2), () {
      if (statusMessage.value == message) {
        statusMessage.value = null;
        statusType.value = null;
      }
    });
  }

  Future<void> toggleTorch() async {
    try {
      await cameraController.toggleTorch();
      torchEnabled.value = !torchEnabled.value;
    } catch (_) {}
  }

  void setQuantity(int value) {
    final clamped = value.clamp(0, currentLine.pickedQty);
    if (clamped == currentLine.relQty) return;
    final wasMore = clamped > currentLine.relQty;
    currentLine.relQty = clamped;
    scanCount.value = clamped;
    _signal(wasMore ? 'success' : 'warn',
        wasMore ? 'Quantity updated to $clamped' : 'Quantity reduced to $clamped');
  }

  void closeScan() {
    Get.back();
  }
}
