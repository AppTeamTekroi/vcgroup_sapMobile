import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/detail_controller.dart';
import '../controllers/sync_controller.dart';

class DetailScreen extends StatelessWidget {
  const DetailScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetBuilder<DetailController>(
      init: DetailController(),
      builder: (controller) => Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 1,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios,size: 24,color: Color(0xFF2A1B10)),
            onPressed: () => Get.back(),
          ),
          title: const Text(
            'Pick List',
            style: TextStyle(
              color: Color(0xFF2A1B10),
              fontSize: 18,
              fontFamily: 'Fredoka',
              fontWeight: FontWeight.w600,
            ),
          ),
          actions: [
            Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF6D9),
                border: Border.all(color: const Color(0xFFFFCD2E)),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                  '${controller.getTotalRequired()}/${controller.getTotalPicked()}',
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
        body: Column(
          children: [
            // Detail Header
            Container(
              padding: const EdgeInsets.all(18),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                  bottom: BorderSide(color: Color(0xFFF1E4D0)),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    controller.pickList.docNum,
                    style: const TextStyle(
                      fontFamily: 'JetBrains Mono',
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFE5322B),
                      letterSpacing: 0.1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    controller.pickList.customer,
                    style: const TextStyle(
                      fontFamily: 'Fredoka',
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2A1B10),
                      letterSpacing: -0.02,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    spacing: 18,
                    children: [
                      RichText(
                        text: TextSpan(
                          children: [
                            const TextSpan(
                              text: 'REF ',
                              style: TextStyle(
                                fontFamily: 'JetBrains Mono',
                                fontSize: 12,
                                color: Color(0xFF8C7A6B),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            TextSpan(
                              text: controller.pickList.ref,
                              style: const TextStyle(
                                fontFamily: 'JetBrains Mono',
                                fontSize: 12,
                                color: Color(0xFF2A1B10),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      RichText(
                        text: TextSpan(
                          children: [
                            const TextSpan(
                              text: 'WHS ',
                              style: TextStyle(
                                fontFamily: 'JetBrains Mono',
                                fontSize: 12,
                                color: Color(0xFF8C7A6B),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            TextSpan(
                              text: controller.pickList.whs,
                              style: const TextStyle(
                                fontFamily: 'JetBrains Mono',
                                fontSize: 12,
                                color: Color(0xFF2A1B10),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Scan until entire pick list is complete
            // Padding(
            //   padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            //   child: SizedBox(
            //     width: double.infinity,
            //     child: OutlinedButton.icon(
            //       onPressed: controller.isComplete
            //           ? null
            //           : () {
            //               final startIndex = controller.pickList.lines.indexWhere(
            //                 (line) => line.pickedQty < line.relQty,
            //               );
            //               if (startIndex >= 0) {
            //                 Get.toNamed(
            //                   '/scanner',
            //                   arguments: {
            //                     'pickList': controller.pickList,
            //                     'lineIndex': startIndex,
            //                   },
            //                 )
            //                     ?.then((_) => controller.update());
            //               }
            //             },
            //       icon: const Icon(Icons.qr_code_scanner,
            //           color: Color(0xFF075A7A), size: 18),
            //       label: const Text(
            //         'Scan pick list until complete',
            //         style: TextStyle(
            //           fontFamily: 'Fredoka',
            //           fontSize: 13,
            //           fontWeight: FontWeight.w600,
            //           color: Color(0xFF075A7A),
            //         ),
            //       ),
            //       style: OutlinedButton.styleFrom(
            //         padding: const EdgeInsets.symmetric(vertical: 12),
            //         backgroundColor: const Color(0xFFE0F2FB),
            //         side: const BorderSide(color: Color(0xFF0B7FAB)),
            //         shape: RoundedRectangleBorder(
            //           borderRadius: BorderRadius.circular(12),
            //         ),
            //       ),
            //     ),
            //   ),
            // ),

            // Test QR codes shortcut
            // Padding(
            //   padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            //   child: SizedBox(
            //     width: double.infinity,
            //     child: OutlinedButton.icon(
            //       onPressed: () => Get.toNamed(
            //         '/qr-gen',
            //         arguments: controller.pickList,
            //       ),
            //       icon: const Icon(Icons.qr_code_2,
            //           color: Color(0xFF075A7A), size: 18),
            //       label: const Text(
            //         'Test QR Codes for this Pick List',
            //         style: TextStyle(
            //           fontFamily: 'Fredoka',
            //           fontSize: 13,
            //           fontWeight: FontWeight.w600,
            //           color: Color(0xFF075A7A),
            //         ),
            //       ),
            //       style: OutlinedButton.styleFrom(
            //         padding: const EdgeInsets.symmetric(vertical: 12),
            //         backgroundColor: const Color(0xFFE0F2FB),
            //         side: const BorderSide(color: Color(0xFF0B7FAB)),
            //         shape: RoundedRectangleBorder(
            //           borderRadius: BorderRadius.circular(12),
            //         ),
            //       ),
            //     ),
            //   ),
            // ),

            // Lines List
            Expanded(
              child: Obx(() {
                Future<void> refreshAll() async {
                  await controller.refreshDetails();
                  if (Get.isRegistered<SyncController>()) {
                    await Get.find<SyncController>().refreshPending();
                  }
                }

                if (controller.isLoading.value &&
                    controller.pickList.lines.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (controller.error.value != null &&
                    controller.pickList.lines.isEmpty) {
                  return RefreshIndicator(
                    onRefresh: refreshAll,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        const SizedBox(height: 40),
                        _DetailErrorView(
                          message: controller.error.value!,
                          onRetry: controller.refreshDetails,
                        ),
                      ],
                    ),
                  );
                }
                if (controller.pickList.lines.isEmpty) {
                  return RefreshIndicator(
                    onRefresh: refreshAll,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: const [
                        SizedBox(height: 120),
                        Center(
                          child: Text(
                            'No items in this pick list',
                            style: TextStyle(
                              fontFamily: 'Fredoka',
                              fontSize: 14,
                              color: Color(0xFF8C7A6B),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return RefreshIndicator(
                  onRefresh: refreshAll,
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    itemCount: controller.pickList.lines.length,
                    itemBuilder: (context, index) {
                      final line = controller.pickList.lines[index];
                      final isComplete = controller.isLineComplete(line);
                      return _buildLineCard(context, line, isComplete, index);
                    },
                  ),
                );
              }),
            ),

            // Submit Bar
            Container(
              padding: const EdgeInsets.all(14),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(color: Color(0xFFF1E4D0)),
                ),
              ),
              child: Obx(
                () {
                  final hasScans = controller.getTotalPicked() > 0;
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const _ResyncBanner(),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: hasScans && !controller.isSubmitting.value
                              ? () => controller.updateScannedItems()
                              : null,
                          icon: const Icon(
                            Icons.cloud_upload_outlined,
                            size: 18,
                            color: Color(0xFF075A7A),
                          ),
                          label: Text(
                            'Update Scanned Items',
                            style: TextStyle(
                              fontFamily: 'Fredoka',
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: hasScans
                                  ? const Color(0xFF075A7A)
                                  : const Color(0xFF8C7A6B),
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            backgroundColor: const Color(0xFFE0F2FB),
                            disabledBackgroundColor: const Color(0xFFF5F0E8),
                            side: BorderSide(
                              color: hasScans
                                  ? const Color(0xFF0B7FAB)
                                  : const Color(0xFFE0D6C7),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: controller.isComplete &&
                                  !controller.isSubmitting.value
                              ? () => controller.postPickList()
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFE5322B),
                            disabledBackgroundColor: const Color(0xFFF1E4D0),
                            padding: const EdgeInsets.all(16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: controller.isSubmitting.value
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Color(0xFF8C7A6B),
                                    ),
                                  ),
                                )
                              : Text(
                                  'Post Full Pick List',
                                  style: TextStyle(
                                    fontFamily: 'Fredoka',
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: controller.isComplete
                                        ? Colors.white
                                        : const Color(0xFF8C7A6B),
                                  ),
                                ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
        // floatingActionButton: FloatingActionButton(
        //   onPressed: controller.isComplete ? null : () => controller.quickScan(),
        //   backgroundColor: controller.isComplete ? const Color(0xFFF1E4D0) : const Color(0xFF075A7A),
        //   child: const Icon(Icons.qr_code_scanner, color: Colors.white),
        // ),
      ),
    );
  }

  Widget _buildLineCard(
    BuildContext context,
    dynamic line,
    bool isComplete,
    int index,
  ) {
    return GestureDetector(
      onTap: () {
        if (line.relQty >= line.pickedQty) return;
        Get.find<DetailController>().scanSingleItem(index);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: isComplete ? const Color(0xFFE8F5E9) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color:
                isComplete ? const Color(0xFF4CAF50) : const Color(0xFFF1E4D0),
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF2A1B10).withOpacity(0.06),
              blurRadius: 24,
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isComplete ? const Color(0xFF4CAF50) : const Color(0xFFFFF4E0),
              ),
              child: Center(
                child: Text(
                  '${line.lineNum + 1}',
                  style: TextStyle(
                    fontFamily: 'Fredoka',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isComplete ? Colors.white : const Color(0xFF5D4836),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    line.itemCode,
                    style: const TextStyle(
                      fontFamily: 'JetBrains Mono',
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFE5322B),
                      letterSpacing: 0.05,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    line.itemName,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Fredoka',
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2A1B10),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'WHS: ${line.whs}',
                    style: const TextStyle(
                      fontFamily: 'JetBrains Mono',
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF8C7A6B),
                    ),
                  ),
                  Text(
                    'BATCH: ${(line.batch as String).isEmpty ? '—' : line.batch}',
                    style: const TextStyle(
                      fontFamily: 'JetBrains Mono',
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF8C7A6B),
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${line.relQty}',
                  style: TextStyle(
                    fontFamily: 'Fredoka',
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: isComplete
                        ? const Color(0xFF2E7D32)
                        : const Color(0xFF2A1B10),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'of ${line.pickedQty}',
                  style: const TextStyle(
                    fontFamily: 'JetBrains Mono',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF8C7A6B),
                    letterSpacing: 0.05,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ResyncBanner extends StatelessWidget {
  const _ResyncBanner();

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<SyncController>()) {
      return const SizedBox.shrink();
    }
    final sync = Get.find<SyncController>();
    return Obx(() {
      if (!sync.hasPending) return const SizedBox.shrink();
      final count = sync.pendingCount;
      return Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF6D9),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFFFCD2E)),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.sync_problem,
              color: Color(0xFFE5A800),
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '$count pending sync',
                style: const TextStyle(
                  fontFamily: 'Fredoka',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF2A1B10),
                ),
              ),
            ),
            ElevatedButton.icon(
              onPressed:
                  sync.isSyncing.value ? null : () => sync.syncAll(),
              icon: sync.isSyncing.value
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.cloud_sync, size: 16),
              label: Text(sync.isSyncing.value ? 'Syncing…' : 'Re-sync'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF075A7A),
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                textStyle: const TextStyle(
                  fontFamily: 'Fredoka',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      );
    });
  }
}

class _DetailErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _DetailErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off,
              size: 48,
              color: Color(0xFFE5322B),
            ),
            const SizedBox(height: 12),
            const Text(
              'Could not load pick list details',
              style: TextStyle(
                fontFamily: 'Fredoka',
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2A1B10),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF8C7A6B),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onRetry,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
