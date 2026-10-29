import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../controllers/scanner_controller.dart';

class ScannerScreen extends StatelessWidget {
  const ScannerScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ScannerController>(
      init: ScannerController(),
      builder: (controller) {
        final mediaTop = MediaQuery.of(context).padding.top;
        final mediaBottom = MediaQuery.of(context).padding.bottom;
        return Scaffold(
          backgroundColor: Colors.black,
          body: Stack(
            fit: StackFit.expand,
            children: [
              MobileScanner(
                controller: controller.cameraController,
                onDetect: controller.onDetect,
                fit: BoxFit.cover,
                errorBuilder: (context, error) => _CameraError(error: error),
              ),

              _buildScanFrame(),

              Obx(() {
                final kind = controller.flashKind.value;
                if (kind == null) return const SizedBox.shrink();
                return IgnorePointer(
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 150),
                    opacity: 1,
                    child: Container(color: _flashColor(kind)),
                  ),
                );
              }),

              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.85),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  padding: EdgeInsets.only(
                    top: mediaTop + 14,
                    left: 18,
                    right: 18,
                    bottom: 14,
                  ),
                  child: Row(
                    children: [
                      _circleButton(
                        '×',
                        onTap: controller.closeScan,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              controller.currentLine.itemCode,
                              style: const TextStyle(
                                fontFamily: 'JetBrains Mono',
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFFFFCD2E),
                                letterSpacing: 0.1,
                              ),
                            ),
                            Text(
                              controller.currentLine.itemName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontFamily: 'Fredoka',
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            if (controller.currentLine.manageBatch)
                              const Padding(
                                padding: EdgeInsets.only(top: 2),
                                child: Text(
                                  'BATCH REQUIRED',
                                  style: TextStyle(
                                    fontFamily: 'JetBrains Mono',
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFFFFCD2E),
                                    letterSpacing: 0.15,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      Obx(
                        () => _circleButton(
                          controller.torchEnabled.value ? '⚡' : '⚐',
                          onTap: controller.toggleTorch,
                        ),
                      ),
                    ],
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
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.95),
                      ],
                    ),
                  ),
                  padding: EdgeInsets.only(
                    top: 24,
                    left: 18,
                    right: 18,
                    bottom: 24 + mediaBottom,
                  ),
                  child: Obx(
                    () => Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Column(
                          children: [
                            Text(
                              '${controller.scanCount.value} / ${controller.currentLine.pickedQty}',
                              style: const TextStyle(
                                fontFamily: 'Fredoka',
                                fontSize: 64,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                height: 1,
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'UNITS PICKED',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFFFFFFFF),
                                letterSpacing: 0.2,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        _buildStatus(controller),
                        const SizedBox(height: 12),
                        _QuantityField(controller: controller),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: controller.closeScan,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white.withOpacity(0.12),
                              padding: const EdgeInsets.all(14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                                side: BorderSide(
                                  color: Colors.white.withOpacity(0.25),
                                ),
                              ),
                            ),
                            child: const Text(
                              'Close',
                              style: TextStyle(
                                fontFamily: 'Fredoka',
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildScanFrame() {
    return Center(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = constraints.maxWidth * 0.75 > 320
              ? 320.0
              : constraints.maxWidth * 0.75;
          return SizedBox(
            width: size,
            height: size,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.55),
                          blurRadius: 0,
                          spreadRadius: 9999,
                        ),
                      ],
                    ),
                  ),
                ),
                _corner(top: 0, left: 0, tl: true),
                _corner(top: 0, right: 0, tr: true),
                _corner(bottom: 0, left: 0, bl: true),
                _corner(bottom: 0, right: 0, br: true),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _corner({
    double? top,
    double? bottom,
    double? left,
    double? right,
    bool tl = false,
    bool tr = false,
    bool bl = false,
    bool br = false,
  }) {
    const yellow = Color(0xFFFFCD2E);
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          // border: Border(
          //   top: BorderSide(
          //     color: (tl || tr) ? yellow : Colors.transparent,
          //     width: 4,
          //   ),
          //   bottom: BorderSide(
          //     color: (bl || br) ? yellow : Colors.transparent,
          //     width: 4,
          //   ),
          //   left: BorderSide(
          //     color: (tl || bl) ? yellow : Colors.transparent,
          //     width: 4,
          //   ),
          //   right: BorderSide(
          //     color: (tr || br) ? yellow : Colors.transparent,
          //     width: 4,
          //   ),
          // ),
          borderRadius: BorderRadius.only(
            topLeft: tl ? const Radius.circular(12) : Radius.zero,
            topRight: tr ? const Radius.circular(12) : Radius.zero,
            bottomLeft: bl ? const Radius.circular(12) : Radius.zero,
            bottomRight: br ? const Radius.circular(12) : Radius.zero,
          ),
        ),
      ),
    );
  }

