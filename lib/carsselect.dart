import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class CarsSelectScreen extends StatefulWidget {
  const CarsSelectScreen({super.key});
  @override
  State<CarsSelectScreen> createState() => _CarsSelectScreenState();
}

class _CarsSelectScreenState extends State<CarsSelectScreen> {
  final DatabaseReference _db = FirebaseDatabase.instance.ref();
  final TextEditingController _search = TextEditingController();

  Query _q =
  FirebaseDatabase.instance.ref().child('cars').orderByChild('createdAt');

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
    final s = _search.text.trim().toLowerCase();
    if (s.isEmpty) {
      setState(() => _q = _db.child('cars').orderByChild('createdAt'));
      return;
    }
    setState(() {
      _q = _db.child('cars').orderByChild('nameLower').startAt(s).endAt('$s\uf8ff');
    });
  }

  String _s(dynamic v) => (v ?? '').toString();

  List<Map<String, dynamic>> _toList(dynamic value) {
    final map = value is Map
        ? Map<String, dynamic>.from(value)
        : <String, dynamic>{};
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
    return Container(color: const Color(0xFF6B4F3A));
  }

  Widget _searchBar() {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.80),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: _search,
        decoration: const InputDecoration(
          prefixIcon: Icon(Icons.search),
          hintText: 'Search car',
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _carCard(Map<String, dynamic> c) {
    final id = _s(c['id']);
    final name = _s(c['name']);
    final desc = _s(c['description']);
    final imageUrl = _s(c['imageUrl']);
    final seats = _s(c['seats']);
    final bags = _s(c['bags']);
    final price = _s(c['pricePerDay']);

    final img = imageUrl.isNotEmpty
        ? Image.network(
      imageUrl,
      width: double.infinity,
      height: 190,
      fit: BoxFit.cover,
    )
        : Container(
      width: double.infinity,
      height: 190,
      color: Colors.black12,
      alignment: Alignment.center,
      child: const Icon(
        Icons.directions_car,
        size: 34,
        color: Colors.black45,
      ),
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFBFA892),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: img,
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        desc,
                        style: const TextStyle(
                          color: Colors.black54,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(
                            Icons.person,
                            size: 16,
                            color: Colors.black54,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            seats.isEmpty ? '-' : seats,
                            style: const TextStyle(
                              color: Colors.black54,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(width: 18),
                          const Icon(
                            Icons.work,
                            size: 16,
                            color: Colors.black54,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            bags.isEmpty ? '-' : bags,
                            style: const TextStyle(
                              color: Colors.black54,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        price.isEmpty ? '-' : '$price OMR /day',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 110,
                  height: 38,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context, {
                        'carId': id,
                        'name': name,
                        'pricePerDay': price,
                        'imageUrl': imageUrl,
                        'description': desc,
                        'seats': seats,
                        'bags': bags,
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white.withOpacity(0.85),
                      foregroundColor: Colors.black,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text('Select Car'),
                  ),
                ),
              ],
            ),
          ),
        ],
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
                        icon: const Icon(
                          Icons.arrow_back_ios_new,
                          color: Colors.black,
                        ),
                      ),
                      const Expanded(
                        child: Center(
                          child: Text(
                            'Select Your Car',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
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
                      stream: _q.onValue,
                      builder: (context, snap) {
                        if (snap.hasError) {
                          return Center(
                            child: Text(
                              'Error loading cars: ${snap.error}',
                              style: const TextStyle(color: Colors.white70),
                              textAlign: TextAlign.center,
                            ),
                          );
                        }

                        if (snap.connectionState == ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        final cars = _toList(snap.data?.snapshot.value);

                        if (cars.isEmpty) {
                          return const Center(
                            child: Text(
                              'No cars available',
                              style: TextStyle(color: Colors.white70),
                            ),
                          );
                        }

                        return ListView.builder(
                          itemCount: cars.length,
                          itemBuilder: (context, i) => _carCard(cars[i]),
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
