import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:flutter_application_1/student_browsing_me.dart';
import 'package:flutter_application_1/student_browsing_study.dart';
import 'package:flutter_application_1/logout_function.dart';

class StudentBrowsingMulti extends StatefulWidget {
  const StudentBrowsingMulti({super.key});

  @override
  State<StudentBrowsingMulti> createState() => _StudentBrowsingMultiState();
}

class _StudentBrowsingMultiState extends State<StudentBrowsingMulti> {
  final List<String> categories = ['Study', 'Multimedia', 'Meeting'];

  final List<Map<String, dynamic>> rooms = [
    {
      'name': 'Multimedia Room A',
      'details': 'TV, Aircon, Netflix, Prime',
      'max': 6,
      'statuses': {
        '8:00 - 10:00': 'available',
        '10:00 - 12:00': 'pending',
        '13:00 - 14:00': 'reserved',
        '14:00 - 16:00': 'disabled',
      },
      'image': 'assets/images/multi room A.jpg',
    },
    {
      'name': 'Multimedia Room B',
      'details': 'TV, Aircon, Netflix, Prime',
      'max': 4,
      'statuses': {
        '8:00 - 10:00': 'available',
        '10:00 - 12:00': 'pending',
        '13:00 - 14:00': 'reserved',
        '14:00 - 16:00': 'disabled',
      },
      'image': 'assets/images/multi room A.jpg',
    },
    {
      'name': 'Multimedia Room C',
      'details': 'TV, Aircon, Netflix, Prime',
      'max': 8,
      'statuses': {
        '8:00 - 10:00': 'available',
        '10:00 - 12:00': 'pending',
        '13:00 - 14:00': 'reserved',
        '14:00 - 16:00': 'disabled',
      },
      'image': 'assets/images/multi room A.jpg',
    },
  ];

  final List<String> timeSlots = [
    '8:00 - 10:00',
    '10:00 - 12:00',
    '13:00 - 14:00',
    '14:00 - 16:00',
  ];

  late Map<int, String> selectedTimes;

  @override
  void initState() {
    super.initState();
    selectedTimes = {for (int i = 0; i < rooms.length; i++) i: timeSlots.first};
  }

