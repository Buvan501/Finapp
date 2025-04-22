// api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  ApiService._privateConstructor();
  static final ApiService instance = ApiService._privateConstructor();

  // TODO: Replace with your backend URL
  static const String _baseUrl = 'http://192.168.29.66:5000';

  String? _jwtToken;

  void updateToken(String token) {
    _jwtToken = token;
  }

  Map<String, String> _headers() {
    final headers = {
      'Content-Type': 'application/json',
    };
    if (_jwtToken != null && _jwtToken!.isNotEmpty) {
      headers['Authorization'] = 'Bearer $_jwtToken';
    }
    return headers;
  }

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
    final body = jsonEncode({ 'email': email, 'password': password });

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
    print('Fetching profile with token: $_jwtToken');
    final res = await http.get(uri, headers: _headers());
    print('PROFILE STATUS: ${res.statusCode}');
    print('PROFILE BODY: ${res.body}');
    if (res.statusCode == 200) {
      return jsonDecode(res.body);
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

  Future<bool> addTransaction({
    required String type,         // 'income' or 'expense'
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
      return jsonDecode(res.body);
    }
    return null;
  }
}
