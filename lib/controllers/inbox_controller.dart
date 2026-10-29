import 'package:get/get.dart';
import '../data/repositories/pick_list_repository.dart';
import '../models/pick_list_model.dart';

class InboxController extends GetxController {
  final PickListRepository _repository;

  InboxController({PickListRepository? repository})
    : _repository = repository ?? const PickListRepository();

  final pickLists = <PickListModel>[].obs;
  final isLoading = false.obs;
  final error = Rxn<String>();
  final selectedPickList = Rxn<PickListModel>();
  final searchQuery = ''.obs;

  List<PickListModel> get filteredPickLists {
    final q = searchQuery.value.trim().toLowerCase();
    if (q.isEmpty) return pickLists;
    return pickLists.where((pl) {
      return pl.docNum.toLowerCase().contains(q) ||
          pl.customer.toLowerCase().contains(q) ||
          pl.ref.toLowerCase().contains(q);
    }).toList();
  }

  void setSearchQuery(String value) {
    searchQuery.value = value;
  }

  @override
  void onInit() {
    super.onInit();
    fetchPickLists();
  }

  Future<void> fetchPickLists() async {
    try {
      isLoading.value = true;
      error.value = null;

      final lists = await _repository.fetchPickLists();
      pickLists.assignAll(lists);
    } catch (e) {
      error.value = e.toString();
      pickLists.clear();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> refreshPickLists() => fetchPickLists();

  void selectPickList(PickListModel pl) {
    selectedPickList.value = pl;
  }

  int getTotalPicked(PickListModel pl) {
    if (pl.lines.isEmpty) return pl.totalPickedQty;
    return pl.lines.fold<int>(0, (sum, line) => sum + line.pickedQty);
  }

  int getTotalRequired(PickListModel pl) {
    if (pl.lines.isEmpty) return pl.totalQty;
    return pl.lines.fold<int>(0, (sum, line) => sum + line.relQty);
  }

  int getLineCount(PickListModel pl) {
    if (pl.lines.isEmpty) return pl.totalLines;
    return pl.lines.length;
  }

  double getProgress(PickListModel pl) {
    if (pl.lines.isEmpty) {
      return (pl.progressPercent / 100.0).clamp(0.0, 1.0);
    }
    final total = getTotalRequired(pl);
    if (total == 0) return 0.0;
    return getTotalPicked(pl) / total;
  }
}
