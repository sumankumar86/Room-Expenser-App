import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/models.dart';
import '../providers/providers.dart';
import '../services/service_locator.dart';
import 'add_expense_screen.dart';
import 'add_user_screen.dart';
import 'monthly_report_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final DateFormat _dateFormat = DateFormat('MMM dd, yyyy');
  final NumberFormat _currencyFormat = NumberFormat.currency(symbol: '₹');
  final _serviceLocator = ServiceLocator();

  // For date filtering
  DateTime _selectedFilterDate = DateTime.now();
  bool _isFilteringByDate = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Load data when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<UserProvider>(context, listen: false).loadUsers();
      Provider.of<ExpenseProvider>(context, listen: false).loadExpenses();
      Provider.of<SummaryProvider>(context, listen: false).loadMonthlySummary();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
            const Text(
              'Room Expense Tracker',
              style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5),
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
          IconButton(
            icon: const Icon(Icons.calendar_month),
            tooltip: 'Monthly Report',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const MonthlyReportScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.summarize),
            tooltip: 'Summary',
            onPressed: () {
              Navigator.pushNamed(context, '/summary');
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.account_circle),
            tooltip: 'Account',
            onSelected: (value) {
              if (value == 'profile') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ProfileScreen(),
                  ),
                );
              } else if (value == 'change_password') {
                Navigator.pushNamed(context, '/change_password');
              } else if (value == 'logout') {
                _handleLogout();
              }
            },
            itemBuilder:
                (BuildContext context) => <PopupMenuEntry<String>>[
                  const PopupMenuItem<String>(
                    value: 'profile',
                    child: ListTile(
                      leading: Icon(Icons.person, color: Colors.teal),
                      title: Text('Update Profile'),
                    ),
                  ),
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
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Expenses', icon: Icon(Icons.receipt_long)),
            Tab(text: 'Users', icon: Icon(Icons.people)),
          ],
          labelColor: Colors.white,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildExpensesTab(), _buildUsersTab()],
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  Widget _buildFloatingActionButton() {
    final serviceLocator = ServiceLocator();
    final isAdmin = serviceLocator.currentUser?.isAdmin ?? false;

    // If on Users tab and not admin, don't show FAB
    if (_tabController.index == 1 && !isAdmin) {
      return Container(); // Return empty container to hide FAB
    }

    return FloatingActionButton(
      backgroundColor: Colors.teal,
      foregroundColor: Colors.white,
      tooltip: _tabController.index == 0 ? 'Add Expense' : 'Add User',
      onPressed: () {
        if (_tabController.index == 0) {
          // Anyone can add expenses
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddExpenseScreen()),
          );
        } else if (isAdmin) {
          // Only admins can add users
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddUserScreen()),
          );
        }
      },
      child: Icon(
        _tabController.index == 0 ? Icons.add_card : Icons.person_add,
      ),
    );
  }

  Widget _buildExpensesTab() {
    return Consumer2<ExpenseProvider, UserProvider>(
      builder: (context, expenseProvider, userProvider, child) {
        if (expenseProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (expenseProvider.expenses.isEmpty) {
          return const Center(
            child: Text('No expenses yet. Add your first expense!'),
          );
        }

        // Sort expenses by date (newest first)
        final allExpenses = List<Expense>.from(expenseProvider.expenses)
          ..sort((a, b) => b.date.compareTo(a.date));

        // Filter expenses by date if needed
        List<Expense> filteredExpenses = allExpenses;
        if (_isFilteringByDate) {
          final filterDateStr = DateFormat(
            'yyyy-MM-dd',
          ).format(_selectedFilterDate);
          filteredExpenses =
              allExpenses.where((expense) {
                final expenseDateStr = DateFormat(
                  'yyyy-MM-dd',
                ).format(expense.date);
                return expenseDateStr == filterDateStr;
              }).toList();
        }

        // Group expenses by date
        final Map<String, List<Expense>> expensesByDate = {};
        final Map<String, double> totalByDate = {};

        for (var expense in filteredExpenses) {
          final dateKey = DateFormat('yyyy-MM-dd').format(expense.date);

          if (!expensesByDate.containsKey(dateKey)) {
            expensesByDate[dateKey] = [];
            totalByDate[dateKey] = 0;
          }

          expensesByDate[dateKey]!.add(expense);
          totalByDate[dateKey] = (totalByDate[dateKey] ?? 0) + expense.amount;
        }

        // Get sorted date keys
        final dateKeys =
            expensesByDate.keys.toList()..sort((a, b) => b.compareTo(a));

        return Column(
          children: [
            // Date filter bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.teal.shade50,
              child: Row(
                children: [
                  const Icon(Icons.calendar_today, color: Colors.teal),
                  const SizedBox(width: 8),
                  Text(
                    _isFilteringByDate
                        ? 'Showing expenses for: ${DateFormat('MMM dd, yyyy').format(_selectedFilterDate)}'
                        : 'Showing all expenses',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  // Clear filter button
                  if (_isFilteringByDate)
                    IconButton(
                      icon: const Icon(Icons.clear, color: Colors.red),
                      onPressed: () {
                        setState(() {
                          _isFilteringByDate = false;
                        });
                      },
                      tooltip: 'Clear filter',
                    ),
                  // Date filter button
                  IconButton(
                    icon: const Icon(Icons.filter_list, color: Colors.teal),
                    onPressed: () async {
                      // Get current date without time component
                      final now = DateTime.now();
                      final today = DateTime(now.year, now.month, now.day);

                      // Ensure initialDate is not in the future
                      final initialDate =
                          _selectedFilterDate.isAfter(today)
                              ? today
                              : _selectedFilterDate;

                      final DateTime? pickedDate = await showDatePicker(
                        context: context,
                        initialDate: initialDate,
                        firstDate: DateTime(2020),
                        lastDate: today, // Restrict to today or earlier
                        builder: (context, child) {
                          return Theme(
                            data: Theme.of(context).copyWith(
                              colorScheme: const ColorScheme.light(
                                primary: Colors.teal,
                                onPrimary: Colors.white,
                                onSurface: Colors.black,
                              ),
                            ),
                            child: child!,
                          );
                        },
                      );

                      if (pickedDate != null) {
                        setState(() {
                          _selectedFilterDate = pickedDate;
                          _isFilteringByDate = true;
                        });
                      }
                    },
                    tooltip: 'Filter by date',
                  ),
                ],
              ),
            ),

            // Expense list
            Expanded(
              child: ListView.builder(
                itemCount: dateKeys.length,
                itemBuilder: (context, index) {
                  final dateKey = dateKeys[index];
                  final expenses = expensesByDate[dateKey]!;
                  final dateTotal = totalByDate[dateKey]!;

                  // Group expenses by user for this date
                  final Map<dynamic, List<Expense>> expensesByUser = {};
                  final Map<dynamic, double> totalByUser = {};

                  for (var expense in expenses) {
                    if (!expensesByUser.containsKey(expense.userId)) {
                      expensesByUser[expense.userId] = [];
                      totalByUser[expense.userId] = 0;
                    }

                    expensesByUser[expense.userId]!.add(expense);
                    totalByUser[expense.userId] =
                        (totalByUser[expense.userId] ?? 0) + expense.amount;
                  }

                  // Parse the date from the key
                  final date = DateTime.parse(dateKey);

                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    elevation: 2,
                    child: Column(
                      children: [
                        // Date header with total
                        Container(
                          padding: const EdgeInsets.all(12),
                          color: Colors.teal.shade100,
                          child: Row(
                            children: [
                              Text(
                                DateFormat('EEEE, MMM dd, yyyy').format(date),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                'Total: ${_currencyFormat.format(dateTotal)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // User summaries with expandable details
                        ...expensesByUser.keys.map((userId) {
                          final userExpenses = expensesByUser[userId]!;
                          final userTotal = totalByUser[userId]!;
                          final user = userProvider.users.firstWhere(
                            (u) => u.id == userId,
                            orElse: () => User(name: 'Unknown'),
                          );

                          return ExpansionTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.teal.shade50,
                              child: Text(
                                user.name.substring(0, 1).toUpperCase(),
                              ),
                            ),
                            title: Text(user.name),
                            subtitle: Text('${userExpenses.length} expense(s)'),
                            trailing: Text(
                              _currencyFormat.format(userTotal),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            children:
                                userExpenses.map((expense) {
                                  final currentUserId =
                                      _serviceLocator.currentUser?.id;
                                  final isAdmin =
                                      _serviceLocator.currentUser?.isAdmin ??
                                      false;
                                  final canEdit =
                                      isAdmin ||
                                      expense.createdBy == currentUserId;

                                  return Slidable(
                                    endActionPane:
                                        canEdit
                                            ? ActionPane(
                                              motion: const ScrollMotion(),
                                              children: [
                                                SlidableAction(
                                                  onPressed: (context) {
                                                    Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                        builder:
                                                            (context) =>
                                                                AddExpenseScreen(
                                                                  expense:
                                                                      expense,
                                                                ),
                                                      ),
                                                    );
                                                  },
                                                  backgroundColor: Colors.blue,
                                                  foregroundColor: Colors.white,
                                                  icon: Icons.edit,
                                                  label: 'Edit',
                                                ),
                                                SlidableAction(
                                                  onPressed: (context) {
                                                    if (expense.id != null) {
                                                      expenseProvider
                                                          .deleteExpense(
                                                            expense.id!,
                                                          );
                                                    }
                                                  },
                                                  backgroundColor: Colors.red,
                                                  foregroundColor: Colors.white,
                                                  icon: Icons.delete,
                                                  label: 'Delete',
                                                ),
                                              ],
                                            )
                                            : null,
                                    child: ListTile(
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 24,
                                          ),
                                      title: Text(expense.description),
                                      subtitle: Text(
                                        _dateFormat.format(expense.date),
                                      ),
                                      trailing: Text(
                                        _currencyFormat.format(expense.amount),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                          );
                        }),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
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
      final serviceLocator = ServiceLocator();
      serviceLocator.clearCurrentUser();
      debugPrint('User logged out and cleared from service locator');

      // Navigate to login screen
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  Widget _buildUsersTab() {
    final serviceLocator = ServiceLocator();
    final isAdmin = serviceLocator.currentUser?.isAdmin ?? false;

    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        if (userProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (userProvider.users.isEmpty) {
          return Center(
            child: Text(
              isAdmin
                  ? 'No users yet. Add your first user!'
                  : 'No users available.',
            ),
          );
        }

        return ListView.builder(
          itemCount: userProvider.users.length,
          itemBuilder: (context, index) {
            final user = userProvider.users[index];

            // Only allow admin to use slidable actions
            if (isAdmin) {
              return Slidable(
                endActionPane: ActionPane(
                  motion: const ScrollMotion(),
                  children: [
                    SlidableAction(
                      onPressed: (context) {
                        if (user.id != null) {
                          userProvider.deleteUser(user.id!);
                        }
                      },
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      icon: Icons.delete,
                      label: 'Delete',
                    ),
                  ],
                ),
                child: _buildUserListTile(user),
              );
            } else {
              // Regular users just see the list without slidable actions
              return _buildUserListTile(user);
            }
          },
        );
      },
    );
  }

  // Helper method to build user list tile
  Widget _buildUserListTile(User user) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Colors.teal.shade100,
        child: Text(user.name.substring(0, 1).toUpperCase()),
      ),
      title: Text(user.name + (user.isAdmin ? ' (Admin)' : '')),
      subtitle: Text(user.email ?? 'No email'),
      trailing: user.phoneNumber != null ? Text(user.phoneNumber!) : null,
    );
  }
}
