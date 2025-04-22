import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app_state.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/expense_tracking_screen.dart';
import 'screens/budget_goals_screen.dart';
import 'screens/analytics_reports_screen.dart';
import 'screens/profile_screen.dart';

void main() => runApp(
  ChangeNotifierProvider(
    create: (context) => FinancialData(),
    child: const MyApp(),
  ),
);

class MyApp extends StatelessWidget {
  const MyApp({super.key});  // Add const constructor here

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Financial Buddy',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.grey[100],
      ),
      initialRoute: '/login',
      routes: {
        '/login': (context) => LoginScreen(),
        '/home': (context) => HomeScreen(),
        '/profile': (context) => ProfileScreen(),
        '/expense': (context) => ExpenseTrackingScreen(),
        '/budget': (context) => BudgetGoalsScreen(),
        '/analytics': (context) => AnalyticsReportsScreen(),
      },
    );
  }
}