import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/inbox_controller.dart';
import '../controllers/sync_controller.dart';
import '../data/repositories/sync_repository.dart';
import '../models/pick_list_model.dart';

class InboxScreen extends StatelessWidget {
  const InboxScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetBuilder<InboxController>(
      init: InboxController(),
      builder: (controller) => Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 1,
          title: Row(
            children: [
              Image.network(
                'https://i0.wp.com/vcnutrifoods.com/wp-content/uploads/2023/02/logo1.png?fit=150%2C65&ssl=1',
                height: 32,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(Icons.image_not_supported);
                },
              ),
              const SizedBox(width: 12),
              const Text(
                'Pick Lists',
                style: TextStyle(
                  color: Color(0xFF2A1B10),
                  fontSize: 18,
                  fontFamily: 'Fredoka',
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF6D9),
                  border: Border.all(color: const Color(0xFFFFCD2E)),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  'PICKER01',
                  style: TextStyle(
                    fontFamily: 'JetBrains Mono',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF2A1B10),
                  ),
                ),
              ),
            ],
          ),
          // actions: [
          //   Obx(
          //     () => IconButton(
          //       icon: const Icon(Icons.refresh, color: Color(0xFF2A1B10)),
          //       onPressed: controller.isLoading.value
          //           ? null
          //           : controller.refreshPickLists,
          //     ),
          //   ),
          // ],
        ),
        body: Obx(() {
          if (controller.isLoading.value && controller.pickLists.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (controller.error.value != null && controller.pickLists.isEmpty) {
            return _ErrorView(
              message: controller.error.value!,
              onRetry: controller.refreshPickLists,
            );
          }
          return RefreshIndicator(
            onRefresh: () async {
              await controller.refreshPickLists();
              if (Get.isRegistered<SyncController>()) {
                await Get.find<SyncController>().refreshPending();
              }
            },
            child: Column(
              children: [
                const _PendingSyncBanner(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                  child: _SearchBar(
                    onChanged: controller.setSearchQuery,
                    initialValue: controller.searchQuery.value,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Obx(
                    () => Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'OPEN ASSIGNMENTS',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF8C7A6B),
                            letterSpacing: 0.12,
                          ),
                        ),
                        Text(
                          '${controller.filteredPickLists.length} lists',
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
                ),
                Expanded(
                  child: Obx(() {
                    final lists = controller.filteredPickLists;
                    if (lists.isEmpty) {
                      final hasQuery = controller.searchQuery.value.isNotEmpty;
                      return ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          const SizedBox(height: 120),
                          Center(
                            child: Text(
                              hasQuery
                                  ? 'No pick lists match your search'
                                  : 'No pick lists found',
                              style: const TextStyle(
                                fontFamily: 'Fredoka',
                                fontSize: 14,
                                color: Color(0xFF8C7A6B),
                              ),
                            ),
                          ),
                        ],
                      );
                    }
                    return ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: lists.length,
                      itemBuilder: (context, index) {
                        final pl = lists[index];
                        return _buildPickListCard(pl, controller);
                      },
                    );
                  }),
                ),
              ],
            ),
          );
        }),
        floatingActionButton: Obx(() {
          if (controller.pickLists.isEmpty) return const SizedBox.shrink();
          return GestureDetector(
            onTap: () => Get.toNamed(
              '/qr-gen',
              arguments: controller.pickLists.toList(),
            ),
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: const Color(0xFF0B7FAB),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0B7FAB).withOpacity(0.5),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Center(
                child: Text(
                  'QR',
                  style: TextStyle(
                    fontFamily: 'Fredoka',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildPickListCard(
    PickListModel pl,
    InboxController controller,
  ) {
    final progress = controller.getProgress(pl);
    final statusStyle = _statusStyleFor(pl.status);

    return GestureDetector(
      onTap: () {
        controller.selectPickList(pl);
        Get.toNamed('/detail', arguments: pl);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFF1E4D0)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF2A1B10).withOpacity(0.06),
              blurRadius: 24,
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 4,
                    height: 60,
                    decoration: BoxDecoration(
                      color: statusStyle.accent,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(2),
                        bottomLeft: Radius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          pl.docNum,
                          style: const TextStyle(
                            fontFamily: 'JetBrains Mono',
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFE5322B),
                            letterSpacing: 0.05,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          pl.customer,
                          style: const TextStyle(
                            fontFamily: 'Fredoka',
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF2A1B10),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          pl.ref,
                          style: const TextStyle(
                            fontFamily: 'JetBrains Mono',
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF8C7A6B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    spacing: 16,
                    children: [
                      _MetricColumn(
                        label: 'ITEMS',
                        value: '${controller.getLineCount(pl)}',
                      ),
                      _MetricColumn(
                        label: 'QTY',
                        value:
                            '${controller.getTotalRequired(pl)}/${controller.getTotalPicked(pl)}',
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusStyle.background,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      statusStyle.label,
                      style: TextStyle(
                        fontFamily: 'JetBrains Mono',
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: statusStyle.foreground,
                        letterSpacing: 0.08,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 6,
                  backgroundColor: const Color(0xFFFFF4E0),
                  valueColor: AlwaysStoppedAnimation<Color>(statusStyle.accent),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  _StatusStyle _statusStyleFor(String status) {
    switch (status) {
      case 'partial':
        return const _StatusStyle(
          label: 'PARTIAL',
          accent: Color(0xFFFFCD2E),
          background: Color(0xFFFFF6D9),
          foreground: Color(0xFFE5A800),
        );
      case 'closed':
        return const _StatusStyle(
          label: 'CLOSED',
          accent: Color(0xFF4CAF50),
          background: Color(0xFFE6F4EA),
          foreground: Color(0xFF2E7D32),
        );
      case 'open':
      default:
        return const _StatusStyle(
          label: 'OPEN',
          accent: Color(0xFFE5322B),
          background: Color(0xFFE0F2FB),
          foreground: Color(0xFF075A7A),
        );
    }
  }
}

class _SearchBar extends StatefulWidget {
  final ValueChanged<String> onChanged;
  final String initialValue;

  const _SearchBar({required this.onChanged, this.initialValue = ''});

  @override
  State<_SearchBar> createState() => _SearchBarState();
}

class _SearchBarState extends State<_SearchBar> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF1E4D0)),
      ),
      child: TextField(
        controller: _controller,
        onChanged: widget.onChanged,
        style: const TextStyle(
          fontFamily: 'Fredoka',
          fontSize: 14,
          color: Color(0xFF2A1B10),
        ),
        decoration: InputDecoration(
          isDense: true,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          border: InputBorder.none,
          hintText: 'Search by doc #, customer, or ref',
          hintStyle: const TextStyle(
            fontFamily: 'Fredoka',
            fontSize: 14,
            color: Color(0xFF8C7A6B),
          ),
          prefixIcon: const Icon(
            Icons.search,
            size: 20,
            color: Color(0xFF8C7A6B),
          ),
          suffixIcon: ValueListenableBuilder<TextEditingValue>(
            valueListenable: _controller,
            builder: (context, value, _) {
              if (value.text.isEmpty) return const SizedBox.shrink();
              return IconButton(
                icon: const Icon(
                  Icons.clear,
                  size: 18,
                  color: Color(0xFF8C7A6B),
                ),
                onPressed: () {
                  _controller.clear();
                  widget.onChanged('');
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

class _PendingSyncBanner extends StatelessWidget {
  const _PendingSyncBanner();

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
        margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF6D9),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFFFCD2E)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.cloud_sync,
                  color: Color(0xFFE5A800),
                  size: 22,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$count pick list${count == 1 ? '' : 's'} pending sync',
                        style: const TextStyle(
                          fontFamily: 'Fredoka',
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF2A1B10),
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Resolve sync issues below to push these to SAP',
                        style: TextStyle(
                          fontFamily: 'Fredoka',
                          fontSize: 11,
                          color: Color(0xFF8C7A6B),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed:
                      sync.isSyncing.value ? null : () => sync.syncAll(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF075A7A),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: sync.isSyncing.value
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Sync All',
                          style: TextStyle(
                            fontFamily: 'Fredoka',
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Divider(height: 1, color: Color(0xFFFFCD2E)),
            const SizedBox(height: 6),
            for (final item in sync.pendingItems) _PendingSyncRow(item: item),
          ],
        ),
      );
    });
  }
}

class _PendingSyncRow extends StatelessWidget {
  final PendingSyncItem item;
  const _PendingSyncRow({required this.item});

  void _openForResync() {
    Get.toNamed('/pending-sync-detail', arguments: {
      'recordId': item.recordId,
      'pickListNo': item.pickListNo,
      'error': (item.error?.isNotEmpty ?? false) ? item.error : item.status,
    });
  }

  @override
  Widget build(BuildContext context) {
    final sync = Get.find<SyncController>();
    final issue = (item.error?.isNotEmpty ?? false)
        ? item.error!
        : (item.status ?? 'Awaiting sync');
    return InkWell(
      onTap: _openForResync,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PL-${item.pickListNo}'
                  '${item.customer != null && item.customer!.isNotEmpty ? '  ·  ${item.customer}' : ''}',
                  style: const TextStyle(
                    fontFamily: 'Fredoka',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF2A1B10),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  issue,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'JetBrains Mono',
                    fontSize: 10,
                    color: Color(0xFFE5322B),
                  ),
                ),
                if (item.attempts != null && item.attempts! > 0) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Attempts: ${item.attempts}',
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
          const SizedBox(width: 8),
          Obx(() => OutlinedButton(
                onPressed:
                    sync.isSyncing.value ? null : () => sync.syncAll(),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF075A7A),
                  side: const BorderSide(color: Color(0xFF075A7A)),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  minimumSize: const Size(0, 32),
                ),
                child: const Text(
                  'Resync',
                  style: TextStyle(
                    fontFamily: 'Fredoka',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              )),
        ],
      ),
      ),
    );
  }
}

class _StatusStyle {
  final String label;
  final Color accent;
  final Color background;
  final Color foreground;

  const _StatusStyle({
    required this.label,
    required this.accent,
    required this.background,
    required this.foreground,
  });
}

class _MetricColumn extends StatelessWidget {
  final String label;
  final String value;

  const _MetricColumn({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'JetBrains Mono',
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Color(0xFF8C7A6B),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontFamily: 'JetBrains Mono',
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Color(0xFF2A1B10),
          ),
        ),
      ],
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

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
              'Could not load pick lists',
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
