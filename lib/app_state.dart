import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:io';

class FinancialData with ChangeNotifier {
  // User Profile Data
  File? _profileImage;

  File? get profileImage => _profileImage;

  String selectedPeriod = 'month';

  void changePeriod(String period) {
    selectedPeriod = period;
    notifyListeners();
  }

  List<Map<String, dynamic>> getChartData() {
    switch(selectedPeriod) {
      case 'week':
        return _generateWeeklyData();
      case 'year':
        return _generateYearlyData();
      default: // month
        return _generateMonthlyData();
    }
  }

  List<Map<String, dynamic>> getPieChartData() {
    switch(selectedPeriod) {
      case 'week':
        return [
          {'category': 'Groceries', 'percentage': 45, 'color': Colors.blue},
          {'category': 'Transport', 'percentage': 20, 'color': Colors.green},
          {'category': 'Entertainment', 'percentage': 15, 'color': Colors.orange},
          {'category': 'Other', 'percentage': 20, 'color': Colors.red},
        ];
      case 'year':
        return [
          {'category': 'Groceries', 'percentage': 45, 'color': Colors.blue},
          {'category': 'Transport', 'percentage': 20, 'color': Colors.green},
          {'category': 'Entertainment', 'percentage': 15, 'color': Colors.orange},
          {'category': 'Other', 'percentage': 20, 'color': Colors.red},
        ];
      default: // month
        return [
          {'category': 'Groceries', 'percentage': 45, 'color': Colors.blue},
          {'category': 'Transport', 'percentage': 20, 'color': Colors.green},
          {'category': 'Entertainment', 'percentage': 15, 'color': Colors.orange},
          {'category': 'Other', 'percentage': 20, 'color': Colors.red},
        ];
    }
  }

  List<Map<String, dynamic>> _generateWeeklyData() {
    return [
      {'day': 'Mon', 'income': 800.0, 'expenses': 600.0},
      {'day': 'Tue', 'income': 750.0, 'expenses': 550.0},
      {'day': 'Wed', 'income': 900.0, 'expenses': 700.0},
      {'day': 'Thu', 'income': 850.0, 'expenses': 650.0},
      {'day': 'Fri', 'income': 1000.0, 'expenses': 800.0},
    ];
  }

  List<Map<String, dynamic>> _generateYearlyData() {
    return [
      {'month': 'Jan', 'income': 4500.0, 'expenses': 3200.0},
      {'month': 'Feb', 'income': 4700.0, 'expenses': 3400.0},
      {'month': 'Mar', 'income': 5000.0, 'expenses': 3600.0},
      {'month': 'Apr', 'income': 4800.0, 'expenses': 3500.0},
      {'month': 'May', 'income': 5100.0, 'expenses': 3700.0},
      {'month': 'Jun', 'income': 5300.0, 'expenses': 3900.0},
      {'month': 'Jul', 'income': 5500.0, 'expenses': 4100.0},
      {'month': 'Aug', 'income': 5700.0, 'expenses': 4300.0},
      {'month': 'Sep', 'income': 5900.0, 'expenses': 4500.0},
      {'month': 'Oct', 'income': 6100.0, 'expenses': 4700.0},
      {'month': 'Nov', 'income': 6300.0, 'expenses': 4900.0},
      {'month': 'Dec', 'income': 6500.0, 'expenses': 5100.0},
    ];
  }

