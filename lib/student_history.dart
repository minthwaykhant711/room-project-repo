import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_application_1/logout_function.dart';
import 'student_browsing.dart';

class StudentHistory extends StatefulWidget {
  const StudentHistory({super.key});

  @override
  State<StudentHistory> createState() => _StudentHistoryState();
}

class _StudentHistoryState extends State<StudentHistory> {
  static const String _baseUrl = 'http://localhost:3000';

  // greeting
  String _firstName = '';

  // bookings from API
  List<Map<String, dynamic>> _pending = [];
  List<Map<String, dynamic>> _history = [];

  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Map<String, String> _authHeaders() {
    final id = StudentBrowsing.mobileTokenUserId;
    if (id != null && id.isNotEmpty) {
      return {
        'Authorization': 'Bearer $id',
        'Content-Type': 'application/json',
      };
    }
    return {'Content-Type': 'application/json'};
  }

  Future<void> _bootstrap() async {
    await _fetchMe(); // "Hi, <first_name>"
    await _fetchBookings(); // fill _pending and _history
  }

  Future<void> _fetchMe() async {
    try {
      final resp = await http
          .get(Uri.parse('$_baseUrl/me'), headers: _authHeaders())
          .timeout(const Duration(seconds: 8));
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        if (data is Map && data['ok'] == true && data['user'] is Map) {
          final u = data['user'] as Map;
          final fn = (u['first_name'] ?? '').toString().trim();
          if (fn.isNotEmpty && mounted) setState(() => _firstName = fn);
          if (u['id'] != null && StudentBrowsing.mobileTokenUserId == null) {
            StudentBrowsing.setMobileToken(u['id'].toString());
          }
          return;
        }
      }
    } catch (_) {}
    // fallback to saved value from sign-in
    try {
      final sp = await SharedPreferences.getInstance();
      final fn = sp.getString('first_name') ?? '';
      if (fn.isNotEmpty && mounted) setState(() => _firstName = fn);
    } catch (_) {}
  }

  String _formatYMD(String ymd) {
    try {
      final d = DateTime.parse(ymd);
      const w = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      const m = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      final wd = w[(d.weekday + 6) % 7];
      final mo = m[d.month - 1];
      return '$wd, $mo ${d.day}';
    } catch (_) {
      return ymd;
    }
  }

  Future<void> _fetchBookings() async {
    setState(() => _loading = true);
    try {
      final resp = await http
          .get(Uri.parse('$_baseUrl/bookings/mine'), headers: _authHeaders())
          .timeout(const Duration(seconds: 12));

      if (resp.statusCode != 200) {
        _snack(resp.body.isNotEmpty ? resp.body : 'Failed to load bookings');
        setState(() {
          _pending = [];
          _history = [];
        });
        return;
      }

      final data = jsonDecode(resp.body);
      if (data is! Map || data['ok'] != true || data['bookings'] is! List) {
        _snack('Invalid bookings response');
        setState(() {
          _pending = [];
          _history = [];
        });
        return;
      }

      final List rows = data['bookings'];
      final List<Map<String, dynamic>> pending = [];
      final List<Map<String, dynamic>> history = [];

      for (final b in rows) {
        final status = (b['booking_status'] ?? '')
            .toString(); // Waiting|Approved|Rejected
        final roomName = (b['room_name'] ?? 'Room').toString();
        final dateYMD = (b['booking_date'] ?? '').toString();
        final start = (b['start_time'] ?? '').toString();
        final end = (b['end_time'] ?? '').toString();
        final approver = (b['approver_name'] ?? '').toString(); // optional
        final reason = (b['reject_reason'] ?? '').toString(); // optional

        final map = {
          'room': roomName,
          'date': _formatYMD(dateYMD),
          'time':
              '${start.isNotEmpty ? start.substring(0, 5) : ''} - ${end.isNotEmpty ? end.substring(0, 5) : ''}',
          'status': status,
          'approver': approver,
          'reason': reason,
        };

        if (status == 'Waiting') {
          pending.add(map);
        } else {
          history.add(map);
        }
      }

      if (mounted) {
        setState(() {
          _pending = pending;
          _history = history;
        });
      }
    } on TimeoutException {
      _snack('Timeout while loading bookings');
    } catch (e) {
      _snack('Network error: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _snack(String m) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  }

  // Card builder (UI unchanged; uses booking_status)
  Widget _buildBookingCard(Map<String, dynamic> b) {
    final String status = (b['status'] ?? 'Waiting') as String;
    final String approver = (b['approver'] ?? '') as String;
    final String reason = (b['reason'] ?? '') as String;

    late final IconData statusIcon;
    late final Color statusColor;
    late final InlineSpan statusSpan;

    if (status == 'Waiting') {
      statusIcon = Icons.circle_outlined;
      statusColor = Colors.orange; // pending -> orange
      statusSpan = const TextSpan(text: 'Pending Approval');
    } else if (status == 'Approved') {
      statusIcon = Icons.check;
      statusColor = const Color(0xFF1FA22A); // approved -> green
      statusSpan = approver.isNotEmpty
          ? TextSpan(
              children: [
                const TextSpan(text: 'Approved by '),
                TextSpan(
                  text: approver,
                  style: const TextStyle(color: Colors.orange),
                ),
              ],
            )
          : const TextSpan(text: 'Approved');
    } else {
      statusIcon = Icons.close;
      statusColor = Colors.red; // rejected -> red
      statusSpan = approver.isNotEmpty
          ? TextSpan(
              children: [
                const TextSpan(text: 'Rejected by '),
                TextSpan(
                  text: approver,
                  style: const TextStyle(color: Colors.orange),
                ),
              ],
            )
          : const TextSpan(text: 'Rejected');
    }

    // Use same color for a visible card border to make status distinct
    final Color borderColor = statusColor;

    return Card(
      color: Colors.white,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: borderColor, width: 2),
      ),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Room name
            RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 16, color: Colors.black),
                children: [
                  const TextSpan(text: 'Session in '),
                  TextSpan(
                    text: b['room'],
                    style: const TextStyle(color: Colors.orange),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Date
            Row(
              children: [
                const Icon(Icons.calendar_month_outlined, size: 20),
                const SizedBox(width: 6),
                Text(b['date'], style: const TextStyle(fontSize: 14)),
              ],
            ),
            const SizedBox(height: 6),

            // Time
            Row(
              children: [
                const Icon(Icons.access_time, size: 18),
                const SizedBox(width: 6),
                Text(b['time'], style: const TextStyle(fontSize: 14)),
              ],
            ),
            const SizedBox(height: 10),

            // Status
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(statusIcon, color: statusColor, size: 20),
                const SizedBox(width: 6),
                Flexible(
                  child: RichText(
                    text: TextSpan(
                      style: const TextStyle(fontSize: 14, color: Colors.black),
                      children: [statusSpan],
                    ),
                  ),
                ),
              ],
            ),

            // Rejection reason (if any)
            if (status == 'Rejected' && reason.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.info_outline,
                    size: 18,
                    color: Colors.redAccent,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Reason: $reason',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String title) => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.inbox_outlined, size: 64, color: Colors.grey[400]),
        const SizedBox(height: 16),
        Text(
          '$title is empty',
          style: TextStyle(fontSize: 18, color: Colors.grey[600]),
        ),
        const SizedBox(height: 8),
        Text(
          'No ${title.toLowerCase()} bookings found',
          style: TextStyle(color: Colors.grey[500]),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final headerHeight = MediaQuery.of(context).size.height * 0.24;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFD9D9D9),
        extendBody: true,

        // Bottom Nav (unchanged)
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
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                  onPressed: () => Navigator.maybePop(context),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.home_filled,
                    color: Colors.white,
                    size: 28,
                  ),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const StudentBrowsing()),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.calendar_today, color: Colors.white),
                  onPressed: () {
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text(
                          'You are already on the Booking page',
                        ),
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
              ],
            ),
          ),
        ),

        // Body
        body: Column(
          children: [
            // Header (unchanged visuals; TabBar now uses inherited controller)
            Container(
              decoration: const BoxDecoration(
                color: Color(0xFF003366),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
                border: Border(
                  bottom: BorderSide(color: Colors.black, width: 2),
                ),
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
                        // Greeting
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            RichText(
                              text: TextSpan(
                                children: [
                                  const TextSpan(
                                    text: 'Hi',
                                    style: TextStyle(
                                      fontSize: 28,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  TextSpan(
                                    text: _firstName.isNotEmpty
                                        ? ', $_firstName'
                                        : ',',
                                    style: const TextStyle(
                                      fontSize: 28,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Text(
                              'Your Bookings',
                              style: TextStyle(
                                fontSize: 25,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
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
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.only(left: 20.0),
                    child: SizedBox(
                      width: 185,
                      child: TabBar(
                        labelColor: Colors.amber,
                        unselectedLabelColor: Colors.white70,
                        indicatorColor: Colors.amber,
                        indicatorSize: TabBarIndicatorSize.label,
                        dividerColor: Colors.transparent,
                        labelStyle: const TextStyle(fontSize: 20),
                        labelPadding: const EdgeInsets.symmetric(horizontal: 0),
                        tabs: const [
                          Tab(text: 'Pending'),
                          Tab(text: 'History'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Tabs content
            Expanded(
              child: TabBarView(
                children: [
                  _loading
                      ? const Center(child: CircularProgressIndicator())
                      : (_pending.isEmpty
                            ? _buildEmptyState('Pending')
                            : ListView.builder(
                                padding: const EdgeInsets.only(
                                  top: 10,
                                  bottom: 100,
                                ),
                                itemCount: _pending.length,
                                itemBuilder: (_, i) =>
                                    _buildBookingCard(_pending[i]),
                              )),
                  _loading
                      ? const Center(child: CircularProgressIndicator())
                      : (_history.isEmpty
                            ? _buildEmptyState('History')
                            : ListView.builder(
                                padding: const EdgeInsets.only(
                                  top: 10,
                                  bottom: 100,
                                ),
                                itemCount: _history.length,
                                itemBuilder: (_, i) =>
                                    _buildBookingCard(_history[i]),
                              )),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
