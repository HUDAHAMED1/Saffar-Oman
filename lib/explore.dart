import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final DatabaseReference _db = FirebaseDatabase.instance.ref();
  final TextEditingController _search = TextEditingController();

  User? get _user => FirebaseAuth.instance.currentUser;

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(
      context,
      '/welcome',
          (route) => false,
    );
  }

  String _s(dynamic v) => (v ?? '').toString();

  Widget _bg() {
    return Stack(
      children: [
        Positioned.fill(
          child: Image.asset(
            'images/background.jpeg',
            fit: BoxFit.cover,
          ),
        ),
        Positioned.fill(
          child: Container(
            color: const Color(0xFF6B4A3A).withOpacity(0.68),
          ),
        ),
      ],
    );
  }

  Widget _actionIcon({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.92),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(
          icon,
          color: Colors.black87,
          size: 20,
        ),
      ),
    );
  }

  Widget _circleAvatar() {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/touristeditprofile'),
      child: StreamBuilder<DatabaseEvent>(
        stream: _user == null
            ? null
            : _db.child('users/${_user!.uid}/photoUrl').onValue,
        builder: (context, snap) {
          final url = _s(snap.data?.snapshot.value);
          if (url.isNotEmpty) {
            return CircleAvatar(
              radius: 20,
              backgroundImage: NetworkImage(url),
            );
          }
          return const CircleAvatar(
            radius: 20,
            backgroundImage: AssetImage('images/man.png'),
          );
        },
      ),
    );
  }

  Widget _searchBar() {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(18),
      ),
      child: TextField(
        controller: _search,
        style: const TextStyle(
          color: Colors.black87,
          fontSize: 14,
        ),
        decoration: const InputDecoration(
          prefixIcon: Icon(Icons.search, color: Colors.black54),
          hintText: 'Search for places or activities',
          hintStyle: TextStyle(
            color: Colors.black54,
            fontSize: 14,
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }

  Widget _categoryCard({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          children: [
            Container(
              height: 58,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.95),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Center(
                child: Icon(
                  icon,
                  color: Colors.black87,
                  size: 28,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _featuredCard(Map<String, dynamic> p) {
    final id = _s(p['id']);
    final name = _s(p['name']);
    final loc = _s(p['location']);
    final photoUrl = _s(p['photoUrl']);

    return GestureDetector(
      onTap: () => Navigator.pushNamed(
        context,
        '/placeDetails',
        arguments: {'placeId': id},
      ),
      child: Container(
        height: 240,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.94),
          borderRadius: BorderRadius.circular(22),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(22),
              ),
              child: photoUrl.isNotEmpty
                  ? Image.network(
                photoUrl,
                height: 140,
                width: double.infinity,
                fit: BoxFit.cover,
              )
                  : Container(
                height: 140,
                width: double.infinity,
                color: Colors.black12,
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name.isEmpty ? 'Place' : name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(
                                Icons.location_on_outlined,
                                size: 16,
                                color: Colors.black54,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  loc.isEmpty ? 'Oman' : loc,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Colors.black54,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () async {
                        final uid = _user?.uid;
                        if (uid == null) return;
                        await _db
                            .child('users/$uid/favourites/places/$id')
                            .set(true);
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Added to favourites'),
                          ),
                        );
                      },
                      icon: const Icon(
                        Icons.favorite_border,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _recommendedTile(Map<String, dynamic> p) {
    final id = _s(p['id']);
    final name = _s(p['name']);
    final loc = _s(p['location']);
    final photoUrl = _s(p['photoUrl']);

    return GestureDetector(
      onTap: () => Navigator.pushNamed(
        context,
        '/placeDetails',
        arguments: {'placeId': id},
      ),
      child: Container(
        height: 96,
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.92),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                bottomLeft: Radius.circular(18),
              ),
              child: photoUrl.isNotEmpty
                  ? Image.network(
                photoUrl,
                width: 96,
                height: 96,
                fit: BoxFit.cover,
              )
                  : Container(
                width: 96,
                height: 96,
                color: Colors.black12,
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      name.isEmpty ? 'Place' : name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      loc.isEmpty ? 'Oman' : loc,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            IconButton(
              onPressed: () async {
                final uid = _user?.uid;
                if (uid == null) return;
                await _db.child('users/$uid/favourites/places/$id').set(true);
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Added to favourites'),
                  ),
                );
              },
              icon: const Icon(
                Icons.favorite_border,
                color: Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<List<Map<String, dynamic>>> _fetchPlaces() async {
    final snap = await _db.child('places').get();

    if (!snap.exists || snap.value == null) return [];

    final raw = Map<String, dynamic>.from(
      snap.value as Map<Object?, Object?>,
    );

    final list = <Map<String, dynamic>>[];

    raw.forEach((key, value) {
      if (value is Map) {
        final p = Map<String, dynamic>.from(
          value as Map<Object?, Object?>,
        );
        p['id'] = key.toString();
        list.add(p);
      }
    });

    return list;
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          _bg(),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Discover Oman',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      _actionIcon(
                        icon: Icons.settings,
                        onTap: () => Navigator.pushNamed(context, '/settings'),
                      ),
                      const SizedBox(width: 8),
                      _actionIcon(
                        icon: Icons.shopping_cart_outlined,
                        onTap: () => Navigator.pushNamed(context, '/cart'),
                      ),
                      const SizedBox(width: 8),
                      _actionIcon(
                        icon: Icons.bookmark_border,
                        onTap: () => Navigator.pushNamed(context, '/favourites'),
                      ),
                      const SizedBox(width: 8),
                      _actionIcon(
                        icon: Icons.logout,
                        onTap: _logout,
                      ),
                      const SizedBox(width: 8),
                      _circleAvatar(),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _searchBar(),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      _categoryCard(
                        icon: Icons.history_edu_outlined,
                        label: 'History',
                        onTap: () => Navigator.pushNamed(context, '/history'),
                      ),
                      _categoryCard(
                        icon: Icons.place_outlined,
                        label: 'Places',
                        onTap: () => Navigator.pushNamed(context, '/places'),
                      ),
                      _categoryCard(
                        icon: Icons.support_agent,
                        label: 'Guides',
                        onTap: () => Navigator.pushNamed(context, '/guides'),
                      ),
                      _categoryCard(
                        icon: Icons.directions_car_outlined,
                        label: 'Cars',
                        onTap: () => Navigator.pushNamed(context, '/carsSelect'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Expanded(
                    child: FutureBuilder<List<Map<String, dynamic>>>(
                      future: _fetchPlaces(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(
                              color: Colors.white,
                            ),
                          );
                        }

                        final places = snapshot.data ?? [];

                        if (places.isEmpty) {
                          return const Center(
                            child: Text(
                              'No places available yet.',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                              ),
                            ),
                          );
                        }

                        final featured = places.first;
                        final recommended = places.length > 1
                            ? places.skip(1).take(6).toList()
                            : <Map<String, dynamic>>[];

                        return ListView(
                          padding: EdgeInsets.zero,
                          children: [
                            const Text(
                              'Featured Attractions',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 10),
                            _featuredCard(featured),
                            const SizedBox(height: 18),
                            const Text(
                              'Recommended for you',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 10),
                            ...recommended.map(_recommendedTile),
                            const SizedBox(height: 10),
                          ],
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