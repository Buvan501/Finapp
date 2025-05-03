import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../app_state.dart';
import '../services/api_service.dart';
import '../main.dart' show flutterLocalNotificationsPlugin;

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _loading = true;
  bool _notifiedBudgetExceeded = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final fd = Provider.of<FinancialData>(context, listen: false);

    // 1) GET /summary
    final summary = await ApiService.instance.fetchMonthlySummary() ?? {};
    final income   = (summary['income']  as num?)?.toDouble() ?? 0.0;
    final expenses = (summary['expenses']as num?)?.toDouble() ?? 0.0;
    final savings  = (summary['savings'] as num?)?.toDouble() ?? (income - expenses);

    fd.budget['income']   = income;
    fd.budget['expenses'] = expenses;
    fd.budget['savings']  = savings;

    // 2) GET /transactions
    final txList = await ApiService.instance.fetchTransactions();
    fd.transactions = txList.map((t) {
      final dateStr = t['date'] as String?;
      DateTime date;
      try {
        date = dateStr != null ? DateTime.parse(dateStr) : DateTime.now();
      } catch (_) {
        date = DateTime.now();
      }
      return {
        'id':       t['id']?.toString() ?? '',
        'type':     t['type']    as String?  ?? '',
        'category': t['category']as String?  ?? '',
        'title':    t['category']as String?  ?? '',
        'amount':   (t['amount'] as num?)?.toDouble() ?? 0.0,
        'date':     date,
        'notes':    t['notes']   as String?  ?? '',
      };
    }).toList();

    fd.notifyListeners();
    setState(() => _loading = false);

    // 3) Send notification at 80%
    if (!_notifiedBudgetExceeded && income > 0 && expenses / income >= 0.8) {
      _notifiedBudgetExceeded = true;
      _showBudgetNotification(expenses / income);
    }
  }

  Future<void> _showBudgetNotification(double percent) async {
    final perc = (percent * 100).toStringAsFixed(0);
    const android = AndroidNotificationDetails(
      'budget_channel',
      'Budget Alerts',
      channelDescription: 'Alerts when spending nears or exceeds your budget',
      importance: Importance.max,
      priority: Priority.high,
    );
    const detail = NotificationDetails(android: android);

    await flutterLocalNotificationsPlugin.show(
      0,
      'Budget Alert',
      'You have used $perc% of your monthly income.',
      detail,
    );
  }

  @override
  Widget build(BuildContext context) {
    final fd = Provider.of<FinancialData>(context);
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final income   = fd.budget['income']   as double;
    final expenses = fd.budget['expenses'] as double;
    final savings  = fd.budget['savings']  as double;
    final progress = income > 0 ? (expenses / income).clamp(0.0,1.0) : 0.0;
    final over80   = progress >= 0.8;

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
      drawer: _buildDrawer(),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _section('MONTHLY SUMMARY', [
            _row('Income:',   '₹${income.toStringAsFixed(2)}'),
            _row('Expenses:', '₹${expenses.toStringAsFixed(2)}'),
            _row('Savings:',  '₹${savings.toStringAsFixed(2)}'),
          ]),
          const SizedBox(height: 20),
          _section('BUDGET PROGRESS', [
            LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey[300],
              minHeight: 12,
              color: over80 ? Colors.red : Colors.blue,
            ),
            const SizedBox(height: 10),
            Text('₹${expenses.toStringAsFixed(2)} / ₹${income.toStringAsFixed(2)} spent'),
          ]),
          const SizedBox(height: 20),
          _section('QUICK ACTIONS', [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildQuickAction(context,'Add',Icons.add,'/expense'),
                _buildQuickAction(context,'Goals',Icons.flag,'/budget'),
                _buildQuickAction(context,'Reports',Icons.analytics,'/analytics'),
              ],
            ),
          ]),
          const SizedBox(height: 20),
          _section('RECENT TRANSACTIONS', [
            if (fd.transactions.isEmpty)
              const Text('No transactions yet', style: TextStyle(color: Colors.grey))
            else
              ...fd.transactions.take(5).map(_buildTransaction),
          ]),
        ],
      ),
    );
  }

  Widget _section(String title, List<Widget> children) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      const SizedBox(height: 10),
      Card(child: Padding(padding: const EdgeInsets.all(15), child: Column(children: children))),
    ],
  );

  Widget _row(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(label), Text(value)]),
  );

  Widget _buildQuickAction(BuildContext ctx, String label, IconData icon, String route) {
    return Column(
      children: [
        IconButton(
          icon: Icon(icon),
          onPressed: () {
            Navigator.pushNamed(ctx, route).then((didAdd) {
              if (didAdd == true) _loadData();
            });
          },
        ),
        Text(label),
      ],
    );
  }

  Widget _buildTransaction(Map<String,dynamic> tx) {
    return ListTile(
      leading: Icon(_iconFor(tx['category'] as String)),
      title: Text(tx['title'] as String),
      subtitle: Text(DateFormat('MMM dd, yyyy – HH:mm').format(tx['date'] as DateTime)),
      trailing: Text(
        '${tx['type']=='income'?'+':'-'}₹${(tx['amount'] as double).toStringAsFixed(2)}',
        style: TextStyle(
          color: tx['type']=='income'?Colors.green:Colors.red,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  IconData _iconFor(String cat) {
    switch(cat) {
      case 'Groceries':   return Icons.shopping_cart;
      case 'Transport':   return Icons.directions_car;
      case 'Salary':      return Icons.work;
      default:            return Icons.money_off;
    }
  }

  Widget _buildDrawer() => Drawer(
    child: ListView(padding: EdgeInsets.zero, children: [
      const DrawerHeader(
        decoration: BoxDecoration(color: Colors.blue),
        child: Text('Financial Buddy', style: TextStyle(color: Colors.white,fontSize:24)),
      ),
      ListTile(
        leading: const Icon(Icons.home),
        title: const Text('Dashboard'),
        onTap: () => Navigator.pushReplacementNamed(context, '/home'),
      ),
      ListTile(
        leading: const Icon(Icons.add_chart),
        title: const Text('Add Transaction'),
        onTap: () => Navigator.pushNamed(context, '/expense').then((didAdd){
          if (didAdd==true) _loadData();
        }),
      ),
      ListTile(
        leading: const Icon(Icons.account_balance_wallet),
        title: const Text('Budgets & Goals'),
        onTap: () => Navigator.pushNamed(context, '/budget'),
      ),
      ListTile(
        leading: const Icon(Icons.analytics),
        title: const Text('Analytics'),
        onTap: () => Navigator.pushNamed(context, '/analytics'),
      ),
    ]),
  );
}
