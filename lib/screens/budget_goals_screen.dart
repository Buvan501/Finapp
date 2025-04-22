import 'package:flutter/material.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Budget & Goals Tracker',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const BudgetGoalsScreen(),
    );
  }
}

class BudgetGoalsScreen extends StatefulWidget {
  const BudgetGoalsScreen({super.key});

  @override
  _BudgetGoalsScreenState createState() => _BudgetGoalsScreenState();
}

class _BudgetGoalsScreenState extends State<BudgetGoalsScreen> {
  final Map<String, double> _categoryBudgets = {
    'Groceries': 5000,
    'Transport': 1000,
    'Entertainment': 2000,
    'Other': 2000,
  };

  final Map<String, double> _categorySpending = {
    'Groceries': 3500,
    'Transport': 900,
    'Entertainment': 600,
    'Other': 300,
  };

  final List<Map<String, dynamic>> _financialGoals = [
    {'title': 'Vacation Fund', 'target': 20000.0, 'saved': 9000.0, 'date': '2025-12-31'},
    {'title': 'Emergency Fund', 'target': 50000.0, 'saved': 17500.0, 'date': 'Ongoing'},
  ];

  void _addNewBudget(String category, double amount) {
    setState(() {
      _categoryBudgets[category] = amount;
      _categorySpending[category] = 0;
    });
  }

  void _addNewGoal(Map<String, dynamic> goal) {
    setState(() {
      _financialGoals.add(goal);
    });
  }

  void _showAddDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.account_balance_wallet),
              title: const Text('Add Budget'),
              onTap: () {
                Navigator.pop(context);
                _showBudgetForm(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.flag),
              title: const Text('Add Goal'),
              onTap: () {
                Navigator.pop(context);
                _showGoalForm(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showBudgetForm(BuildContext context) {
    final _formKey = GlobalKey<FormState>();
    final _categoryController = TextEditingController();
    final _amountController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Budget'),
        content: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _categoryController,
                decoration: const InputDecoration(
                  labelText: 'Budget Category',
                  hintText: 'e.g. Groceries, Rent, Utilities',
                ),
                validator: (value) => value!.isEmpty ? 'Category required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Budget Amount',
                  hintText: 'Enter amount in numbers only',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Amount required';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Numbers only';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                _addNewBudget(
                  _categoryController.text,
                  double.parse(_amountController.text),
                );
                Navigator.pop(context);
              }
            },
            child: const Text('Add Budget'),
          ),
        ],
      ),
    );
  }

  Future<void> _selectDate(BuildContext context, TextEditingController controller) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      controller.text = "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
    }
  }

  void _showGoalForm(BuildContext context) {
    final _formKey = GlobalKey<FormState>();
    final _titleController = TextEditingController();
    final _targetController = TextEditingController();
    final _savedController = TextEditingController();
    final _dateController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Financial Goal'),
        content: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Goal Title'),
                validator: (value) => value!.isEmpty ? 'Title required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _targetController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Target Amount'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Amount required';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Numbers only';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _savedController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Amount Saved'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Amount required';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Numbers only';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _dateController,
                decoration: const InputDecoration(
                  labelText: 'Target Date',
                  suffixIcon: Icon(Icons.calendar_today),
                ),
                readOnly: true,
                onTap: () => _selectDate(context, _dateController),
                validator: (value) => value!.isEmpty ? 'Date required' : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                _addNewGoal({
                  'title': _titleController.text,
                  'target': double.parse(_targetController.text),
                  'saved': double.parse(_savedController.text),
                  'date': _dateController.text,
                });
                Navigator.pop(context);
              }
            },
            child: const Text('Add Goal'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Budget & Goals'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddDialog(context),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionHeader('Monthly Budgets'),
          ..._categoryBudgets.keys.map((category) => _buildBudgetCard(
            category,
            _categoryBudgets[category]!,
            _categorySpending[category]!,
          )),
          _buildSectionHeader('Financial Goals'),
          ..._financialGoals.map((goal) => _buildGoalCard(
            goal['title'] as String,
            goal['target'] as double,
            goal['saved'] as double,
            goal['date'] as String,
          )),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.blue,
        ),
      ),
    );
  }

  Widget _buildBudgetCard(String category, double budget, double spent) {
    final progress = spent / budget;
    final remaining = budget - spent;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  category,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Chip(
                  label: Text('Budget: \$${budget.toStringAsFixed(2)}'),
                  backgroundColor: Colors.blue.withOpacity(0.1),
                ),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: progress > 1 ? 1 : progress,
              minHeight: 12,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(
                progress > 1 ? Colors.red : Colors.blue,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildAmountColumn('Spent', spent, Colors.red),
                _buildAmountColumn(
                  'Remaining',
                  remaining,
                  remaining >= 0 ? Colors.green : Colors.red,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalCard(String title, double target, double saved, String date) {
    final progress = saved / target;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Chip(
                  label: Text(date),
                  backgroundColor: Colors.green.withOpacity(0.1),
                ),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: progress,
              minHeight: 12,
              backgroundColor: Colors.grey[200],
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildAmountColumn('Saved', saved, Colors.green),
                _buildAmountColumn('Target', target, Colors.blue),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAmountColumn(String label, double amount, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        Text(
          '\$${amount.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}