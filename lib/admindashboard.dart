import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  Future<void> _logout(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
      Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
    } catch (_) {}
  }

  String _formatDate(String iso) {
    try {
      final dt = DateTime.parse(iso);
      const months = [
        'JAN','FEB','MAR','APR','MAY','JUN',
        'JUL','AUG','SEP','OCT','NOV','DEC'
      ];
      final d = dt.day.toString().padLeft(2, '0');
      final m = months[dt.month - 1];
      final y = dt.year.toString();
      return '$d.$m.$y';
    } catch (_) {
      return iso;
    }
  }

  @override
  Widget build(BuildContext context) {
    final DatabaseReference reqRef = FirebaseDatabase.instance.ref('guideRequests');

    return Scaffold(
      backgroundColor: const Color(0xFF6B4F3A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF6B4F3A),
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            onPressed: () => _logout(context),
            icon: const Icon(Icons.logout, color: Colors.white),
            tooltip: "Logout",
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Center(
                  child: Text(
                    "Saffar Oman",
                    style: TextStyle(fontSize: 22, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 30),
                const Text(
                  "Admin Tools",
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
                const SizedBox(height: 20),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _adminBox(
                      title: "Manage Users",
                      subtitle: "Add, Update, Delete",
                      icon: Icons.group,
                      onTap: () {
                        Navigator.pushNamed(context, "/adminManageUsers");
                      },
                    ),
                    _adminBox(
                      title: "Manage Sites",
                      subtitle: "Add, Update, Delete",
                      icon: Icons.location_on,
                      onTap: () {
                        Navigator.pushNamed(context, "/adminManageSites");
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _adminBox(
                      title: "Manage Reviews",
                      subtitle: "View & respond",
                      icon: Icons.reviews,
                      onTap: () {
                        Navigator.pushNamed(context, "/adminManageReviews");
                      },
                    ),
                    _adminBox(
                      title: "Send Notifications",
                      subtitle: "Push alerts",
                      icon: Icons.notifications,
                      onTap: () {
                        Navigator.pushNamed(context, "/adminSendNotifications");
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _adminBox(
                      title: "Approve Guides",
                      subtitle: "Review Applications",
                      icon: Icons.verified_user,
                      onTap: () {
                        Navigator.pushNamed(context, "/adminGuideRequests");
                      },
                    ),
                    _adminBox(
                      title: "Manage Cars",
                      subtitle: "Add, Update, Delete",
                      icon: Icons.directions_car,
                      onTap: () {
                        Navigator.pushNamed(context, "/adminCars");
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 30),

                const Text(
                  "Pending Guides Approvals",
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
                const SizedBox(height: 20),

                StreamBuilder<DatabaseEvent>(
                  stream: reqRef.onValue,
                  builder: (context, snapshot) {
                    if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
                      return const Text(
                        "No pending requests",
                        style: TextStyle(color: Colors.white70),
                      );
                    }

                    final raw = snapshot.data!.snapshot.value as Map;
                    final pending = <Map<String, dynamic>>[];

                    raw.forEach((k, v) {
                      if (v is Map) {
                        final m = Map<String, dynamic>.from(v);
                        final status = (m['status'] ?? 'pending').toString();
                        if (status == 'pending') {
                          m['uid'] = k.toString();
                          pending.add(m);
                        }
                      }
                    });

                    if (pending.isEmpty) {
                      return const Text(
                        "No pending requests",
                        style: TextStyle(color: Colors.white70),
                      );
                    }

                    pending.sort((a, b) {
                      final aT = (a['createdAt'] ?? '').toString();
                      final bT = (b['createdAt'] ?? '').toString();
                      return bT.compareTo(aT);
                    });

                    return Column(
                      children: pending.map((r) {
                        final name = (r['name'] ?? 'Unknown').toString();
                        final createdAt = (r['createdAt'] ?? '').toString();
                        final dateText = createdAt.isEmpty ? '' : _formatDate(createdAt);

                        return _pendingGuide(
                          context,
                          name,
                          dateText.isEmpty ? '' : dateText,
                        );
                      }).toList(),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static Widget _adminBox({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 150,
        height: 130,
        decoration: BoxDecoration(
          color: const Color(0xFFBFA892),
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 35, color: Colors.black87),
            const SizedBox(height: 10),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(subtitle, style: const TextStyle(fontSize: 11)),
          ],
        ),
      ),
    );
  }

  Widget _pendingGuide(BuildContext context, String name, String date) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, "/adminGuideRequests");
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: const Color(0xFFBFA892),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            const CircleAvatar(
              radius: 28,
              backgroundImage: AssetImage("images/man.png"),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text(date.isEmpty ? "Applied" : "Applied $date"),
                ],
              ),
            ),
            Column(
              children: [
                _statusButton("OPEN", const Color(0xFF2E7D32)),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _statusButton(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(text, style: const TextStyle(color: Colors.white)),
    );
  }
}
