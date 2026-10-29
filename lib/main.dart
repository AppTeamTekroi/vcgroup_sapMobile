import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kids4/screens/gateIn_screen.dart';
import 'ui/themes/app_theme.dart';
import 'screens/login_screen.dart';
import 'screens/inbox_screen.dart';
import 'screens/detail_screen.dart';
import 'screens/scanner_screen.dart';
import 'screens/success_screen.dart';
import 'screens/qr_gen_screen.dart';
import 'screens/pending_sync_detail_screen.dart';
import 'bindings/app_bindings.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Kids4 · Pick & Scan',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light,
      initialRoute: '/login',
      getPages: [
        GetPage(
          name: '/login',
          page: () => const LoginScreen(),
          binding: LoginBinding(),
        ),
        GetPage(
          name: '/inbox',
          page: () => const InboxScreen(),
          binding: InboxBinding(),
        ),
        GetPage(
          name: '/detail',
          page: () => const DetailScreen(),
          binding: DetailBinding(),
        ),
        GetPage(
          name: '/scanner',
          page: () => const ScannerScreen(),
          binding: ScannerBinding(),
        ),
        GetPage(
          name: '/qr-gen',
          page: () => const QRGenScreen(),
          binding: QRGenBinding(),
        ),
        GetPage(
          name: '/gate-in',
          page: () => const GateInScreen(),
          binding: GateInBinding(),
        ),
        GetPage(name: '/success', page: () => const SuccessScreen()),
        GetPage(
          name: '/pending-sync-detail',
          page: () => const PendingSyncDetailScreen(),
          binding: PendingSyncDetailBinding(),
        ),
      ],
    );
  }
}
