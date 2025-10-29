import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/logout_function.dart';

class LecturerHistory extends StatefulWidget {
  const LecturerHistory({super.key});

  @override
  State<LecturerHistory> createState() => _LecturerHistoryState();
}

class _LecturerHistoryState extends State<LecturerHistory>
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
  // Sample Data
  // -------------------------------------------------------------------------
  final List<Map<String, dynamic>> _allBookings = [
    {
      'room': 'Study Room A',
      'date': 'Mon, Oct 20',
      'time': '08:00 - 10:00',
      'status': 0,
      'approver': '', // Approver Empty = Pending
      'booked_by': 'Lisa',
    },
    {
      'room': 'Study Room B',
      'date': 'Wed, Oct 27',
      'time': '12:00 - 14:00',
      'status': 0,
      'approver': '',
      'booked_by': 'Tom',
    },
    {
      'room': 'Study Room C',
      'date': 'Mon, Oct 29',
      'time': '10:00 - 12:00',
      'status': 0,
      'approver': '',
      'booked_by': 'Adam',
    },
    {
      'room': 'Study Room A',
      'date': 'Mon, Oct 6',
      'time': '08:00 - 10:00',
      'status': 1, // 1 = Approved
      'approver': 'Ajarn Surapong', // Has Approver = History
      'booked_by': 'Lisa',
    },
    {
      'room': 'Multimedia Room A',
      'date': 'Wed, Oct 1',
      'time': '08:00 - 10:00',
      'status': 1,
      'approver': 'Ajarn Bryan',
      'booked_by': 'John',
    },
    {
      'room': 'Study Room C',
      'date': 'Tue, Sep 30',
      'time': '13:00 - 15:00',
      'status': 0, // 0 = Rejected
      'approver': 'Ajarn Nick',
      'booked_by': 'Emma',
    },
    {
      'room': 'Meeting Room A',
      'date': 'Fri, Sep 26',
      'time': '10:00 - 12:00',
      'status': 1,
      'approver': 'Ajarn Surapong',
      'booked_by': 'Olivia',
    },
    {
      'room': 'Meeting Room A',
      'date': 'Fri, Sep 26',
      'time': '10:00 - 12:00',
      'status': 1,
      'approver': 'Ajarn Surapong',
      'booked_by': 'Liam',
    },
  ];

  // -------------------------------------------------------------------------
  // Action Handlers (Approve & Reject) & Custom Dialog
  // -------------------------------------------------------------------------

  // UPDATED WIDGET: A custom, auto-dismissing dialog that is also tappable
  Future<void> _showAutoDismissDialog({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String message,
  }) async {
    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        // Automatically close the dialog after 2 seconds
        Future.delayed(const Duration(seconds: 2), () {
          // Add a check to prevent errors if the dialog was already closed by a tap
          if (Navigator.of(ctx, rootNavigator: true).canPop()) {
            Navigator.of(ctx, rootNavigator: true).pop(true);
          }
        });

        // Wrap the Dialog with GestureDetector
        return GestureDetector(
          // This function will be called when the user taps the dialog
          onTap: () {
            Navigator.of(ctx, rootNavigator: true).pop(true);
          },
          child: Dialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 45,
                    backgroundColor: iconColor,
                    child: Icon(icon, color: Colors.white, size: 60),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    message,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // UPDATED FUNCTION
  Future<void> _approveBooking(Map<String, dynamic> booking) async {
    // Show the custom dialog and wait for it to finish
    await _showAutoDismissDialog(
      context: context,
      icon: Icons.check,
      iconColor: Colors.green,
      message: 'Booking Approved',
    );

    // Update the state AFTER the dialog has closed
    if (!mounted) return; // Check if the widget is still in the tree
    setState(() {
      final index = _allBookings.indexOf(booking);
      if (index != -1) {
        _allBookings[index]['status'] = 1; // Set status to Approved
        _allBookings[index]['approver'] = username; // Set approver
      }
    });
  }

  // UPDATED FUNCTION with new UI for Reject Dialog
  Future<void> _rejectBooking(Map<String, dynamic> booking) async {
    final reasonController = TextEditingController();
    bool isButtonEnabled = false;

    final bool? isSubmitted = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              // Style for the dialog itself
              backgroundColor: Colors.white,
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
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Theme.of(context).primaryColor,
                      width: 2,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 20,
                  ),
                ),
                onChanged: (text) {
                  setDialogState(() {
                    isButtonEnabled = text.trim().isNotEmpty;
                  });
                },
              ),
              actions: [
                // Secondary action button
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: Colors.black),
                  ),
                ),
                // Primary action button, changed to ElevatedButton
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromRGBO(0, 51, 102, 1),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: isButtonEnabled
                      ? () => Navigator.of(ctx).pop(true)
                      : null, // Still disabled when no reason is entered
                  child: const Text('Submit'),
                ),
              ],
            );
          },
        );
      },
    );

    if (isSubmitted == true) {
      await _showAutoDismissDialog(
        context: context,
        icon: Icons.close,
        iconColor: Colors.red,
        message: 'Booking Rejected',
      );

      if (!mounted) return;
      setState(() {
        final index = _allBookings.indexOf(booking);
        if (index != -1) {
          _allBookings[index]['status'] = 0;
          _allBookings[index]['approver'] = username;
        }
      });
    }
  }

  // -------------------------------------------------------------------------
  // WIDGET BUILDERS
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
            RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 16, color: Colors.black),
                children: [
                  const TextSpan(text: 'Session in '),
                  TextSpan(
                    text: b['room'],
                    style: const TextStyle(color: Colors.orange),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.calendar_month_outlined, size: 20),
                const SizedBox(width: 6),
                Text(b['date'], style: const TextStyle(fontSize: 14)),
                const SizedBox(width: 20),
                const Icon(Icons.access_time, size: 18),
                const SizedBox(width: 6),
                Text(b['time'], style: const TextStyle(fontSize: 14)),
              ],
            ),
            const SizedBox(height: 8),
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
                        text: b['booked_by'],
                        style: const TextStyle(color: Colors.orange),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                if (isPending) ...[
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _approveBooking(b),
                      icon: const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 20,
                      ),
                      label: const Text(
                        'Approve',
                        style: TextStyle(color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _rejectBooking(b),
                      icon: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 20,
                      ),
                      label: const Text(
                        'Reject',
                        style: TextStyle(color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ] else ...[
                  Icon(statusIcon, color: statusColor, size: 20),
                  const SizedBox(width: 6),
                  RichText(
                    text: TextSpan(
                      style: const TextStyle(fontSize: 14, color: Colors.black),
                      children: [
                        TextSpan(text: statusText),
                        const TextSpan(text: ' by '),
                        TextSpan(
                          text: b['approver'],
                          style: const TextStyle(color: Colors.orange),
                        ),
                      ],
                    ),
                  ),
                ],
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

  // -------------------------------------------------------------------------
  // MAIN BUILD METHOD
  // -------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final pending = _allBookings.where((b) => b['approver'].isEmpty).toList();
    final history = _allBookings
        .where((b) => b['approver'].isNotEmpty)
        .toList();

    return Scaffold(
      backgroundColor: const Color.fromRGBO(217, 217, 217, 1),
      extendBody: true,
      body: Stack(
        children: [
          Column(
            children: [
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
                                'Booking Requests',
                                style: TextStyle(
                                  fontSize: 25,
                                  color: Colors.white,
                                ),
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
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    pending.isEmpty
                        ? _buildEmptyState('Pending')
                        : ListView.builder(
                            padding: const EdgeInsets.only(
                              top: 10,
                              bottom: 100,
                            ),
                            itemCount: pending.length,
                            itemBuilder: (_, i) =>
                                _buildBookingCard(pending[i]),
                          ),
                    history.isEmpty
                        ? _buildEmptyState('History')
                        : ListView.builder(
                            padding: const EdgeInsets.only(
                              top: 10,
                              bottom: 100,
                            ),
                            itemCount: history.length,
                            itemBuilder: (_, i) =>
                                _buildBookingCard(history[i]),
                          ),
                  ],
                ),
              ),
            ],
          ),
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
                      IconButton(
                        icon: Icon(
                          Icons.home_rounded,
                          size: 40,
                          color: Colors.white.withOpacity(0.8),
                        ),
                        onPressed: () {},
                      ),
                      const Spacer(),
                      IconButton(
                        icon: Icon(
                          Icons.today_rounded,
                          size: 40,
                          color: Colors.white.withOpacity(0.8),
                        ),
                        onPressed: () {
                          final bool isOnBookingPage =
                              context.widget.runtimeType == LecturerHistory;
                          if (!isOnBookingPage) {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const LecturerHistory(),
                              ),
                            );
                          } else {
                            if (_tabController.index != 0) {
                              _tabController.animateTo(0);
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
