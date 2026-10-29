import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/pending_sync_detail_controller.dart';
import '../data/repositories/sync_repository.dart';

class PendingSyncDetailScreen extends StatelessWidget {
  const PendingSyncDetailScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final c = Get.find<PendingSyncDetailController>();
    return Scaffold(
      backgroundColor: const Color(0xFFFFFBF5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios,
              size: 22, color: Color(0xFF2A1B10)),
          onPressed: () => Get.back(),
        ),
        title: const Text(
          'Pending Sync',
          style: TextStyle(
            color: Color(0xFF2A1B10),
            fontSize: 18,
            fontFamily: 'Fredoka',
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          Obx(() => IconButton(
                icon: const Icon(Icons.refresh, color: Color(0xFF2A1B10)),
                onPressed: c.isLoading.value ? null : c.fetch,
              )),
        ],
      ),
      body: Obx(() {
        if (c.isLoading.value && c.data.value == null) {
          return const Center(child: CircularProgressIndicator());
        }
        if (c.error.value != null && c.data.value == null) {
          return _ErrorView(message: c.error.value!, onRetry: c.fetch);
        }
        final data = c.data.value;
        return RefreshIndicator(
          onRefresh: c.fetch,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              _ErrorBanner(message: c.displayError),
              const SizedBox(height: 12),
              if (data != null) _HeaderCard(data: data),
              if (data != null) const SizedBox(height: 12),
              if (data != null) _SummaryCard(summary: data.summary),
              if (data != null) const SizedBox(height: 16),
              if (data != null) ...[
                const Padding(
                  padding: EdgeInsets.fromLTRB(4, 0, 4, 8),
                  child: Text(
                    'LINES',
                    style: TextStyle(
                      fontFamily: 'JetBrains Mono',
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF8C7A6B),
                      letterSpacing: 0.15,
                    ),
                  ),
                ),
                for (final line in data.lines) _LineCard(line: line, c: c),
              ],
              const SizedBox(height: 20),
              Obx(() => _DeleteAllButton(
                    busy: c.isMutating.value,
                    onPressed: c.isMutating.value ? null : c.deleteAll,
                  )),
            ],
          ),
        );
      }),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF6D9),
        border: Border.all(color: const Color(0xFFFFCD2E)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline,
              size: 20, color: Color(0xFFE5322B)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'SAP SYNC FAILED',
                  style: TextStyle(
                    fontFamily: 'JetBrains Mono',
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFFE5322B),
                    letterSpacing: 0.15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: const TextStyle(
                    fontFamily: 'Fredoka',
                    fontSize: 12,
                    color: Color(0xFF2A1B10),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  final PendingPickListData data;
  const _HeaderCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFF1E4D0)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'PL-${data.pickId}',
                style: const TextStyle(
                  fontFamily: 'JetBrains Mono',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFE5322B),
                  letterSpacing: 0.1,
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFE0DD),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  data.sapSync == 0 ? 'NOT SYNCED' : 'SYNCED',
                  style: const TextStyle(
                    fontFamily: 'JetBrains Mono',
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFFE5322B),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _kv('Record ID', '${data.recordId}'),
          if (data.docDate != null) _kv('Doc Date', data.docDate!),
        ],
      ),
    );
  }

  Widget _kv(String k, String v) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              k,
              style: const TextStyle(
                fontFamily: 'JetBrains Mono',
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Color(0xFF8C7A6B),
              ),
            ),
          ),
          Expanded(
            child: Text(
              v,
              style: const TextStyle(
                fontFamily: 'JetBrains Mono',
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Color(0xFF2A1B10),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final PendingSummary summary;
  const _SummaryCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFE0F2FB),
        border: Border.all(color: const Color(0xFF0B7FAB)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          _stat('LINES', '${summary.lineCount}'),
          _stat('QTY', '${summary.totalQuantity}'),
          _stat('BATCH QTY', '${summary.totalBatchQty}'),
          _stat('BATCHES', '${summary.batchCount}'),
        ],
      ),
    );
  }

  Widget _stat(String label, String value) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'Fredoka',
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xFF075A7A),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'JetBrains Mono',
              fontSize: 9,
              fontWeight: FontWeight.w800,
              color: Color(0xFF075A7A),
              letterSpacing: 0.15,
            ),
          ),
        ],
      ),
    );
  }
}

class _LineCard extends StatelessWidget {
  final PendingLine line;
  final PendingSyncDetailController c;
  const _LineCard({required this.line, required this.c});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFF1E4D0)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF6D9),
                  border: Border.all(color: const Color(0xFFFFCD2E)),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'LINE ${line.baseLine}',
                  style: const TextStyle(
                    fontFamily: 'JetBrains Mono',
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF2A1B10),
                    letterSpacing: 0.1,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'BaseEntry ${line.baseEntry}',
                style: const TextStyle(
                  fontFamily: 'JetBrains Mono',
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF8C7A6B),
                ),
              ),
              const Spacer(),
              Text(
                '${line.quantity}',
                style: const TextStyle(
                  fontFamily: 'Fredoka',
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF2A1B10),
                ),
              ),
              const SizedBox(width: 2),
              const Text(
                'qty',
                style: TextStyle(
                  fontFamily: 'JetBrains Mono',
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF8C7A6B),
                ),
              ),
            ],
          ),
          if (line.batches.isNotEmpty) ...[
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
            for (final b in line.batches) _BatchRow(line: line, batch: b, c: c),
          ],
        ],
      ),
    );
  }
}

class _BatchRow extends StatelessWidget {
  final PendingLine line;
  final PendingBatch batch;
  final PendingSyncDetailController c;
  const _BatchRow({required this.line, required this.batch, required this.c});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              batch.batchNumber,
              style: const TextStyle(
                fontFamily: 'JetBrains Mono',
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Color(0xFF2A1B10),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFFE0F2FB),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '${batch.quantity}',
              style: const TextStyle(
                fontFamily: 'JetBrains Mono',
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Color(0xFF075A7A),
              ),
            ),
          ),
          const SizedBox(width: 4),
          Obx(() => IconButton(
                onPressed: c.isMutating.value
                    ? null
                    : () => c.deleteBatch(line, batch),
                icon: const Icon(
                  Icons.delete_outline,
                  size: 18,
                  color: Color(0xFFE5322B),
                ),
                padding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
                constraints: const BoxConstraints(),
                tooltip: 'Delete batch',
              )),
        ],
      ),
    );
  }
}

class _DeleteAllButton extends StatelessWidget {
  final bool busy;
  final VoidCallback? onPressed;
  const _DeleteAllButton({required this.busy, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: busy
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Icon(Icons.delete_forever, size: 20),
        label: Text(
          busy ? 'Deleting…' : 'Delete entire pending record',
          style: const TextStyle(
            fontFamily: 'Fredoka',
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFE5322B),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
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
            const Icon(Icons.cloud_off, size: 48, color: Color(0xFFE5322B)),
            const SizedBox(height: 12),
            const Text(
              'Could not load pending record',
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
            ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
