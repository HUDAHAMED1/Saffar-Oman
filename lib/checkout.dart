import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';


class Checkout extends StatefulWidget {
  const Checkout({super.key});

  @override
  State<Checkout> createState() => _CheckoutState();
}

class _CheckoutState extends State<Checkout> {
  final DatabaseReference _db = FirebaseDatabase.instance.ref();

  User? get _user => FirebaseAuth.instance.currentUser;

  DatabaseReference? get _cartRef {
    final uid = _user?.uid;
    if (uid == null) return null;
    return _db.child('users/$uid/cart');
  }

  DatabaseReference? get _payRef {
    final uid = _user?.uid;
    if (uid == null) return null;
    return _db.child('users/$uid/paymentCards');
  }

  String _s(dynamic v) => (v ?? '').toString();

  double _toDouble(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v.toDouble();
    if (v is double) return v;
    return double.tryParse(v.toString()) ?? 0;
  }

  String _formatMoney(double value) {
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }
    return value.toStringAsFixed(2);
  }

  int _countDaysInclusive(String from, String to) {
    try {
      if (from.isEmpty || to.isEmpty) return 1;
      final start = DateTime.parse(from);
      final end = DateTime.parse(to);
      final diff = end.difference(start).inDays + 1;
      return diff <= 0 ? 1 : diff;
    } catch (_) {
      return 1;
    }
  }

  double _extractPlaceDailyPrice(
      Map<String, dynamic> cart,
      Map<String, dynamic> place,
      ) {
    final candidates = [
      cart['tourPricePerNight'],
      cart['tourPrice'],
      cart['tourPricePerDay'],
      cart['pricePerNight'],
      cart['priceOmr'],
      cart['pricePerDay'],
      place['pricePerDay'],
      place['pricePerNight'],
      place['price'],
      place['priceOmr'],
      place['tourPrice'],
      place['tourPricePerNight'],
    ];

    for (final c in candidates) {
      final v = _toDouble(c);
      if (v > 0) return v;
    }
    return 0;
  }

  double _extractCarDailyPrice(Map<String, dynamic> cart) {
    final candidates = [
      cart['carPricePerDay'],
      cart['carPrice'],
      cart['pricePerDay'],
      cart['carRentPrice'],
    ];

    for (final c in candidates) {
      final v = _toDouble(c);
      if (v > 0) return v;
    }
    return 0;
  }

  Widget _bg() {
    return Stack(
      children: [
        Positioned.fill(
          child: Image.asset('images/background.jpeg', fit: BoxFit.cover),
        ),
        Positioned.fill(
          child: Container(
            color: const Color(0xFF6B4A3A).withAlpha(140),
          ),
        ),
      ],
    );
  }

  Widget _line(String l, String r) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 72,
          child: Text(
            l,
            style: const TextStyle(color: Colors.black, fontSize: 13),
          ),
        ),
        Expanded(
          child: Text(
            r,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _infoCard({
    required String date,
    required String time,
    required String location,
    required String car,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(140),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _line('Date:', date),
          const SizedBox(height: 10),
          _line('Time:', time),
          const SizedBox(height: 10),
          _line('Location:', location),
          const SizedBox(height: 10),
          _line('Car:', car),
        ],
      ),
    );
  }

  Widget _priceCard({
    required int days,
    required double tourTotal,
    required double carTotal,
    required double total,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(140),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _line('Tour Price:', '($days days) ${_formatMoney(tourTotal)} OMR'),
          const SizedBox(height: 12),
          _line('Car Rent Price:', '($days days) ${_formatMoney(carTotal)} OMR'),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total:',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '${_formatMoney(total)} OMR',
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _paymentCard({
    required String brand,
    required String last4,
  }) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(160),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 22,
            decoration: BoxDecoration(
              color: Colors.black.withAlpha(20),
              borderRadius: BorderRadius.circular(6),
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.credit_card,
              size: 16,
              color: Colors.black54,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '$brand ending $last4',
              style: const TextStyle(
                color: Colors.black,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.black, width: 1.5),
            ),
            child: Center(
              child: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cartRef = _cartRef;
    final payRef = _payRef;

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
                            'Checkout',
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
                  const SizedBox(height: 10),
                  if (cartRef == null || payRef == null)
                    const Expanded(
                      child: Center(
                        child: Text('Not logged in'),
                      ),
                    )
                  else
                    Expanded(
                      child: StreamBuilder<DatabaseEvent>(
                        stream: cartRef.onValue,
                        builder: (context, cartSnap) {
                          final cartVal = cartSnap.data?.snapshot.value;
                          final cartMap = cartVal is Map
                              ? Map<String, dynamic>.from(cartVal)
                              : <String, dynamic>{};

                          final placeId = _s(cartMap['placeId']);
                          final title = _s(cartMap['tourTitle']);
                          final dateFrom = _s(cartMap['dateFrom']);
                          final dateTo = _s(cartMap['dateTo']);
                          final timeFrom = _s(cartMap['timeFrom']);
                          final timeTo = _s(cartMap['timeTo']);
                          final location = _s(cartMap['pickupLocation']);
                          final carName = _s(cartMap['carTitle']);

                          final dateText = (dateFrom.isNotEmpty && dateTo.isNotEmpty)
                              ? '$dateFrom - $dateTo'
                              : '-';

                          final timeText = (timeFrom.isNotEmpty && timeTo.isNotEmpty)
                              ? '$timeFrom - $timeTo'
                              : '-';

                          final days = _countDaysInclusive(dateFrom, dateTo);

                          return FutureBuilder<DataSnapshot>(
                            future: placeId.isEmpty
                                ? null
                                : _db.child('places/$placeId').get(),
                            builder: (context, placeSnap) {
                              final placeVal = placeSnap.data?.value;
                              final placeMap = placeVal is Map
                                  ? Map<String, dynamic>.from(placeVal)
                                  : <String, dynamic>{};

                              final placeDailyPrice =
                              _extractPlaceDailyPrice(cartMap, placeMap);
                              final carDailyPrice =
                              _extractCarDailyPrice(cartMap);

                              final tourTotal = placeDailyPrice * days;
                              final carTotal = carDailyPrice * days;
                              final total = tourTotal + carTotal;

                              return ListView(
                                children: [
                                  Text(
                                    title.isEmpty ? 'Trip' : title,
                                    style: const TextStyle(
                                      color: Colors.black,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  _infoCard(
                                    date: dateText,
                                    time: timeText,
                                    location: location.isEmpty ? '-' : location,
                                    car: carName.isEmpty ? '-' : carName,
                                  ),
                                  const SizedBox(height: 18),
                                  const Text(
                                    'Price Summary',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  _priceCard(
                                    days: days,
                                    tourTotal: tourTotal,
                                    carTotal: carTotal,
                                    total: total,
                                  ),
                                  const SizedBox(height: 18),
                                  const Text(
                                    'Payment Method',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  StreamBuilder<DatabaseEvent>(
                                    stream: payRef.onValue,
                                    builder: (context, paySnap) {
                                      final payVal = paySnap.data?.snapshot.value;
                                      final payMap = payVal is Map
                                          ? Map<String, dynamic>.from(payVal)
                                          : <String, dynamic>{};

                                      final selected = _s(payMap['selected']);
                                      final cards = payMap['cards'];

                                      Map<String, dynamic> card = {};
                                      bool hasCards = false;

                                      if (cards is Map && cards.isNotEmpty) {
                                        hasCards = true;

                                        if (selected.isNotEmpty &&
                                            cards[selected] is Map) {
                                          card = Map<String, dynamic>.from(
                                            cards[selected] as Map,
                                          );
                                        } else {
                                          final firstKey = cards.keys.first.toString();
                                          if (cards[firstKey] is Map) {
                                            card = Map<String, dynamic>.from(
                                              cards[firstKey] as Map,
                                            );
                                          }
                                        }
                                      }

                                      if (!hasCards || card.isEmpty) {
                                        return Center(
                                          child: TextButton(
                                            onPressed: () => Navigator.pushNamed(
                                              context,
                                              '/addcard',
                                            ),
                                            child: const Text(
                                              'Add New Card',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 13,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                        );
                                      }

                                      final brand = _s(card['brand']).isEmpty
                                          ? 'Visa'
                                          : _s(card['brand']);
                                      final last4 = _s(card['last4']).isEmpty
                                          ? '----'
                                          : _s(card['last4']);

                                      return Column(
                                        children: [
                                          _paymentCard(
                                            brand: brand,
                                            last4: last4,
                                          ),
                                          const SizedBox(height: 10),
                                          Center(
                                            child: TextButton(
                                              onPressed: () => Navigator.pushNamed(
                                                context,
                                                '/addcard',
                                              ),
                                              child: const Text(
                                                'Add New Card',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 10),
                                          Center(
                                            child: SizedBox(
                                              width: 240,
                                              height: 44,
                                              child: ElevatedButton(
                                                onPressed: () {
                                                  Navigator.pushNamed(
                                                    context,
                                                    '/paymentverification',
                                                  );
                                                },
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor:
                                                  Colors.white.withAlpha(160),
                                                  foregroundColor: Colors.black,
                                                  elevation: 0,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                    BorderRadius.circular(12),
                                                  ),
                                                ),
                                                child: const Text(
                                                  'Confirm Booking',
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      );
                                    },
                                  ),
                                  const SizedBox(height: 10),
                                ],
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
