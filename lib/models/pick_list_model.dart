class PickListModel {
  final int absEntry;
  final String docNum;
  final String customer;
  final String ref;
  final String whs;
  final String status;
  final List<PickLineModel> lines;

  // Fields populated from the GetPickList API list endpoint.
  final int pickListNo;
  final DateTime? pickDate;
  final int picker;
  final int refDocNum;
  final int docEntry;
  final int totalLines;
  final int totalPickedQty;
  final int totalQty;
  final String uiStatus;
  final double progressPercent;

  PickListModel({
    required this.absEntry,
    required this.docNum,
    required this.customer,
    required this.ref,
    required this.whs,
    required this.status,
    required this.lines,
    this.pickListNo = 0,
    this.pickDate,
    this.picker = 0,
    this.refDocNum = 0,
    this.docEntry = 0,
    this.totalLines = 0,
    this.totalPickedQty = 0,
    this.totalQty = 0,
    this.uiStatus = '',
    this.progressPercent = 0.0,
  });

  factory PickListModel.fromJson(Map<String, dynamic> json) {
    final pickListNo = (json['pickListNo'] as num?)?.toInt() ?? 0;
    final docEntry = (json['docEntry'] as num?)?.toInt() ?? 0;
    final refDocNum = (json['refDocNum'] as num?)?.toInt() ?? 0;
    final pickDateStr = json['pickDate'] as String?;
    final uiStatus = (json['uiStatus'] as String?) ?? '';

    return PickListModel(
      absEntry: docEntry,
      docNum: 'PL-$pickListNo',
      customer: (json['customerName'] as String?) ?? '',
      ref: refDocNum > 0 ? 'SO-$refDocNum' : '',
      whs: '',
      status: _normalizeStatus(uiStatus),
      lines: const [],
      pickListNo: pickListNo,
      pickDate: pickDateStr != null ? DateTime.tryParse(pickDateStr) : null,
      picker: (json['picker'] as num?)?.toInt() ?? 0,
      refDocNum: refDocNum,
      docEntry: docEntry,
      totalLines: (json['totalLines'] as num?)?.toInt() ?? 0,
      totalPickedQty: (json['pickedQty'] as num?)?.toInt() ?? 0,
      totalQty: (json['totalQty'] as num?)?.toInt() ?? 0,
      uiStatus: uiStatus,
      progressPercent: (json['progress'] as num?)?.toDouble() ?? 0.0,
    );
  }

  PickListModel copyWith({
    int? absEntry,
    String? docNum,
    String? customer,
    String? ref,
    String? whs,
    String? status,
    List<PickLineModel>? lines,
    int? pickListNo,
    DateTime? pickDate,
    int? picker,
    int? refDocNum,
    int? docEntry,
    int? totalLines,
    int? totalPickedQty,
    int? totalQty,
    String? uiStatus,
    double? progressPercent,
  }) {
    return PickListModel(
      absEntry: absEntry ?? this.absEntry,
      docNum: docNum ?? this.docNum,
      customer: customer ?? this.customer,
      ref: ref ?? this.ref,
      whs: whs ?? this.whs,
      status: status ?? this.status,
      lines: lines ?? this.lines,
      pickListNo: pickListNo ?? this.pickListNo,
      pickDate: pickDate ?? this.pickDate,
      picker: picker ?? this.picker,
      refDocNum: refDocNum ?? this.refDocNum,
      docEntry: docEntry ?? this.docEntry,
      totalLines: totalLines ?? this.totalLines,
      totalPickedQty: totalPickedQty ?? this.totalPickedQty,
      totalQty: totalQty ?? this.totalQty,
      uiStatus: uiStatus ?? this.uiStatus,
      progressPercent: progressPercent ?? this.progressPercent,
    );
  }

  static String _normalizeStatus(String uiStatus) {
    switch (uiStatus.toUpperCase()) {
      case 'PARTIAL':
        return 'partial';
      case 'CLOSED':
        return 'closed';
      case 'OPEN':
      default:
        return 'open';
    }
  }
}

class PickLineModel {
  final int lineNum;
  final String itemCode;
  final String itemName;
  final String whs;
  int relQty;
  final bool manageBatch;
  int pickedQty;
  final List<ScanResult> scans;
  final List<AllocationModel> allocations;

  PickLineModel({
    required this.lineNum,
    required this.itemCode,
    required this.itemName,
    required this.whs,
    required this.relQty,
    required this.pickedQty,
    this.manageBatch = false,
    List<ScanResult>? scans,
    List<AllocationModel>? allocations,
  }) : scans = scans ?? <ScanResult>[],
       allocations = allocations ?? <AllocationModel>[];

  String get batch {
    final scanned = scans
        .map((s) => s.batch)
        .whereType<String>()
        .where((b) => b.isNotEmpty)
        .toSet();
    if (scanned.isNotEmpty) return scanned.join(', ');
    final allocated = allocations
        .map((a) => a.batch)
        .where((b) => b.isNotEmpty)
        .toSet();
    return allocated.join(', ');
  }

  Map<String, int> get batchQuantities {
    final map = <String, int>{};
    for (final s in scans) {
      final b = s.batch;
      if (b == null || b.isEmpty) continue;
      map[b] = (map[b] ?? 0) + 1;
    }
    return map;
  }

  factory PickLineModel.fromJson(Map<String, dynamic> json) {
    final rawAllocs = json['allocations'];
    final allocations = (rawAllocs is List)
        ? rawAllocs
              .whereType<Map<String, dynamic>>()
              .map(AllocationModel.fromJson)
              .toList()
        : <AllocationModel>[];

    final relQty = allocations.fold<int>(0, (sum, a) => sum + a.totalQty);
    final pickedQty = allocations.fold<int>(0, (sum, a) => sum + a.pickedQty);
    final firstBin = allocations.isNotEmpty ? allocations.first.bin : '';
    final hasBatch = allocations.any((a) => a.batch.isNotEmpty);

    return PickLineModel(
      lineNum: (json['lineNo'] as num?)?.toInt() ?? 0,
      itemCode: (json['itemCode'] as String?) ?? '',
      itemName: (json['itemName'] as String?) ?? '',
      whs: firstBin,
      relQty: relQty,
      pickedQty: pickedQty,
      manageBatch: hasBatch,
      allocations: allocations,
    );
  }
}

class AllocationModel {
  final String bin;
  final String batch;
  final int pickedQty;
  final int totalQty;

  const AllocationModel({
    required this.bin,
    required this.batch,
    required this.pickedQty,
    required this.totalQty,
  });

  factory AllocationModel.fromJson(Map<String, dynamic> json) {
    return AllocationModel(
      bin: (json['bin'] as String?) ?? '',
      batch: (json['batch'] as String?) ?? '',
      pickedQty: (json['pickedQty'] as num?)?.toInt() ?? 0,
      totalQty: (json['totalQty'] as num?)?.toInt() ?? 0,
    );
  }
}

class ScanResult {
  final String itemCode;
  final String? batch;
  final String? serial;
  final String? mfg;
  final String? exp;
  final String raw;

  ScanResult({
    required this.itemCode,
    this.batch,
    this.serial,
    this.mfg,
    this.exp,
    required this.raw,
  });
}
