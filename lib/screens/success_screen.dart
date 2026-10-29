import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/pick_list_model.dart';

class SuccessScreen extends StatefulWidget {
  const SuccessScreen({Key? key}) : super(key: key);

  @override
  State<SuccessScreen> createState() => _SuccessScreenState();
}

class _SuccessScreenState extends State<SuccessScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late PickListModel pickList;
  Map<String, dynamic>? result;

  @override
  void initState() {
    super.initState();
    final args = Get.arguments as Map;
    pickList = args['pickList'] as PickListModel;
    result = args['result'] as Map<String, dynamic>?;

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 450),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final totalPicked = pickList.lines
        .fold<int>(0, (sum, line) => sum + line.relQty);

    final sapSynced = result?['sap_synced'] == true;
    final accent = sapSynced
        ? const Color(0xFF4CAF50)
        : const Color(0xFFFFC107);
    final title = sapSynced ? 'Posted to SAP!' : 'Saved Locally';
    final subtitle = result?['message']?.toString() ??
        (sapSynced
            ? 'Pick list successfully updated'
            : 'SAP sync pending — retry from sync queue');

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Success Icon
              ScaleTransition(
                scale: _scaleAnimation,
                child: Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    color: accent,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: accent.withOpacity(0.5),
                        blurRadius: 40,
                        spreadRadius: -8,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Icon(
                      sapSynced ? Icons.check : Icons.cloud_off,
                      color: Colors.white,
                      size: 44,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Title
              Text(
                title,
                style: const TextStyle(
                  fontFamily: 'Fredoka',
                  fontSize: 30,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2A1B10),
                  letterSpacing: -0.02,
                ),
              ),
              const SizedBox(height: 8),

              // Message
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF8C7A6B),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Receipt
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFF8C7A6B),
                    style: BorderStyle.solid,
                    width: 1,
                  ),
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
                    if (result != null && result!['data'] != null && result!['data']['DocNum'] != null)
                      _receiptRow('Delivery', 'DL-${result!['data']['DocNum']}'),
                    _receiptRow('Document', pickList.docNum),
                    _receiptRow('Customer', pickList.customer),
                    _receiptRow('Items', '${pickList.lines.length}'),
                    _receiptRow('Qty', '$totalPicked'),
                    const Divider(
                      height: 16,
                      color: Color(0xFFF1E4D0),
                    ),
                    _receiptRow('Reference', pickList.ref, bold: true),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Back Button
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Get.offNamed('/inbox'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE5322B),
                    padding: const EdgeInsets.all(16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Back to Inbox',
                    style: TextStyle(
                      fontFamily: 'Fredoka',
                      fontSize: 16,
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
    );
  }

  Widget _receiptRow(String label, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'JetBrains Mono',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF8C7A6B),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'JetBrains Mono',
              fontSize: 12,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
              color: bold ? const Color(0xFF2A1B10) : const Color(0xFF8C7A6B),
            ),
          ),
        ],
      ),
    );
  }
}
