import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final DatabaseReference _db = FirebaseDatabase.instance.ref();
  String _tab = 'completed';

  String _s(dynamic v) => (v ?? '').toString();

  DatabaseReference? get _ref {
    final u = FirebaseAuth.instance.currentUser;
    if (u == null) return null;
    return _db.child('users/${u.uid}/bookings');
  }

  DateTime? _parseDate(dynamic v) {
    if (v == null) return null;
    if (v is int) return DateTime.fromMillisecondsSinceEpoch(v);
    final s = v.toString().trim();
    if (s.isEmpty) return null;
    final d = DateTime.tryParse(s);
    return d;
  }

  String _formatDateTime(DateTime? dt) {
    if (dt == null) return '';
    String two(int n) => n.toString().padLeft(2, '0');
    final m = [
      'Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'
    ][dt.month - 1];
    int hour = dt.hour;
    final ampm = hour >= 12 ? 'PM' : 'AM';
    hour = hour % 12;
    if (hour == 0) hour = 12;
    return '$m${dt.day},${dt.year} at $hour:${two(dt.minute)}$ampm';
  }

  Widget _tripCard({
    required String title,
    required String dateText,
    required String guide,
    required String imageAsset,
    required String photoUrl,
  }) {
    Widget img;
    if (photoUrl.isNotEmpty) {
      img = Image.network(photoUrl, width: 86, height: 68, fit: BoxFit.cover);
    } else if (imageAsset.isNotEmpty) {
      img = Image.asset(imageAsset, width: 86, height: 68, fit: BoxFit.cover);
    } else {
      img = Container(
        width: 86,
        height: 68,
        color: Colors.black12,
        alignment: Alignment.center,
        child: const Icon(Icons.image, color: Colors.black45),
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(140),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: img,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.black, fontSize: 14, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 14, color: Colors.black54),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        dateText,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Colors.black.withAlpha(170), fontSize: 12),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.person_outline, size: 16, color: Colors.black54),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Guide: $guide',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Colors.black.withAlpha(170), fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tabs() {
    final selected = const Color(0xFFBFA892).withAlpha(190);
    final unselected = Colors.white.withAlpha(120);

    Widget pill(String label, bool active) {
      return Expanded(
        child: GestureDetector(
          onTap: () => setState(() => _tab = label.toLowerCase()),
          child: Container(
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: active ? selected : unselected,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              label[0].toUpperCase() + label.substring(1),
              style: const TextStyle(color: Colors.black, fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(110),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          pill('completed', _tab == 'completed'),
          const SizedBox(width: 8),
          pill('upcoming', _tab == 'upcoming'),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ref = _ref;

    return Scaffold(
      body: Container(
        color: const Color(0xFF6B4A3A),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
            child: Column(
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
                    ),
                    const Expanded(
                      child: Center(
                        child: Text(
                          'My Trips',
                          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
                const SizedBox(height: 14),
                _tabs(),
                const SizedBox(height: 18),
                if (ref == null)
                  const Expanded(child: Center(child: Text('Not logged in', style: TextStyle(color: Colors.white))))
                else
                  Expanded(
                    child: StreamBuilder<DatabaseEvent>(
                      stream: ref.onValue,
                      builder: (context, snap) {
                        if (!snap.hasData) {
                          return const Center(child: CircularProgressIndicator());
                        }

                        final val = snap.data!.snapshot.value;
                        final map = val is Map ? Map<String, dynamic>.from(val) : <String, dynamic>{};

                        final items = <Map<String, dynamic>>[];
                        for (final e in map.entries) {
                          final v = e.value;
                          if (v is Map) {
                            final it = Map<String, dynamic>.from(v);
                            it['_id'] = e.key.toString();
                            items.add(it);
                          }
                        }

                        final wanted = _tab;
                        final filtered = items.where((it) {
                          final st = _s(it['status']).toLowerCase();
                          return st == wanted;
                        }).toList();

                        filtered.sort((a, b) {
                          final ad = _parseDate(a['dateTime'] ?? a['date']);
                          final bd = _parseDate(b['dateTime'] ?? b['date']);
                          if (ad == null && bd == null) return 0;
                          if (ad == null) return 1;
                          if (bd == null) return -1;
                          return bd.compareTo(ad);
                        });

                        if (filtered.isEmpty) {
                          return Center(
                            child: Text(
                              'No trips yet',
                              style: TextStyle(color: Colors.white.withAlpha(220)),
                            ),
                          );
                        }

                        return ListView.builder(
                          itemCount: filtered.length,
                          itemBuilder: (context, i) {
                            final it = filtered[i];
                            final title = _s(it['title']);
                            final guide = _s(it['guideName']);
                            final image = _s(it['image']);
                            final photoUrl = _s(it['photoUrl']);
                            final dt = _parseDate(it['dateTime'] ?? it['date']);
                            final dateText = it['timeRange'] != null && _s(it['timeRange']).isNotEmpty
                                ? _formatDateTime(dt)
                                : _formatDateTime(dt);

                            return _tripCard(
                              title: title.isEmpty ? 'Trip' : title,
                              dateText: dateText,
                              guide: guide.isEmpty ? '-' : guide,
                              imageAsset: image,
                              photoUrl: photoUrl,
                            );
                          },
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
