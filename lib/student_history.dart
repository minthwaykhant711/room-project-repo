import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/logout_function.dart';
import 'student_browsing.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class StudentHistory extends StatefulWidget {
  const StudentHistory({super.key});

  @override
  State<StudentHistory> createState() => _StudentHistoryState();
}

class _StudentHistoryState extends State<StudentHistory>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Timer? _refreshTimer; // add this
  late String username;

  // Use emulator-friendly host. For Android emulator use 10.0.2.2
  final String baseUrl = 'http://127.0.0.1:3000';

  @override
  void dispose() {
    _refreshTimer?.cancel(); // cancel timer
    _tabController.dispose();
    super.dispose();
  }

  List<dynamic> _bookings = [];
  bool _isLoading = true;

  Future<void> _fetchBookings() async {
    setState(() {
      _isLoading = true;
    });

    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('user_id');

    print('ℹ️ StudentHistory: SharedPreferences user_id = $userId');

    if (userId == null) {
      print("⚠️ No user_id found in SharedPreferences");
      setState(() {
        _isLoading = false;
      });
      return;
    }

    final uri = Uri.parse('$baseUrl/api/bookings/$userId');
    print('➡️ GET $uri');
    try {
      final response = await http.get(uri);
      print('⬅️ status=${response.statusCode} body=${response.body}');
      // add explicit debug of parsed JSON
      if (response.statusCode == 200) {
        try {
          final parsed = jsonDecode(response.body);
          print('🔍 parsed bookings json: $parsed');
        } catch (e) {
          print('⚠️ parse error: $e');
        }
      }
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List<dynamic>;
        final normalized = data.map((raw) {
          final m = Map<String, dynamic>.from(raw as Map);
          // normalize booking_date to LOCAL yyyy-mm-dd
          final rawDate = (m['booking_date'] ?? '').toString();
          String localDateStr = rawDate;
          try {
            final dt = DateTime.parse(rawDate).toLocal();
            localDateStr =
                '${dt.year.toString().padLeft(4, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
          } catch (_) {
            // fallback to first 10 chars or original
            if (rawDate.length >= 10) localDateStr = rawDate.substring(0, 10);
          }
          m['booking_date'] = localDateStr;

          // canonicalize status (map common variants)
          final rs = (m['booking_status'] ?? '')
              .toString()
              .trim()
              .toLowerCase();
          String canonical;
          if (rs.contains('pend') || rs.contains('wait'))
            canonical = 'pending';
          else if (rs.contains('approv') || rs == 'approved')
            canonical = 'approved';
          else if (rs.contains('reject'))
            canonical = 'rejected';
          else
            canonical = rs.isNotEmpty ? rs : 'unknown';
          m['__status_norm'] = canonical;

          return m;
        }).toList();

        print(
          '🔎 normalized bookings: ${normalized.map((b) => {'id': b['booking_id'], 'date': b['booking_date'], 'status': b['__status_norm']}).toList()}',
        );
        setState(() {
          _bookings = normalized;
          _isLoading = false;
        });
      } else {
        print(
          "⚠️ Failed to load bookings: ${response.statusCode} ${response.body}",
        );
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('⚠️ Exception fetching bookings: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadUserData();
    _fetchBookings();
    _refreshTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      _fetchBookings();
    });
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      username = prefs.getString('first_name') ?? 'User';
    });
  }

  // ────────────────────────────────────────────────────────────────────────────
  // Card builder (UI matches Figma + rejection reason)
  Widget _buildBookingCard(Map<String, dynamic> b) {
    final statusNorm = (b['__status_norm'] ?? (b['booking_status'] ?? ''))
        .toString()
        .trim()
        .toLowerCase();
    final approver = b['approver_name'];

    late final IconData statusIcon;
    late final Color statusColor;
    late final InlineSpan statusSpan;

    if (statusNorm == 'pending') {
      statusIcon = Icons.circle_outlined;
      statusColor = Colors.amber;
      statusSpan = const TextSpan(text: 'Pending Approval');
    } else if (statusNorm == 'approved') {
      statusIcon = Icons.check_circle;
      statusColor = Colors.green;
      statusSpan = TextSpan(
        children: [
          const TextSpan(text: 'Approved by '),
          TextSpan(
            text: approver ?? 'Unknown',
            style: const TextStyle(color: Colors.orange),
          ),
        ],
      );
    } else if (statusNorm == 'rejected') {
      statusIcon = Icons.close;
      statusColor = Colors.red;
      statusSpan = TextSpan(
        children: [
          const TextSpan(text: 'Rejected by '),
          TextSpan(
            text: approver ?? 'Unknown',
            style: const TextStyle(color: Colors.orange),
          ),
        ],
      );
    } else {
      statusIcon = Icons.info_outline;
      statusColor = Colors.grey;
      statusSpan = TextSpan(
        text: (b['booking_status'] ?? 'Unknown').toString(),
      );
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Session in ${b['room_name']}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 18),
                const SizedBox(width: 6),
                Text(b['booking_date']),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.access_time, size: 18),
                const SizedBox(width: 6),
                Text('${b['start_time']} - ${b['end_time']}'),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(statusIcon, color: statusColor, size: 20),
                const SizedBox(width: 6),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      RichText(
                        text: TextSpan(
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black,
                          ),
                          children: [statusSpan],
                        ),
                      ),
                      if (statusNorm == 'rejected' &&
                          b['reason'] != null &&
                          b['reason'].toString().isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            'Reason: ${b['reason']}',
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.redAccent,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
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

  // ────────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFD9D9D9),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final today = DateTime.now();
    // Use a normalized "date only" value for comparisons
    final todayStr =
        '${today.year.toString().padLeft(4, '0')}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    final todayDateOnly = DateTime(today.year, today.month, today.day);

    final List<dynamic> pending = [];
    final List<dynamic> history = [];

    for (final b in _bookings) {
      final status = (b['__status_norm'] ?? (b['booking_status'] ?? ''))
          .toString()
          .trim()
          .toLowerCase();
      var dateStr = (b['booking_date'] ?? '').toString();
      if (dateStr.length >= 10)
        dateStr = dateStr.substring(0, 10); // yyyy-mm-dd

      if (status == 'pending') {
        // show only pending that are for TODAY
        if (dateStr == todayStr) {
          pending.add(b);
        } else {
          // old pending -> ignore (auto-disappear)
          continue;
        }
      } else {
        // approved/rejected/other -> history
        history.add(b);
      }
    }

    // debug
    print('ℹ️ pending=${pending.length} history=${history.length}');

    final headerHeight = MediaQuery.of(context).size.height * 0.24;

    return Scaffold(
      backgroundColor: const Color(0xFFD9D9D9),
      extendBody: true,

      // Bottom Nav
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
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const StudentBrowsing()),
                  ).then((_) {
                    // This runs when coming back to StudentHistory
                    _fetchBookings();
                  });
                },
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
          // Header
          Container(
            decoration: const BoxDecoration(
              color: Color(0xFF003366),
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
                                  text: ', $username',
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
                            style: TextStyle(fontSize: 25, color: Colors.white),
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
                      controller: _tabController,
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

          // Tabs
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                pending.isEmpty
                    ? _buildEmptyState('Pending')
                    : RefreshIndicator(
                        onRefresh: _fetchBookings,
                        child: ListView.builder(
                          padding: const EdgeInsets.only(top: 10, bottom: 100),
                          itemCount: pending.length,
                          itemBuilder: (_, i) => _buildBookingCard(pending[i]),
                        ),
                      ),
                history.isEmpty
                    ? _buildEmptyState('History')
                    : RefreshIndicator(
                        onRefresh: _fetchBookings,
                        child: ListView.builder(
                          padding: const EdgeInsets.only(top: 10, bottom: 100),
                          itemCount: history.length,
                          itemBuilder: (_, i) => _buildBookingCard(history[i]),
                        ),
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
