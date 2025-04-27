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

  /// Common headers
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

  Future<Map<String, dynamic>?> fetchProfile() async {
    final uri = Uri.parse('$_baseUrl/profile');
    final res = await http.get(uri, headers: _headers());
    if (res.statusCode == 200) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    }
    return null;
  }

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

  Future<bool> addTransaction({
    required String type,
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

  Future<List<dynamic>> fetchTransactions() async {
    final uri = Uri.parse('$_baseUrl/transactions');
    final res = await http.get(uri, headers: _headers());
    if (res.statusCode == 200) {
      return jsonDecode(res.body) as List<dynamic>;
    }
    return [];
  }

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

  Future<List<dynamic>> fetchBudgets() async {
    final uri = Uri.parse('$_baseUrl/budgets');
    final res = await http.get(uri, headers: _headers());
    if (res.statusCode == 200) {
      return jsonDecode(res.body) as List<dynamic>;
    }
    throw Exception('Failed to load budgets (${res.statusCode})');
  }

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
  // Goals
  // -----------------------

  Future<List<dynamic>> fetchGoals() async {
    final uri = Uri.parse('$_baseUrl/goals');
    final res = await http.get(uri, headers: _headers());
    if (res.statusCode == 200) {
      return jsonDecode(res.body) as List<dynamic>;
    }
    throw Exception('Failed to load goals (${res.statusCode})');
  }

  Future<void> addGoal({
    required String title,
    required double target,
    required double saved,
    required String date,
    int? priority,
    String? status,
  }) async {
    final uri = Uri.parse('$_baseUrl/goals');
    final body = jsonEncode({
      'title': title,
      'target': target,
      'saved': saved,
      'date': date,
      if (priority != null) 'priority': priority,
      if (status != null) 'status': status,
    });
    final res = await http.post(uri, headers: _headers(), body: body);
    if (res.statusCode != 201) {
      throw Exception('Failed to save goal (${res.statusCode})');
    }
  }

  Future<void> updateGoal({
    required String title,
    required double target,
    required double saved,
    required String date,
    int? priority,
    String? status,
  }) async {
    final uri = Uri.parse('$_baseUrl/goals');
    final body = jsonEncode({
      'title': title,
      'target': target,
      'saved': saved,
      'date': date,
      if (priority != null) 'priority': priority,
      if (status != null) 'status': status,
    });
    final res = await http.put(uri, headers: _headers(), body: body);
    if (res.statusCode != 200) {
      throw Exception('Failed to update goal (${res.statusCode})');
    }
  }
}
