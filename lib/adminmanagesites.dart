import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class AdminManageSitesScreen extends StatefulWidget {
  const AdminManageSitesScreen({super.key});

  @override
  State<AdminManageSitesScreen> createState() => _AdminManageSitesScreenState();
}

class _AdminManageSitesScreenState extends State<AdminManageSitesScreen> {
  final DatabaseReference _db = FirebaseDatabase.instance.ref();
  final TextEditingController _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  String _s(dynamic v) => (v ?? '').toString();

  Future<void> _deleteSite(String id) async {
    await _db.child('places/$id').remove();
  }

  // ✅ TEMP: create places + add 2 items
  Future<void> _createPlacesTemp() async {
    try {
      await _db.child('places').push().set({
        "name": "Test Place 1",
        "nameLower": "test place 1",
        "photoUrl": "",
        "image": "",
      });

      await _db.child('places').push().set({
        "name": "Test Place 2",
        "nameLower": "test place 2",
        "photoUrl": "",
        "image": "",
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ places created + items added")),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Error: $e")),
      );
    }
  }

  Widget _bg() {
    return Stack(
      children: [
        Positioned.fill(
          child: Image.asset('images/background.jpeg', fit: BoxFit.cover),
        ),
        Positioned.fill(
          child: Container(color: const Color(0xFF6B4A3A).withAlpha(120)),
        ),
      ],
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
                        icon: const Icon(Icons.arrow_back_ios_new,
                            color: Colors.black),
                      ),
                      const Expanded(
                        child: Center(
                          child: Text(
                            'Manage Tourist Sites',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),

                  // ✅ TEMP BUTTON (remove later)
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton(
                      onPressed: _createPlacesTemp,
                      child: const Text("Create places (TEMP)"),
                    ),
                  ),

                  const SizedBox(height: 10),
                  Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(170),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      children: [
                        const Icon(Icons.search, color: Colors.black54),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _search,
                            onChanged: (_) => setState(() {}),
                            decoration: const InputDecoration(
                              hintText: 'Search for a site',
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () =>
                            Navigator.pushNamed(context, '/adminAddSite'),
                        child:
                        const Icon(Icons.add, size: 26, color: Colors.black),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'Add site',
                        style: TextStyle(color: Colors.black, fontSize: 13),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: StreamBuilder<DatabaseEvent>(
                      stream: _db.child('places').onValue,
                      builder: (context, snap) {
                        if (!snap.hasData) {
                          return const Center(child: CircularProgressIndicator());
                        }

                        final val = snap.data!.snapshot.value;
                        final map = val is Map
                            ? Map<String, dynamic>.from(val)
                            : <String, dynamic>{};

                        final items = <Map<String, dynamic>>[];
                        for (final e in map.entries) {
                          final v = e.value;
                          if (v is Map) {
                            final it = Map<String, dynamic>.from(v);
                            it['_id'] = e.key.toString();
                            items.add(it);
                          }
                        }

                        final q = _search.text.trim().toLowerCase();
                        final filtered = q.isEmpty
                            ? items
                            : items.where((it) {
                          final nameLower =
                          _s(it['nameLower']).toLowerCase();
                          final name = _s(it['name']).toLowerCase();
                          return nameLower.contains(q) || name.contains(q);
                        }).toList();

                        filtered.sort((a, b) => _s(a['nameLower'])
                            .compareTo(_s(b['nameLower'])));

                        if (filtered.isEmpty) {
                          return Center(
                            child: Text(
                              'No sites',
                              style: TextStyle(color: Colors.white.withAlpha(220)),
                            ),
                          );
                        }

                        return ListView.builder(
                          itemCount: filtered.length,
                          itemBuilder: (context, i) {
                            final it = filtered[i];
                            final id = _s(it['_id']);
                            final name = _s(it['name']);
                            final image = _s(it['image']);
                            final photoUrl = _s(it['photoUrl']);

                            Widget img;
                            if (photoUrl.isNotEmpty) {
                              img = Image.network(photoUrl,
                                  width: 90, height: 80, fit: BoxFit.cover);
                            } else if (image.isNotEmpty) {
                              img = Image.asset(image,
                                  width: 90, height: 80, fit: BoxFit.cover);
                            } else {
                              img = Container(
                                width: 90,
                                height: 80,
                                color: Colors.black12,
                                alignment: Alignment.center,
                                child: const Icon(Icons.image,
                                    color: Colors.black45),
                              );
                            }

                            return Container(
                              height: 110,
                              margin: const EdgeInsets.only(bottom: 14),
                              decoration: BoxDecoration(
                                color: Colors.white.withAlpha(120),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                children: [
                                  ClipRRect(
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(10),
                                      bottomLeft: Radius.circular(10),
                                    ),
                                    child: img,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          name,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 20,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        Row(
                                          children: [
                                            SizedBox(
                                              width: 90,
                                              height: 34,
                                              child: ElevatedButton(
                                                onPressed: () {
                                                  Navigator.pushNamed(
                                                    context,
                                                    '/adminEditSite',
                                                    arguments: it,
                                                  );
                                                },
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor:
                                                  Colors.white.withAlpha(200),
                                                  foregroundColor: Colors.black,
                                                  elevation: 0,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                    BorderRadius.circular(10),
                                                  ),
                                                ),
                                                child: const Text('edit'),
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            SizedBox(
                                              width: 90,
                                              height: 34,
                                              child: TextButton(
                                                onPressed: () => _deleteSite(id),
                                                child: const Text(
                                                  'delete',
                                                  style: TextStyle(
                                                    color: Colors.red,
                                                    fontSize: 18,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        )
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                ],
                              ),
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
        ],
      ),
    );
  }
}