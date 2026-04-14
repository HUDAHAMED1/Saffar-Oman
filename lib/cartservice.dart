import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class CartService {
  static final DatabaseReference _db = FirebaseDatabase.instance.ref();

  static String _uid() {
    final u = FirebaseAuth.instance.currentUser;
    if (u == null) throw Exception('Not logged in');
    return u.uid;
  }

  static Future<void> addTourToCart({
    required String title,
    required String date,
    required double priceOmr,
    required String image,
    String? region,
  }) async {
    final uid = _uid();
    final key = _db.child('users/$uid/cart/tours').push().key!;
    await _db.child('users/$uid/cart/tours/$key').set({
      'title': title,
      'date': date,
      'price': priceOmr,
      'image': image,
      'region': region ?? '',
      'type': 'tour',
      'createdAt': ServerValue.timestamp,
    });
  }

  static Future<void> addCarToCart({
    required String carName,
    required String date,
    required double priceOmr,
    required String image,
  }) async {
    final uid = _uid();
    final key = _db.child('users/$uid/cart/cars').push().key!;
    await _db.child('users/$uid/cart/cars/$key').set({
      'carName': carName,
      'date': date,
      'price': priceOmr,
      'image': image,
      'type': 'car',
      'createdAt': ServerValue.timestamp,
    });
  }

  static Future<void> removeTour(String key) async {
    final uid = _uid();
    await _db.child('users/$uid/cart/tours/$key').remove();
  }

  static Future<void> removeCar(String key) async {
    final uid = _uid();
    await _db.child('users/$uid/cart/cars/$key').remove();
  }

  static DatabaseReference cartRef() {
    final uid = _uid();
    return _db.child('users/$uid/cart');
  }
}