  Widget _buildStatus(ScannerController controller) {
    final type = controller.statusType.value;
    final msg = controller.statusMessage.value ?? 'Align QR within frame';
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _statusBg(type),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _statusBorder(type)),
      ),
      child: Text(
        msg,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontFamily: 'Fredoka',
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
  }

  Color _statusBg(String? type) {
    return switch (type) {
      'success' => const Color(0xFF4CAF50).withOpacity(0.25),
      'error' => const Color(0xFFE5322B).withOpacity(0.3),
      'warn' => const Color(0xFFFFCD2E).withOpacity(0.3),
      _ => Colors.white.withOpacity(0.1),
    };
  }

  Color _statusBorder(String? type) {
    return switch (type) {
      'success' => const Color(0xFF4CAF50),
      'error' => const Color(0xFFE5322B),
      'warn' => const Color(0xFFFFCD2E),
      _ => Colors.white.withOpacity(0.15),
    };
  }

  Color _flashColor(String kind) {
    return switch (kind) {
      'success' => const Color(0xFF4CAF50).withOpacity(0.35),
      'error' => const Color(0xFFE5322B).withOpacity(0.4),
      'warn' => const Color(0xFFFFCD2E).withOpacity(0.35),
      _ => Colors.transparent,
    };
  }

  Widget _circleButton(String glyph, {required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withOpacity(0.15),
          border: Border.all(color: Colors.white.withOpacity(0.3)),
        ),
        child: Center(
          child: Text(
            glyph,
            style: const TextStyle(color: Colors.white, fontSize: 18),
          ),
        ),
      ),
    );
  }

}

class _QuantityField extends StatefulWidget {
  final ScannerController controller;
  const _QuantityField({required this.controller});

  @override
  State<_QuantityField> createState() => _QuantityFieldState();
}

class _QuantityFieldState extends State<_QuantityField> {
  late final TextEditingController _textController;
  late final Worker _worker;

  @override
  void initState() {
    super.initState();
    _textController =
        TextEditingController(text: '${widget.controller.scanCount.value}');
    _worker = ever<int>(widget.controller.scanCount, (value) {
      final current = int.tryParse(_textController.text);
      if (current != value) {
        _textController.text = '$value';
        _textController.selection = TextSelection.fromPosition(
          TextPosition(offset: _textController.text.length),
        );
      }
    });
  }

  @override
  void dispose() {
    _worker.dispose();
    _textController.dispose();
    super.dispose();
  }

  void _submit(String value) {
    final parsed = int.tryParse(value.trim());
    if (parsed == null) {
      _textController.text = '${widget.controller.scanCount.value}';
      return;
    }
    widget.controller.setQuantity(parsed);
  }

  @override
  Widget build(BuildContext context) {
    final target = widget.controller.currentLine.pickedQty;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          const Text(
            'QTY',
            style: TextStyle(
              fontFamily: 'JetBrains Mono',
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: Color(0xFFFFCD2E),
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _textController,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              textInputAction: TextInputAction.done,
              onSubmitted: _submit,
              onTapOutside: (_) {
                _submit(_textController.text);
                FocusManager.instance.primaryFocus?.unfocus();
              },
              style: const TextStyle(
                fontFamily: 'Fredoka',
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
              decoration: const InputDecoration(
                isDense: true,
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 8),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '/ $target',
            style: const TextStyle(
              fontFamily: 'Fredoka',
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }
}

class _CameraError extends StatelessWidget {
  final MobileScannerException error;
  const _CameraError({required this.error});

  @override
  Widget build(BuildContext context) {
    final code = error.errorCode;
    final isPermission = code == MobileScannerErrorCode.permissionDenied;
    return Container(
      color: Colors.black,
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isPermission ? Icons.no_photography : Icons.error_outline,
              color: const Color(0xFFFFCD2E),
              size: 56,
            ),
            const SizedBox(height: 12),
            Text(
              isPermission
                  ? 'Camera permission denied'
                  : 'Camera unavailable',
              style: const TextStyle(
                color: Colors.white,
                fontFamily: 'Fredoka',
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              isPermission
                  ? 'Grant camera access in Settings to scan QR codes.'
                  : (error.errorDetails?.message ?? 'Try restarting the app.'),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Get.back(),
              child: const Text('Back'),
            ),
          ],
        ),
      ),
    );
  }
}
