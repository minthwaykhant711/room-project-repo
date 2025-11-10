import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_application_1/lecturer_browsing.dart';
import 'package:flutter_application_1/student_browsing.dart';
import 'package:flutter_application_1/logout_function.dart';
import 'package:flutter_application_1/lecturer_dashboard.dart';

class LecturerHistory extends StatefulWidget {
  const LecturerHistory({super.key});

  @override
  State<LecturerHistory> createState() => _LecturerHistoryState();
}

class _LecturerHistoryState extends State<LecturerHistory>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late TabController _tabController;
  String username = '';
  static const String _baseUrl = 'http://localhost:3000';

  // Live lists (populated from server, fall back to _allBookings demo)
  List<Map<String, dynamic>> _pending = [];
  List<Map<String, dynamic>> _history = [];
  bool _loading = false;

  Map<String, String> _authHeaders() {
    final token = StudentBrowsing.mobileTokenUserId;
    if (token != null && token.isNotEmpty) {
      return {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      };
    }
    return {'Content-Type': 'application/json'};
  }

  // Load current lecturer profile to show correct name and set token id
  Future<void> _fetchMe() async {
    try {
      final resp = await http
          .get(Uri.parse('$_baseUrl/me'), headers: _authHeaders())
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
          if (u['id'] != null)
            StudentBrowsing.setMobileToken(u['id'].toString());
        }
      }
    } catch (_) {
      // non-fatal
    }
  }

  // helper: parse status which might be int or string like 'Waiting'/'Approved' or numeric string
  int _parseStatus(dynamic s) {
    if (s is int) return s;
    if (s is String) {
      final ls = s.toLowerCase();
      if (ls == 'waiting' || ls == 'pending' || ls == '0') return 0;
      if (ls == 'approved' || ls == '1') return 1;
      if (ls == 'rejected' || ls == '-1') return -1;
      final p = int.tryParse(s);
      if (p != null) return p;
    }
    return 0;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _tabController = TabController(length: 2, vsync: this);
    // populate from demo first so UI isn't empty, then try network
    _refreshListsFromDemo();
    _fetchMe();
    _refreshLists();
    // poll periodically to keep lists fresh while this screen is visible
    _pollTimer = Timer.periodic(const Duration(seconds: 6), (_) {
      if (!mounted) return;
      if (ModalRoute.of(context)?.isCurrent == true) _refreshLists();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pollTimer?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  Timer? _pollTimer;

  // ---------------------------------------------------------------------------
  // DIALOG HELPERS (Figma-style)
  // ---------------------------------------------------------------------------
  Future<void> _showApprovedDialog() async {
    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        Future.delayed(const Duration(milliseconds: 1200), () {
          if (Navigator.of(ctx, rootNavigator: true).canPop()) {
            Navigator.of(ctx, rootNavigator: true).pop();
          }
        });
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 40),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.check_circle, size: 120, color: Color(0xFF1FA22A)),
                SizedBox(height: 14),
                Text(
                  'Booking Approved',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showRejectedDialog() async {
    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        Future.delayed(const Duration(milliseconds: 1200), () {
          if (Navigator.of(ctx, rootNavigator: true).canPop()) {
            Navigator.of(ctx, rootNavigator: true).pop();
          }
        });
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 40),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.cancel, size: 120, color: Color(0xFFDA351C)),
                SizedBox(height: 14),
                Text(
                  'Booking Rejected',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // ACTIONS
  // ---------------------------------------------------------------------------
  Future<void> _approveBooking(Map<String, dynamic> booking) async {
    final bool confirmed =
        await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Approve booking'),
            content: const Text(
              'Are you sure you want to approve this booking?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Approve'),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed) return;

    // optimistic: call backend to approve (endpoint may not exist yet)
    final bookingId = booking['booking_id'] ?? booking['id'];
    try {
      final uri = Uri.parse('$_baseUrl/bookings/$bookingId/approve');
      final resp = await http
          .post(uri, headers: _authHeaders())
          .timeout(const Duration(seconds: 8));
      if (resp.statusCode == 200 || resp.statusCode == 204) {
        await _showApprovedDialog();
        // move locally
        setState(() {
          _pending.remove(booking);
          final h = Map<String, dynamic>.from(booking);
          h['status'] = 1;
          h['approver'] = username;
          _history.insert(0, h);
        });
        return;
      }
    } catch (_) {}

    // fallback: update local demo lists
    await _showApprovedDialog();
    if (!mounted) return;
    setState(() {
      // If server not reachable, optimistically update UI locally
      _pending.remove(booking);
      final h = Map<String, dynamic>.from(booking);
      h['status'] = 1;
      h['approver'] = username;
      _history.insert(0, h);
    });
  }

  Future<void> _rejectBooking(Map<String, dynamic> booking) async {
    final reasonController = TextEditingController();
    bool enabled = false;

    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialog) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text('Reason for Rejection'),
          content: TextField(
            controller: reasonController,
            autofocus: true,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: 'Reason',
              hintText: 'e.g., Room maintenance',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 18,
              ),
            ),
            onChanged: (t) => setDialog(() => enabled = t.trim().isNotEmpty),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: enabled ? () => Navigator.of(ctx).pop(true) : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF003366),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Submit'),
            ),
          ],
        ),
      ),
    );

    if (ok == true) {
      final bookingId = booking['booking_id'] ?? booking['id'];
      try {
        final uri = Uri.parse('$_baseUrl/bookings/$bookingId/reject');
        final resp = await http
            .post(
              uri,
              headers: _authHeaders(),
              body: jsonEncode({'reason': reasonController.text.trim()}),
            )
            .timeout(const Duration(seconds: 8));
        if (resp.statusCode == 200 || resp.statusCode == 204) {
          await _showRejectedDialog();
          if (!mounted) return;
          setState(() {
            _pending.remove(booking);
            final h = Map<String, dynamic>.from(booking);
            h['status'] = -1;
            h['approver'] = username;
            h['reason'] = reasonController.text.trim();
            _history.insert(0, h);
          });
          return;
        }
      } catch (_) {}

      // fallback to demo update
      await _showRejectedDialog();
      if (!mounted) return;
      setState(() {
        // Update lists locally when backend not reachable
        _pending.remove(booking);
        final h = Map<String, dynamic>.from(booking);
        h['status'] = -1;
        h['approver'] = username;
        h['reason'] = reasonController.text.trim();
        _history.insert(0, h);
      });
    }
  }

  // -------------------------------------------------------------------------
  // Fetching from server (if endpoints exist). Otherwise keep demo data.
  Future<void> _refreshLists() async {
    setState(() => _loading = true);
    try {
      final today = DateTime.now().toIso8601String().substring(0, 10);
      // attempt to fetch pending bookings for today
      final pUri = Uri.parse('$_baseUrl/bookings/pending?date=$today');
      final hUri = Uri.parse('$_baseUrl/bookings/for-lecturer');
      final pResp = await http
          .get(pUri, headers: _authHeaders())
          .timeout(const Duration(seconds: 8));
      if (pResp.statusCode == 200) {
        final Map<String, dynamic> pd =
            jsonDecode(pResp.body) as Map<String, dynamic>;
        // Debug log: show how many bookings returned
        // ignore: avoid_print
        print('lecturer_history: /bookings/pending returned ok=${pd['ok']}');
        if (pd['bookings'] is List) {
          final List rows = pd['bookings'];
          // primary filter: pending today
          final filtered = rows
              .where((raw) {
                try {
                  final Map<String, dynamic> b = Map<String, dynamic>.from(raw);
                  final int st = _parseStatus(
                    b['booking_status'] ?? b['status'],
                  );
                  if (st != 0) return false; // only waiting/pending
                  final bd = (b['booking_date'] ?? b['date'])?.toString() ?? '';
                  if (bd.length >= 10) {
                    final ymd = bd.substring(0, 10);
                    return ymd == today;
                  }
                  return false;
                } catch (e) {
                  // ignore this row
                  // ignore: avoid_print
                  print('lecturer_history: filter error $e');
                  return false;
                }
              })
              .map((e) => Map<String, dynamic>.from(e))
              .toList();

          if (filtered.isNotEmpty) {
            _pending = filtered;
          } else {
            // fallback: if server returned rows and some are pending but date mismatch,
            // surface them for debugging so you can see incoming requests.
            final pendingsAny = rows
                .where((raw) {
                  try {
                    final Map<String, dynamic> b = Map<String, dynamic>.from(
                      raw,
                    );
                    return _parseStatus(b['booking_status'] ?? b['status']) ==
                        0;
                  } catch (_) {
                    return false;
                  }
                })
                .map((e) => Map<String, dynamic>.from(e))
                .toList();
            if (pendingsAny.isNotEmpty) {
              // ignore: avoid_print
              print(
                'lecturer_history: no today-matching pending found, showing all pending for debugging',
              );
              _pending = pendingsAny;
            } else {
              _pending = [];
            }
          }
        } else {
          // ignore: avoid_print
          print(
            'lecturer_history: /bookings/pending missing bookings list: ${pResp.body}',
          );
        }
      } else {
        // ignore: avoid_print
        print(
          'lecturer_history: /bookings/pending status=${pResp.statusCode} body=${pResp.body}',
        );
      }

      final hResp = await http
          .get(hUri, headers: _authHeaders())
          .timeout(const Duration(seconds: 8));
      if (hResp.statusCode == 200) {
        final Map<String, dynamic> hd =
            jsonDecode(hResp.body) as Map<String, dynamic>;
        if (hd['ok'] == true && hd['bookings'] is List) {
          // server should return history (approved/rejected) for this lecturer.
          // Only keep items that are approved/rejected (status != 0) and where
          // the current lecturer is the approver (match by approver id or name).
          final List rows = hd['bookings'];
          final String myToken = StudentBrowsing.mobileTokenUserId ?? '';
          final List<Map<String, dynamic>> kept = [];
          for (final raw in rows) {
            try {
              final Map<String, dynamic> b = Map<String, dynamic>.from(raw);
              final int st = _parseStatus(b['booking_status'] ?? b['status']);
              if (st == 0) continue; // skip pending

              // determine approver identity
              final approverName = _firstString(b, [
                'approver',
                'approver_name',
                'approved_by',
                'approvedBy',
                'approverName',
              ]);
              final approverId =
                  (b['approver_id'] ?? b['approverId'] ?? b['approver_id'])
                      ?.toString() ??
                  '';

              // include only if this lecturer approved/rejected it
              final bool mine =
                  (approverName.isNotEmpty && approverName == username) ||
                  (approverId.isNotEmpty &&
                      myToken.isNotEmpty &&
                      approverId == myToken);
              if (!mine) continue;

              // ensure approver name is present for display
              if (approverName.isEmpty) b['approver'] = username;

              kept.add(b);
            } catch (_) {
              // ignore malformed row
            }
          }
          _history = kept;
        }
      }
    } catch (_) {
      // keep demo as fallback
      _refreshListsFromDemo();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _refreshListsFromDemo() {
    // No demo data: leave lists empty when server unreachable
    _pending = [];
    _history = [];
  }

  // ---------------------------------------------------------------------------
  // CARD & EMPTY
  // ---------------------------------------------------------------------------
  String _firstString(Map<String, dynamic> m, List<String> keys) {
    for (final k in keys) {
      if (!m.containsKey(k)) continue;
      final v = m[k];
      if (v == null) continue;
      if (v is String && v.trim().isNotEmpty) return v.trim();
      if (v is int || v is double) return v.toString();
      if (v is Map) {
        if (v['name'] != null) return v['name'].toString();
        if (v['room_name'] != null) return v['room_name'].toString();
      }
    }
    return '';
  }

  Map<String, String> _splitDateTime(String raw) {
    if (raw.isEmpty) return {'date': '', 'time': ''};
    if (raw.contains('T')) {
      try {
        final parts = raw.split('T');
        final date = parts[0];
        String time = parts.length > 1 ? parts[1] : '';
        if (time.contains('+')) time = time.split('+')[0];
        if (time.contains('-')) time = time.split('-')[0];
        if (time.contains('Z')) time = time.replaceAll('Z', '');
        if (time.contains(':')) {
          final hhmm = time.split(':');
          if (hhmm.length >= 2) time = '${hhmm[0]}:${hhmm[1]}';
        }
        return {'date': date, 'time': time};
      } catch (_) {
        return {'date': raw, 'time': ''};
      }
    }
    if (raw.contains(' ')) {
      final idx = raw.indexOf(' ');
      return {'date': raw.substring(0, idx), 'time': raw.substring(idx + 1)};
    }
    return {'date': raw, 'time': ''};
  }

  Widget _buildBookingCard(Map<String, dynamic> b) {
    // Defensive parsing: server may return status under different keys
    final int status = _parseStatus(
      b['booking_status'] ?? b['status'] ?? b['bookingStatus'],
    );
    final String approver = _firstString(b, [
      'approver',
      'approver_name',
      'approved_by',
      'approvedBy',
    ]);
    // pending is purely determined by status == 0
    final bool isPending = status == 0;
    // other safe string getters: try multiple possible keys and nested shapes
    final String room = _firstString(b, [
      'room',
      'room_name',
      'roomName',
      'room_number',
    ]);
    final String rawDate = _firstString(b, [
      'booking_date',
      'date',
      'bookingDate',
      'start',
    ]);
    final dt = _splitDateTime(rawDate);
    final String date = dt['date'] ?? '';
    final String time =
        dt['time'] ?? _firstString(b, ['time', 'time_slot', 'slot']);
    final String bookedBy = _firstString(b, [
      'booked_by',
      'bookedBy',
      'user',
      'requester',
      'student_name',
    ]);
    final String reason = _firstString(b, ['reason', 'notes', 'message']);

    String statusText;
    Color statusColor;
    IconData statusIcon;

    if (isPending) {
      statusText = 'Pending Approval';
      statusColor = Colors.orange; // pending -> orange (match student/staff)
      statusIcon = Icons.circle_outlined;
    } else if (status == -1) {
      statusText = 'Rejected';
      statusColor = Colors.red;
      statusIcon = Icons.close;
    } else {
      statusText = 'Approved';
      statusColor = const Color(
        0xFF1FA22A,
      ); // approved -> green (match student view)
      statusIcon = Icons.check;
    }

    // use statusColor for a visible card border to make status distinct
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
            // Title + room
            RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 16, color: Colors.black),
                children: [
                  const TextSpan(text: 'Session in '),
                  TextSpan(
                    text: room,
                    style: const TextStyle(color: Colors.orange),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Date & time
            Row(
              children: [
                const Icon(Icons.calendar_month_outlined, size: 20),
                const SizedBox(width: 6),
                Text(date, style: const TextStyle(fontSize: 14)),
                const SizedBox(width: 20),
                const Icon(Icons.access_time, size: 18),
                const SizedBox(width: 6),
                Text(time, style: const TextStyle(fontSize: 14)),
              ],
            ),
            const SizedBox(height: 8),

            // Booked by
            Row(
              children: [
                const Icon(Icons.person_outline, size: 20),
                const SizedBox(width: 6),
                RichText(
                  text: TextSpan(
                    style: const TextStyle(fontSize: 14, color: Colors.black),
                    children: [
                      const TextSpan(text: 'Booked by '),
                      TextSpan(
                        text: bookedBy,
                        style: const TextStyle(color: Colors.orange),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // show request reason if provided (for pending or history)
            if (reason.isNotEmpty) ...[
              Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    size: 18,
                    color: Colors.black54,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      reason,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],

            // Pending actions OR status line
            if (isPending) ...[
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _approveBooking(b),
                      icon: const Icon(
                        Icons.check,
                        size: 18,
                        color: Colors.white,
                      ),
                      label: const Text(
                        'Approve',
                        style: TextStyle(color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1FA22A),
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        shape: const StadiumBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _rejectBooking(b),
                      icon: const Icon(
                        Icons.close,
                        size: 18,
                        color: Colors.white,
                      ),
                      label: const Text(
                        'Reject',
                        style: TextStyle(color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFDA351C),
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        shape: const StadiumBorder(),
                      ),
                    ),
                  ),
                ],
              ),
            ] else ...[
              Row(
                children: [
                  Icon(statusIcon, color: statusColor, size: 20),
                  const SizedBox(width: 6),
                  RichText(
                    text: TextSpan(
                      style: const TextStyle(fontSize: 14, color: Colors.black),
                      children: [
                        TextSpan(text: statusText),
                        const TextSpan(text: ' by '),
                        TextSpan(
                          text: approver,
                          style: const TextStyle(color: Colors.orange),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (reason.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.info_outline,
                      size: 20,
                      color: Colors.redAccent,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Reason: $reason',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
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

  // ---------------------------------------------------------------------------
  // BUILD
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final pending = _pending;
    final history = _history;
    final headerHeight = MediaQuery.of(context).size.height * 0.24;
    return Scaffold(
      backgroundColor: const Color(0xFFD9D9D9),
      extendBody: true,

      // ===== Bottom Nav (same format as Staff) =====
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
                  MaterialPageRoute(builder: (_) => const LecturerDashboard()),
                ),
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
              IconButton(
                icon: const Icon(Icons.calendar_today, color: Colors.white),
                onPressed: () {
                  // already here
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

      // ===== Body =====
      body: Column(
        children: [
          // ===== Header (matched to StaffHistory) =====
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
                      // Greeting + subtitle
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
                                  text: username.isNotEmpty
                                      ? ', $username'
                                      : '',
                                  style: const TextStyle(
                                    fontSize: 28,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Text(
                            'Booking Requests',
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

                // Tabs
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

          // ===== Tab Content =====
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _loading
                    ? const Center(child: CircularProgressIndicator())
                    : (pending.isEmpty
                          ? _buildEmptyState('Pending')
                          : ListView.builder(
                              padding: const EdgeInsets.only(
                                top: 10,
                                bottom: 100,
                              ),
                              itemCount: pending.length,
                              itemBuilder: (_, i) =>
                                  _buildBookingCard(pending[i]),
                            )),
                _loading
                    ? const SizedBox.shrink()
                    : (history.isEmpty
                          ? _buildEmptyState('History')
                          : ListView.builder(
                              padding: const EdgeInsets.only(
                                top: 10,
                                bottom: 100,
                              ),
                              itemCount: history.length,
                              itemBuilder: (_, i) =>
                                  _buildBookingCard(history[i]),
                            )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
