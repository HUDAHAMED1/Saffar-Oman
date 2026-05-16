import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class GuidesScreen extends StatefulWidget {
  const GuidesScreen({super.key});
  @override
  State<GuidesScreen> createState() => _GuidesScreenState();
}

class _GuidesScreenState extends State<GuidesScreen> {
  final DatabaseReference _db = FirebaseDatabase.instance.ref();
  final TextEditingController _search = TextEditingController();

  Query _q = FirebaseDatabase.instance.ref().child('guides').orderByChild('createdAt');

  User? get _user => FirebaseAuth.instance.currentUser;

  DatabaseReference? get _favGuidesRef {
    final uid = _user?.uid;
    if (uid == null) return null;
    return _db.child('users/$uid/favourites/guides');
  }

  DatabaseReference? get _cartRef {
    final uid = _user?.uid;
    if (uid == null) return null;
    return _db.child('users/$uid/cart');
  }

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
      setState(() => _q = _db.child('guides').orderByChild('createdAt'));
      return;
    }
    setState(() {
      _q = _db.child('guides').orderByChild('nameLower').startAt(s).endAt('$s\uf8ff');
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

  Future<void> _toggleFav(String guideId, bool isFav) async {
    final ref = _favGuidesRef;
    if (ref == null) return;
    if (isFav) {
      await ref.child(guideId).remove();
    } else {
      await ref.child(guideId).set(true);
    }
  }

  Future<void> _addGuideToCart(Map<String, dynamic> g) async {
    final ref = _cartRef;
    if (ref == null) return;

    final id = _s(g['id']);
    final name = _s(g['name']);
    final langs = _s(g['languages']);
    final photoUrl = _s(g['photoUrl']);

    final key = ref.child('guide').push().key!;
    await ref.child('guide/$key').set({
      'guideId': id,
      'name': name,
      'languages': langs,
      'photoUrl': photoUrl,
      'createdAt': ServerValue.timestamp,
    });
  }

  Widget _bg() {
    return Container(color: const Color(0xFF6B4F3A));
  }

  Widget _searchBar() {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: const Color(0xFFBFA892),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: _search,
        decoration: const InputDecoration(
          prefixIcon: Icon(Icons.search),
          hintText: 'Search by name',
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _avatar(Map<String, dynamic> g) {
    final photoUrl = _s(g['photoUrl']);
    if (photoUrl.isNotEmpty) {
      return CircleAvatar(radius: 26, backgroundImage: NetworkImage(photoUrl));
    }
    final asset = _s(g['avatarAsset']);
    if (asset.isNotEmpty) {
      return CircleAvatar(radius: 26, backgroundImage: AssetImage(asset));
    }
    return const CircleAvatar(radius: 26, child: Icon(Icons.person));
  }

  Widget _card(Map<String, dynamic> g, bool isFav) {
    final name = _s(g['name']);
    final langs = _s(g['languages']);
    final id = _s(g['id']);

    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFBFA892),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          _avatar(g),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                Text(langs, style: const TextStyle(fontSize: 12, color: Colors.black54)),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _addGuideToCart(g),
            icon: const Icon(Icons.shopping_basket_outlined),
            color: Colors.black54,
          ),
          IconButton(
            onPressed: () => _toggleFav(id, isFav),
            icon: Icon(isFav ? Icons.favorite : Icons.favorite_border),
            color: Colors.black54,
          ),
          const Icon(Icons.chevron_right, color: Colors.black54),
        ],
      ),
    );
  }

  Widget _empty() {
    return const Center(
      child: Text('No guides found', style: TextStyle(color: Colors.white70)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final favRef = _favGuidesRef;

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
                            'Tour Guides',
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
                      stream: _q.onValue,
                      builder: (context, guideSnap) {
                        final guides = _toList(guideSnap.data?.snapshot.value);
                        if (guides.isEmpty) return _empty();

                        if (favRef == null) {
                          return ListView.builder(
                            itemCount: guides.length,
                            itemBuilder: (context, i) => _card(guides[i], false),
                          );
                        }

                        return StreamBuilder<DatabaseEvent>(
                          stream: favRef.onValue,
                          builder: (context, favSnap) {
                            final fv = favSnap.data?.snapshot.value;
                            final favMap = fv is Map ? Map<String, dynamic>.from(fv) : <String, dynamic>{};

                            return ListView.builder(
                              itemCount: guides.length,
                              itemBuilder: (context, i) {
                                final g = guides[i];
                                final id = _s(g['id']);
                                final isFav = favMap.containsKey(id);
                                return _card(g, isFav);
                              },
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
