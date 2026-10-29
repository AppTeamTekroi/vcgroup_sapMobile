import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../../constants/app_constants.dart';
import 'base_repository.dart';

class SyncRepository extends BaseRepository {
  const SyncRepository();

  /// POST /update-picked-items
  /// Posts the picked items for a pick list. Backend queues them for SAP sync.
  Future<Map<String, dynamic>> updatePickedItems({
    required int pickListNo,
    required List<Map<String, dynamic>> documentLines,
  }) async {
    final today = DateTime.now();
    final dateStr =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    final payload = {
      'pick_id': pickListNo,
      'DocDate': dateStr,
      'DocDueDate': dateStr,
      'TaxDate': dateStr,
      'Comments': 'Created From PickList',
      'DocumentLines': documentLines,
    };

    return _postJson(Uri.parse(AppConstants.baseUrl+AppConstants.updatePickedItem), payload);
  }

  /// POST /update-pending-sync
  /// Replaces a pending-sync record with corrected data and retriggers SAP push.
  Future<Map<String, dynamic>> updatePendingSync({
    required int pickListNo,
    required List<Map<String, dynamic>> documentLines,
  }) async {
    final today = DateTime.now();
    final dateStr =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    final payload = {
      'pick_id': pickListNo,
      'DocDate': dateStr,
      'DocDueDate': dateStr,
      'TaxDate': dateStr,
      'Comments': 'Resync from PickList',
      'DocumentLines': documentLines,
    };

    return _postJson(
      Uri.parse(AppConstants.baseUrl + AppConstants.updatePendingSync),
      payload,
    );
  }

  /// POST /delete-pending-sync
  /// Removes part (or all) of a pending-sync record.
  /// - pickListNo only           → delete whole document
  /// - pickListNo + baseLine     → delete one document line
  /// - pickListNo + baseLine + batch → delete one batch on a line.
  ///   When deleting a batch, [newQuantity] should be the line's quantity
  ///   AFTER the batch is removed (sum of remaining batch quantities), so
  ///   the backend can update the line total in the same call.
  Future<Map<String, dynamic>> deletePending({
    required int recordId,
    required int pickListNo,
    int? baseLine,
    String? batch,
    int? newQuantity,
  }) async {
    final payload = <String, dynamic>{
      'id': recordId,
      'pick_id': pickListNo,
      if (baseLine != null) 'BaseLine': baseLine,
      if (batch != null && batch.isNotEmpty) 'BatchNumber': batch,
      if (newQuantity != null) 'Quantity': newQuantity,
    };
    return _postJson(
      Uri.parse(AppConstants.baseUrl + AppConstants.deletePendingSync),
      payload,
    );
  }

  /// POST /retry-sync
  /// Retries sync for a specific pick list that previously failed.
  // Future<Map<String, dynamic>> retrySync({required int pickListNo}) async {
  //   return _postJson(
  //     Uri.parse(AppConstants.baseUrl+AppConstants.syncPickedItems),
  //     {'pickListNo': pickListNo},
  //   );
  // }

  /// GET /pending-sync
  /// Returns the list of pick lists that are pending sync to SAP.
  Future<List<PendingSyncItem>> getPendingSync() async {
    final decoded = await _getJson(Uri.parse(AppConstants.baseUrl+AppConstants.checkSyncStatus));
    final raw = decoded['data'] ?? decoded['pending'] ?? decoded['items'];
    if (raw is! List) return const [];
    return raw
        .whereType<Map<String, dynamic>>()
        .map(PendingSyncItem.fromJson)
        .toList();
  }

  /// GET /pick-list/{recordId}
  /// Returns the full pending-sync record (summary + lines + batches).
  Future<PendingPickListData> getPendingDetail(int recordId) async {
    final decoded = await _getJson(Uri.parse(
      '${AppConstants.baseUrl}${AppConstants.pendingSyncDetail}/$recordId',
    ));
    if (decoded['success'] == false) {
      throw Exception(decoded['message']?.toString() ?? 'Request failed');
    }
    final data = decoded['data'];
    if (data is! Map<String, dynamic>) {
      throw Exception('Unexpected response format');
    }
    return PendingPickListData.fromJson(data);
  }

  /// POST /sync-all-pending
  /// Triggers backend to push all pending pick lists to SAP.
  Future<Map<String, dynamic>> syncAllPending() async {
    return _postJson(Uri.parse(AppConstants.baseUrl+AppConstants.syncAllPending), const {});
  }

