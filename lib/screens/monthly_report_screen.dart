import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../providers/providers.dart';

class MonthlyReportScreen extends StatefulWidget {
  const MonthlyReportScreen({super.key});

  @override
  State<MonthlyReportScreen> createState() => _MonthlyReportScreenState();
}

class _MonthlyReportScreenState extends State<MonthlyReportScreen> {
  final DateFormat _monthYearFormat = DateFormat('MMMM yyyy');
  final NumberFormat _currencyFormat = NumberFormat.currency(symbol: '₹');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<SummaryProvider>(context, listen: false).loadMonthlySummary();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Monthly Report'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: Consumer2<SummaryProvider, UserProvider>(
        builder: (context, summaryProvider, userProvider, child) {
          if (summaryProvider.isLoading || userProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          // Show error message if there is one
          if (summaryProvider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, color: Colors.red, size: 48),
                  SizedBox(height: 16),
                  Text(
                    summaryProvider.error!,
                    style: TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          final summary = summaryProvider.currentSummary;
          if (summary == null) {
            return const Center(
              child: Text('No data available for this month'),
            );
          }

          final DateTime currentMonth = DateTime(
            summaryProvider.currentYear,
            summaryProvider.currentMonth,
          );

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios),
                      onPressed: () {
                        summaryProvider.previousMonth();
                      },
                    ),
                    Text(
                      _monthYearFormat.format(currentMonth),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.arrow_forward_ios),
                      onPressed:
                          _isCurrentMonth(summaryProvider)
                              ? null // Disable button if already at current month
                              : () {
                                summaryProvider.nextMonth();
                              },
                      // Show disabled color when at current month
                      color:
                          _isCurrentMonth(summaryProvider)
                              ? Colors.grey.shade400
                              : null,
                    ),
                  ],
                ),
              ),
              _buildSummaryCard(summary),
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'User Expenses',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              Expanded(child: _buildUserExpensesList(summary, userProvider)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSummaryCard(summary) {
    return Card(
      margin: const EdgeInsets.all(16.0),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildSummaryRow(
              'Total Expenses',
              _currencyFormat.format(summary.totalAmount),
              Colors.red,
            ),
            const Divider(),
            _buildSummaryRow(
              'Number of Users',
              summary.userCount.toString(),
              Colors.blue,
            ),
            const Divider(),
            _buildSummaryRow(
              'Per Head Amount',
              _currencyFormat.format(summary.perHeadAmount),
              Colors.green,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, Color valueColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }

  // Check if the displayed month is the current month
  bool _isCurrentMonth(SummaryProvider provider) {
    final now = DateTime.now();
    return provider.currentMonth == now.month &&
        provider.currentYear == now.year;
  }

  Widget _buildUserExpensesList(summary, userProvider) {
    return ListView.builder(
      itemCount: summary.userExpenses.length,
      itemBuilder: (context, index) {
        final userId = summary.userExpenses.keys.elementAt(index);
        final userAmount = summary.userExpenses[userId] ?? 0.0;

        final user = userProvider.users.firstWhere(
          (u) => u.id == userId,
          orElse: () => User(name: 'Unknown'),
        );

        final balance = userAmount - summary.perHeadAmount;
        final isPositive = balance >= 0;

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.teal.shade100,
              child: Text(user.name.substring(0, 1).toUpperCase()),
            ),
            title: Text(user.name),
            subtitle: Text('Spent: ${_currencyFormat.format(userAmount)}'),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  isPositive ? 'To Receive' : 'To Pay',
                  style: TextStyle(
                    fontSize: 12,
                    color: isPositive ? Colors.green : Colors.red,
                  ),
                ),
                Text(
                  _currencyFormat.format(balance.abs()),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isPositive ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
