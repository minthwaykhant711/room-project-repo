import 'package:flutter/material.dart';

class StaffEditRoomPage extends StatelessWidget {
  const StaffEditRoomPage({
    super.key,
    this.initialName = 'Meeting Room A',
    this.initialCapacity = '4 People',
    this.initialDescription = 'Quiet Room, Aircon, Projector',
    required this.imagePath,
  });

  final String initialName;
  final String initialCapacity;
  final String initialDescription;
  final String imagePath; // 👈 room image to show

  static const kNavy  = Color(0xFF003366);
  static const kGreen = Color(0xFF1FA22A);
  static const kRed   = Color(0xFFDA351C);

  @override
  Widget build(BuildContext context) {
    final headerHeight = MediaQuery.of(context).size.height * 0.23;

    return Scaffold(
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          height: 56,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 1),
          decoration: BoxDecoration(
            color: Colors.black87,
            borderRadius: BorderRadius.circular(28),
            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 3))],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(icon: const Icon(Icons.arrow_back_ios, color: Colors.white), onPressed: () => Navigator.maybePop(context)),
              const Icon(Icons.home_filled, color: Colors.white, size: 28),
              const Icon(Icons.calendar_today, color: Colors.white),
            ],
          ),
        ),
      ),

      body: Column(
        children: [
          // Header
          SizedBox(
            height: headerHeight,
            width: double.infinity,
            child: Stack(
              children: [
                Container(
                  decoration: const BoxDecoration(
                    color: kNavy,
                    borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
                  ),
                ),
                Positioned.fill(
                  child: SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text('Hi, Staff', style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800)),
                          SizedBox(height: 2),
                          Text('Edit the Room', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: 8, top: 0,
                  child: SafeArea(
                    bottom: false,
                    child: IconButton(icon: const Icon(Icons.logout, color: Colors.white, size: 26), onPressed: () {}),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Form card
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 3))],
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Image preview box (shows actual room photo)
                      Container(
                        height: 150,
                        decoration: BoxDecoration(
                          color: const Color(0xFFD9D9D9),
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2))],
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.asset(imagePath, fit: BoxFit.cover),
                            // Change image link (purely visual)
                            Align(
                              alignment: Alignment.bottomCenter,
                              child: Container(
                                color: Colors.white70,
                                padding: const EdgeInsets.symmetric(vertical: 6),
                                child: const Text(
                                  'Change image',
                                  style: TextStyle(
                                    color: Color(0xFF4A90E2),
                                    decoration: TextDecoration.underline,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      _label('Room name'),
                      _greyText(initialName),
                      const SizedBox(height: 12),

                      _label('Capacity'),
                      _greyText(initialCapacity),
                      const SizedBox(height: 12),

                      _label('Description'),
                      _greyText(initialDescription, height: 72, alignTop: true),
                      const SizedBox(height: 20),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kGreen,
                              shape: const StadiumBorder(),
                              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                            ),
                            onPressed: () => _showSuccessThenBack(context),
                            child: const Text('Save', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kRed,
                              shape: const StadiumBorder(),
                              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                            ),
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancel', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                          ),
                        ],
                      ),
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

  // helpers
  static Widget _label(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Align(alignment: Alignment.centerLeft, child: Text(t, style: const TextStyle(fontWeight: FontWeight.w600))),
      );

  static Widget _greyText(String text, {double height = 44, bool alignTop = false}) {
    return Container(
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(color: const Color(0xFFD9D9D9), borderRadius: BorderRadius.circular(12)),
      alignment: alignTop ? Alignment.topLeft : Alignment.center,
      child: Text(text, style: const TextStyle(color: Colors.black87)),
    );
  }

  Future<void> _showSuccessThenBack(BuildContext context) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 32),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.check_circle, size: 120, color: Color(0xFF1FA22A)),
              SizedBox(height: 12),
              Text('Room edited successfully', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700), textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
    await Future.delayed(const Duration(milliseconds: 1200));
    Navigator.of(context, rootNavigator: true).pop(); // close dialog
    Navigator.of(context).pop(); // back to Room Management
  }
}
