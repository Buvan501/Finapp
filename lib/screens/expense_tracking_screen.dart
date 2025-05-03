// lib/screens/expense_tracking_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';             // ← import intl
import '../services/api_service.dart';

class ExpenseTrackingScreen extends StatefulWidget {
  @override
  _ExpenseTrackingScreenState createState() => _ExpenseTrackingScreenState();
}

class _ExpenseTrackingScreenState extends State<ExpenseTrackingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _otherCategoryController = TextEditingController();

  String _transactionType = 'Expense';
  String _category = 'Groceries';
  DateTime _selectedDate = DateTime.now();
  bool _showOtherCategoryField = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Transaction'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              _buildTypeSelector(),
              const SizedBox(height: 20),
              _buildAmountField(),
              const SizedBox(height: 20),
              _buildCategoryDropdown(),
              if (_showOtherCategoryField) ...[
                const SizedBox(height: 20),
                _buildOtherCategoryField(),
              ],
              const SizedBox(height: 20),
              _buildDatePicker(),
              const SizedBox(height: 20),
              _buildNotesField(),
              const SizedBox(height: 30),
              _buildSaveButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeSelector() {
    return Row(
      children: [
        Expanded(
          child: ChoiceChip(
            label: const Text('Expense'),
            selected: _transactionType == 'Expense',
            onSelected: (_) {
              setState(() {
                _transactionType = 'Expense';
                _category = 'Groceries';
                _showOtherCategoryField = false;
                _otherCategoryController.clear();
              });
            },
            selectedColor: Colors.blue,
            labelStyle: TextStyle(
              color: _transactionType == 'Expense' ? Colors.white : Colors.black,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ChoiceChip(
            label: const Text('Income'),
            selected: _transactionType == 'Income',
            onSelected: (_) {
              setState(() {
                _transactionType = 'Income';
                _category = 'Salary';
                _showOtherCategoryField = false;
                _otherCategoryController.clear();
              });
            },
            selectedColor: Colors.green,
            labelStyle: TextStyle(
              color: _transactionType == 'Income' ? Colors.white : Colors.black,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAmountField() {
    return TextFormField(
      controller: _amountController,
      decoration: const InputDecoration(
        labelText: 'AMOUNT',
        prefixText: '₹ ',
        border: OutlineInputBorder(),
        suffixIcon: Icon(Icons.currency_rupee),
      ),
      keyboardType: TextInputType.number,
      validator: (v) => (v == null || v.isEmpty) ? 'Enter amount' : null,
    );
  }

  Widget _buildCategoryDropdown() {
    final categories = _transactionType == 'Income'
        ? ['Salary', 'Freelance', 'Investments', 'Other']
        : ['Groceries', 'Transport', 'Entertainment', 'Other'];

    return DropdownButtonFormField<String>(
      value: _category,
      decoration: const InputDecoration(
        labelText: 'CATEGORY',
        border: OutlineInputBorder(),
      ),
      items: categories
          .map((c) => DropdownMenuItem(value: c, child: Text(c)))
          .toList(),
      onChanged: (val) {
        setState(() {
          _category = val!;
          _showOtherCategoryField = val == 'Other';
          if (!_showOtherCategoryField) _otherCategoryController.clear();
        });
      },
    );
  }

  Widget _buildOtherCategoryField() {
    return TextFormField(
      controller: _otherCategoryController,
      decoration: const InputDecoration(
        labelText: 'Specify Category',
        border: OutlineInputBorder(),
      ),
      validator: (v) {
        if (_showOtherCategoryField && (v == null || v.isEmpty)) {
          return 'Enter category name';
        }
        return null;
      },
    );
  }

  Widget _buildDatePicker() {
    return ListTile(
      title: const Text('DATE'),
      subtitle: Text(DateFormat('yyyy-MM-dd').format(_selectedDate)), // ← use DateFormat
      trailing: const Icon(Icons.calendar_today),
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: _selectedDate,
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
        );
        if (picked != null) setState(() => _selectedDate = picked);
      },
    );
  }

  Widget _buildNotesField() {
    return const TextField(
      decoration: InputDecoration(
        labelText: 'NOTES',
        border: OutlineInputBorder(),
        alignLabelWithHint: true,
      ),
      maxLines: 3,
    );
  }

  Widget _buildSaveButton() {
    return ElevatedButton(
      onPressed: _saveTransaction,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
      child: const Text('SAVE TRANSACTION'),
    );
  }

  Future<void> _saveTransaction() async {
    if (!_formKey.currentState!.validate()) return;

    final category = _showOtherCategoryField
        ? _otherCategoryController.text
        : _category;

    final success = await ApiService.instance.addTransaction(
      type:     _transactionType.toLowerCase(),
      category: category,
      amount:   double.parse(_amountController.text),
      date:     _selectedDate,
      notes:    '',
    );

    if (success) {
      Navigator.pop(context, true); // ← return `true` so HomeScreen knows to refresh
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to save transaction')),
      );
    }
  }
}
