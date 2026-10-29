/// App-wide constants
class AppConstants {
  // App Info
  static const String appName = 'Kids4';
  static const String appVersion = '1.0.2';

  static const String listUrl =
      'https://117.250.194.177:4300/SalesAPP/XSJS/GetPickList.xsjs';
  static const String detailsUrl =
      'https://117.250.194.177:4300/SalesAPP/XSJS/GetPickListDetails.xsjs';
  static const String defaultDbName = 'VCNFPL_LIVE';

  static const String baseUrl = 'https://tekai.c360.zone/vc_mobile/public/api';
  static const String updatePickedItem = '/update-picked-items';
  static const String updatePendingSync = '/update-pending-sync';//optional
  static const String deletePendingSync = '/delete-pending-sync';
  static const String pendingSyncDetail = '/pick-list';
  // static const String syncPickedItems = '/retry-sync';
  static const String checkSyncStatus = '/pending-sync'; // get pending sync
  static const String syncAllPending = '/sync-all-pending';
  static const String gateEntry = '/gate-entry';

  static const int connectionTimeout = 30;

  // Strings
  static const String noDataFound = 'No data found';
  static const String error = 'An error occurred';
  static const String loading = 'Loading...';
}
