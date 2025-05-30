import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../providers/providers.dart';
import '../services/service_locator.dart';

class AddExpenseScreen extends StatefulWidget {
  final Expense? expense;

  const AddExpenseScreen({super.key, this.expense});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  final _dateController = TextEditingController();
  final _serviceLocator = ServiceLocator();

  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();

    // If editing an existing expense, use its values
    if (widget.expense != null) {
      _descriptionController.text = widget.expense!.description;
      _amountController.text = widget.expense!.amount.toString();
      _selectedDate = widget.expense!.date;
    } else {
      // For new expense, log the current user
      final currentUser = _serviceLocator.currentUser;
      if (currentUser != null) {
        debugPrint('Current user: ${currentUser.name} (ID: ${currentUser.id})');
      }
    }

    _dateController.text = DateFormat('MMM dd, yyyy').format(_selectedDate);
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    // Get current date without time component
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Ensure initialDate is not in the future
    final initialDate = _selectedDate.isAfter(today) ? today : _selectedDate;

    final DateTime? picked = await showDatePicker(
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

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _dateController.text = DateFormat('MMM dd, yyyy').format(_selectedDate);
      });
    }
  }

  Future<void> _saveExpense() async {
    if (_formKey.currentState!.validate()) {
      final expenseProvider = Provider.of<ExpenseProvider>(
        context,
        listen: false,
      );

      // For new expenses, always use the logged-in user
      // For editing, use the existing user ID
      final currentUser = _serviceLocator.currentUser;
      if (currentUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error: No logged-in user found'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // If creating a new expense, use the current user's ID
      // If editing, keep the original user ID
      final userId =
          widget.expense == null ? currentUser.id : widget.expense!.userId;

      final expense = Expense(
        id: widget.expense?.id,
        userId: userId,
        description: _descriptionController.text.trim(),
        amount: double.parse(_amountController.text.trim()),
        date: _selectedDate,
        createdBy: widget.expense?.createdBy ?? currentUser.id,
      );

      bool success = false;
      if (widget.expense == null) {
        // Adding new expense
        success = await expenseProvider.addExpense(expense);

        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Expense added successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        // Updating existing expense - check if current user is the creator
        final currentUserId = _serviceLocator.currentUser?.id;
        final isAdmin = _serviceLocator.currentUser?.isAdmin ?? false;

        if (isAdmin || expense.createdBy == currentUserId) {
          success = await expenseProvider.updateExpense(expense);

          if (success && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Expense updated successfully'),
                backgroundColor: Colors.green,
              ),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('You can only edit expenses you created'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }
      }

      if (success && mounted) {
        Navigator.pop(context);
      } else if (mounted && expenseProvider.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${expenseProvider.error}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.expense == null ? 'Add Expense' : 'Edit Expense'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: Consumer<UserProvider>(
        builder: (context, userProvider, child) {
          if (userProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (userProvider.users.isEmpty) {
            return const Center(
              child: Text('Please add users first before adding expenses'),
            );
          }

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // For new expenses, always use the logged-in user
                  // For editing, show the user the expense belongs to
                  TextFormField(
                    initialValue:
                        widget.expense != null
                            ? userProvider.users
                                .firstWhere(
                                  (u) => u.id == widget.expense!.userId,
                                  orElse: () => User(name: 'Unknown'),
                                )
                                .name
                            : _serviceLocator.currentUser?.name ??
                                'Current User',
                    decoration: const InputDecoration(
                      labelText: 'User',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person),
                    ),
                    readOnly: true,
                    enabled: false,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.description),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter a description';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _amountController,
                    decoration: const InputDecoration(
                      labelText: 'Amount',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.currency_rupee),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter an amount';
                      }
                      if (double.tryParse(value) == null) {
                        return 'Please enter a valid number';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _dateController,
                    decoration: const InputDecoration(
                      labelText: 'Date',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.calendar_today),
                    ),
                    readOnly: true,
                    onTap: () => _selectDate(context),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _saveExpense,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(
                      widget.expense == null ? 'Add Expense' : 'Update Expense',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