  List<Map<String, dynamic>> _generateMonthlyData() {
    return [
      {'day': '01', 'income': 1500.0, 'expenses': 1000.0},
      {'day': '02', 'income': 1600.0, 'expenses': 1100.0},
      {'day': '03', 'income': 1700.0, 'expenses': 1200.0},
      {'day': '04', 'income': 1800.0, 'expenses': 1300.0},
      {'day': '05', 'income': 1900.0, 'expenses': 1400.0},
      {'day': '06', 'income': 2000.0, 'expenses': 1500.0},
      {'day': '07', 'income': 2100.0, 'expenses': 1600.0},
      {'day': '08', 'income': 2200.0, 'expenses': 1700.0},
      {'day': '09', 'income': 2300.0, 'expenses': 1800.0},
      {'day': '10', 'income': 2400.0, 'expenses': 1900.0},
      {'day': '11', 'income': 2500.0, 'expenses': 2000.0},
      {'day': '12', 'income': 2600.0, 'expenses': 2100.0},
      {'day': '13', 'income': 2700.0, 'expenses': 2200.0},
      {'day': '14', 'income': 2800.0, 'expenses': 2300.0},
      {'day': '15', 'income': 2900.0, 'expenses': 2400.0},
      {'day': '16', 'income': 3000.0, 'expenses': 2500.0},
      {'day': '17', 'income': 3100.0, 'expenses': 2600.0},
      {'day': '18', 'income': 3200.0, 'expenses': 2700.0},
      {'day': '19', 'income': 3300.0, 'expenses': 2800.0},
      {'day': '20', 'income': 3400.0, 'expenses': 2900.0},
      {'day': '21', 'income': 3500.0, 'expenses': 3000.0},
      {'day': '22', 'income': 3600.0, 'expenses': 3100.0},
      {'day': '23', 'income': 3700.0, 'expenses': 3200.0},
      {'day': '24', 'income': 3800.0, 'expenses': 3300.0},
      {'day': '25', 'income': 3900.0, 'expenses': 3400.0},
      {'day': '26', 'income': 4000.0, 'expenses': 3500.0},
      {'day': '27', 'income': 4100.0, 'expenses': 3600.0},
      {'day': '28', 'income': 4200.0, 'expenses': 3700.0},
      {'day': '29', 'income': 4300.0, 'expenses': 3800.0},
      {'day': '30', 'income': 4400.0, 'expenses': 3900.0},
      {'day': '31', 'income': 4500.0, 'expenses': 4000.0},
    ];
  }

  void updateProfileImage(File newImage) {
    _profileImage = newImage;
    notifyListeners();
  }

  Map<String, dynamic> userProfile = {
    'name': '',
    'email': '',
    'phone': '',
    'registered': false,
  };

  void updateProfile(String newName, String newEmail, String newPhone) {
    userProfile = {
      'name': newName,
      'email': newEmail,
      'phone': newPhone,
      'registered': true,
    };
    notifyListeners();
  }

  void logout() {
    userProfile = {
      'name': '',
      'email': '',
      'phone': '',
      'registered': false,
    };
    transactions.clear();
    budget = {
      'income': 4500.0,
      'expenses': 3200.0,
      'savings': 1300.0,
      'categories': {
        'Groceries': {'budget': 5000.0, 'spent': 3500.0},
        'Transport': {'budget': 1000.0, 'spent': 900.0},
      }
    };
    notifyListeners();
  }

  // Registration method
  void registerUser(String name, String email, String phone) {
    userProfile = {
      'name': name,
      'email': email,
      'phone': phone,
      'registered': true,
    };
    notifyListeners();
  }

  // Rest of your existing state management code...
  List<Map<String, dynamic>> transactions = [];
  Map<String, dynamic> budget = {
    'income': 4500.0,
    'expenses': 3200.0,
    'savings': 1300.0,
    'categories': {
      'Groceries': {'budget': 5000.0, 'spent': 3500.0},
      'Transport': {'budget': 1000.0, 'spent': 900.0},
    }
  };

  void addTransaction(Map<String, dynamic> newTransaction) {
    transactions.insert(0, {
      ...newTransaction,
      'date': DateTime.now(),
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
    });
    _updateBudget(newTransaction);
    notifyListeners();
  }

  void _updateBudget(Map<String, dynamic> transaction) {
    if (transaction['type'] == 'expense') {
      budget['expenses'] += transaction['amount'];
      budget['savings'] = budget['income'] - budget['expenses'];

      String category = transaction['category'];
      if (budget['categories'].containsKey(category)) {
        budget['categories'][category]['spent'] += transaction['amount'];
      }
    }
    notifyListeners();
  }
}