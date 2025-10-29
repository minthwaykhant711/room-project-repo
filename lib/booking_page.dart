import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/logout_function.dart';

class BookingPage extends StatefulWidget {
  const BookingPage({super.key});

  @override
  State<BookingPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<BookingPage>
    with SingleTickerProviderStateMixin {
  // -------------------------------------------------------------------------
  // VARIABLES & CONTROLLERS
  // -------------------------------------------------------------------------
  late TabController _tabController;
  final String username = 'David';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // -------------------------------------------------------------------------
  // SAMPLE DATA (Pending & History Bookings)
  // -------------------------------------------------------------------------
  final List<Map<String, dynamic>> _pendingBookings = [
    {
      'room': 'Study Room A',
      'date': 'Mon, Oct 20',
      'time': '08:00 - 10:00',
      'status': 0,
      'approver': '',
    },
    {
      'room': 'Study Room B',
      'date': 'Wed, Oct 27',
      'time': '12:00 - 14:00',
      'status': 0,
      'approver': '',
    },
    {
      'room': 'Study Room C',
      'date': 'Mon, Oct 29',
      'time': '10:00 - 12:00',
      'status': 0,
      'approver': '',
    },
  ];

  final List<Map<String, dynamic>> _historyBookings = [
    {
      'room': 'Study Room A',
      'date': 'Mon, Oct 6',
      'time': '08:00 - 10:00',
      'status': 1, // 1 = Approved
      'approver': 'Ajarn Surapong',
    },
    {
      'room': 'Multimedia Room A',
      'date': 'Wed, Oct 1',
      'time': '08:00 - 10:00',
      'status': 1,
      'approver': 'Ajarn Bryan',
    },
    {
      'room': 'Study Room C',
      'date': 'Tue, Sep 30',
      'time': '13:00 - 15:00',
      'status': 0, // 0 = Rejected
      'approver': 'Ajarn Nick',
    },
    {
      'room': 'Meeting Room A',
      'date': 'Fri, Sep 26',
      'time': '10:00 - 12:00',
      'status': 1,
      'approver': 'Ajarn Surapong',
    },
    {
      'room': 'Meeting Room A',
      'date': 'Fri, Sep 26',
      'time': '10:00 - 12:00',
      'status': 1,
      'approver': 'Ajarn Surapong',
    },
  ];

  // -------------------------------------------------------------------------
  // BOOKING CARD BUILDER
  // -------------------------------------------------------------------------
  Widget _buildBookingCard(Map<String, dynamic> b) {
    final int status = b['status'] as int;
    final bool isPending = status == 0 && b['approver'].isEmpty;

    String statusText;
    Color statusColor;
    IconData statusIcon;

    if (isPending) {
      statusText = 'Pending Approval';
      statusColor = Colors.amber;
      statusIcon = Icons.circle_outlined;
    } else if (status == 0) {
      statusText = 'Rejected';
      statusColor = Colors.red;
      statusIcon = Icons.close;
    } else {
      statusText = 'Approved';
      statusColor = Colors.green;
      statusIcon = Icons.check;
    }

    return Card(
      color: Colors.white,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Title + Room Name ---
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      RichText(
                        text: TextSpan(
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.black,
                          ),
                          children: [
                            const TextSpan(text: 'Session in '),
                            TextSpan(
                              text: b['room'],
                              style: const TextStyle(color: Colors.orange),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // --- Date Row ---
            Row(
              children: [
                const Icon(Icons.calendar_month_outlined, size: 20),
                const SizedBox(width: 6),
                Text(b['date'], style: const TextStyle(fontSize: 14)),
              ],
            ),

            const SizedBox(height: 8),

            // --- Time Row ---
            Row(
              children: [
                const Icon(Icons.access_time, size: 18),
                const SizedBox(width: 8),
                Text(b['time'], style: const TextStyle(fontSize: 14)),
              ],
            ),

            const SizedBox(height: 7),

            // --- Status Row ---
            Row(
              children: [
                Icon(statusIcon, color: statusColor, size: 20),
                const SizedBox(width: 6),
                RichText(
                  text: TextSpan(
                    style: const TextStyle(fontSize: 14, color: Colors.black),
                    children: [
                      TextSpan(text: statusText),
                      if (b['approver'].isNotEmpty) ...[
                        const TextSpan(text: ' by '),
                        TextSpan(
                          text: b['approver'],
                          style: const TextStyle(color: Colors.orange),
                        ),
                      ],
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

  // -------------------------------------------------------------------------
  // EMPTY STATE BUILDER (for no bookings)
  // -------------------------------------------------------------------------
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

  // -------------------------------------------------------------------------
  // MAIN BUILD METHOD
  // -------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromRGBO(217, 217, 217, 1),
      extendBody: true,
      body: Stack(
        children: [
          Column(
            children: [
              // =============================================================
              // HEADER SECTION
              // =============================================================
              Container(
                decoration: const BoxDecoration(
                  color: Color.fromRGBO(0, 51, 102, 1),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(30),
                    bottomRight: Radius.circular(30),
                  ),
                  border: Border(
                    bottom: BorderSide(color: Colors.black, width: 2),
                  ),
                ),
                width: double.infinity,
                height: 200,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 50),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 25),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // --- Greeting and title ---
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
                                style: TextStyle(
                                  fontSize: 25,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                          // --- Logout Button ---
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

                    // --- TabBar: Pending & History ---
                    Padding(
                      padding: const EdgeInsets.only(left: 20.0),
                      child: SizedBox(
                        width: 160,
                        child: TabBar(
                          controller: _tabController,
                          labelColor: Colors.amber,
                          unselectedLabelColor: Colors.white70,
                          indicatorColor: Colors.amber,
                          indicatorSize: TabBarIndicatorSize.label,
                          dividerColor: Colors.transparent,
                          labelStyle: const TextStyle(fontSize: 18),
                          labelPadding: const EdgeInsets.symmetric(
                            horizontal: 0,
                          ),
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

              // =============================================================
              // TAB CONTENT SECTION
              // =============================================================
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // --- Pending Tab ---
                    _pendingBookings.isEmpty
                        ? _buildEmptyState('Pending')
                        : ListView.builder(
                            padding: const EdgeInsets.only(
                              top: 10,
                              bottom: 100,
                            ),
                            itemCount: _pendingBookings.length,
                            itemBuilder: (_, i) =>
                                _buildBookingCard(_pendingBookings[i]),
                          ),

                    // --- History Tab ---
                    _historyBookings.isEmpty
                        ? _buildEmptyState('History')
                        : ListView.builder(
                            padding: const EdgeInsets.only(
                              top: 10,
                              bottom: 100,
                            ),
                            itemCount: _historyBookings.length,
                            itemBuilder: (_, i) =>
                                _buildBookingCard(_historyBookings[i]),
                          ),
                  ],
                ),
              ),
            ],
          ),

          // =============================================================
          // BOTTOM NAVIGATION BAR
          // =============================================================
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 1, sigmaY: 1),
                child: Container(
                  height: 65,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      const SizedBox(width: 20),
                      // --- Back Button ---
                      IconButton(
                        icon: Icon(
                          Icons.arrow_back_rounded,
                          size: 40,
                          color: Colors.white.withOpacity(0.8),
                        ),
                        onPressed: () {
                          Navigator.maybePop(context);
                        },
                      ),
                      const Spacer(),
                      // --- Home Button ---
                      IconButton(
                        icon: Icon(
                          Icons.home_rounded,
                          size: 40,
                          color: Colors.white.withOpacity(0.8),
                        ),
                        onPressed: () {
                          // Navigate to StudentBrowse Page
                        },
                      ),
                      const Spacer(),
                      // --- Today Button ---
                      IconButton(
                        icon: Icon(
                          Icons.today_rounded,
                          size: 40,
                          color: Colors.white.withOpacity(0.8),
                        ),
                        onPressed: () {
                          // Check if already on BookingPage
                          final bool isOnBookingPage =
                              context.widget.runtimeType == BookingPage;

                          if (!isOnBookingPage) {
                            // On other pages --> Navigate to BookingPage
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const BookingPage(),
                              ),
                            );
                          } else {
                            // If already on BookingPage --> Go to Pending tab
                            if (_tabController.index != 0) {
                              _tabController.animateTo(0); // Go to Pending tab
                            }
                          }
                        },
                      ),
                      const SizedBox(width: 20),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
