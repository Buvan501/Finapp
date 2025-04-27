// budget_goals_screen.dart
import 'package:flutter/material.dart';
import 'package:finapp/services/api_service.dart';

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
  List<Map<String, dynamic>> _budgets = [];
  List<Map<String, dynamic>> _goals = [];
  bool _isLoading = true;

  final Map<String, TextEditingController> _contribControllers = {};

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    final budgets = await ApiService.instance.fetchBudgets();
    final goals = await ApiService.instance.fetchGoals();
    // Sort by priority if present
    goals.sort((a, b) =>
        (a['priority'] as int? ?? 0).compareTo(b['priority'] as int? ?? 0));

    setState(() {
      _budgets = List<Map<String, dynamic>>.from(budgets);
      _goals = List<Map<String, dynamic>>.from(goals);
      // Initialize contribution controllers
      _contribControllers.clear();
      for (var g in _goals) {
        _contribControllers[g['title']] = TextEditingController();
      }
      _isLoading = false;
    });
  }

  Future<void> _addNewBudget(String category, double amount) async {
    await ApiService.instance.addBudget(
      category: category,
      budget: amount,
    );
    await _fetchData();
  }

  Future<void> _addNewGoal(Map<String, dynamic> goal) async {
    await ApiService.instance.addGoal(
      title: goal['title'],
      target: goal['target'],
      saved: goal['saved'],
      date: goal['date'],
      priority: goal['priority'] ?? 0,
      status: goal['status'] ?? 'active',
    );
    await _fetchData();
  }

  Future<void> _contributeToGoal(String title) async {
    final controller = _contribControllers[title]!;
    final value = double.tryParse(controller.text);
    if (value == null || value <= 0) return;

    final goal = _goals.firstWhere((g) => g['title'] == title);
    final newSaved = (goal['saved'] as num).toDouble() + value;

    await ApiService.instance.updateGoal(
      title: title,
      target: (goal['target'] as num).toDouble(),
      saved: newSaved,
      date: goal['date'],
      priority: goal['priority'] ?? 0,
      status: goal['status'] ?? 'active',
    );

    controller.clear();
    await _fetchData();
  }

  void _showAddDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
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
      builder: (_) => AlertDialog(
        title: const Text('New Budget'),
        content: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _categoryController,
                decoration: const InputDecoration(labelText: 'Category'),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Amount'),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Required';
                  if (double.tryParse(v) == null) return 'Numbers only';
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
            onPressed: () async {
              if (_formKey.currentState!.validate()) {
                await _addNewBudget(
                  _categoryController.text,
                  double.parse(_amountController.text),
                );
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showGoalForm(BuildContext context) {
    final _formKey = GlobalKey<FormState>();
    final _titleController = TextEditingController();
    final _targetController = TextEditingController();
    final _savedController = TextEditingController();
    final _dateController = TextEditingController();
    int _priority = 0;
    String _status = 'active';

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('New Goal'),
        content: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Title'),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              TextFormField(
                controller: _targetController,
                decoration: const InputDecoration(labelText: 'Target'),
                keyboardType: TextInputType.number,
                validator: (v) =>
                v!.isEmpty ? 'Required' : double.tryParse(v) == null ? 'Numbers only' : null,
              ),
              TextFormField(
                controller: _savedController,
                decoration: const InputDecoration(labelText: 'Saved'),
                keyboardType: TextInputType.number,
                validator: (v) =>
                v!.isEmpty ? 'Required' : double.tryParse(v) == null ? 'Numbers only' : null,
              ),
              TextFormField(
                controller: _dateController,
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: 'Deadline',
                  suffixIcon: Icon(Icons.calendar_today),
                ),
                onTap: () async {
                  final d = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime(2100),
                  );
                  if (d != null) {
                    _dateController.text =
                    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
                  }
                },
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<int>(
                decoration: const InputDecoration(labelText: 'Priority'),
                value: 0,
                items: List.generate(4, (i) => i)
                    .map((i) => DropdownMenuItem(value: i, child: Text('Level $i')))
                    .toList(),
                onChanged: (v) => _priority = v!,
              ),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Status'),
                value: 'active',
                items: ['active', 'paused', 'completed']
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (v) => _status = v!,
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
            onPressed: () async {
              if (_formKey.currentState!.validate()) {
                await _addNewGoal({
                  'title': _titleController.text,
                  'target': double.parse(_targetController.text),
                  'saved': double.parse(_savedController.text),
                  'date': _dateController.text,
                  'priority': _priority,
                  'status': _status,
                });
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
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
          ..._budgets.map((b) => _buildBudgetCard(
            b['category'],
            (b['budget'] as num).toDouble(),
            (b['spent'] as num).toDouble(),
          )),
          _buildSectionHeader('Financial Goals'),
          ..._goals.map((g) => _buildGoalCard(
            g['title'] as String,
            (g['target'] as num).toDouble(),
            (g['saved'] as num).toDouble(),
            g['date'] as String,
            priority: g['priority'] as int?,
            status: g['status'] as String?,
          )),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) => Padding(
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

  Widget _buildBudgetCard(String category, double budget, double spent) {
    final prog = (spent / budget).clamp(0.0, 1.0);
    final rem = budget - spent;
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
                Text(category, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                Chip(
                  label: Text('Budget: ₹${budget.toStringAsFixed(2)}'),
                  backgroundColor: Colors.blue.withOpacity(0.1),
                ),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: prog,
              minHeight: 12,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(prog > 1 ? Colors.red : Colors.blue),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildAmountColumn('Spent', spent, Colors.red),
                _buildAmountColumn('Remaining', rem, rem >= 0 ? Colors.green : Colors.red),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalCard(String title, double target, double saved, String date,
      {int? priority, String? status}) {
    final prog = (saved / target).clamp(0.0, 1.0);
    final statusColor = status == 'completed'
        ? Colors.green
        : status == 'paused'
        ? Colors.grey
        : Colors.blue;
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
                Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                Column(
                  children: [
                    Chip(label: Text(date), backgroundColor: statusColor.withOpacity(0.1)),
                    if (priority != null) Text('Priority: $priority'),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: prog,
              minHeight: 12,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(status == 'completed' ? Colors.green : Colors.green),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildAmountColumn('Saved', saved, Colors.green),
                _buildAmountColumn('Target', target, Colors.blue),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _contribControllers[title],
                    decoration: const InputDecoration(
                      hintText: 'Add to goal',
                      prefixText: '₹ ',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => _contributeToGoal(title),
                  child: const Text('Allocate'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAmountColumn(String label, double amount, Color color) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
      Text(
        '₹${amount.toStringAsFixed(2)}',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color),
      ),
    ],
  );
}
