import 'package:flutter/material.dart';

class BookingConfirmation extends StatelessWidget {
  const BookingConfirmation({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF6B4A3A),
      body: SafeArea(
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
                        'Confirmation',
                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
              const SizedBox(height: 70),
              Container(
                width: 190,
                height: 190,
                decoration: const BoxDecoration(color: Colors.black, shape: BoxShape.circle),
                child: const Center(
                  child: Icon(Icons.check, color: Color(0xFF6B4A3A), size: 120),
                ),
              ),
              const SizedBox(height: 26),
              const Text(
                'Booking Confirmed !',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 10),
              Text(
                'Your Payment was successful.',
                style: TextStyle(color: Colors.white.withAlpha(180), fontSize: 12),
              ),
              const Spacer(),
              SizedBox(
                width: 240,
                height: 44,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamedAndRemoveUntil(context, '/explore', (route) => false);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white.withAlpha(120),
                    foregroundColor: Colors.black,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('Go To Home'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
