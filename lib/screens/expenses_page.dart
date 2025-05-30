import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../providers/providers.dart';
import '../services/service_locator.dart';
import 'add_expense_screen.dart';

class ExpensesPage extends StatefulWidget {
  const ExpensesPage({super.key});

  @override
  State<ExpensesPage> createState() => _ExpensesPageState();
}

class _ExpensesPageState extends State<ExpensesPage> {
  final DateFormat _dateFormat = DateFormat('MMM dd, yyyy');
  final NumberFormat _currencyFormat = NumberFormat.currency(symbol: '₹');
  final _serviceLocator = ServiceLocator();

  // For date filtering
  DateTime _selectedFilterDate = DateTime.now();
  bool _isFilteringByDate = false;

  @override
  Widget build(BuildContext context) {
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
              child:
                  dateKeys.isEmpty
                      ? const Center(
                        child: Text('No expenses found for the selected date'),
                      )
                      : ListView.builder(
                        itemCount: dateKeys.length,
                        itemBuilder: (context, index) {
                          return _buildDateExpenseCard(
                            dateKeys[index],
                            expensesByDate,
                            totalByDate,
                            userProvider,
                            expenseProvider,
                          );
                        },
                      ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDateExpenseCard(
    String dateKey,
    Map<String, List<Expense>> expensesByDate,
    Map<String, double> totalByDate,
    UserProvider userProvider,
    ExpenseProvider expenseProvider,
  ) {
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
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
            return _buildUserExpansionTile(
              userId,
              expensesByUser,
              totalByUser,
              userProvider,
              expenseProvider,
            );
          }),
        ],
      ),
    );
  }

  Widget _buildUserExpansionTile(
    dynamic userId,
    Map<dynamic, List<Expense>> expensesByUser,
    Map<dynamic, double> totalByUser,
    UserProvider userProvider,
    ExpenseProvider expenseProvider,
  ) {
    final userExpenses = expensesByUser[userId]!;
    final userTotal = totalByUser[userId]!;
    final user = userProvider.users.firstWhere(
      (u) => u.id == userId,
      orElse: () => User(name: 'Unknown'),
    );

    return ExpansionTile(
      leading: CircleAvatar(
        backgroundColor: Colors.teal.shade50,
        child: Text(user.name.substring(0, 1).toUpperCase()),
      ),
      title: Text(user.name),
      subtitle: Text('${userExpenses.length} expense(s)'),
      trailing: Text(
        _currencyFormat.format(userTotal),
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      ),
      children:
          userExpenses.map((expense) {
            final currentUserId = _serviceLocator.currentUser?.id;
            final isAdmin = _serviceLocator.currentUser?.isAdmin ?? false;
            final canEdit = isAdmin || expense.createdBy == currentUserId;

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
                                          AddExpenseScreen(expense: expense),
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
                                expenseProvider.deleteExpense(expense.id!);
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
                contentPadding: const EdgeInsets.symmetric(horizontal: 24),
                title: Text(expense.description),
                subtitle: Text(_dateFormat.format(expense.date)),
                trailing: Text(
                  _currencyFormat.format(expense.amount),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            );
          }).toList(),
    );
  }
}
