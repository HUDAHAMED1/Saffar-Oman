// file: lib/cart.dart
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'cartservice.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}
class _CartScreenState extends State<CartScreen> {
  late final DatabaseReference _cartRef;

  @override
  void initState() {
    super.initState();
    _cartRef = CartService.cartRef();
  }

  double _toDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }

  Widget _itemCard({
    required String image,
    required String title,
    required String date,
    required double price,
    required VoidCallback onDelete,
  }) {
    return Container(
      height: 80,
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(140),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(10),
              bottomLeft: Radius.circular(10),
            ),
            child: Image.asset(
              image,
              width: 90,
              height: 80,
              fit: BoxFit.cover,
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.black, fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Date  $date',
                    style: TextStyle(color: Colors.black.withAlpha(170), fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${price.toStringAsFixed(0)} OMR',
                    style: const TextStyle(color: Colors.black, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            onPressed: onDelete,
            icon: const Icon(Icons.delete, color: Colors.red),
          ),
          const SizedBox(width: 6),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: const Color(0xFF6B4A3A),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
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
                          'Cart',
                          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: StreamBuilder<DatabaseEvent>(
                    stream: _cartRef.onValue,
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final data = snapshot.data!.snapshot.value;
                      final root = data is Map ? Map<String, dynamic>.from(data) : <String, dynamic>{};

                      final toursNode = root['tours'];
                      final carsNode = root['cars'];

                      final tours = <Map<String, dynamic>>[];
                      final cars = <Map<String, dynamic>>[];

                      if (toursNode is Map) {
                        final m = Map<String, dynamic>.from(toursNode);
                        for (final e in m.entries) {
                          final v = e.value;
                          if (v is Map) {
                            final item = Map<String, dynamic>.from(v);
                            item['_key'] = e.key;
                            tours.add(item);
                          }
                        }
                      }

                      if (carsNode is Map) {
                        final m = Map<String, dynamic>.from(carsNode);
                        for (final e in m.entries) {
                          final v = e.value;
                          if (v is Map) {
                            final item = Map<String, dynamic>.from(v);
                            item['_key'] = e.key;
                            cars.add(item);
                          }
                        }
                      }

                      double total = 0.0;
                      for (final t in tours) {
                        total += _toDouble(t['price']);
                      }
                      for (final c in cars) {
                        total += _toDouble(c['price']);
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Your Tours:', style: TextStyle(color: Colors.white, fontSize: 14)),
                          const SizedBox(height: 12),
                          if (tours.isEmpty)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: Text(
                                'No tours added yet',
                                style: TextStyle(color: Colors.white.withAlpha(180), fontSize: 12),
                              ),
                            )
                          else
                            ...tours.map((t) {
                              final key = (t['_key'] ?? '').toString();
                              final title = (t['title'] ?? '').toString();
                              final date = (t['date'] ?? '').toString();
                              final image = (t['image'] ?? 'images/matrah.jpeg').toString();
                              final price = _toDouble(t['price']);
                              return _itemCard(
                                image: image,
                                title: title,
                                date: date,
                                price: price,
                                onDelete: () => CartService.removeTour(key),
                              );
                            }),
                          const SizedBox(height: 8),
                          const Text('Your Car Rental:', style: TextStyle(color: Colors.white, fontSize: 14)),
                          const SizedBox(height: 12),
                          if (cars.isEmpty)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: Text(
                                'No cars added yet',
                                style: TextStyle(color: Colors.white.withAlpha(180), fontSize: 12),
                              ),
                            )
                          else
                            ...cars.map((c) {
                              final key = (c['_key'] ?? '').toString();
                              final title = (c['carName'] ?? '').toString();
                              final date = (c['date'] ?? '').toString();
                              final image = (c['image'] ?? 'images/car.png').toString();
                              final price = _toDouble(c['price']);
                              return _itemCard(
                                image: image,
                                title: title,
                                date: date,
                                price: price,
                                onDelete: () => CartService.removeCar(key),
                              );
                            }),
                          const Spacer(),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Text(
                              'Total:  ${total.toStringAsFixed(0)} OMR',
                              style: const TextStyle(color: Colors.white, fontSize: 14),
                            ),
                          ),
                          Center(
                            child: SizedBox(
                              width: 230,
                              height: 44,
                              child: ElevatedButton(
                                onPressed: total <= 0
                                    ? null
                                    : () {
                                  Navigator.pushNamed(context, '/checkout');
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white.withAlpha(220),
                                  foregroundColor: Colors.black,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                child: const Text('Proceed to Checkout'),
                              ),
                            ),
                          ),
                        ],
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