  Color getStatusColor(String status) {
    switch (status) {
      case 'available':
        return Colors.teal;
      case 'pending':
        return Colors.orange;
      case 'reserved':
        return Colors.blueGrey;
      case 'disabled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String selectedCategory = 'Multimedia';

  void _navigateToCategory(String cat) {
    if (cat == selectedCategory) return; // already here

    if (cat == 'Study') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const StudentBrowsingStudy()),
      );
    } else if (cat == 'Meeting') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const StudentBrowsingMe()),
      );
    } else if (cat == 'Multimedia') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const StudentBrowsingMulti()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final screenHeight = media.size.height;
    final headerHeight = screenHeight * 0.30;

    return Scaffold(
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
              const Icon(Icons.home_filled, color: Colors.white, size: 28),
              const Icon(Icons.calendar_today, color: Colors.white),
            ],
          ),
        ),
      ),

      body: Column(
        children: [
          Container(
            width: double.infinity,
            height: headerHeight,
            decoration: const BoxDecoration(
              color: Color(0xFF003366),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(35)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Hi, David',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Reserve the Room',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 16),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: IconButton(
                        icon: const Icon(
                          Icons.logout,
                          color: Colors.white,
                          size: 28,
                        ),
                        onPressed: () => showLogoutDialog(context),
                      ),
                    ),
                  ],
                ),

                Align(
                  alignment: Alignment.topLeft,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 20,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(50),
                      ),

                      child: Row(
                        mainAxisSize: MainAxisSize.min,

                        children: [
                          const Icon(
                            Icons.calendar_month,
                            color: Colors.black87,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            // Always show today's date
                            "${DateTime.now().toLocal()}".split(' ')[0],
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.black87,
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

          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,

              children: categories.map((cat) {
                final isSelected = cat == selectedCategory;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: ChoiceChip(
                    label: Text(cat),
                    selected: isSelected,
                    selectedColor: const Color.fromARGB(255, 24, 77, 131),
                    backgroundColor: Colors.white,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.black87,
                    ),

                    onSelected: (_) => _navigateToCategory(cat),
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 20),

          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal, // Make list scroll horizontally
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: rooms.length,
              itemBuilder: (context, index) {
                final room = rooms[index];
                final currentSlot = selectedTimes[index];
                final currentStatus =
                    room['statuses'][currentSlot] ?? 'unknown';
                final isAvailable = currentStatus == 'available';
                return Container(
                  width: 320,
                  height: 420,

                  margin: EdgeInsets.only(
                    left: index == 0 ? 4 : 12,
                    right: index == rooms.length - 1 ? 4 : 0,
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
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(16),
                        ),
                        child: Image.asset(
                          room['image'],
                          height: 260,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),

                      // First row: Room name and info icon
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 8,
                        ),

                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    children: [
                                      Text(
                                        room['name'],
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        "${room['details']}\nMax: ${room['max']} people",
                                        style: const TextStyle(
                                          color: Color.fromARGB(
                                            255,
                                            71,
                                            69,
                                            69,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                IconButton(
                                  icon: const Icon(
                                    Icons.assignment_turned_in,
                                    color: Color(0xFF003366),
                                  ),
                                  onPressed: isAvailable
                                      ? () {
                                          showDialog(
                                            context: context,
                                            barrierDismissible:
                                                true, // allow tap outside to close
                                            builder: (BuildContext context) {
                                              return BackdropFilter(
                                                filter: ImageFilter.blur(
                                                  sigmaX: 4,
                                                  sigmaY: 4,
                                                ),
                                                child: AlertDialog(
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          20,
                                                        ),
                                                  ),
                                                  title: const Text(
                                                    'Confirm Booking',
                                                    textAlign: TextAlign.center,
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                  content: Column(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        'Session in ${room['name']}',
                                                        style: const TextStyle(
                                                          color: Colors.orange,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                        ),
                                                      ),
                                                      const SizedBox(height: 8),
                                                      Row(
                                                        children: [
                                                          const Icon(
                                                            Icons
                                                                .calendar_month,
                                                            size: 18,
                                                          ),
                                                          const SizedBox(
                                                            width: 6,
                                                          ),
                                                          Text(
                                                            "${DateTime.now().toLocal()}"
                                                                .split(' ')[0],
                                                            style:
                                                                const TextStyle(
                                                                  fontSize: 14,
                                                                ),
                                                          ),
                                                        ],
                                                      ),
                                                      const SizedBox(height: 4),
                                                      Row(
                                                        children: [
                                                          const Icon(
                                                            Icons.access_time,
                                                            size: 18,
                                                          ),
                                                          const SizedBox(
                                                            width: 6,
                                                          ),
                                                          Text(
                                                            selectedTimes[rooms
                                                                    .indexOf(
                                                                      room,
                                                                    )] ??
                                                                'Unknown Time', // Updated line
                                                          ),
                                                        ],
                                                      ),
                                                      const SizedBox(height: 4),
                                                      Row(
                                                        children: [
                                                          const Icon(
                                                            Icons.people,
                                                            size: 18,
                                                          ),
                                                          const SizedBox(
                                                            width: 6,
                                                          ),
                                                          Text(
                                                            'Quiet space for up to ${room['max']} people.',
                                                          ),
                                                        ],
                                                      ),
                                                    ],
                                                  ),
                                                  actionsAlignment:
                                                      MainAxisAlignment
                                                          .spaceEvenly,
                                                  actions: [
                                                    ElevatedButton(
                                                      style: ElevatedButton.styleFrom(
                                                        backgroundColor:
                                                            Colors.green,
                                                        shape: RoundedRectangleBorder(
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                8,
                                                              ),
                                                        ),
                                                      ),
                                                      onPressed: () {
                                                        Navigator.pop(context);
                                                        ScaffoldMessenger.of(
                                                          context,
                                                        ).showSnackBar(
                                                          SnackBar(
                                                            content: Text(
                                                              'Booking confirmed for ${room['name']} at ${selectedTimes[index]}',
                                                            ),
                                                          ),
                                                        );
                                                      },
                                                      child: const Text(
                                                        'Confirm',
                                                        style: TextStyle(
                                                          color: Colors.white,
                                                        ),
                                                      ),
                                                    ),
                                                    ElevatedButton(
                                                      style: ElevatedButton.styleFrom(
                                                        backgroundColor:
                                                            Colors.red,
                                                        shape: RoundedRectangleBorder(
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                8,
                                                              ),
                                                        ),
                                                      ),
                                                      onPressed: () =>
                                                          Navigator.pop(
                                                            context,
                                                          ),
                                                      child: const Text(
                                                        'Cancel',
                                                        style: TextStyle(
                                                          color: Colors.white,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            },
                                          );
                                        }
                                      : null,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 8),

                      // Time slot row with dropdown
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          const Icon(Icons.access_time, size: 20),
                          const SizedBox(width: 8),
                          Flexible(
                            fit: FlexFit.loose,

                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 160),
                              child: DropdownButton<String>(
                                isExpanded: true,
                                value: selectedTimes[index],
                                items: timeSlots.map((slot) {
                                  return DropdownMenuItem<String>(
                                    value: slot,
                                    child: Text(slot),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  if (value != null) {
                                    setState(() {
                                      selectedTimes[index] = value;
                                    });
                                  }
                                },
                              ),
                            ),
                          ),

                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: getStatusColor(currentStatus),
                              borderRadius: BorderRadius.circular(50),
                            ),
                            child: Text(
                              currentStatus,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),
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
