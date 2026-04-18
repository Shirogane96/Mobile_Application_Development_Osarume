import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLogin = true;
  final _formKey = GlobalKey<FormState>();
  
  final _idController = TextEditingController();
  final _emailController = TextEditingController();
  final _userController = TextEditingController();
  final _passController = TextEditingController();
  final _confirmPassController = TextEditingController();

  double _passwordStrength = 0;
  String _strengthLabel = '';
  Color _strengthColor = Colors.grey;

  void _checkPasswordStrength(String value) {
    double strength = 0;
    if (value.length >= 6) strength += 0.25;
    if (value.contains(RegExp(r'[A-Z]'))) strength += 0.25;
    if (value.contains(RegExp(r'[0-9]'))) strength += 0.25;
    if (value.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) strength += 0.25;

    setState(() {
      _passwordStrength = strength;
      if (strength <= 0.25) {
        _strengthLabel = 'Weak';
        _strengthColor = Colors.red;
      } else if (strength <= 0.75) {
        _strengthLabel = 'Medium';
        _strengthColor = Colors.orange;
      } else {
        _strengthLabel = 'Strong';
        _strengthColor = Colors.green;
      }
    });
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    try {
      if (_isLogin) {
        final success = await auth.login(_idController.text, _passController.text);
        if (!success) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Invalid credentials')),
            );
          }
        }
      } else {
        if (_passController.text != _confirmPassController.text) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Passwords do not match!')),
          );
          return;
        }
        await auth.register(_userController.text, _emailController.text, _passController.text);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  Future<void> _handleGoogleSignIn() async {
    final auth = context.read<AuthProvider>();
    final success = await auth.signInWithGoogle();
    if (!success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Google Sign-In failed.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFE8EAF6), // Pastel Indigo
              Color(0xFFFCE4EC), // Pastel Pink
            ],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.mood, size: 80, color: Color(0xFF5C6BC0)),
                  const SizedBox(height: 10),
                  Text(
                    _isLogin ? 'Welcome Back' : 'Create Account',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF5C6BC0),
                    ),
                  ),
                  const SizedBox(height: 30),
                  
                  Card(
                    elevation: 0,
                    color: Colors.white.withOpacity(0.6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        children: [
                          if (_isLogin) ...[
                            TextFormField(
                              controller: _idController,
                              decoration: const InputDecoration(
                                labelText: 'Email Address', 
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.email_outlined),
                              ),
                              validator: (v) => v!.isEmpty ? 'Enter email' : null,
                            ),
                          ] else ...[
                            TextFormField(
                              controller: _userController,
                              decoration: const InputDecoration(
                                labelText: 'Username', 
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.person_outline),
                              ),
                              validator: (v) => v!.isEmpty ? 'Enter username' : null,
                            ),
                            const SizedBox(height: 15),
                            TextFormField(
                              controller: _emailController,
                              decoration: const InputDecoration(
                                labelText: 'Email Address', 
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.email_outlined),
                              ),
                              validator: (v) => v!.isEmpty ? 'Enter email' : null,
                            ),
                          ],
                          
                          const SizedBox(height: 15),
                          TextFormField(
                            controller: _passController,
                            obscureText: true,
                            decoration: const InputDecoration(
                              labelText: 'Password', 
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.lock_outline),
                            ),
                            onChanged: _isLogin ? null : _checkPasswordStrength,
                            validator: (v) => v!.length < 6 ? 'Password too short' : null,
                          ),

                          if (!_isLogin) ...[
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: LinearProgressIndicator(
                                    value: _passwordStrength,
                                    backgroundColor: Colors.white.withOpacity(0.5),
                                    color: _strengthColor,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(_strengthLabel, style: TextStyle(color: _strengthColor, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            const SizedBox(height: 15),
                            TextFormField(
                              controller: _confirmPassController,
                              obscureText: true,
                              decoration: const InputDecoration(
                                labelText: 'Confirm Password', 
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.lock_reset),
                              ),
                              validator: (v) => v!.isEmpty ? 'Confirm your password' : null,
                            ),
                          ],

                          const SizedBox(height: 30),
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: _submit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF5C6BC0), 
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                elevation: 0,
                              ),
                              child: Text(_isLogin ? 'Login' : 'Register'),
                            ),
                          ),
                          
                          const SizedBox(height: 20),
                          const Text('OR', style: TextStyle(color: Colors.grey)),
                          const SizedBox(height: 20),
                          
                          OutlinedButton.icon(
                            onPressed: _handleGoogleSignIn,
                            icon: const Icon(Icons.g_mobiledata, size: 30),
                            label: const Text('Continue with Google'),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(double.infinity, 50),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              side: const BorderSide(color: Color(0xFF5C6BC0)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  TextButton(
                    onPressed: () => setState(() => _isLogin = !_isLogin),
                    child: Text(
                      _isLogin ? "Don't have an account? Register" : "Already have an account? Login",
                      style: const TextStyle(color: Color(0xFF5C6BC0), fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
