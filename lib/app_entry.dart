import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class AppEntryScreen extends StatefulWidget {
  const AppEntryScreen({super.key});
  
  @override
  State<AppEntryScreen> createState() => _AppEntryScreenState();
}

class _AppEntryScreenState extends State<AppEntryScreen> {
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _boot());
  }

  Future<void> _boot() async {
    if (_navigated || !mounted) return;

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      _go('/');
      return;
    }

    final uid = user.uid;

    final userSnap = await FirebaseDatabase.instance.ref('users/$uid').get();
    if (!userSnap.exists || userSnap.value == null) {
      await FirebaseAuth.instance.signOut();
      _go('/');
      return;
    }

    final userData = Map<String, dynamic>.from(
      userSnap.value as Map<Object?, Object?>,
    );

    final role = (userData['role'] ?? '').toString();
    final status = (userData['status'] ?? 'approved').toString();

    final bannerShown = await _showLatestUnread(uid);

    if (!mounted) return;

    if (bannerShown) {
      await Future.delayed(const Duration(milliseconds: 1600));
      if (!mounted) return;
    }

    if (role == 'admin') {
      _go('/adminDashboard');
      return;
    }

    if (role == 'tourist') {
      _go('/explore');
      return;
    }

    if (role == 'guide') {
      if (status != 'approved') {
        await FirebaseAuth.instance.signOut();
        _go('/touristLogin');
        return;
      }
      _go('/guideHome');
      return;
    }

    await FirebaseAuth.instance.signOut();
    _go('/touristLogin');
  }

  Future<bool> _showLatestUnread(String uid) async {
    final ref = FirebaseDatabase.instance.ref('notifications/$uid');
    final snap = await ref
        .orderByChild('read')
        .equalTo(false)
        .limitToLast(1)
        .get();

    if (!snap.exists || snap.value == null) return false;

    final map = Map<String, dynamic>.from(
      snap.value as Map<Object?, Object?>,
    );

    String key = '';
    Map<String, dynamic> notif = {};

    map.forEach((k, v) {
      key = k.toString();
      notif = Map<String, dynamic>.from(v as Map<Object?, Object?>);
    });

    final title = (notif['title'] ?? 'Notification').toString();
    final message = (notif['message'] ?? '').toString();

    bool shown = false;

    if (message.trim().isNotEmpty) {
      await _topBanner(title: title, message: message);
      shown = true;
    }

    if (key.isNotEmpty) {
      await ref.child(key).update({'read': true});
    }

    return shown;
  }

  Future<void> _topBanner({
    required String title,
    required String message,
  }) async {
    final overlay = Overlay.of(context);

    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (_) => Positioned(
        top: MediaQuery.of(context).padding.top + 12,
        left: 16,
        right: 16,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.notifications_active,
                  color: Colors.orange,
                  size: 26,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        message,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    if (entry.mounted) entry.remove();
                  },
                  child: const Icon(
                    Icons.close,
                    size: 20,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    overlay.insert(entry);

    await Future.delayed(const Duration(seconds: 5));
    if (entry.mounted) entry.remove();
  }

  void _go(String route) {
    if (_navigated || !mounted) return;
    _navigated = true;

    Navigator.pushNamedAndRemoveUntil(
      context,
      route,
          (r) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
