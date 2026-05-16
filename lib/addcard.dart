import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class AddCardScreen extends StatefulWidget {
  const AddCardScreen({super.key});

  @override
  State<AddCardScreen> createState() => _AddCardScreenState();
}

class _AddCardScreenState extends State<AddCardScreen> {
  final _formKey = GlobalKey<FormState>();

  final _cardNumber = TextEditingController();
  final _name = TextEditingController();
  final _expiry = TextEditingController();
  final _cvv = TextEditingController();

  final DatabaseReference _db = FirebaseDatabase.instance.ref();

  bool _saving = false;

  String _digits(String s) => s.replaceAll(RegExp(r'[^0-9]'), '');

  @override
  void dispose() {
    _cardNumber.dispose();
    _name.dispose();
    _expiry.dispose();
    _cvv.dispose();
    super.dispose();
  }

  Future<void> _saveCard() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        throw Exception('No logged-in user found');
      }

      final uid = user.uid;
      final cardNumber = _digits(_cardNumber.text);

      if (cardNumber.length < 4) {
        throw Exception('Card number is too short');
      }

      final last4 = cardNumber.substring(cardNumber.length - 4);

      final brand = cardNumber.startsWith('4')
          ? 'Visa'
          : cardNumber.startsWith('5')
          ? 'MasterCard'
          : 'Card';

      final ref = _db.child('users/$uid/paymentCards/cards').push();

      await ref.set({
        'brand': brand,
        'last4': last4,
        'cardNumber': cardNumber,
        'name': _name.text.trim(),
        'expiry': _expiry.text.trim(),
        'createdAt': ServerValue.timestamp,
      });

      await _db.child('users/$uid/paymentCards').update({
        'selected': ref.key,
      });

      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save card: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  InputDecoration _dec(String label, IconData icon) {
    return InputDecoration(
      prefixIcon: Icon(icon),
      labelText: label,
      filled: true,
      fillColor: Colors.white.withAlpha(200),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
    );
  }

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
            color: const Color(0xFF6B4A3A).withAlpha(120),
          ),
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
                        icon: const Icon(Icons.arrow_back_ios_new),
                      ),
                      const Expanded(
                        child: Center(
                          child: Text(
                            'Add Card',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: Form(
                      key: _formKey,
                      child: ListView(
                        children: [
                          TextFormField(
                            controller: _cardNumber,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(19),
                            ],
                            decoration: _dec('Card Number', Icons.credit_card),
                            validator: (v) {
                              final s = _digits((v ?? '').trim());

                              if (s.isEmpty) {
                                return 'Enter card number';
                              }

                              if (s.length < 12 || s.length > 19) {
                                return 'Card number must be 12-19 digits';
                              }

                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _name,
                            decoration: _dec('Card Holder Name', Icons.person),
                            validator: (v) {
                              if ((v ?? '').trim().isEmpty) {
                                return 'Enter card holder name';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _expiry,
                            keyboardType: TextInputType.number,
                            decoration: _dec('Expiry MM/YY', Icons.date_range),
                            validator: (v) {
                              if ((v ?? '').trim().isEmpty) {
                                return 'Enter expiry date';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _cvv,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(4),
                            ],
                            decoration: _dec('CVV', Icons.lock),
                            validator: (v) {
                              if ((v ?? '').trim().length < 3) {
                                return 'Enter valid CVV';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 30),
                          SizedBox(
                            height: 50,
                            child: ElevatedButton(
                              onPressed: _saving ? null : _saveCard,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: Colors.black,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: _saving
                                  ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                ),
                              )
                                  : const Text(
                                'Save Card',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
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