  Future<Map<String, dynamic>> _postJson(
    Uri uri,
    Map<String, dynamic> payload,
  ) async {
    final bodyJson = const JsonEncoder.withIndent('  ').convert(payload);
    debugPrint('→ POST $uri');
    debugPrint('  body: $bodyJson');

    final client = HttpClient();
    client.badCertificateCallback = (cert, host, port) => true;
    client.connectionTimeout = const Duration(seconds: 30);

    try {
      final request = await client.postUrl(uri);
      request.headers.set('Content-Type', 'application/json');
      request.headers.set('Accept', 'application/json');
      request.write(jsonEncode(payload));
      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();

      debugPrint('← ${response.statusCode} $uri');
      debugPrint('  response: ${_safeMessage(body)}');

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception(
          'Request failed (HTTP ${response.statusCode}) ${_safeMessage(body)}',
        );
      }

      final decoded = jsonDecode(body);
      if (decoded is! Map<String, dynamic>) {
        throw Exception('Unexpected response format');
      }
      if (decoded['success'] == false) {
        throw Exception(
          decoded['message']?.toString() ?? 'Request failed',
        );
      }
      final status = decoded['status']?.toString().toLowerCase();
      if (status != null && status != 'success' && status != 'ok') {
        throw Exception(
          decoded['message']?.toString() ?? 'Request failed',
        );
      }
      return decoded;
    } finally {
      client.close(force: true);
    }
  }

  Future<Map<String, dynamic>> _getJson(Uri uri) async {
    debugPrint('→ GET $uri');

    final client = HttpClient();
    client.badCertificateCallback = (cert, host, port) => true;
    client.connectionTimeout = const Duration(seconds: 30);

    try {
      final request = await client.getUrl(uri);
      request.headers.set('Accept', 'application/json');
      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();

      debugPrint('← ${response.statusCode} $uri');
      debugPrint('  response: ${_safeMessage(body)}');

      if (response.statusCode != HttpStatus.ok) {
        throw Exception(
          'Request failed (HTTP ${response.statusCode}) ${_safeMessage(body)}',
        );
      }
      final decoded = jsonDecode(body);
      if (decoded is! Map<String, dynamic>) {
        throw Exception('Unexpected response format');
      }
      return decoded;
    } finally {
      client.close(force: true);
    }
  }

  String _safeMessage(String body) {
    if (body.isEmpty) return '';
    return body.length > 200 ? body.substring(0, 200) : body;
  }
}

class PendingSyncItem {
  final int recordId;
  final int pickListNo;
  final String? customer;
  final String? status;
  final String? error;
  final int? attempts;

  const PendingSyncItem({
    required this.recordId,
    required this.pickListNo,
    this.customer,
    this.status,
    this.error,
    this.attempts,
  });

  factory PendingSyncItem.fromJson(Map<String, dynamic> json) {
    return PendingSyncItem(
      recordId: _asInt(json['id']),
      pickListNo: _asInt(
        json['pick_id'],
      ),
      customer: (json['customerName'] ?? json['customer']) as String?,
      status: json['status'] as String?,
      error: (json['sap_error_msg'] ??
          json['sap_error'] ??
          json['error'] ??
          json['message']) as String?,
      attempts: (json['attempts'] as num?)?.toInt(),
    );
  }
}

int _asInt(dynamic v) {
  if (v == null) return 0;
  if (v is int) return v;
  if (v is num) return v.toInt();
  return num.tryParse(v.toString())?.toInt() ?? 0;
}

class PendingPickListData {
  final int recordId;
  final String pickId;
  final String? docDate;
  final int sapSync;
  final String? errorMsg;
  final PendingSummary summary;
  final List<PendingLine> lines;

  const PendingPickListData({
    required this.recordId,
    required this.pickId,
    required this.sapSync,
    required this.summary,
    required this.lines,
    this.docDate,
    this.errorMsg,
  });

  factory PendingPickListData.fromJson(Map<String, dynamic> json) {
    final rawLines = json['lines'];
    return PendingPickListData(
      recordId: _asInt(json['id']),
      pickId: json['pick_id']?.toString() ?? '',
      docDate: json['doc_date'] as String?,
      sapSync: _asInt(json['sap_sync']),
      errorMsg: (json['sap_error_msg'] ??
          json['sap_error'] ??
          json['error_msg'] ??
          json['message']) as String?,
      summary: PendingSummary.fromJson(
        (json['summary'] is Map<String, dynamic>)
            ? json['summary'] as Map<String, dynamic>
            : const {},
      ),
      lines: rawLines is List
          ? rawLines
              .whereType<Map<String, dynamic>>()
              .map(PendingLine.fromJson)
              .toList()
          : const [],
    );
  }
}

class PendingSummary {
  final int lineCount;
  final int totalQuantity;
  final int totalBatchQty;
  final int batchCount;

  const PendingSummary({
    required this.lineCount,
    required this.totalQuantity,
    required this.totalBatchQty,
    required this.batchCount,
  });

  factory PendingSummary.fromJson(Map<String, dynamic> json) {
    return PendingSummary(
      lineCount: _asInt(json['line_count']),
      totalQuantity: _asInt(json['total_quantity']),
      totalBatchQty: _asInt(json['total_batch_qty']),
      batchCount: _asInt(json['batch_count']),
    );
  }
}

class PendingLine {
  final int id;
  final int baseEntry;
  final int baseLine;
  final int quantity;
  final List<PendingBatch> batches;

  const PendingLine({
    required this.id,
    required this.baseEntry,
    required this.baseLine,
    required this.quantity,
    required this.batches,
  });

  factory PendingLine.fromJson(Map<String, dynamic> json) {
    final rawBatches = json['batches'];
    return PendingLine(
      id: _asInt(json['id']),
      baseEntry: _asInt(json['base_entry']),
      baseLine: _asInt(json['base_line']),
      quantity: _asInt(json['quantity']),
      batches: rawBatches is List
          ? rawBatches
              .whereType<Map<String, dynamic>>()
              .map(PendingBatch.fromJson)
              .toList()
          : const [],
    );
  }
}

class PendingBatch {
  final String batchNumber;
  final int quantity;

  const PendingBatch({required this.batchNumber, required this.quantity});

  factory PendingBatch.fromJson(Map<String, dynamic> json) {
    return PendingBatch(
      batchNumber: json['batch_number']?.toString() ?? '',
      quantity: _asInt(json['quantity']),
    );
  }
}
