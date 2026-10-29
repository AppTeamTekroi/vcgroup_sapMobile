import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../controllers/qr_gen_controller.dart';

class QRGenScreen extends StatelessWidget {
  const QRGenScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<QRGenController>(
      init: QRGenController(),
      builder: (controller) => Scaffold(
        backgroundColor: const Color(0xFFFFFAF1),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 1,
          leading: IconButton(
            icon: const Text(
              '‹',
              style: TextStyle(fontSize: 24, color: Color(0xFF2A1B10)),
            ),
            onPressed: () => Get.back(),
          ),
          title: Text(
            controller.title,
            style: const TextStyle(
              color: Color(0xFF2A1B10),
              fontSize: 18,
              fontFamily: 'Fredoka',
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        body: Obx(
          () {
            final items = controller.items;
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 12, left: 4, right: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'TEST QR CODES',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF8C7A6B),
                          letterSpacing: 0.12,
                        ),
                      ),
                      Text(
                        '${items.length} codes',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF8C7A6B),
                          letterSpacing: 0.12,
                        ),
                      ),
                    ],
                  ),
                ),
                if (items.isEmpty)
                  _emptyState()
                else
                  ...items.map(_buildCard),
                if (controller.showInvalidSamples.value) ...[
                  _buildInvalidCard(
                    title: '⚠ INVALID FORMAT (test)',
                    description: 'Should be rejected',
                    payload: 'hello world',
                  ),
                  _buildInvalidCard(
                    title: '⚠ UNKNOWN ITEM (test)',
                    description: 'Item not in any pick list',
                    payload: 'ITM|ZZ-NOTREAL|SR|U001',
                  ),
                ],
                const SizedBox(height: 24),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _emptyState() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFF1E4D0)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Column(
        children: [
          Icon(Icons.check_circle_outline,
              color: Color(0xFF4CAF50), size: 48),
          SizedBox(height: 8),
          Text(
            'All lines complete',
            style: TextStyle(
              fontFamily: 'Fredoka',
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2A1B10),
            ),
          ),
          SizedBox(height: 4),
          Text(
            'No remaining units to scan.',
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF8C7A6B),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(QRTestItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFF1E4D0)),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2A1B10).withOpacity(0.06),
            blurRadius: 24,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${item.pickList.docNum} · L${item.line.lineNum + 1} · UNIT ${item.unitIndex}/${item.unitCount}',
            style: const TextStyle(
              fontFamily: 'Fredoka',
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFFE5322B),
              letterSpacing: 0.02,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${item.line.itemCode} — ${item.line.itemName}',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF8C7A6B),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: const Color(0xFFF1E4D0)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: QrImageView(
                data: item.payload,
                version: QrVersions.auto,
                errorCorrectionLevel: QrErrorCorrectLevel.M,
                size: 200,
                backgroundColor: Colors.white,
                gapless: true,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF4E0),
              borderRadius: BorderRadius.circular(8),
            ),
            child: SelectableText(
              item.payload,
              style: const TextStyle(
                fontFamily: 'JetBrains Mono',
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: Color(0xFF5D4836),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInvalidCard({
    required String title,
    required String description,
    required String payload,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFF1E4D0)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'Fredoka',
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFFE5322B),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF8C7A6B),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: const Color(0xFFF1E4D0)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: QrImageView(
                data: payload,
                version: QrVersions.auto,
                size: 200,
                backgroundColor: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF4E0),
              borderRadius: BorderRadius.circular(8),
            ),
            child: SelectableText(
              payload,
              style: const TextStyle(
                fontFamily: 'JetBrains Mono',
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: Color(0xFF5D4836),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
