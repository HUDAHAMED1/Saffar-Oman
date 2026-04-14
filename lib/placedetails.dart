import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class PlaceDetailsScreen extends StatefulWidget {
  const PlaceDetailsScreen({super.key});

  @override
  State<PlaceDetailsScreen> createState() => _PlaceDetailsScreenState();
}

class _PlaceDetailsScreenState extends State<PlaceDetailsScreen> {
  final DatabaseReference _db = FirebaseDatabase.instance.ref();

  String _s(dynamic v) => (v ?? '').toString();

  Widget _bg() {
    return Stack(
      children: [
        Positioned.fill(child: Image.asset('images/background.jpeg', fit: BoxFit.cover)),
        Positioned.fill(child: Container(color: Colors.brown.withOpacity(0.6))),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    final placeId = (args is Map && args['placeId'] != null) ? args['placeId'].toString() : '';

    return Scaffold(
      body: Stack(
        children: [
          _bg(),
          SafeArea(
            child: StreamBuilder<DatabaseEvent>(
              stream: _db.child('places/$placeId').onValue,
              builder: (context, snap) {
                final v = snap.data?.snapshot.value;
                final p = v is Map ? Map<String, dynamic>.from(v) : <String, dynamic>{};

                final name = _s(p['name']);
                final location = _s(p['location']);
                final desc = _s(p['description']);
                final price = _s(p['pricePerDay']).isNotEmpty ? _s(p['pricePerDay']) : '17';
                final photoUrl = _s(p['photoUrl']);

                final img = photoUrl.isNotEmpty
                    ? Image.network(photoUrl, fit: BoxFit.cover, width: double.infinity, height: 240)
                    : Container(
                  width: double.infinity,
                  height: 240,
                  color: Colors.black12,
                  alignment: Alignment.center,
                  child: const Icon(Icons.image, size: 34, color: Colors.black45),
                );

                return Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
                          ),
                          Expanded(
                            child: Center(
                              child: Text(
                                name.isEmpty ? 'Details' : name,
                                style: const TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ),
                          const SizedBox(width: 48),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: GestureDetector(
                          onTap: () {
                            Navigator.pushNamed(
                              context,
                              '/bookingForm',
                              arguments: {'placeId': placeId},
                            );
                          },
                          child: img,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          location.isEmpty ? 'location_on  Muscat, Oman' : 'location_on  $location',
                          style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 13),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.10),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Descriptions',
                              style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              desc.isEmpty ? '-' : desc,
                              style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 12, height: 1.35),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        '$price OMR/day',
                        style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                      const Spacer(),
                      SizedBox(
                        width: 260,
                        height: 44,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pushNamed(
                              context,
                              '/bookingForm',
                              arguments: {'placeId': placeId},
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white.withOpacity(0.35),
                            foregroundColor: Colors.black,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          child: const Text('Book Now'),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
