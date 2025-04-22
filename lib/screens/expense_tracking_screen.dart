import 'package:flutter/material.dart';
import '../app_state.dart';
import '../services/api_service.dart';

class ExpenseTrackingScreen extends StatefulWidget {
  @override
  _ExpenseTrackingScreenState createState() => _ExpenseTrackingScreenState();
}

class _ExpenseTrackingScreenState extends State<ExpenseTrackingScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _otherCategoryController = TextEditingController();
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
            onSelected: (val) {
              setState(() {
                _transactionType = 'Expense';
                _category = 'Groceries';
                _showOtherCategoryField = false;
                _otherCategoryController.clear();
              });
            },
            selectedColor: Colors.blue,
            labelStyle: TextStyle(
              color: _transactionType == 'Expense' ? Colors.white : Colors
                  .black,
            ),
          ),
        ),
        Expanded(
          child: ChoiceChip(
            label: const Text('Income'),
            selected: _transactionType == 'Income',
            onSelected: (val) {
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
      decoration: InputDecoration(
        labelText: 'AMOUNT',
        prefixText: '₹ ',
        border: OutlineInputBorder(),
        suffixIcon: Icon(Icons.currency_rupee),
      ),
      keyboardType: TextInputType.number,
      validator: (value) => value!.isEmpty ? 'Enter amount' : null,
    );
  }

  Widget _buildCategoryDropdown() {
    List<String> categories = _transactionType == 'Income'
        ? ['Salary', 'Freelance', 'Investments', 'Other']
        : ['Groceries', 'Transport', 'Entertainment', 'Other'];

    return DropdownButtonFormField(
      value: _category,
      decoration: InputDecoration(
        labelText: 'CATEGORY',
        border: OutlineInputBorder(),
      ),
      items: categories
          .map((cat) =>
          DropdownMenuItem(
            value: cat,
            child: Text(cat),
          ))
          .toList(),
      onChanged: (value) {
        setState(() {
          _category = value.toString();
          _showOtherCategoryField = (value == 'Other');
          if (!_showOtherCategoryField) {
            _otherCategoryController.clear();
          }
        });
      },
    );
  }

  Widget _buildOtherCategoryField() {
    return TextFormField(
      controller: _otherCategoryController,
      decoration: InputDecoration(
        labelText: 'Specify Category',
        border: OutlineInputBorder(),
      ),
      validator: (value) =>
      _showOtherCategoryField && value!.isEmpty ? 'Enter category name' : null,
    );
  }

  Widget _buildDatePicker() {
    return ListTile(
      title: Text('DATE'),
      subtitle: Text('${_selectedDate.toLocal()}'.split(' ')[0]),
      trailing: Icon(Icons.calendar_today),
      onTap: () async {
        final pickedDate = await showDatePicker(
          context: context,
          initialDate: _selectedDate,
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
        );
        if (pickedDate != null) {
          setState(() => _selectedDate = pickedDate);
        }
      },
    );
  }

  Widget _buildNotesField() {
    return TextFormField(
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
      child: const Text('SAVE TRANSACTION'),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _saveTransaction() async {
    if (_formKey.currentState!.validate()) {
      final category = _showOtherCategoryField
          ? _otherCategoryController.text
          : _category;

      final success = await ApiService.instance.addTransaction(
        type: _transactionType.toLowerCase(),
        category: category,
        amount: double.parse(_amountController.text),
        date: _selectedDate,
        notes: '', // You can add a TextController for notes if needed
      );

      if (success) {
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save transaction')),
        );
      }
    }
  }
}
