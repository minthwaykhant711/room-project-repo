import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_application_1/logout_function.dart';
import 'package:flutter_application_1/student_history.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class StudentBrowsing extends StatefulWidget {
  const StudentBrowsing({super.key});

  @override
  State<StudentBrowsing> createState() => _StudentBrowsingState();
}

class _StudentBrowsingState extends State<StudentBrowsing> {
  // ===========================================================================
  // 1. STATE VARIABLES
  // ===========================================================================
  bool _isLoading = true;
  String _error = '';
  final DateTime _selectedDate = DateTime.now();

  // Data stores
  List<dynamic> _allApiRooms = [], _allApiTimeSlots = [], _apiBookings = [];
  bool _hasStudentBookedToday = false;
  Map<String, List<Map<String, dynamic>>> _roomsByCategory = {
    'Study': [],
    'Multimedia': [],
    'Meeting': [],
  };

  // Config
  final String _baseUrl = 'http://10.0.2.2:3000'; // Localhost for Android emulator
  final List<String> categories = ['Study', 'Multimedia', 'Meeting'];
  String selectedCategory = 'Study';
  int? _userId;
  String? _firstName;

  // ===========================================================================
  // 2. LIFECYCLE METHODS
  // ===========================================================================
  @override
  void initState() {
    super.initState();
    _loadSessionData();
  }

  // ===========================================================================
  // 3. API & DATA LOGIC
  // ===========================================================================

  // Load user session data from shared preferences
  Future<void> _loadSessionData() async {
    final prefs = await SharedPreferences.getInstance();
    String? sessionString = prefs.getString('token');

    if (sessionString != null && sessionString.isNotEmpty) {
      Map<String, dynamic> sessionData = jsonDecode(sessionString);
      setState(() {
        _userId = sessionData['user_id'];
        _firstName = sessionData['first_name'];
      });
      // Fetch data after session is loaded
      await _fetchDataForUI();
    } else {
      setState(() => _error = "Session not found. Please login again.");
      setState(() => _isLoading = false);
    }
  }

