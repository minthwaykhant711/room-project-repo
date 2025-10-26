import 'package:flutter/material.dart';

class LecturerDashboard extends StatefulWidget {
  const LecturerDashboard({super.key});

  @override
  State<LecturerDashboard> createState() => _LecturerDashboardState();
}

class _LecturerDashboardState extends State<LecturerDashboard> {
  String username = 'Aj.Surapong';

  final List<Map<String, dynamic>> _statusCards = [
    {'title': 'Available', 'count': 5, 'titleColor': Colors.green},
    {'title': 'Pending', 'count': 3, 'titleColor': Colors.orange},
    {'title': 'Reserved', 'count': 4, 'titleColor': Colors.blue},
    {'title': 'Disabled', 'count': 2, 'titleColor': Colors.red},
  ];

  Widget _buildStatusCard(Map<String, dynamic> item) {
    final Color countColor = item['title'] == 'Disabled'
        ? Color.fromRGBO(0, 51, 102, 120)
        : const Color.fromRGBO(0, 51, 102, 1);
    return Card(
      color: Colors.white,
      elevation: 6,
      shadowColor: Colors.black.withOpacity(0.15),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: BorderSide(color: const Color.fromRGBO(0, 51, 102, 1), width: 1),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            item['title'],
            style: TextStyle(color: item['titleColor'], fontSize: 16),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromRGBO(217, 217, 217, 100),
      body: Column(
        children: [
          Container(
            decoration: const BoxDecoration(
              color: Color.fromRGBO(0, 51, 102, 100),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
              border: Border(
                bottom: BorderSide(color: Colors.black, width: 2.0),
              ),
            ),
            width: double.infinity,
            height: 250,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 50),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 25),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hi, $username',
                            style: TextStyle(fontSize: 30, color: Colors.white),
                          ),
                          Text(
                            "Lecturer's Dashboard",
                            style: TextStyle(fontSize: 28, color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.only(right: 20),
                      child: IconButton(
                        onPressed: () {
                          // Add function here
                        },
                        icon: Icon(Icons.logout, color: Colors.white, size: 45),
                      ),
                    ),
                  ],
                ),
                Spacer(),
                Center(
                  child: Text(
                    "Dashboard shows today's room status summary.",
                    style: TextStyle(color: Colors.white.withOpacity(0.7)),
                  ),
                ),
                SizedBox(height: 5),
              ],
            ),
          ),
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(30),
                child: GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 20,
                  mainAxisSpacing: 20,
                  children: _statusCards.map(_buildStatusCard).toList(),
                ),
              ),
              SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () {
                  // Your action here
                },
                icon: const Icon(
                  Icons.exit_to_app_rounded,
                  color: Colors.black87,
                  size: 28,
                ),
                label: const Text(
                  'Browse Room',
                  style: TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  surfaceTintColor: Colors.white,
                  elevation: 2,
                  shape: const StadiumBorder(),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(20),
        child: Container(
          height: 65,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            color: Colors.black.withOpacity(0.8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            children: [
              SizedBox(width: 20),
              IconButton(
                onPressed: () {
                  // Add function here
                },
                icon: Icon(
                  Icons.arrow_back_rounded,
                  size: 40,
                  color: Colors.white.withOpacity(0.8),
                ),
              ),
              Spacer(),
              IconButton(
                onPressed: () {
                  // Add function here
                },
                icon: Icon(
                  Icons.home_rounded,
                  size: 40,
                  color: Colors.white.withOpacity(0.8),
                ),
              ),
              Spacer(),
              IconButton(
                onPressed: () {
                  // Add function here
                },
                icon: Icon(
                  Icons.today_rounded,
                  size: 40,
                  color: Colors.white.withOpacity(0.8),
                ),
              ),
              SizedBox(width: 20),
            ],
          ),
        ),
      ),
    );
  }
}
