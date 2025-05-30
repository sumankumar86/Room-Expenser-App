import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../providers/providers.dart';
import '../screens/screens.dart';
import '../services/api_client.dart';
import '../services/service_locator.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize API client
  final apiClient = ApiClient();
  await apiClient.init();

  // Set API mode (mock or real)
  final serviceLocator = ServiceLocator();
  serviceLocator.setApiMode(ApiMode.real); // Use real API

  // Check if user is logged in
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('token');

  runApp(MyApp(isLoggedIn: token != null));
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;

  const MyApp({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => ExpenseProvider()),
        ChangeNotifierProvider(create: (_) => SummaryProvider()),
      ],
      child: MaterialApp(
        title: 'Room Expense Tracker',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
          useMaterial3: true,
          appBarTheme: const AppBarTheme(centerTitle: true),
          inputDecorationTheme: InputDecorationTheme(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
        ),
        initialRoute: isLoggedIn ? '/home' : '/login',
        routes: {
          '/login': (context) => const LoginScreen(),
          '/home':
              (context) =>
                  const NewHomeScreen(), // Use the new home screen with bottom navigation
          '/add_user': (context) => const AddUserScreen(),
          '/add_expense': (context) => const AddExpenseScreen(),
          '/monthly_report': (context) => const MonthlyReportScreen(),
          '/summary': (context) => const SummaryScreen(),
          '/change_password': (context) => const ChangePasswordScreen(),
        },
      ),
    );
  }
}