  // Main data fetching function
  Future<void> _fetchDataForUI() async {
    if (_userId == null) {
      setState(() => _error = "Session not found");
      setState(() => _isLoading = false);
      return;
    }

    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      final dateString =
          "${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}";

      final responses = await Future.wait([
        http.get(Uri.parse('$_baseUrl/api/rooms')),
        http.get(Uri.parse('$_baseUrl/api/timeslots')),
        http.get(Uri.parse('$_baseUrl/api/bookings_by_date?date=$dateString')),
      ]);

      for (var r in responses) {
        if (r.statusCode != 200) {
          throw Exception('Failed to load data: ${r.reasonPhrase}');
        }
      }

      _allApiRooms = jsonDecode(responses[0].body);
      _allApiTimeSlots = jsonDecode(responses[1].body);
      _apiBookings = jsonDecode(responses[2].body);

      // Check if current user has already booked today
      _hasStudentBookedToday = _apiBookings.any((b) => b['user_id'] == _userId);

      _processApiData();
    } catch (e) {
      setState(() => _error = "Error fetching data: ${e.toString()}");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Process room data and categorize them
  void _processApiData() {
    final Map<String, List<Map<String, dynamic>>> processedData = {
      'Study': [],
      'Multimedia': [],
      'Meeting': [],
    };
    final enabledRooms = _allApiRooms
        .where((r) => r['room_status'] != 0)
        .toList();
    final disabledRooms = _allApiRooms
        .where((r) => r['room_status'] == 0)
        .toList();

    for (var room in [...enabledRooms, ...disabledRooms]) {
      _addRoomToCategory(room, processedData);
    }
    setState(() => _roomsByCategory = processedData);
  }

  // Add room to appropriate category with time slot statuses
  void _addRoomToCategory(
    dynamic room,
    Map<String, List<Map<String, dynamic>>> processedData,
  ) {
    String category = room['room_name'].toLowerCase().contains('multimedia')
        ? 'Multimedia'
        : room['room_name'].toLowerCase().contains('meeting')
        ? 'Meeting'
        : 'Study';
    final bool isDisabled = room['room_status'] == 0;
    final Map<String, dynamic> statuses = {};

    for (var slot in _allApiTimeSlots) {
      final startTime = slot['start_time'].substring(0, 5);
      final endTime = slot['end_time'].substring(0, 5);
      final timeString = '$startTime - $endTime';
      String status = 'available';

      if (isDisabled) {
        status = 'disabled';
      } else {
        final matchingBookings = _apiBookings
            .where(
              (b) =>
                  b['room_id'] == room['room_id'] &&
                  b['slot_id'] == slot['slot_id'],
            )
            .toList();

        if (matchingBookings.isNotEmpty) {
          final booking = matchingBookings.first;
          status = booking['booking_status'] == 'Approved'
              ? 'reserved'
              : booking['booking_status'] == 'Waiting'
              ? 'pending'
              : 'available';
        }
      }

      statuses[timeString] = {
        'status': status,
        'slot_id': slot['slot_id'],
        'is_time_passed': _isTimeSlotPassed(endTime),
        'is_room_disabled': isDisabled,
      };
    }

    processedData[category]?.add({
      'room_id': room['room_id'],
      'name': room['room_name'],
      'details': room['description'],
      'max': room['capacity'],
      'image': 'assets/images/${room['image']}',
      'statuses': statuses,
      'is_disabled': isDisabled,
    });
  }

  // Create booking API call
  Future<void> _createBooking({
    required int roomId,
    required int slotId,
  }) async {
    if (_userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Session not found. Please login again.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final dateString =
        "${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}";
    final response = await http.post(
      Uri.parse('$_baseUrl/api/book'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'user_id': _userId, // Use actual _userId from session
        'room_id': roomId,
        'slot_id': slotId,
        'booking_date': dateString,
        'Objective': 'Study',
      }),
    );

    if (mounted) {
      if (response.statusCode == 200) {
        await _fetchDataForUI();
        await _showSuccessDialog();
      } else {
        final errorMessage =
            jsonDecode(response.body)['message'] ?? 'Booking failed';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Booking failed: $errorMessage'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Check if time slot has already passed
  bool _isTimeSlotPassed(String endTime) {
    final now = DateTime.now();
    final parts = endTime.split(':');
    final slotEndTime = DateTime(
      now.year,
      now.month,
      now.day,
      int.parse(parts[0]),
      int.parse(parts[1]),
    );
    return now.isAfter(slotEndTime);
  }

  // ===========================================================================
  // 4. BUILD METHOD
  // ===========================================================================
  @override
  Widget build(BuildContext context) {
    final headerHeight = MediaQuery.of(context).size.height * 0.28;
    final rooms = _roomsByCategory[selectedCategory] ?? [];

    return Scaffold(
      backgroundColor: const Color(0xFFD9D9D9),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
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
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const StudentHistory()),
                ),
              ),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          // Header Section
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
                      _HeaderText(
                        title: 'Hi, ${_firstName ?? "User"}',
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
                  child: Column(
                    children: [
                      Container(
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
                              _formatHeaderDate(_selectedDate),
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Category Selection
          const SizedBox(height: 10),
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

          // Rooms List
          const SizedBox(height: 5),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error.isNotEmpty
                ? Center(
                    child: Text(
                      _error,
                      style: const TextStyle(color: Colors.red),
                    ),
                  )
                : rooms.isEmpty
                ? Center(
                    child: Text('No rooms available for $selectedCategory.'),
                  )
                : ListView.builder(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    itemCount: rooms.length,
                    itemBuilder: (context, index) {
                      const double cardH = 420, cardW = 320;
                      final double imgH = cardH * 0.70;
                      final room = rooms[index];
                      final bool isDisabled = room['is_disabled'] ?? false;

                      return Container(
                        width: cardW,
                        height: cardH,
                        margin: EdgeInsets.only(
                          left: index == 0 ? 0 : 12,
                          right: index == rooms.length - 1 ? 0 : 12,
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
                            // Room Image
                            ClipRRect(
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(16),
                              ),
                              child: SizedBox(
                                height: imgH,
                                width: double.infinity,
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    Image.asset(
                                      room['image'],
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => const Icon(
                                        Icons.broken_image,
                                        size: 50,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    if (isDisabled)
                                      Container(
                                        color: Colors.black.withOpacity(0.6),
                                        child: const Center(
                                          child: Text(
                                            'Disabled',
                                            style: TextStyle(
                                              fontSize: 24,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 18),
                            // Room Info
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(7, 4, 5, 1),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      room['name'],
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                        color: isDisabled
                                            ? Colors.grey
                                            : Colors.black,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      "${room['details']}  •  Max : ${room['max']} people",
                                      style: TextStyle(
                                        color: isDisabled
                                            ? Colors.grey
                                            : Colors.black54,
                                        fontSize: 16,
                                        height: 1.25,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 25),
                                    Center(
                                      child: ElevatedButton.icon(
                                        onPressed: () =>
                                            _showRoomDetailDialog(room),
                                        icon: const Icon(
                                          Icons.info_outline,
                                          size: 18,
                                        ),
                                        label: const Text("Detail"),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: isDisabled
                                              ? Colors.grey
                                              : const Color(0xFF003366),
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
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

  // ===========================================================================
  // 5. UI HELPERS & DIALOGS
  // ===========================================================================

  // Show room details with time slots
  void _showRoomDetailDialog(Map<String, dynamic> room) {
    final bool isDisabled = room['is_disabled'] ?? false;
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  room['name'],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF003366),
                  ),
                ),
                if (isDisabled)
                  const Text(
                    '(Disabled)',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                const Divider(thickness: 1),
                const SizedBox(height: 8),
                // Time slots list
                Column(
                  children: room['statuses'].entries.map<Widget>((entry) {
                    final time = entry.key;
                    final statusData = entry.value;
                    final status = statusData['status'];
                    final slotId = statusData['slot_id'];
                    final isTimePassed = statusData['is_time_passed'] ?? false;
                    final isRoomDisabled =
                        statusData['is_room_disabled'] ?? false;

                    // Booking eligibility check
                    final canBook =
                        status == 'available' &&
                        !isRoomDisabled &&
                        !_hasStudentBookedToday &&
                        !isTimePassed;

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            flex: 2,
                            child: Text(
                              time,
                              style: TextStyle(
                                fontSize: 15,
                                color: isTimePassed
                                    ? Colors.grey
                                    : Colors.black,
                              ),
                            ),
                          ),
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
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: ElevatedButton(
                                onPressed: canBook
                                    ? () async {
                                        Navigator.pop(context);
                                        await _showConfirmDialog(
                                          room: room,
                                          slot: time,
                                          slotId: slotId,
                                        );
                                      }
                                    : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: canBook
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
                                child: Text(
                                  _hasStudentBookedToday ? "Booked" : "Book",
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
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
      ),
    );
  }

  // Booking confirmation dialog
  Future<void> _showConfirmDialog({
    required Map<String, dynamic> room,
    required String slot,
    required int slotId,
  }) async {
    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => BackdropFilter(
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
                    _formatHeaderDate(_selectedDate),
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
                await _createBooking(roomId: room['room_id'], slotId: slotId);
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
      ),
    );
  }

  // Success dialog after booking
  Future<void> _showSuccessDialog() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: const Padding(
          padding: EdgeInsets.fromLTRB(20, 24, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
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

  // Format date for header display
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
    return '${w[d.weekday - 1]}, ${m[d.month - 1]} ${d.day}, ${d.year}';
  }

  // Get color based on booking status
  Color getStatusColor(String status) {
    switch (status) {
      case 'available':
        return Colors.teal;
      case 'pending':
        return Colors.orange;
      case 'reserved':
        return const Color.fromARGB(255, 12, 143, 209);
      default:
        return Colors.grey;
    }
  }
}

// ===========================================================================
// 6. HELPER WIDGETS
// ===========================================================================
class _HeaderText extends StatelessWidget {
  const _HeaderText({required this.title, required this.subtitle});
  final String title, subtitle;

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
