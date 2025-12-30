import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'core/services/arri_service.dart';
import 'features/dashboard/screens/dashboard_screen.dart';
import 'features/dashboard/controllers/dashboard_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initServices();
  runApp(const AdminApp());
}

Future<void> initServices() async {
  await Get.putAsync(() => ArriService().init());
}

class AdminApp extends StatelessWidget {
  const AdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Vyom Admin Panel',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      initialBinding: BindingsBuilder(() {
        Get.put(DashboardController());
      }),
      home: const DashboardScreen(),
    );
  }
}
