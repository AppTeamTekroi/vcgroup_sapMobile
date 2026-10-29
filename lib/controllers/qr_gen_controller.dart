import 'package:get/get.dart';
import '../data/qr_parser.dart';
import '../models/pick_list_model.dart';

class QRTestItem {
  final PickListModel pickList;
  final PickLineModel line;
  final int unitIndex;
  final int unitCount;
  final String payload;

  QRTestItem({
    required this.pickList,
    required this.line,
    required this.unitIndex,
    required this.unitCount,
    required this.payload,
  });
}

class QRGenController extends GetxController {
  PickListModel? targetPickList;
  final pickLists = <PickListModel>[].obs;
  final items = <QRTestItem>[].obs;
  final showInvalidSamples = false.obs;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args is PickListModel) {
      targetPickList = args;
      pickLists.value = [args];
      showInvalidSamples.value = false;
    } else if (args is List<PickListModel>) {
      pickLists.value = args;
      showInvalidSamples.value = true;
    } else if (args is Map && args['pickLists'] is List<PickListModel>) {
      pickLists.value = args['pickLists'] as List<PickListModel>;
      showInvalidSamples.value = true;
    }
    _build();
  }

  void _build() {
    final out = <QRTestItem>[];
    for (final pl in pickLists) {
      for (final line in pl.lines) {
        final remaining = line.relQty - line.pickedQty;
        if (remaining <= 0) continue;
        for (var i = 1; i <= remaining; i++) {
          final batch = line.manageBatch
              ? 'B26-${pl.absEntry}-${line.lineNum}'
              : null;
          final serial = line.manageBatch
              ? 'U${i.toString().padLeft(3, '0')}'
              : '${pl.absEntry}-${line.lineNum}-${i.toString().padLeft(3, '0')}';
          final payload = buildQRPayload(
            itemCode: line.itemCode,
            batch: batch,
            serial: serial,
          );
          out.add(QRTestItem(
            pickList: pl,
            line: line,
            unitIndex: i,
            unitCount: remaining,
            payload: payload,
          ));
        }
      }
    }
    items.value = out;
  }

  String get title => targetPickList != null
      ? 'Test QRs · ${targetPickList!.docNum}'
      : 'Test QR Codes';
}
