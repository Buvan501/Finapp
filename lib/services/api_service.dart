// api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  ApiService._privateConstructor();
  static final ApiService instance = ApiService._privateConstructor();

  // TODO: Replace with your backend URL
  static const String _baseUrl = 'http://192.168.29.66:5000';
  String? _jwtToken;

  /// Update JWT token after login/signup
  void updateToken(String token) {
    _jwtToken = token;
  }

  /// Common headers for all requests
  Map<String, String> _headers() {
    final headers = {'Content-Type': 'application/json'};
    if (_jwtToken != null && _jwtToken!.isNotEmpty) {
      headers['Authorization'] = 'Bearer $_jwtToken';
    }
    return headers;
  }

  // -----------------------
  // Authentication & Profile
  // -----------------------

  /// Sign up a new user
  Future<bool> signUp({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    final uri = Uri.parse('$_baseUrl/signup');
    final body = jsonEncode({
      'name': name,
      'email': email,
      'phone': phone,
      'password': password,
    });

    final res = await http.post(uri, headers: _headers(), body: body);
    if (res.statusCode == 201) {
      final data = jsonDecode(res.body);
      updateToken(data['access_token']);
      return true;
    }
    return false;
  }

  /// Log in an existing user
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    final uri = Uri.parse('$_baseUrl/login');
    final body = jsonEncode({
      'email': email,
      'password': password,
    });

    final res = await http.post(uri, headers: _headers(), body: body);
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      updateToken(data['access_token']);
      return true;
    }
    return false;
  }

  /// Fetch user profile data
  Future<Map<String, dynamic>?> fetchProfile() async {
    final uri = Uri.parse('$_baseUrl/profile');
    final res = await http.get(uri, headers: _headers());
    if (res.statusCode == 200) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    }
    return null;
  }

  /// Update user profile
  Future<bool> updateProfile({
    required String name,
    required String email,
    required String phone,
  }) async {
    final uri = Uri.parse('$_baseUrl/profile');
    final body = jsonEncode({
      'name': name,
      'email': email,
      'phone': phone,
    });
    final res = await http.put(uri, headers: _headers(), body: body);
    return res.statusCode == 200;
  }

  // -----------------------
  // Transactions
  // -----------------------

  /// Add a new income or expense transaction
  Future<bool> addTransaction({
    required String type, // 'income' or 'expense'
    required String category,
    required double amount,
    DateTime? date,
    String? notes,
  }) async {
    final uri = Uri.parse('$_baseUrl/transaction');
    final body = jsonEncode({
      'type': type,
      'category': category,
      'amount': amount,
      'date': date?.toIso8601String(),
      'notes': notes ?? '',
    });

    final res = await http.post(uri, headers: _headers(), body: body);
    return res.statusCode == 201;
  }

  /// Fetch all transactions for the user
  Future<List<dynamic>> fetchTransactions() async {
    final uri = Uri.parse('$_baseUrl/transactions');
    final res = await http.get(uri, headers: _headers());
    if (res.statusCode == 200) {
      return jsonDecode(res.body) as List<dynamic>;
    }
    return [];
  }

  /// Fetch summary (income, expenses, savings) for current month
  Future<Map<String, dynamic>?> fetchMonthlySummary() async {
    final uri = Uri.parse('$_baseUrl/summary');
    final res = await http.get(uri, headers: _headers());
    if (res.statusCode == 200) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    }
    return null;
  }

  // -----------------------
  // Budgets
  // -----------------------

  /// Fetch budget categories with limits and spent for current month
  Future<List<dynamic>> fetchBudgets() async {
    final uri = Uri.parse('$_baseUrl/budgets');
    final res = await http.get(uri, headers: _headers());
    if (res.statusCode == 200) {
      return jsonDecode(res.body) as List<dynamic>;
    }
    throw Exception('Failed to load budgets (${res.statusCode})');
  }

  /// Add or update a budget category
  Future<void> addBudget({
    required String category,
    required double budget,
  }) async {
    final uri = Uri.parse('$_baseUrl/budgets');
    final body = jsonEncode({'category': category, 'budget': budget});
    final res = await http.post(uri, headers: _headers(), body: body);
    if (res.statusCode != 201) {
      throw Exception('Failed to save budget (${res.statusCode})');
    }
  }

  // -----------------------
  // Financial Goals
  // -----------------------

  /// Fetch all financial goals
  Future<List<dynamic>> fetchGoals() async {
    final uri = Uri.parse('$_baseUrl/goals');
    final res = await http.get(uri, headers: _headers());
    if (res.statusCode == 200) {
      return jsonDecode(res.body) as List<dynamic>;
    }
    throw Exception('Failed to load goals (${res.statusCode})');
  }

  /// Add a new financial goal
  Future<void> addGoal({
    required String title,
    required double target,
    required double saved,
    required String date,
  }) async {
    final uri = Uri.parse('$_baseUrl/goals');
    final body = jsonEncode({
      'title': title,
      'target': target,
      'saved': saved,
      'date': date,
    });
    final res = await http.post(uri, headers: _headers(), body: body);
    if (res.statusCode != 201) {
      throw Exception('Failed to save goal (${res.statusCode})');
    }
  }
}