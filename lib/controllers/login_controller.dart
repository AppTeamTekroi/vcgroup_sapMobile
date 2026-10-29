import 'package:get/get.dart';
import '../models/pick_list_model.dart';
import 'package:flutter/material.dart';
class LoginController extends GetxController {
  final userController = TextEditingController();
  final passwordController = TextEditingController();
  
  final isLoading = false.obs;
  final error = Rxn<String>();

  Future<void> login(String username, String password) async {
    try {
      isLoading.value = true;
      error.value = null;

      // Simulate API call
      await Future.delayed(const Duration(seconds: 1));

      // if (username.isEmpty || password.isEmpty) {
      //   error.value = 'Please fill all fields';
      //   return;
      // }

      // Demo: Any credentials work
      Get.offNamed('/inbox');
    } catch (e) {
      error.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    userController.dispose();
    passwordController.dispose();
    super.onClose();
  }
}
//https://117.250.194.177:4300/SalesAPP/XSJS/GetPickListDetails.xsjs?DBName=VCNFPL_LIVE&PickEntry=173

//{
  // "status": "success",
  // "message": "Pick list fetched successfully",
  // "data": {
  //   "header": {
  //     "pickListNo": 173,
  //     "pickDate": "2026-04-29T18:30:00.000Z",
  //     "status": "C",
  //     "customerName": "AARADHYA TRADING COMPANY KOLKATTA",
  //     "refDocNum": 89
  //   },
  //   "items": [
  //     {
  //       "lineNo": 0,
  //       "itemCode": "FG106",
  //       "itemName": "4KIDS CHOCO ROLL(28 DP BOX*30PCS*5RS)",
  //       "allocations": [
  //         {
  //           "bin": "",
  //           "batch": "",
  //           "pickedQty": 0,
  //           "totalQty": 80
  //         }
  //       ]
  //     },
  //     {
  //       "lineNo": 1,
  //       "itemCode": "FG331",
  //       "itemName": "4KIDS 40% CHOCO ROLL(28 DP BOX*30PCS*5RS)",
  //       "allocations": [
  //         {
  //           "bin": "",
  //           "batch": "",
  //           "pickedQty": 20,
  //           "totalQty": 50
  //         }
  //       ]
  //     },
  //     {