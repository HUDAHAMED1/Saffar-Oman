import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class FavouritesScreen extends StatefulWidget {
  const FavouritesScreen({super.key});

  @override
  State<FavouritesScreen> createState() => _FavouritesScreenState();
}

class _FavouritesScreenState extends State<FavouritesScreen> {
  final DatabaseReference _db = FirebaseDatabase.instance.ref();

  User? get _user => FirebaseAuth.instance.currentUser;

  DatabaseReference? get _favPlacesRef {
    final uid = _user?.uid;
    if (uid == null) return null;
    return _db.child('users/$uid/favourites/places');
  }

  DatabaseReference? get _favGuidesRef {
    final uid = _user?.uid;
    if (uid == null) return null;
    return _db.child('users/$uid/favourites/guides');
  }

  String _s(dynamic v) => (v ?? '').toString();

  List<String> _ids(dynamic value) {
    final map = value is Map ? Map<String, dynamic>.from(value) : <String, dynamic>{};
    return map.keys.map((e) => e.toString()).toList();
  }

  Future<Map<String, dynamic>?> _getPlace(String id) async {
    final snap = await _db.child('places/$id').get();
    if (!snap.exists) return null;
    final v = snap.value;
    if (v is Map) {
      final m = Map<String, dynamic>.from(v);
      m['id'] = id;
      return m;
    }
    return null;
  }

  Future<Map<String, dynamic>?> _getGuide(String id) async {
    final snap = await _db.child('guides/$id').get();
    if (!snap.exists) return null;
    final v = snap.value;
    if (v is Map) {
      final m = Map<String, dynamic>.from(v);
      m['id'] = id;
      return m;
    }
    return null;
  }

  Future<List<Map<String, dynamic>>> _loadFavPlaces(List<String> ids) async {
    final List<Map<String, dynamic>> out = [];
    for (final id in ids) {
      final p = await _getPlace(id);
      if (p != null) out.add(p);
    }
    return out;
  }

  Future<List<Map<String, dynamic>>> _loadFavGuides(List<String> ids) async {
    final List<Map<String, dynamic>> out = [];
    for (final id in ids) {
      final g = await _getGuide(id);
      if (g != null) out.add(g);
    }
    return out;
  }

  Future<void> _removePlace(String id) async {
    final ref = _favPlacesRef;
    if (ref == null) return;
    await ref.child(id).remove();
  }

  Future<void> _removeGuide(String id) async {
    final ref = _favGuidesRef;
    if (ref == null) return;
    await ref.child(id).remove();
  }

  Widget _bg() {
    return Container(color: const Color(0xFF6B4F3A));
  }

  Widget _tile({
    required Widget leading,
    required String title,
    required String subtitle,
    required VoidCallback onRemove,
    VoidCallback? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFBFA892),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          leading,
          const SizedBox(width: 10),
          Expanded(
            child: GestureDetector(
              onTap: onTap,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: const TextStyle(color: Colors.black54, fontSize: 12)),
                ],
              ),
            ),
          ),
          IconButton(
            onPressed: onRemove,
            icon: const Icon(Icons.favorite, color: Colors.black54),
          ),
        ],
      ),
    );
  }

  Widget _placeLeading(Map<String, dynamic> p) {
    final photoUrl = _s(p['photoUrl']);
    if (photoUrl.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.network(photoUrl, width: 54, height: 54, fit: BoxFit.cover),
      );
    }
    final asset = _s(p['image']);
    if (asset.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.asset(asset, width: 54, height: 54, fit: BoxFit.cover),
      );
    }
    return Container(
      width: 54,
      height: 54,
      decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(10)),
      alignment: Alignment.center,
      child: const Icon(Icons.image, color: Colors.black45),
    );
  }

  Widget _guideLeading(Map<String, dynamic> g) {
    final photoUrl = _s(g['photoUrl']);
    if (photoUrl.isNotEmpty) {
      return CircleAvatar(radius: 22, backgroundImage: NetworkImage(photoUrl));
    }
    final asset = _s(g['avatarAsset']);
    if (asset.isNotEmpty) {
      return CircleAvatar(radius: 22, backgroundImage: AssetImage(asset));
    }
    return const CircleAvatar(radius: 22, child: Icon(Icons.person));
  }

  Widget _loading() {
    return const Center(child: CircularProgressIndicator());
  }

  Widget _empty(String text) {
    return Center(child: Text(text, style: const TextStyle(color: Colors.white70)));
  }

  @override
  Widget build(BuildContext context) {
    final placesRef = _favPlacesRef;
    final guidesRef = _favGuidesRef;

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
                            'Favourites',
                            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: (placesRef == null && guidesRef == null)
                        ? _empty('No favourites yet')
                        : ListView(
                      children: [
                        StreamBuilder<DatabaseEvent>(
                          stream: guidesRef?.onValue,
                          builder: (context, snap) {
                            if (guidesRef == null) return const SizedBox.shrink();
                            final ids = _ids(snap.data?.snapshot.value);
                            if (ids.isEmpty) return const SizedBox.shrink();

                            return FutureBuilder<List<Map<String, dynamic>>>(
                              future: _loadFavGuides(ids),
                              builder: (context, fs) {
                                if (fs.connectionState == ConnectionState.waiting) return _loading();
                                final guides = fs.data ?? [];
                                if (guides.isEmpty) return const SizedBox.shrink();

                                return Column(
                                  children: guides.map((g) {
                                    final id = _s(g['id']);
                                    final name = _s(g['name']);
                                    final langs = _s(g['languages']);
                                    return _tile(
                                      leading: _guideLeading(g),
                                      title: name.isEmpty ? 'Guide' : name,
                                      subtitle: langs.isEmpty ? 'Tour Guide' : langs,
                                      onRemove: () => _removeGuide(id),
                                    );
                                  }).toList(),
                                );
                              },
                            );
                          },
                        ),
                        const SizedBox(height: 10),
                        StreamBuilder<DatabaseEvent>(
                          stream: placesRef?.onValue,
                          builder: (context, snap) {
                            if (placesRef == null) return const SizedBox.shrink();
                            final ids = _ids(snap.data?.snapshot.value);
                            if (ids.isEmpty) return _empty('No favourites yet');

                            return FutureBuilder<List<Map<String, dynamic>>>(
                              future: _loadFavPlaces(ids),
                              builder: (context, fs) {
                                if (fs.connectionState == ConnectionState.waiting) return _loading();
                                final places = fs.data ?? [];
                                if (places.isEmpty) return _empty('No favourites yet');

                                return Column(
                                  children: places.map((p) {
                                    final id = _s(p['id']);
                                    final name = _s(p['name']);
                                    final loc = _s(p['location']);
                                    return _tile(
                                      leading: _placeLeading(p),
                                      title: name.isEmpty ? 'Place' : name,
                                      subtitle: loc.isEmpty ? 'Attraction' : loc,
                                      onRemove: () => _removePlace(id),
                                      onTap: () {
                                        Navigator.pushNamed(context, '/placeDetails', arguments: {'placeId': id});
                                      },
                                    );
                                  }).toList(),
                                );
                              },
                            );
                          },
                        ),
                      ],
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
