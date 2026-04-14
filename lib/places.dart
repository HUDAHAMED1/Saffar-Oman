import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class PlacesScreen extends StatefulWidget {
  const PlacesScreen({super.key});

  @override
  State<PlacesScreen> createState() => _PlacesScreenState();
}

class _PlacesScreenState extends State<PlacesScreen> {
  final DatabaseReference _db = FirebaseDatabase.instance.ref();
  final TextEditingController _search = TextEditingController();

  Query _query = FirebaseDatabase.instance.ref().child('places').orderByChild('createdAt');

  @override
  void initState() {
    super.initState();
    _search.addListener(_onSearch);
  }

  @override
  void dispose() {
    _search.removeListener(_onSearch);
    _search.dispose();
    super.dispose();
  }

  void _onSearch() {
    final q = _search.text.trim().toLowerCase();
    if (q.isEmpty) {
      setState(() {
        _query = _db.child('places').orderByChild('createdAt');
      });
      return;
    }

    setState(() {
      _query = _db.child('places').orderByChild('nameLower').startAt(q).endAt('$q\uf8ff');
    });
  }

  String _s(dynamic v) => (v ?? '').toString();

  List<Map<String, dynamic>> _toList(dynamic value) {
    final map = value is Map ? Map<String, dynamic>.from(value) : <String, dynamic>{};
    final out = <Map<String, dynamic>>[];

    for (final e in map.entries) {
      final v = e.value;
      if (v is Map) {
        final item = Map<String, dynamic>.from(v);
        item['id'] = e.key.toString();
        out.add(item);
      }
    }

    out.sort((a, b) {
      final aa = (a['createdAt'] is int) ? a['createdAt'] as int : 0;
      final bb = (b['createdAt'] is int) ? b['createdAt'] as int : 0;
      return bb.compareTo(aa);
    });

    return out;
  }

  Widget _bg() {
    return Stack(
      children: [
        Positioned.fill(child: Image.asset('images/background.jpeg', fit: BoxFit.cover)),
        Positioned.fill(child: Container(color: Colors.brown.withOpacity(0.6))),
      ],
    );
  }

  Widget _searchBar() {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: const Color(0xFFE7D5C0).withOpacity(0.9),
        borderRadius: BorderRadius.circular(14),
      ),
      child: TextField(
        controller: _search,
        decoration: const InputDecoration(
          prefixIcon: Icon(Icons.search),
          hintText: 'Search for attractions',
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _placeCard(Map<String, dynamic> p) {
    final id = _s(p['id']);
    final name = _s(p['name']);
    final desc = _s(p['description']);
    final photoUrl = _s(p['photoUrl']);

    final img = photoUrl.isNotEmpty
        ? Image.network(photoUrl, fit: BoxFit.cover, width: double.infinity, height: 210)
        : Container(
      width: double.infinity,
      height: 210,
      color: Colors.black12,
      alignment: Alignment.center,
      child: const Icon(Icons.image, size: 34, color: Colors.black45),
    );

    return MouseRegion(
      child: Tooltip(
        message: 'View Details',
        child: GestureDetector(
          onTap: () {
            Navigator.pushNamed(
              context,
              '/placeDetails',
              arguments: {'placeId': id},
            );
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 18),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.10),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Stack(
                    children: [
                      img,
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withOpacity(0.45),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        left: 14,
                        right: 14,
                        bottom: 12,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              name,
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              desc,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 11),
                            ),
                            const SizedBox(height: 10),
                            SizedBox(
                              width: 200,
                              height: 36,
                              child: ElevatedButton(
                                onPressed: () {
                                  Navigator.pushNamed(
                                    context,
                                    '/bookingForm',
                                    arguments: {'placeId': id},
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFE7D5C0).withOpacity(0.95),
                                  foregroundColor: Colors.black,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                child: const Text('Select for Booking'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _empty() {
    return const Center(
      child: Text(
        'No attractions found',
        style: TextStyle(color: Colors.white70),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          _bg(),
          SafeArea(
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
                            'Attractions',
                            style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _searchBar(),
                  const SizedBox(height: 14),
                  Expanded(
                    child: StreamBuilder<DatabaseEvent>(
                      stream: _query.onValue,
                      builder: (context, snap) {
                        final items = _toList(snap.data?.snapshot.value);
                        if (items.isEmpty) return _empty();

                        return ListView.builder(
                          itemCount: items.length,
                          itemBuilder: (context, i) => _placeCard(items[i]),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
