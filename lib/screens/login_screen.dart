// login_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';
import '../services/api_service.dart';

enum AuthMode { login, signUp }

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  AuthMode _authMode = AuthMode.login;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              const SizedBox(height: 50),
              const Text(
                'Financial Buddy',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _buildHeaderImage(),
              ),
              const SizedBox(height: 30),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _buildFormFields(),
              ),
              const SizedBox(height: 30),
              _buildMainButton(),
              const SizedBox(height: 15),
              _buildSecondaryActions(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderImage() {
    return Container(
      key: ValueKey(_authMode),
      height: 100,
      width: 100,
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.blue, width: 2),
      ),
      child: const Icon(
        Icons.account_balance_wallet,
        size: 60,
        color: Colors.blue,
      ),
    );
  }

  Widget _buildFormFields() {
    return Column(
      key: ValueKey(_authMode),
      children: [
        if (_authMode == AuthMode.signUp)
          _buildInputField(
            'Name',
            Icons.person,
            controller: _nameController,
            validator: (value) => value == null || value.isEmpty ? 'Please enter your name' : null,
          ),
        _buildInputField(
          'Email',
          Icons.email,
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          validator: (value) => value == null || value.isEmpty ? 'Please enter your email' : null,
        ),
        _buildInputField(
          'Password',
          Icons.lock,
          controller: _passwordController,
          isPassword: true,
          validator: (value) {
            if (value == null || value.isEmpty) return 'Please enter your password';
            if (_authMode == AuthMode.signUp && value.length < 6) {
              return 'Password must be at least 6 characters';
            }
            return null;
          },
        ),
        if (_authMode == AuthMode.signUp)
          _buildInputField(
            'Phone',
            Icons.phone,
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            validator: (value) => value == null || value.isEmpty ? 'Please enter your phone number' : null,
          ),
      ],
    );
  }

  Widget _buildInputField(
      String label,
      IconData icon, {
        bool isPassword = false,
        TextInputType? keyboardType,
        TextEditingController? controller,
        String? Function(String?)? validator,
      }
      ) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            obscureText: isPassword,
            keyboardType: keyboardType,
            decoration: InputDecoration(
              prefixIcon: Icon(icon),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
            ),
            validator: validator,
          ),
        ],
      ),
    );
  }

  Widget _buildMainButton() {
    return ElevatedButton(
      onPressed: _isSubmitting ? null : _submit,
      child: _isSubmitting
          ? const CircularProgressIndicator(color: Colors.white)
          : Text(_authMode == AuthMode.login ? 'LOGIN' : 'SIGN UP'),
      style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
    );
  }

  Widget _buildSecondaryActions() {
    return TextButton(
      onPressed: _isSubmitting
          ? null
          : () => setState(() => _authMode = _authMode == AuthMode.login ? AuthMode.signUp : AuthMode.login),
      child: Text(
        _authMode == AuthMode.login
            ? "Don't have an account? Sign Up"
            : 'Back to Login',
      ),
    );
  }

  // ★ UPDATED: handle login/signUp and fetch protected data before navigating
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);

    final fd = Provider.of<FinancialData>(context, listen: false);
    bool ok;
    if (_authMode == AuthMode.login) {
      ok = await ApiService.instance.login(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
    } else {
      ok = await ApiService.instance.signUp(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        password: _passwordController.text.trim(),
      );
    }

    if (ok) {
      // ★ NEW: fetch profile, summary, transactions with auth
      final profile = await ApiService.instance.fetchProfile();
      final summary = await ApiService.instance.fetchMonthlySummary();
      final txs     = await ApiService.instance.fetchTransactions();

      if (profile != null) {
        fd.updateProfile(profile['name'], profile['email'], profile['phone']);
      }
      if (summary != null) {
        fd.budget['income']   = summary['income'];
        fd.budget['expenses'] = summary['expenses'];
        fd.budget['savings']  = summary['savings'];
      }
      fd.transactions = txs.map((t) => {
        'id': t['id'],
        'type': t['type'],
        'category': t['category'],
        'amount': t['amount'],
        'date': DateTime.parse(t['date']),
        'notes': t['notes'],
      }).toList();
      fd.notifyListeners();

      if (mounted) Navigator.pushReplacementNamed(context, '/home');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Authentication failed'))
      );
    }
    setState(() => _isSubmitting = false);
  }

  void _clearControllers() {
    _nameController.clear();
    _emailController.clear();
    _passwordController.clear();
    _phoneController.clear();
  }
}

// home_screen.dart (unchanged)
// api_service.dart (unchanged)
// expense_tracking_screen.dart (unchanged)
