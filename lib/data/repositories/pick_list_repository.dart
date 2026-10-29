import 'dart:convert';
import 'dart:io';

import 'package:kids4/constants/app_constants.dart';

import '../../models/pick_list_model.dart';
import 'base_repository.dart';

class PickListRepository extends BaseRepository {
  const PickListRepository();

  Future<List<PickListModel>> fetchPickLists({
    String dbName = AppConstants.defaultDbName,
  }) async {
    final uri = Uri.parse('${AppConstants.listUrl}?DBName=$dbName');
    final decoded = await _getJson(uri);
    final data = decoded['data'];
    if (data is! List) return const [];
    return data
        .whereType<Map<String, dynamic>>()
        .map(PickListModel.fromJson)
        .toList();
  }

  Future<PickListDetailsResult> fetchPickListDetails({
    required int pickEntry,
    String dbName = AppConstants.defaultDbName,
  }) async {
    final uri = Uri.parse(
      '${AppConstants.detailsUrl}?DBName=$dbName&PickEntry=$pickEntry',
    );
    final decoded = await _getJson(uri);
    final data = decoded['data'];
    if (data is! Map<String, dynamic>) {
      throw Exception('Unexpected details payload');
    }

    final headerJson = data['header'];
    final itemsJson = data['items'];

    final items = (itemsJson is List)
        ? itemsJson
              .whereType<Map<String, dynamic>>()
              .map(PickLineModel.fromJson)
              .toList()
        : <PickLineModel>[];

    return PickListDetailsResult(
      header: headerJson is Map<String, dynamic>
          ? PickListHeader.fromJson(headerJson)
          : const PickListHeader.empty(),
      items: items,
    );
  }

  Future<Map<String, dynamic>> postDelivery({
    required int baseEntry,
    required List<Map<String, dynamic>> documentLines,
    String dbName = AppConstants.defaultDbName,
  }) async {
    // Assuming the endpoint is something like this; adjust as needed
    const String postUrl = 'https://117.250.194.177:4300/SalesAPP/XSJS/PostDelivery.xsjs';
    final uri = Uri.parse('$postUrl?DBName=$dbName');

    final today = DateTime.now();
    final dateStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    final payload = {
      'DocDate': dateStr,
      'DocDueDate': dateStr,
      'TaxDate': dateStr,
      'Comments': 'Created From PickList',
      'DocumentLines': documentLines,
    };

    final client = HttpClient();
    client.badCertificateCallback = (cert, host, port) => true;
    client.connectionTimeout = const Duration(seconds: 30);

    try {
      final request = await client.postUrl(uri);
      request.headers.set('Content-Type', 'application/json');
      request.write(jsonEncode(payload));
      final response = await request.close();

      if (response.statusCode != HttpStatus.ok && response.statusCode != HttpStatus.created) {
        throw Exception('Request failed (HTTP ${response.statusCode})');
      }

      final body = await response.transform(utf8.decoder).join();
      final decoded = jsonDecode(body);
      if (decoded is! Map<String, dynamic>) {
        throw Exception('Unexpected response format');
      }
      if (decoded['status'] != 'success') {
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
    final client = HttpClient();
    client.badCertificateCallback = (cert, host, port) => true;
    client.connectionTimeout = const Duration(seconds: 30);

    try {
      final request = await client.getUrl(uri);
      final response = await request.close();

      if (response.statusCode != HttpStatus.ok) {
        throw Exception('Request failed (HTTP ${response.statusCode})');
      }

      final body = await response.transform(utf8.decoder).join();
      final decoded = jsonDecode(body);
      if (decoded is! Map<String, dynamic>) {
        throw Exception('Unexpected response format');
      }
      if (decoded['status'] != 'success') {
        throw Exception(
          decoded['message']?.toString() ?? 'Request failed',
        );
      }
      return decoded;
    } finally {
      client.close(force: true);
    }
  }
}

class PickListDetailsResult {
  final PickListHeader header;
  final List<PickLineModel> items;

  const PickListDetailsResult({required this.header, required this.items});
}

class PickListHeader {
  final int pickListNo;
  final DateTime? pickDate;
  final String status;
  final String customerName;
  final int refDocNum;

  const PickListHeader({
    required this.pickListNo,
    required this.pickDate,
    required this.status,
    required this.customerName,
    required this.refDocNum,
  });

  const PickListHeader.empty()
    : pickListNo = 0,
      pickDate = null,
      status = '',
      customerName = '',
      refDocNum = 0;

  factory PickListHeader.fromJson(Map<String, dynamic> json) {
    final pickDateStr = json['pickDate'] as String?;
    return PickListHeader(
      pickListNo: (json['pickListNo'] as num?)?.toInt() ?? 0,
      pickDate: pickDateStr != null ? DateTime.tryParse(pickDateStr) : null,
      status: (json['status'] as String?) ?? '',
      customerName: (json['customerName'] as String?) ?? '',
      refDocNum: (json['refDocNum'] as num?)?.toInt() ?? 0,
    );
  }
}
