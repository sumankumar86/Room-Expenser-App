import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../providers/providers.dart';
import '../services/service_locator.dart';
import 'add_expense_screen.dart';
import 'add_user_screen.dart';
import 'expenses_page.dart';
import 'profile_page.dart';
import 'reports_page.dart';
import 'users_page.dart';

class NewHomeScreen extends StatefulWidget {
  const NewHomeScreen({super.key});

  @override
  State<NewHomeScreen> createState() => _NewHomeScreenState();
}

class _NewHomeScreenState extends State<NewHomeScreen> {
  final _serviceLocator = ServiceLocator();
  int _currentIndex = 0;

  // Pages to show in the bottom navigation
  late final List<Widget> _pages;

  // Page titles
  final List<String> _titles = ['Expenses', 'Users', 'Reports', 'Profile'];

  // Icons for the bottom navigation
  final List<IconData> _icons = [
    Icons.receipt_long,
    Icons.people,
    Icons.bar_chart,
    Icons.person,
  ];

  @override
  void initState() {
    super.initState();

    // Initialize pages
    _pages = [
      const ExpensesPage(),
      const UsersPage(),
      const ReportsPage(),
      const ProfilePage(),
    ];

    // Load data when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<UserProvider>(context, listen: false).loadUsers();
      Provider.of<ExpenseProvider>(context, listen: false).loadExpenses();
      Provider.of<SummaryProvider>(context, listen: false).loadMonthlySummary();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(51), // 0.2 * 255 = 51
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.account_balance_wallet,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              _titles[_currentIndex],
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        elevation: 4,
        shadowColor: Colors.teal.shade200,
        actions: [
          // Current user display
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Center(
              child: Text(
                _serviceLocator.currentUser?.name ?? 'User',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            tooltip: 'More options',
            onSelected: (value) {
              if (value == 'change_password') {
                Navigator.pushNamed(context, '/change_password');
              } else if (value == 'logout') {
                _handleLogout();
              }
            },
            itemBuilder:
                (BuildContext context) => <PopupMenuEntry<String>>[
                  const PopupMenuItem<String>(
                    value: 'change_password',
                    child: ListTile(
                      leading: Icon(Icons.password, color: Colors.teal),
                      title: Text('Change Password'),
                    ),
                  ),
                  const PopupMenuItem<String>(
                    value: 'logout',
                    child: ListTile(
                      leading: Icon(Icons.logout, color: Colors.red),
                      title: Text('Logout'),
                    ),
                  ),
                ],
          ),
        ],
      ),
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: Colors.teal,
        unselectedItemColor: Colors.grey,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
        items: List.generate(
          _titles.length,
          (index) => BottomNavigationBarItem(
            icon: Icon(_icons[index]),
            label: _titles[index],
          ),
        ),
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  Widget? _buildFloatingActionButton() {
    final isAdmin = _serviceLocator.currentUser?.isAdmin ?? false;

    // Only show FAB on Expenses and Users (if admin) tabs
    if (_currentIndex == 0) {
      // Expenses tab - anyone can add expenses
      return FloatingActionButton(
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        tooltip: 'Add Expense',
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddExpenseScreen()),
          );
        },
        child: const Icon(Icons.add),
      );
    } else if (_currentIndex == 1 && isAdmin) {
      // Users tab - only admins can add users
      return FloatingActionButton(
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        tooltip: 'Add User',
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddUserScreen()),
          );
        },
        child: const Icon(Icons.add),
      );
    }

    // No FAB for other tabs
    return null;
  }

  Future<void> _handleLogout() async {
    // Show confirmation dialog
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Logout'),
            content: const Text('Are you sure you want to logout?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Logout'),
              ),
            ],
          ),
    );

    if (shouldLogout == true) {
      // Clear token from shared preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('token');

      // Clear current user from service locator
      _serviceLocator.clearCurrentUser();
      debugPrint('User logged out and cleared from service locator');

      // Navigate to login screen
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/login');
    }
  }
}
