// ignore_for_file: deprecated_member_use
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter_application_1/logout_function.dart';
import 'package:flutter_application_1/lecturer_browsing.dart';
import 'package:flutter_application_1/lecturer_history.dart';
import 'package:flutter_application_1/student_browsing.dart';

class LecturerDashboard extends StatefulWidget {
  const LecturerDashboard({super.key});

  @override
  State<LecturerDashboard> createState() => _LecturerDashboardState();
}

class _LecturerDashboardState extends State<LecturerDashboard> {
  // ===== Brand Colors (same as staff pages) =====
  static const kNavy = Color(0xFF003366);
  static const kGreen = Color(0xFF1FA22A);
  static const kRed = Color(0xFFDA351C);
  static const kGreyBg = Color(0xFFD9D9D9);

  String username = 'Aj.Surapong';

  // backend base (match your app.js)
  static const String kBaseUrl = 'http://localhost:3000';

  // live data for the 4 cards
  List<Map<String, dynamic>> _statusCards = [
    {'title': 'Available', 'count': 0, 'titleColor': kGreen},
    {'title': 'Pending', 'count': 0, 'titleColor': Colors.orange},
    {'title': 'Reserved', 'count': 0, 'titleColor': Colors.blue},
    {'title': 'Disabled', 'count': 0, 'titleColor': kRed},
  ];

  bool _loading = false; // show spinner while fetching
  String? _error; // optional: store last fetch error

  // ===== Build Status Card =====
  Widget _buildStatusCard(Map<String, dynamic> item) {
    final bool isDisabled = item['title'] == 'Disabled';
    final Color countColor = isDisabled ? kNavy.withOpacity(0.6) : kNavy;

    return Card(
      color: Colors.white,
      elevation: 6,
      shadowColor: Colors.black.withOpacity(0.15),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: const BorderSide(color: kNavy, width: 1),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            item['title'],
            style: TextStyle(
              color: item['titleColor'],
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            '${item['count']}',
            style: TextStyle(
              color: countColor,
              fontSize: 40,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _fetchStatusSummary() async {
    setState(() => _loading = true);
    try {
      final today = DateTime.now().toIso8601String().substring(
        0,
        10,
      ); // YYYY-MM-DD
      final uri = Uri.parse('$kBaseUrl/api/rooms/status-summary?date=$today');
      // your endpoint in backend used req to compute today's date itself, so date param optional
      final resp = await http
          .get(uri, headers: _authHeaders())
          .timeout(const Duration(seconds: 8));

      if (resp.statusCode != 200) {
        // record error for the UI (optional)
        setState(() => _error = 'Server ${resp.statusCode}: ${resp.body}');
        return;
      }

      final Map<String, dynamic> data =
          jsonDecode(resp.body) as Map<String, dynamic>;
      if (data['ok'] != true) {
        setState(() => _error = 'Invalid response');
        return;
      }

      final Map<String, dynamic> summary =
          (data['summary'] ?? {}) as Map<String, dynamic>;
      // summary expected shape: { available: 3, pending: 1, reserved: 2, disabled: 0 }
      final int available = (summary['available'] ?? 0) as int;
      final int pending = (summary['pending'] ?? 0) as int;
      final int reserved = (summary['reserved'] ?? 0) as int;
      final int disabled = (summary['disabled'] ?? 0) as int;

      setState(() {
        _statusCards = [
          {'title': 'Available', 'count': available, 'titleColor': kGreen},
          {'title': 'Pending', 'count': pending, 'titleColor': Colors.orange},
          {'title': 'Reserved', 'count': reserved, 'titleColor': Colors.blue},
          {'title': 'Disabled', 'count': disabled, 'titleColor': kRed},
        ];
        _error = null;
      });
    } catch (e, st) {
      // log & surface a friendly message
      // ignore: avoid_print
      print('fetchStatusSummary error: $e\n$st');
      setState(() => _error = 'Network error');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Map<String, String> _authHeaders() {
    // if you have StudentBrowsing.mobileTokenUserId static token, use it:
    final token =
        StudentBrowsing.mobileTokenUserId; // or load from SharedPreferences
    if (token != null && token.isNotEmpty) {
      return {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      };
    }
    return {'Content-Type': 'application/json'};
  }

  // ===== Main Build =====
  @override
  Widget build(BuildContext context) {
    final headerHeight = MediaQuery.of(context).size.height * 0.26;

    return Scaffold(
      backgroundColor: kGreyBg,

      // ===== BOTTOM NAV BAR (standardized) =====
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          height: 56,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 1),
          decoration: BoxDecoration(
            color: Colors.black87,
            borderRadius: BorderRadius.circular(28),
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 8,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Back button
              IconButton(
                icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                onPressed: () => Navigator.maybePop(context),
              ),
              // Home button
              IconButton(
                icon: const Icon(
                  Icons.home_filled,
                  color: Colors.white,
                  size: 28,
                ),
                onPressed: () {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('You are already on the Home page'),
                      duration: const Duration(milliseconds: 1200),
                      behavior: SnackBarBehavior.floating,
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.search, color: Colors.white, size: 28),
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const LecturerBrowsing()),
                  );
                },
              ),
              // Calendar (Booking History)
              IconButton(
                icon: const Icon(
                  Icons.calendar_today,
                  color: Colors.white,
                  size: 28,
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const LecturerHistory()),
                  );
                },
              ),
            ],
          ),
        ),
      ),

      // ===== BODY =====
      body: Column(
        children: [
          // ===== HEADER =====
          Container(
            decoration: const BoxDecoration(
              color: kNavy,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
              border: Border(bottom: BorderSide(color: Colors.black, width: 2)),
            ),
            width: double.infinity,
            height: headerHeight,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 60),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Hi, Lecturer + subtitle
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          RichText(
                            text: TextSpan(
                              children: [
                                const TextSpan(
                                  text: 'Hi',
                                  style: TextStyle(
                                    fontSize: 30,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                TextSpan(
                                  text: ', $username',
                                  style: const TextStyle(
                                    fontSize: 30,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Text(
                            "Lecturer's Dashboard",
                            style: TextStyle(fontSize: 26, color: Colors.white),
                          ),
                        ],
                      ),
                      // Logout button
                      IconButton(
                        onPressed: () => showLogoutDialog(context),
                        icon: const Icon(
                          Icons.logout_rounded,
                          color: Colors.white,
                          size: 40,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Center(
                  child: Text(
                    "Dashboard shows today's room status summary.",
                    style: TextStyle(color: Colors.white.withOpacity(0.7)),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),

          SizedBox(height: 35),

          // ===== SCROLLABLE BODY CONTENT =====
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                children: [
                  // ===== GRID STATUS CARDS =====
                  if (_loading)
                    const SizedBox(
                      height: 160,
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (_error != null)
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        'Failed to load: $_error',
                        style: TextStyle(color: Colors.red),
                      ),
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 1, 14, 8),
                      child: GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 10,
                        childAspectRatio: 1.05,
                        children: _statusCards.map(_buildStatusCard).toList(),
                      ),
                    ),

                  const SizedBox(height: 28),

                  const SizedBox(height: 25),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _fetchStatusSummary();
  }
}
