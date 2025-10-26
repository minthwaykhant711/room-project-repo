import 'package:flutter/material.dart';

class StudentBrowse extends StatefulWidget {
  const StudentBrowse({super.key});

  @override
  State<StudentBrowse> createState() => _StudentBrowseState();
}

class _StudentBrowseState extends State<StudentBrowse> {
  DateTime selectedDate = DateTime(2025, 10, 24);
  String selectedCategory = 'meeting room';

  final List<String> categories = [
    'study room',
    'multimedia room',
    'meeting room',
  ];

  final List<Map<String, dynamic>> rooms = [
    {
      'name': 'Meeting Room A',
      'details': 'TV, Aircon, Projects',
      'max': 6,
      'available': true,
      'image': 'assets/images/study room A.jpg',
    },
    {
      'name': 'Meeting Room B',
      'details': 'Whiteboard, Aircon',
      'max': 4,
      'available': false,
      'image': 'assets/images/study room A.jpg',
    },
    {
      'name': 'Meeting Room C',
      'details': 'TV, Aircon, 8 seats',
      'max': 8,
      'available': true,
      'image': 'assets/images/study room A.jpg',
    },
  ];

  final List<String> timeSlots = [
    '8:00 - 10:00',
    '10:00 - 12:00',
    '13:00 - 14:00',
    '14:00 - 16:00',
  ];

  String selectedTime = '8:00 - 10:00';

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final screenHeight = media.size.height;
    final headerHeight = screenHeight * 0.25; // reduce height

    return Scaffold(
      backgroundColor: Colors.grey[100],

      // ✅ fixed bottom navigation bar
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          height: 50,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.grey,
            borderRadius: BorderRadius.circular(28),
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 6,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios,
                  color: Colors.white,
                  size: 26,
                ),
                onPressed: () => Navigator.maybePop(context),
              ),
              const Icon(Icons.home_filled, color: Colors.white, size: 28),
              const Icon(Icons.calendar_today, color: Colors.white, size: 26),
            ],
          ),
        ),
      ),

      // ✅ Main Body
      body: Column(
        children: [
          // 🔵 Header section (auto-sized)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            height: headerHeight,
            decoration: const BoxDecoration(
              color: Color(0xFF003366),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title + top-right icon
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 25),
                        Text(
                          "Hi, David",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          "Reserve the room",
                          style: TextStyle(color: Colors.white70, fontSize: 18),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.exit_to_app,
                        color: Colors.white,
                        size: 28,
                      ),
                      onPressed: () {},
                    ),
                  ],
                ),
                const Spacer(),
                // Date selector
                GestureDetector(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime(2024),
                      lastDate: DateTime(2026),
                    );
                    if (picked != null) {
                      setState(() => selectedDate = picked);
                    }
                  },
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
                        const Icon(Icons.calendar_month, color: Colors.black87),
                        const SizedBox(width: 8),
                        Text(
                          "${selectedDate.toLocal()}".split(' ')[0],
                          style: const TextStyle(
                            fontSize: 16,
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
          SizedBox(height: 15),

          // ✅ Scrollable content below header
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Category chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      children: categories.map((cat) {
                        final isSelected = cat == selectedCategory;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(cat),
                            selected: isSelected,
                            selectedColor: const Color(0xFF003366),
                            backgroundColor: Colors.white,
                            labelStyle: TextStyle(
                              color: isSelected ? Colors.white : Colors.black87,
                            ),
                            onSelected: (_) {
                              setState(() => selectedCategory = cat);
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Rooms horizontal scroll
                SizedBox(
                  height: 340,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    itemCount: rooms.length,
                    itemBuilder: (context, index) {
                      final room = rooms[index];
                      final available = room['available'] as bool;
                      return Container(
                        width: 280,
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

                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // First row: Room name and info icon
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      room['name'],
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              // Room details
                              Text(
                                "${room['details']}\nMax: ${room['max']} people",
                                style: const TextStyle(color: Colors.grey),
                              ),
                              const SizedBox(height: 12),

                              // Time slot row with dropdown
                              Row(
                                children: [
                                  const Icon(Icons.access_time, size: 20),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: DropdownButton<String>(
                                      isExpanded: true,
                                      value: selectedTime,
                                      items: timeSlots.map((slot) {
                                        return DropdownMenuItem<String>(
                                          value: slot,
                                          child: Text(slot),
                                        );
                                      }).toList(),
                                      onChanged: (value) {
                                        if (value != null) {
                                          setState(() {
                                            selectedTime = value;
                                          });
                                        }
                                      },
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 8),

                              // Status and request button row
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: available
                                          ? Colors.teal[300]
                                          : Colors.red[300],
                                      borderRadius: BorderRadius.circular(50),
                                    ),
                                    child: Text(
                                      available ? "available" : "disabled",
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.arrow_forward_rounded,
                                      color: Color(0xFF003366),
                                    ),
                                    onPressed: available
                                        ? () {
                                            // Add your request action here
                                          }
                                        : null,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
