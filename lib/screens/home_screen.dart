// home_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../app_state.dart';
import '../services/api_service.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final fd = Provider.of<FinancialData>(context, listen: false);

    final summaryMap = await ApiService.instance.fetchMonthlySummary() ?? {};
    final income = (summaryMap['income'] as num?)?.toDouble() ?? 0.0;
    final expenses = (summaryMap['expenses'] as num?)?.toDouble() ?? 0.0;
    final savings = (summaryMap['savings'] as num?)?.toDouble() ?? (income - expenses);

    fd.budget['income'] = income;
    fd.budget['expenses'] = expenses;
    fd.budget['savings'] = savings;

    final txList = await ApiService.instance.fetchTransactions();
    fd.transactions = txList.map((t) {
      final dateStr = t['date'] as String?;
      DateTime date;
      try {
        date = dateStr != null ? DateTime.parse(dateStr) : DateTime.now();
      } catch (_) {
        date = DateTime.now();
      }
      final category = t['category'] as String? ?? '';
      return {
        'id': t['id']?.toString() ?? '',
        'type': t['type'] as String? ?? '',
        'category': category,
        'title': category,
        'amount': (t['amount'] as num?)?.toDouble() ?? 0.0,
        'date': date,
        'notes': t['notes'] as String? ?? '',
      };
    }).toList();

    fd.notifyListeners();
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final fd = Provider.of<FinancialData>(context);

    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final income = fd.budget['income'] as double;
    final expenses = fd.budget['expenses'] as double;
    final savings = fd.budget['savings'] as double;

    final progress = income > 0 ? (expenses / income).clamp(0.0, 1.0) : 0.0;
    final isOverBudget = progress >= 0.8;

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: const Text('Financial Buddy'),
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () => Navigator.pushNamed(context, '/profile'),
          ),
        ],
      ),
      drawer: _buildNavigationDrawer(context),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildSection('MONTHLY SUMMARY', [
            _buildSummaryRow('Income:', '₹${income.toStringAsFixed(2)}'),
            _buildSummaryRow('Expenses:', '₹${expenses.toStringAsFixed(2)}'),
            _buildSummaryRow('Savings:', '₹${savings.toStringAsFixed(2)}'),
          ]),
          const SizedBox(height: 20),
          _buildSection('BUDGET PROGRESS', [
            LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey[300],
              minHeight: 12,
              color: isOverBudget ? Colors.red : Colors.blue,
            ),
            const SizedBox(height: 10),
            Text('₹${expenses.toStringAsFixed(2)} / ₹${income.toStringAsFixed(2)} spent'),
          ]),
          const SizedBox(height: 20),
          _buildSection('AI INSIGHTS', [
            const Text(
              '"Making coffee at home\ncould save ₹1,500/month"',
              textAlign: TextAlign.center,
            ),
          ]),
          const SizedBox(height: 20),
          _buildSection('QUICK ACTIONS', [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildQuickAction(context, 'Add', Icons.add, '/expense'),
                _buildQuickAction(context, 'Goals', Icons.flag, '/budget'),
                _buildQuickAction(context, 'Reports', Icons.description, '/analytics'),
              ],
            ),
          ]),
          const SizedBox(height: 20),
          _buildSection('RECENT TRANSACTIONS', [
            if (fd.transactions.isEmpty)
              const Text('No transactions yet', style: TextStyle(color: Colors.grey))
            else ...fd.transactions.take(5).map(_buildTransaction)
          ]),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 10),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(15.0),
            child: Column(children: children),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [Text(label), Text(value)],
      ),
    );
  }

  Widget _buildQuickAction(BuildContext context, String label, IconData icon, String routeName) {
    return Column(
      children: [
        IconButton(icon: Icon(icon), onPressed: () => Navigator.pushNamed(context, routeName)),
        Text(label),
      ],
    );
  }

  Widget _buildTransaction(Map<String, dynamic> transaction) {
    return ListTile(
      title: Text(transaction['title'] as String),
      subtitle: Text(
        DateFormat('MMM dd, yyyy - HH:mm').format(transaction['date'] as DateTime),
      ),
      trailing: Text(
        '${transaction['type'] == 'income' ? '+' : '-'}₹${(transaction['amount'] as double).toStringAsFixed(2)}',
        style: TextStyle(
          color: transaction['type'] == 'income' ? Colors.green : Colors.red,
          fontWeight: FontWeight.bold,
        ),
      ),
      leading: Icon(_getCategoryIcon(transaction['category'] as String)),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Groceries': return Icons.shopping_cart;
      case 'Transport': return Icons.directions_car;
      case 'Salary': return Icons.work;
      default: return Icons.money_off;
    }
  }

  Widget _buildNavigationDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(color: Colors.blue),
            child: Text('Financial Buddy', style: TextStyle(color: Colors.white, fontSize: 24)),
          ),
          ListTile(leading: const Icon(Icons.home), title: const Text('Dashboard'), onTap: () => Navigator.pushReplacementNamed(context, '/home')),
          ListTile(leading: const Icon(Icons.add_chart), title: const Text('Add Transaction'), onTap: () => Navigator.pushNamed(context, '/expense')),
          ListTile(leading: const Icon(Icons.account_balance_wallet), title: const Text('Budgets & Goals'), onTap: () => Navigator.pushNamed(context, '/budget')),
          ListTile(leading: const Icon(Icons.analytics), title: const Text('Analytics'), onTap: () => Navigator.pushNamed(context, '/analytics')),
        ],
      ),
    );
  }
}