import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_application_1/lecturer_dashboard.dart';
import 'package:flutter_application_1/staff_dashboard.dart';
import 'package:flutter_application_1/student_browsing.dart';
import 'signup_page.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final TextEditingController _email = TextEditingController();
  final TextEditingController _pass = TextEditingController();
  bool _rememberMe = false;
  bool isLoading = false;
  bool isWaiting = false;

  Uri uri = Uri(
    scheme: 'http',
    host: '127.0.0.1', // just the IP
    port: 3000, // separate port
    path: '/api/login',
  );

  void popDialog(String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(title: const Text('Error'), content: Text(message));
      },
    );
  }

  @override
  void dispose() {
    _email.dispose();
    _pass.dispose();
    super.dispose();
  }

  void login() async {
    setState(() {
      isWaiting = true;
    });
    try {
      Map account = {
        'email': _email.text.trim(),
        'password': _pass.text.trim(),
      };
      http.Response response = await http
          .post(
            uri,
            body: jsonEncode(account),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(const Duration(seconds: 10));
      // check server's response
      if (response.statusCode == 200) {
        // get token and save to local storage
        String token = response.body;
        // debugPrint(token);

        final storage = await SharedPreferences.getInstance();
        await storage.setString('token', token);
        // decode token to get user role
        final user = jsonDecode(token);
        // debugPrint(user['role']);

        // to prevent warning of using 'context' in navigation
        if (!mounted) return;
        // navigate to admin page or user page
        if (user['role'] == 'student') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (BuildContext context) => const StudentBrowsing(),
            ),
          );
        } else if (user['role'] == 'staff') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (BuildContext context) => const StaffDashboard(),
            ),
          );
        } else if (user['role'] == 'lecturer') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (BuildContext context) => const LecturerDashboard(),
            ),
          );
        }
      } else {
        // wrong username or password
        popDialog(response.body);
      }
    } on TimeoutException catch (e) {
      debugPrint(e.message);
      popDialog('Timeout error, try again!');
    } catch (e) {
      debugPrint(e.toString());
      popDialog('Unknown error, try again!');
    } finally {
      setState(() {
        isWaiting = false;
      });
    }
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 30,
                      vertical: 40,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(height: 40),
                        TextField(
                          controller: _email,
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.person_outline),
                            hintText: 'Email',
                            filled: true,
                            fillColor: Colors.grey.shade300,
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 18,
                            ),
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
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 18,
                            ),
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
                              checkColor: Color(0xFF0E2A5D),
                            ),
                            const Text(
                              'Remember me',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 40),
                        isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: const Color(0xFF0E2A5D),
                                  elevation: 10,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 80,
                                    vertical: 16,
                                  ),
                                ),
                                onPressed: login,
                                child: const Text(
                                  'SIGN IN',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                              ),

                        const SizedBox(height: 40),
                        GestureDetector(
                          onTap: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const SignUpPage(),
                              ),
                            );
                          },
                          child: const Text.rich(
                            TextSpan(
                              text: "Don’t have an Account? ",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                              ),
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
