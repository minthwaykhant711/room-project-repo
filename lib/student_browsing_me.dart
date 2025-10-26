import 'package:flutter/material.dart';

class StudentBrowsingMe extends StatefulWidget {
  const StudentBrowsingMe({super.key});

  @override
  State<StudentBrowsingMe> createState() => _StudentBrowsingMeState();
}

class _StudentBrowsingMeState extends State<StudentBrowsingMe> {
  final List<String> categories = ['Study', 'Multimedia', 'Meeting'];

  final List<Map<String, dynamic>> rooms = [
    {
      'name': 'Meeting Room A',
      'details': 'TV, Aircon, Projects',
      'max': 6,
      'status': 'available',
      'image': 'assets/images/study room A.jpg',
    },
    {
      'name': 'Meeting Room B',
      'details': 'Whiteboard, Aircon',
      'max': 4,
      'status': 'disabled',
      'image': 'assets/images/study room A.jpg',
    },
    {
      'name': 'Meeting Room C',
      'details': 'TV, Aircon, 8 seats',
      'max': 8,
      'status': 'reserved',
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

  String selectedCategory = 'Meeting';

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final screenHeight = media.size.height;
    final headerHeight = screenHeight * 0.25;

    return Scaffold(
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
                        padding: const EdgeInsets.all(8.0),
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
                          ],
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.logout,
                        color: Colors.white,
                        size: 28,
                      ),
                      onPressed: () {},
                    ),
                  ],
                ),

                Container(
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
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.calendar_month, color: Colors.black87),
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
                    onSelected: (_) {
                      setState(() => selectedCategory = cat);
                    },
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
                final isAvailable = room['status'] == 'available';
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

                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(16),
                        ),
                        child: Image.asset(
                          room['image'],
                          height: 160,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),

                      // First row: Room name and info icon
                      Padding(
                        padding: const EdgeInsets.all(8.0),

                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                          ],
                        ),
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
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: isAvailable
                                  ? Colors.teal[300]
                                  : Colors.red[300],
                              borderRadius: BorderRadius.circular(50),
                            ),
                            child: Text(
                              isAvailable ? "available" : "disabled",
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
                            onPressed: isAvailable
                                ? () {
                                    // Add your request action here
                                  }
                                : null,
                          ),
                        ],
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
