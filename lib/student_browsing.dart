import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/logout_function.dart';
import 'package:flutter_application_1/student_history.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class StudentBrowsing extends StatefulWidget {
  const StudentBrowsing({super.key});

  @override
  State<StudentBrowsing> createState() => _StudentBrowsingState();
}

class _StudentBrowsingState extends State<StudentBrowsing> {
  // ────────────────────────────────────────────────────────────────────────────
  // Date formatter: FRI, OCT 24, 2025
  String _formatHeaderDate(DateTime d) {
    const w = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
    const m = [
      'JAN',
      'FEB',
      'MAR',
      'APR',
      'MAY',
      'JUN',
      'JUL',
      'AUG',
      'SEP',
      'OCT',
      'NOV',
      'DEC',
    ];
    final weekday = w[(d.weekday + 6) % 7];
    final month = m[d.month - 1];
    return '$weekday, $month ${d.day}, ${d.year}';
  }

  // Status → color
  Color getStatusColor(String status) {
    switch (status) {
      case 'available':
        return Colors.teal;
      case 'pending':
        return Colors.orange;
      case 'reserved':
        return const Color.fromARGB(255, 12, 143, 209);
      case 'disabled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  // ────────────────────────────────────────────────────────────────────────────
  // Config
  final List<String> categories = ['Study', 'Multimedia', 'Meeting'];
  String selectedCategory = 'Multimedia';

  final List<String> timeSlots = [
    '8:00 - 10:00',
    '10:00 - 12:00',
    '13:00 - 14:00',
    '14:00 - 16:00',
  ];

  late Map<String, List<Map<String, dynamic>>> roomsByCategory = {
    for (final c in ['Study', 'Multimedia', 'Meeting']) c: [],
  };

  Map<int, String> slotDisplayById = {};

  List<Map<String, dynamic>> bookingsForDate = [];

  final String baseUrl = 'http://127.0.0.1:3000';

  // Each category keeps its own selected time per card
  late Map<String, Map<int, String>> selectedTimesByCat;

  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    selectedTimesByCat = {for (final cat in categories) cat: {}};
    _fetchInitialData();
  }

  Future<void> _fetchInitialData() async {
    setState(() => isLoading = true);
    try {
      await Future.wait([_fetchTimeSlots(), _fetchRooms()]);
      // after rooms & slots fetched, set default selectedTimesByCat entries
      for (final cat in categories) {
        final rooms = roomsByCategory[cat]!;
        selectedTimesByCat[cat] = {
          for (int i = 0; i < rooms.length; i++)
            i: slotDisplayById.isNotEmpty
                ? slotDisplayById.values.first
                : timeSlots.first,
        };
      }
      // fetch bookings for today to derive statuses
      final today = DateTime.now();
      final dateStr =
          '${today.year.toString().padLeft(4, '0')}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
      await _fetchBookingsByDate(dateStr);
      _applyBookingsToRooms();
    } catch (e) {
      // ignore — you may want to show a message
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _fetchTimeSlots() async {
    final res = await http.get(Uri.parse('$baseUrl/api/timeslots'));
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body) as List;
      slotDisplayById.clear();
      for (final item in data) {
        final id = item['slot_id'] as int;
        final start = (item['start_time'] as String).substring(0, 5);
        final end = (item['end_time'] as String).substring(0, 5);
        slotDisplayById[id] = '$start - $end';
      }
    }
  }

  Future<void> _fetchRooms() async {
    final res = await http.get(Uri.parse('$baseUrl/api/rooms'));
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body) as List;
      // clear previous
      roomsByCategory = {for (final c in categories) c: []};
      for (final r in data) {
        final name = (r['room_name'] ?? '').toString();
        final description = (r['description'] ?? '').toString();
        final capacity = (r['capacity'] ?? 0) as int;
        final rawImage = (r['image'] ?? '').toString();
        final roomStatus = (r['room_status'] ?? 1) as int; // keep status

        // classify category by name heuristic:
        String category = 'Meeting';
        final lname = name.toLowerCase();
        if (lname.contains('multimedia') || lname.contains('multi'))
          category = 'Multimedia';
        else if (lname.contains('study'))
          category = 'Study';
        else
          category = 'Meeting';

        // attempt to build image URL — fallback to local asset if not available
        String imageUrl = rawImage.trim();
        if (imageUrl.isNotEmpty &&
            !imageUrl.startsWith('http') &&
            !imageUrl.startsWith('/')) {
          imageUrl = '$baseUrl/images/$imageUrl';
        }

        // initialize statuses. If room is disabled, mark all slots as 'disabled'
        final initialStatuses = <String, String>{
          for (final s in slotDisplayById.values)
            s: roomStatus == 1 ? 'available' : 'disabled',
        };

        final roomMap = {
          'room_id': r['room_id'],
          'name': name,
          'details': description,
          'max': capacity,
          'image': imageUrl,
          'room_status': roomStatus,
          'statuses': initialStatuses,
        };

        roomsByCategory[category]!.add(roomMap);
      }
      // ensure at least default selectedCategory exists
      if (!roomsByCategory.containsKey(selectedCategory)) {
        selectedCategory = categories.first;
      }
    }
  }

  Future<void> _fetchBookingsByDate(String date) async {
    final res = await http.get(
      Uri.parse('$baseUrl/api/bookings_by_date?date=$date'),
    );
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body) as List;
      bookingsForDate = data
          .map<Map<String, dynamic>>(
            (e) => {
              'room_id': e['room_id'],
              'slot_id': e['slot_id'],
              'booking_status': e['booking_status'],
              'user_id': e['user_id'],
            },
          )
          .toList();
    }
  }

  void _applyBookingsToRooms() {
    final slotIdToDisplay = slotDisplayById;
    for (final cat in roomsByCategory.keys) {
      for (final room in roomsByCategory[cat]!) {
        final roomId = room['room_id'];
        final roomStatus = room['room_status'] ?? 1;
        final statuses = <String, String>{
          for (final s in slotIdToDisplay.values)
            s: roomStatus == 1 ? 'available' : 'disabled',
        };
        for (final b in bookingsForDate) {
          if (b['room_id'] == roomId) {
            final slotId = b['slot_id'] as int;
            final display = slotIdToDisplay[slotId];
            if (display == null) continue;
            if (b['disabled'] == true) {
              statuses[display] = 'disabled';
              continue;
            }
            final bookingStatus = (b['booking_status'] ?? '')
                .toString()
                .toLowerCase();
            if (bookingStatus.contains('approve'))
              statuses[display] = 'reserved';
            else if (bookingStatus.contains('wait') ||
                bookingStatus.contains('pending'))
              statuses[display] = 'pending';
            else
              statuses[display] = 'reserved';
          }
        }
        room['statuses'] = statuses;
      }
    }
    if (mounted) setState(() {});
  }

  void _showRoomDetailDialog(Map<String, dynamic> room) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 24,
          ), // Adjusts dialog position
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth:
                  420, // wider dialog — adjust this value (e.g., 450–500 if you want)
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    room['name'],
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF003366),
                    ),
                  ),
                  const Divider(thickness: 1),
                  const SizedBox(height: 8),

                  // Time slot list
                  Column(
                    children: room['statuses'].entries.map<Widget>((entry) {
                      final time = entry.key;
                      final status = entry.value;

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Time slot text
                            Expanded(
                              flex: 2,
                              child: Text(
                                time,
                                style: const TextStyle(fontSize: 15),
                              ),
                            ),

                            // Status badge
                            Expanded(
                              flex: 2,
                              child: Container(
                                alignment: Alignment.center,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: getStatusColor(status),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  status,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),

                            // Book button
                            Expanded(
                              flex: 2,
                              child: Align(
                                alignment: Alignment.centerRight,
                                child: ElevatedButton(
                                  onPressed: status == 'available'
                                      ? () async {
                                          Navigator.pop(context);
                                          await _showConfirmDialog(
                                            room: room,
                                            slot: time,
                                          );
                                        }
                                      : null,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: status == 'available'
                                        ? const Color(0xFF003366)
                                        : Colors.grey,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: const Text(
                                    "Book",
                                    style: TextStyle(fontSize: 13),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ────────────────────────────────────────────────────────────────────────────
  // Booking UI
  Future<void> _showConfirmDialog({
    required Map<String, dynamic> room,
    required String slot,
  }) async {
    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
          child: AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Text(
              'Confirm Booking',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    style: const TextStyle(color: Colors.black87, fontSize: 16),
                    children: [
                      const TextSpan(text: 'Session in '),
                      TextSpan(
                        text: room['name'],
                        style: const TextStyle(
                          color: Colors.orange,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(Icons.calendar_month, size: 18),
                    const SizedBox(width: 6),
                    Text(
                      _formatHeaderDate(DateTime.now()).replaceAll(',', ','),
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.access_time, size: 18),
                    const SizedBox(width: 6),
                    Text(slot, style: const TextStyle(fontSize: 14)),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.people, size: 18),
                    const SizedBox(width: 6),
                    Text(
                      'Quiet space for up to ${room['max']} people.',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ],
            ),
            actionsAlignment: MainAxisAlignment.spaceEvenly,
            actions: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () async {
                  Navigator.of(ctx).pop();
                  await _showSuccessDialog();
                },
                child: const Text('Confirm'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Cancel'),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showSuccessDialog() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.check_circle, size: 140, color: Colors.green),
              SizedBox(height: 14),
              Text(
                'Your reservation is completed',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
    await Future.delayed(const Duration(milliseconds: 1200));
    if (mounted) Navigator.of(context, rootNavigator: true).pop();
  }

  // ────────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final headerHeight = MediaQuery.of(context).size.height * 0.28;
    final rooms = roomsByCategory[selectedCategory]!;
    final timesForCat = selectedTimesByCat[selectedCategory]!;

    return Scaffold(
      backgroundColor: const Color(0xFFD9D9D9),

      // Bottom nav (student: Home == this page)
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
                  // already here
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
                icon: const Icon(Icons.calendar_today, color: Colors.white),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const StudentHistory()),
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
          // Header (same format as Staff Browsing)
          Container(
            width: double.infinity,
            height: headerHeight,
            decoration: const BoxDecoration(
              color: Color(0xFF003366),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
              border: Border(bottom: BorderSide(color: Colors.black, width: 2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 60),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const _HeaderText(
                        title: 'Hi, David',
                        subtitle: 'Reserve the room',
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
                const SizedBox(height: 40),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 18,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 8,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 30,
                          height: 30,
                          decoration: const BoxDecoration(
                            color: Colors.black87,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.calendar_month,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          _formatHeaderDate(DateTime.now()),
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // Category chips (3 across, no checkmark)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Row(
              children: List.generate(categories.length, (i) {
                final cat = categories[i];
                final isSelected = cat == selectedCategory;
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      left: i == 0 ? 0 : 8,
                      right: i == categories.length - 1 ? 0 : 8,
                    ),
                    child: ChoiceChip(
                      showCheckmark: false,
                      label: Center(child: Text(cat.toLowerCase())),
                      selected: isSelected,
                      backgroundColor: Colors.white,
                      selectedColor: const Color(0xFF184D83),
                      shape: const StadiumBorder(
                        side: BorderSide(color: Color(0xFFBDBDBD), width: 1),
                      ),
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : Colors.black87,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      onSelected: (_) => setState(() => selectedCategory = cat),
                    ),
                  ),
                );
              }),
            ),
          ),

          const SizedBox(height: 5),

          // Cards (horizontal list)
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              itemCount: rooms.length,
              itemBuilder: (context, index) {
                const double cardH = 420;
                const double cardW = 320;
                final double imgH = cardH * 0.70;

                final room = roomsByCategory[selectedCategory]![index];

                return Container(
                  width: cardW,
                  height: cardH,
                  margin: EdgeInsets.only(
                    left: index == 0 ? 0 : 12,
                    right:
                        index == roomsByCategory[selectedCategory]!.length - 1
                        ? 0
                        : 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 6,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ─── Image (Top) ─────────────────────────────
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(16),
                        ),
                        child: SizedBox(
                          height: imgH,
                          width: double.infinity,
                          child:
                              room['image'] != null &&
                                  room['image'].toString().startsWith('http')
                              ? Image.network(
                                  room['image'],
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) {
                                    return Image.asset(
                                      'assets/images/study room B.jpg',
                                      fit: BoxFit.cover,
                                    );
                                  },
                                )
                              : Image.asset(
                                  room['image'] ??
                                      'assets/images/study room B.jpg',
                                  fit: BoxFit.cover,
                                ),
                        ),
                      ),
                      const SizedBox(height: 18),

                      // ─── Info (Bottom) ──────────────────────────
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(7, 4, 5, 1),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                room['name'],
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                "${room['details']}  •  Max : ${room['max']} people",
                                style: const TextStyle(
                                  color: Colors.black54,
                                  fontSize: 16,
                                  height: 1.25,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 25),

                              // ─── Detail Button ──────────────────────
                              Center(
                                child: ElevatedButton.icon(
                                  onPressed: () => _showRoomDetailDialog(room),
                                  icon: const Icon(
                                    Icons.info_outline,
                                    size: 18,
                                  ),
                                  label: const Text("Detail"),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF003366),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// Reusable header text
class _HeaderText extends StatelessWidget {
  const _HeaderText({required this.title, required this.subtitle});
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          subtitle,
          style: const TextStyle(color: Colors.white, fontSize: 22),
        ),
      ],
    );
  }
}
