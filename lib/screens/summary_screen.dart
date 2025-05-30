import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../providers/providers.dart';
import '../services/service_locator.dart';

class SummaryScreen extends StatefulWidget {
  const SummaryScreen({super.key});

  @override
  State<SummaryScreen> createState() => _SummaryScreenState();
}

class _SummaryScreenState extends State<SummaryScreen> {
  final _serviceLocator = ServiceLocator();
  bool _isLoading = false;
  String? _errorMessage;

  // Default to current month and year
  late int _selectedMonth;
  late int _selectedYear;
  dynamic _selectedUserId; // null means show all users

  @override
  void initState() {
    super.initState();

    // Set current month and year
    final now = DateTime.now();
    _selectedMonth = now.month;
    _selectedYear = now.year;

    // Load summary for current month
    _loadSummary();
  }

  Future<void> _loadSummary() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final summaryProvider = Provider.of<SummaryProvider>(
        context,
        listen: false,
      );
      await summaryProvider.loadMonthlySummary(_selectedMonth, _selectedYear);
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Expense Summary'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month),
            onPressed: _showMonthYearPicker,
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showUserFilter,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Error: $_errorMessage',
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _loadSummary, child: const Text('Retry')),
          ],
        ),
      );
    }

    return Consumer<SummaryProvider>(
      builder: (context, summaryProvider, child) {
        final summary = summaryProvider.currentSummary;

        if (summary == null) {
          return const Center(
            child: Text('No summary data available for selected month'),
          );
        }

        return _buildSummaryContent(summary);
      },
    );
  }

  Widget _buildSummaryContent(MonthlySummary summary) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildMonthYearHeader(),
          const SizedBox(height: 24),
          _buildSummaryCard(summary),
          const SizedBox(height: 24),
          _buildUserExpensesList(summary),
        ],
      ),
    );
  }

  Widget _buildMonthYearHeader() {
    final monthNames = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    return Center(
      child: Text(
        '${monthNames[_selectedMonth - 1]} $_selectedYear',
        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildSummaryCard(MonthlySummary summary) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Summary',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            _buildSummaryRow(
              'Total Expenses',
              '₹${summary.totalAmount.toStringAsFixed(2)}',
            ),
            _buildSummaryRow('Number of Users', '${summary.userCount}'),
            _buildSummaryRow(
              'Per Head Amount',
              '₹${summary.perHeadAmount.toStringAsFixed(2)}',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 16)),
          Text(
            value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildUserExpensesList(MonthlySummary summary) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        final users = userProvider.users;

        if (users.isEmpty) {
          return const Center(child: Text('No user data available'));
        }

        // Filter by selected user if needed
        if (_selectedUserId != null) {
          final filteredUsers =
              users.where((user) => user.id == _selectedUserId).toList();
          if (filteredUsers.isNotEmpty) {
            return _buildUserExpensesListContent(filteredUsers, summary);
          }
        }

        return _buildUserExpensesListContent(users, summary);
      },
    );
  }

  Widget _buildUserExpensesListContent(
    List<User> users,
    MonthlySummary summary,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'User Expenses',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: users.length,
          itemBuilder: (context, index) {
            final user = users[index];
            final userId = user.id;
            final spent =
                userId != null ? summary.userExpenses[userId] ?? 0.0 : 0.0;
            final balance = summary.perHeadAmount - spent;

            return Card(
              margin: const EdgeInsets.symmetric(vertical: 4),
              child: ListTile(
                title: Text(user.name),
                subtitle: Text('Spent: ₹${spent.toStringAsFixed(2)}'),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      balance >= 0
                          ? 'To Pay: ₹${balance.toStringAsFixed(2)}'
                          : 'To Receive: ₹${(-balance).toStringAsFixed(2)}',
                      style: TextStyle(
                        color: balance >= 0 ? Colors.red : Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  void _showMonthYearPicker() async {
    // Show month picker
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(_selectedYear, _selectedMonth),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      initialDatePickerMode: DatePickerMode.year,
    );

    if (picked != null) {
      setState(() {
        _selectedMonth = picked.month;
        _selectedYear = picked.year;
      });

      _loadSummary();
    }
  }

  void _showUserFilter() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final users = userProvider.users;

    if (users.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No users available to filter')),
      );
      return;
    }

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Filter by User'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView(
              shrinkWrap: true,
              children: [
                ListTile(
                  title: const Text('All Users'),
                  selected: _selectedUserId == null,
                  onTap: () {
                    setState(() {
                      _selectedUserId = null;
                    });
                    Navigator.pop(context);
                  },
                ),
                ...users.map(
                  (user) => ListTile(
                    title: Text(user.name),
                    selected: _selectedUserId == user.id,
                    onTap: () {
                      setState(() {
                        _selectedUserId = user.id;
                      });
                      Navigator.pop(context);
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    // Refresh the UI
    setState(() {});
  }
}
