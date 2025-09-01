import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:productivity_planning_app/providers/plan_provider.dart';
import 'package:productivity_planning_app/screens/home_screen.dart';
import 'package:productivity_planning_app/utils/app_theme.dart';
import 'package:productivity_planning_app/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize notification service
  final notificationService = NotificationService();
  await notificationService.initialize();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => PlanProvider(),
      child: MaterialApp(
        title: 'hrghrgh',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        home: const HomeScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
