// ignore_for_file: deprecated_member_use
import 'dart:async';
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

class _LecturerDashboardState extends State<LecturerDashboard>
    with WidgetsBindingObserver {
  // ===== Brand Colors (same as staff pages) =====
  static const kNavy = Color(0xFF003366);
  static const kGreen = Color(0xFF1FA22A);
  static const kRed = Color(0xFFDA351C);
  static const kGreyBg = Color(0xFFD9D9D9);

  String username = '';

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
  // Poll timer to refresh summary periodically while the screen is visible
  Timer? _pollTimer;
  // prevent overlapping requests
  bool _isFetching = false;
  StreamSubscription<String>? _eventsSub;

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

  int _toInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is double) return v.toInt();
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }

  Future<void> _fetchStatusSummary() async {
    if (_isFetching) return; // avoid overlapping
    _isFetching = true;
    setState(() => _loading = true);
    try {
      final today = DateTime.now().toIso8601String().substring(
        0,
        10,
      ); // YYYY-MM-DD
      final uri = Uri.parse('$kBaseUrl/api/rooms/status-summary?date=$today');
      final resp = await http
          .get(uri, headers: _authHeaders())
          .timeout(const Duration(seconds: 8));

      if (resp.statusCode != 200) {
        // ignore: avoid_print
        print(
          'fetchStatusSummary: non-200 ${resp.statusCode} body=${resp.body}',
        );
        setState(() => _error = 'Server ${resp.statusCode}');
        return;
      }

      final dynamic data = jsonDecode(resp.body);

      int available = 0, pending = 0, reserved = 0, disabled = 0;

      // Case A: { ok: true, summary: { available: x, ... } }
      if (data is Map && data['summary'] is Map) {
        final Map summary = data['summary'] as Map;
        available = _toInt(
          summary['available'] ??
              summary['available_count'] ??
              summary['avail'],
        );
        pending = _toInt(
          summary['pending'] ?? summary['pending_count'] ?? summary['pend'],
        );
        reserved = _toInt(
          summary['reserved'] ?? summary['reserved_count'] ?? summary['resv'],
        );
        disabled = _toInt(
          summary['disabled'] ??
              summary['disabled_count'] ??
              summary['disabled_rooms'],
        );

        // Case B: flat map with counts at root
      } else if (data is Map &&
          (data['available'] != null || data['pending'] != null)) {
        available = _toInt(data['available']);
        pending = _toInt(data['pending']);
        reserved = _toInt(data['reserved']);
        disabled = _toInt(data['disabled']);

        // Case C: list of { status/name, count }
      } else if (data is List) {
        for (final e in data) {
          if (e is Map) {
            final label = (e['status'] ?? e['name'] ?? '')
                .toString()
                .toLowerCase();
            final cnt = _toInt(e['count'] ?? e['value']);
            if (label.contains('avail'))
              available += cnt;
            else if (label.contains('pend'))
              pending += cnt;
            else if (label.contains('res'))
              reserved += cnt;
            else if (label.contains('dis'))
              disabled += cnt;
          }
        }

        // Case D: rooms array -> compute counts via status
      } else if (data is Map && data['rooms'] is List) {
        final List rooms = data['rooms'] as List;
        for (final r in rooms) {
          try {
            final Map m = Map<String, dynamic>.from(r as Map);
            final st =
                m['status'] ??
                m['state'] ??
                m['booking_status'] ??
                m['room_status'];
            final ps = st == null ? 0 : _toInt(st);
            if (ps == 0)
              pending += 1;
            else if (ps == 1)
              reserved += 1;
            else if (ps == -1)
              disabled += 1;
            else
              available += 1;
          } catch (_) {
            available += 1;
          }
        }
      } else {
        // Unknown shape: log and surface error to UI
        // ignore: avoid_print
        print('fetchStatusSummary: unexpected body shape: ${resp.body}');
        setState(() => _error = 'Unexpected response');
        return;
      }

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
      _isFetching = false;
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

  // Load current user profile to show correct name in header and set token id
  Future<void> _fetchMe() async {
    try {
      final resp = await http
          .get(Uri.parse('$kBaseUrl/me'), headers: _authHeaders())
          .timeout(const Duration(seconds: 8));
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        if (data is Map && data['ok'] == true && data['user'] is Map) {
          final u = data['user'] as Map;
          final fn = (u['first_name'] ?? u['firstName'] ?? '')
              .toString()
              .trim();
          final ln = (u['last_name'] ?? u['lastName'] ?? '').toString().trim();
          final display = (fn.isNotEmpty && ln.isNotEmpty)
              ? '$fn $ln'
              : (fn.isNotEmpty ? fn : (ln.isNotEmpty ? ln : ''));
          if (mounted) setState(() => username = display);
          if (u['id'] != null) {
            StudentBrowsing.setMobileToken(u['id'].toString());
          }
        }
      }
    } catch (_) {
      // non-fatal: keep default username if network fails
    }
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
                                  text: username.isNotEmpty
                                      ? ', $username'
                                      : '',
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
    WidgetsBinding.instance.addObserver(this);
    _fetchMe();
    _fetchStatusSummary();
    // Note: App-wide event bus is optional. If present, it can be used to
    // refresh immediately after booking actions. Currently not subscribing
    // here to avoid a missing dependency.
    // start a periodic poll every 6 seconds (adjust as needed)
    _pollTimer = Timer.periodic(const Duration(seconds: 6), (_) async {
      if (!mounted) return;
      // only poll when screen is visible
      if (ModalRoute.of(context)?.isCurrent == true) {
        await _fetchStatusSummary();
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // refresh when app returns to foreground
    if (state == AppLifecycleState.resumed) {
      _fetchStatusSummary();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _eventsSub?.cancel();
    _pollTimer?.cancel();
    super.dispose();
  }
}
