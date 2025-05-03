// lib/app_state.dart
import 'dart:io';
import 'package:flutter/foundation.dart';

class FinancialData with ChangeNotifier {
  // —————————————————————————————————————————————————————————
  // Profile
  // —————————————————————————————————————————————————————————
  File? _profileImage;
  File? get profileImage => _profileImage;

  Map<String, dynamic> userProfile = {
    'name': '',
    'email': '',
    'phone': '',
    'registered': false,
  };

  void updateProfileImage(File newImage) {
    _profileImage = newImage;
    notifyListeners();
  }

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
      'income': 0.0,
      'expenses': 0.0,
      'savings': 0.0,
      'categories': {}
    };
    notifyListeners();
  }

  void registerUser(String name, String email, String phone) {
    userProfile = {
      'name': name,
      'email': email,
      'phone': phone,
      'registered': true,
    };
    notifyListeners();
  }

  // —————————————————————————————————————————————————————————
  // Period selection & navigation
  // —————————————————————————————————————————————————————————
  /// 'month' or 'year'
  String selectedPeriod = 'month';

  /// Base date for filtering (current or previous month/year)
  DateTime currentBaseDate = DateTime.now();

  /// Switch between 'month' and 'year'
  void changePeriod(String period) {
    selectedPeriod = period;
    currentBaseDate = DateTime.now();
    notifyListeners();
  }

  /// Go to previous month or year
  void goToPreviousPeriod() {
    if (selectedPeriod == 'month') {
      currentBaseDate = DateTime(
        currentBaseDate.year,
        currentBaseDate.month - 1,
        currentBaseDate.day,
      );
    } else {
      currentBaseDate = DateTime(
        currentBaseDate.year - 1,
        currentBaseDate.month,
        currentBaseDate.day,
      );
    }
    notifyListeners();
  }

  /// Go to next month or year
  void goToNextPeriod() {
    if (selectedPeriod == 'month') {
      currentBaseDate = DateTime(
        currentBaseDate.year,
        currentBaseDate.month + 1,
        currentBaseDate.day,
      );
    } else {
      currentBaseDate = DateTime(
        currentBaseDate.year + 1,
        currentBaseDate.month,
        currentBaseDate.day,
      );
    }
    notifyListeners();
  }

  /// Transactions filtered to the selected month or year
  List<Map<String, dynamic>> get filteredTransactions {
    return transactions.where((tx) {
      final date = tx['date'] as DateTime;
      if (selectedPeriod == 'month') {
        return date.year == currentBaseDate.year &&
            date.month == currentBaseDate.month;
      } else {
        return date.year == currentBaseDate.year;
      }
    }).toList();
  }

  // —————————————————————————————————————————————————————————
  // Transactions & Budget
  // —————————————————————————————————————————————————————————
  List<Map<String, dynamic>> transactions = [];

  Map<String, dynamic> budget = {
    'income': 0.0,
    'expenses': 0.0,
    'savings': 0.0,
    'categories': <String, Map<String, double>>{}
  };

  /// Add a new transaction (and update budgets accordingly)
  void addTransaction(Map<String, dynamic> newTransaction) {
    transactions.insert(
      0,
      {
        ...newTransaction,
        'date': DateTime.now(),
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
      },
    );
    _updateBudget(newTransaction);
    notifyListeners();
  }

  /// Internal: update budget & category spent when a transaction is added
  void _updateBudget(Map<String, dynamic> transaction) {
    final amt = transaction['amount'] as double;
    if (transaction['type'] == 'income') {
      budget['income'] = (budget['income'] as double) + amt;
    } else {
      budget['expenses'] = (budget['expenses'] as double) + amt;
    }
    budget['savings'] =
        (budget['income'] as double) - (budget['expenses'] as double);

    if (transaction['type'] == 'expense') {
      final category = transaction['category'] as String;
      final cats = budget['categories'] as Map<String, Map<String, double>>;
      cats.putIfAbsent(category, () => {'budget': 0.0, 'spent': 0.0});
      cats[category]!['spent'] = (cats[category]!['spent'] ?? 0) + amt;
    }
    notifyListeners();
  }
}
