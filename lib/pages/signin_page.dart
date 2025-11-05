import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_application_1/lecturer_dashboard.dart';
import 'package:flutter_application_1/staff_dashboard.dart';
import 'package:flutter_application_1/student_browsing.dart';
import 'signup_page.dart';

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final TextEditingController _user = TextEditingController(); // email
  final TextEditingController _pass = TextEditingController();
  bool _rememberMe = false;
  bool _loading = false;

  static const String _baseUrl = 'http://localhost:3000';

  @override
  void initState() {
    super.initState();
    _loadRemembered();
  }

  Future<void> _loadRemembered() async {
    final sp = await SharedPreferences.getInstance();
    final remember = sp.getBool('remember_me') ?? false;
    final email = sp.getString('remember_email') ?? '';
    setState(() {
      _rememberMe = remember;
      if (remember && email.isNotEmpty) {
        _user.text = email;
      }
    });
  }

  @override
  void dispose() {
    _user.dispose();
    _pass.dispose();
    super.dispose();
  }

  Future<void> _attemptSignIn() async {
    final email = _user.text.trim();
    final password = _pass.text;

    if (email.isEmpty || password.isEmpty) {
      _snack('Please enter email and password');
      return;
    }

    setState(() => _loading = true);
    try {
      final resp = await http.post(
        Uri.parse('$_baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        if (data is Map && data['ok'] == true) {
          final user = (data['user'] ?? {}) as Map;
          final token = (data['mobile_token'] ?? '').toString();
          final firstName = (user['first_name'] ?? '').toString();
          final role = (user['role'] ?? 'student').toString();

          // set the token so all subsequent pages send header Authorization: Bearer <user_id>
          if (token.isNotEmpty) {
            StudentBrowsing.setMobileToken(token); // <-- FIX: public & available
          }

          // persist optionally what you need
          final sp = await SharedPreferences.getInstance();
          await sp.setString('mobile_token', token);
          await sp.setString('first_name', firstName);
          await sp.setString('role', role);
          await sp.setBool('remember_me', _rememberMe);
          if (_rememberMe) {
            await sp.setString('remember_email', email);
          } else {
            await sp.remove('remember_email');
          }

          // route by role
          if (role == 'staff') {
            if (!mounted) return;
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => StaffDashboard()));
          } else if (role == 'lecturer') {
            if (!mounted) return;
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => LecturerDashboard()));
          } else {
            if (!mounted) return;
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const StudentBrowsing()));
          }
          return;
        } else {
          final err = (data['error'] ?? 'Login failed').toString();
          _snack(err);
        }
      } else {
        _snack(resp.body.isNotEmpty ? resp.body : 'Login failed');
      }
    } catch (e) {
      _snack('Network error: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _snack(String m) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        width: size.width,
        height: size.height,
        color: Colors.white,
        child: Align(
          alignment: Alignment.topLeft,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.only(top: 100, left: 30, bottom: 80),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RichText(
                      text: const TextSpan(
                        children: [
                          TextSpan(
                            text: 'Sign ',
                            style: TextStyle(
                              color: Color(0xFF0E2A5D),
                              fontSize: 49,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextSpan(
                            text: 'In',
                            style: TextStyle(
                              color: Color(0xFF0E2A5D),
                              fontSize: 49,
                              fontWeight: FontWeight.bold,
                              decoration: TextDecoration.underline,
                              decorationThickness: 1,
                            ),
                          ),
                          TextSpan(
                            text: ',',
                            style: TextStyle(
                              color: Color(0xFF0E2A5D),
                              fontSize: 49,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Small steps lead to big changes',
                      style: TextStyle(
                        color: Color(0xFF0E2A5D),
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Form Card
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF0E2A5D), Color(0xFF1A4FA8)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(50),
                      topRight: Radius.circular(50),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 40),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(height: 40),

                        TextField(
                          controller: _user,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.person_outline),
                            hintText: 'Email',
                            filled: true,
                            fillColor: Colors.grey.shade300,
                            contentPadding: const EdgeInsets.symmetric(vertical: 18),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        TextField(
                          controller: _pass,
                          obscureText: true,
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.lock_outline),
                            hintText: 'Password',
                            filled: true,
                            fillColor: Colors.grey.shade300,
                            contentPadding: const EdgeInsets.symmetric(vertical: 18),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),

                        Row(
                          children: [
                            Checkbox(
                              value: _rememberMe,
                              onChanged: (value) {
                                setState(() {
                                  _rememberMe = value ?? false;
                                });
                              },
                              activeColor: Colors.white,
                              checkColor: const Color(0xFF0E2A5D),
                            ),
                            const Text(
                              'Remember me',
                              style: TextStyle(color: Colors.white, fontSize: 14),
                            ),
                          ],
                        ),

                        const SizedBox(height: 40),

                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFF0E2A5D),
                            shadowColor: Colors.black,
                            elevation: 10,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 80, vertical: 16),
                          ),
                          onPressed: _loading ? null : _attemptSignIn,
                          child: _loading
                              ? const SizedBox(
                                  height: 22,
                                  width: 22,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Text(
                                  'SIGN IN',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                                ),
                        ),

                        const SizedBox(height: 40),

                        GestureDetector(
                          onTap: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(builder: (context) => const SignUpPage()),
                            );
                          },
                          child: const Text.rich(
                            TextSpan(
                              text: "Don’t have an Account? ",
                              style: TextStyle(color: Colors.white, fontSize: 15),
                              children: [
                                TextSpan(
                                  text: "Sign Up",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    decoration: TextDecoration.underline,
                                    decorationColor: Colors.white,
                                    decorationThickness: 1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
