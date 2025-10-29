// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_application_1/lecturer_browsing.dart';
import 'package:flutter_application_1/logout_function.dart';

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
              color: Color(0xFF003366),
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
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: 'Hi',
                                  style: TextStyle(
                                    fontSize: 28,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                TextSpan(
                                  text: ', $username',
                                  style: TextStyle(
                                    fontSize: 28,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            "Lecturer's Dashboard",
                            style: TextStyle(fontSize: 23, color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.only(right: 20),
                      child: IconButton(
                        onPressed: () => showLogoutDialog(context),
                        icon: Icon(Icons.logout, color: Colors.white, size: 35),
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
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LecturerBrowsing(),
                    ),
                  );
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
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const LecturerDashboard(),
                    ),
                  );
                },
              ),

              const Icon(Icons.calendar_today, color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}
