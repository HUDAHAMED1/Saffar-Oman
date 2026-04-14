import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class BookingFormScreen extends StatefulWidget {
  const BookingFormScreen({super.key});

  @override
  State<BookingFormScreen> createState() => _BookingFormScreenState();
}

class _BookingFormScreenState extends State<BookingFormScreen> {
  final DatabaseReference _db = FirebaseDatabase.instance.ref();

  final TextEditingController _dateRange = TextEditingController();
  final TextEditingController _pickup = TextEditingController();
  final TextEditingController _car = TextEditingController();
  final TextEditingController _notes = TextEditingController();

  String _dateFrom = '';
  String _dateTo = '';

  String _startTime = '';
  String _endTime = '';

  String _carId = '';
  String _carName = '';
  String _carPrice = '';
  String _carImageUrl = '';
  String _carDescription = '';
  String _carSeats = '';
  String _carBags = '';

  bool _saving = false;
  bool _loadingLocation = false;

  User? get _user => FirebaseAuth.instance.currentUser;

  DatabaseReference? get _cartRef {
    final uid = _user?.uid;
    if (uid == null) return null;
    return _db.child('users/$uid/cart');
  }

  String _s(dynamic v) => (v ?? '').toString();

  final List<String> _timeOptions = const [
    '6:00 AM',
    '7:00 AM',
    '8:00 AM',
    '9:00 AM',
    '10:00 AM',
    '11:00 AM',
    '12:00 PM',
    '1:00 PM',
    '2:00 PM',
    '3:00 PM',
    '4:00 PM',
    '5:00 PM',
    '6:00 PM',
    '7:00 PM',
    '8:00 PM',
  ];

  Widget _bg() {
    return Stack(
      children: [
        Positioned.fill(
          child: Image.asset('images/background.jpeg', fit: BoxFit.cover),
        ),
        Positioned.fill(
          child: Container(color: Colors.brown.withOpacity(0.6)),
        ),
      ],
    );
  }

  String _fmtDate(DateTime d) {
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '${d.year}-$m-$day';
  }

  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    final res = await showDateRangePicker(
      context: context,
      firstDate: now,
      lastDate: DateTime(now.year + 2),
      initialDateRange: DateTimeRange(
        start: now,
        end: now.add(const Duration(days: 1)),
      ),
    );
    if (res == null) return;

    final from = _fmtDate(res.start);
    final to = _fmtDate(res.end);

    setState(() {
      _dateFrom = from;
      _dateTo = to;
      _dateRange.text = '$from  -  $to';
    });
  }

  Future<void> _chooseCar() async {
    try {
      final res = await Navigator.pushNamed(context, '/carsSelect');

      if (res != null && res is Map) {
        setState(() {
          _carId = _s(res['carId']);
          _carName = _s(res['name']);
          _carPrice = _s(res['pricePerDay']);
          _carImageUrl = _s(res['imageUrl']);
          _carDescription = _s(res['description']);
          _carSeats = _s(res['seats']);
          _carBags = _s(res['bags']);
          _car.text = _carName;
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to open cars page: $e')),
      );
    }
  }

  Future<void> _useCurrentLocation() async {
    if (_loadingLocation) return;

    setState(() {
      _loadingLocation = true;
    });

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enable location services first'),
          ),
        );
        setState(() => _loadingLocation = false);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location permission was denied'),
          ),
        );
        setState(() => _loadingLocation = false);
        return;
      }

      if (permission == LocationPermission.deniedForever) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Location permission is permanently denied. Please enable it from settings.',
            ),
          ),
        );
        setState(() => _loadingLocation = false);
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      String locationText =
          '${position.latitude.toStringAsFixed(5)}, ${position.longitude.toStringAsFixed(5)}';

      try {
        final placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );

        if (placemarks.isNotEmpty) {
          final p = placemarks.first;
          final parts = <String>[
            if ((p.name ?? '').trim().isNotEmpty) p.name!.trim(),
            if ((p.street ?? '').trim().isNotEmpty) p.street!.trim(),
            if ((p.locality ?? '').trim().isNotEmpty) p.locality!.trim(),
            if ((p.administrativeArea ?? '').trim().isNotEmpty)
              p.administrativeArea!.trim(),
            if ((p.country ?? '').trim().isNotEmpty) p.country!.trim(),
          ];

          final cleaned = parts.toSet().where((e) => e.isNotEmpty).toList();
          if (cleaned.isNotEmpty) {
            locationText = cleaned.join(', ');
          }
        }
      } catch (_) {}

      if (!mounted) return;

      setState(() {
        _pickup.text = locationText;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to get current location: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _loadingLocation = false;
        });
      }
    }
  }

  Future<void> _saveToCart(String placeId) async {
    if (_saving) return;

    final cartRef = _cartRef;
    if (cartRef == null) return;

    final placeSnap = await _db.child('places/$placeId').get();
    final pv = placeSnap.value;
    final p = pv is Map ? Map<String, dynamic>.from(pv) : <String, dynamic>{};

    final title = _s(p['name']);
    final photoUrl = _s(p['photoUrl']);
    final pickup = _pickup.text.trim();

    if (_dateFrom.isEmpty || _dateTo.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select date range')),
      );
      return;
    }

    if (_startTime.isEmpty || _endTime.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select start and end time')),
      );
      return;
    }

    final startIndex = _timeOptions.indexOf(_startTime);
    final endIndex = _timeOptions.indexOf(_endTime);

    if (startIndex == -1 || endIndex == -1 || endIndex <= startIndex) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('End time must be later than start time')),
      );
      return;
    }

    if (pickup.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter pickup location')),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      await cartRef.set({
        'placeId': placeId,
        'tourTitle': title,
        'dateFrom': _dateFrom,
        'dateTo': _dateTo,
        'timeFrom': _startTime,
        'timeTo': _endTime,
        'pickupLocation': pickup,
        'carId': _carId,
        'carTitle': _carName,
        'carPricePerDay': _carPrice,
        'carImageUrl': _carImageUrl,
        'carDescription': _carDescription,
        'carSeats': _carSeats,
        'carBags': _carBags,
        'notes': _notes.text.trim(),
        'photoUrl': photoUrl,
        'createdAt': ServerValue.timestamp,
      });

      if (!mounted) return;
      setState(() => _saving = false);

      Navigator.pushNamed(context, '/checkout');
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save booking: $e')),
      );
    }
  }

  Widget _field({
    required String label,
    required TextEditingController c,
    required IconData icon,
    VoidCallback? onTap,
    int maxLines = 1,
    bool readOnly = false,
    String hint = '',
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
        const SizedBox(height: 6),
        Container(
          height: maxLines == 1 ? 44 : 140,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.80),
            borderRadius: BorderRadius.circular(10),
          ),
          child: TextField(
            controller: c,
            readOnly: readOnly || onTap != null,
            maxLines: maxLines,
            onTap: onTap,
            decoration: InputDecoration(
              hintText: hint,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              suffixIcon: Icon(icon, color: Colors.black54),
            ),
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _timeDropdown({
    required String label,
    required String value,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
        const SizedBox(height: 6),
        Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.80),
            borderRadius: BorderRadius.circular(10),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value.isEmpty ? null : value,
              isExpanded: true,
              hint: const Text('Select time'),
              icon: const Icon(Icons.access_time, color: Colors.black54),
              items: _timeOptions.map((time) {
                return DropdownMenuItem<String>(
                  value: time,
                  child: Text(time),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _locationField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Pick Up Location',
          style: TextStyle(color: Colors.white, fontSize: 12),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.80),
            borderRadius: BorderRadius.circular(10),
          ),
          child: TextField(
            controller: _pickup,
            decoration: const InputDecoration(
              hintText: 'Enter Hotel name or Address',
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              suffixIcon: Icon(Icons.location_on, color: Colors.black54),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: _loadingLocation ? null : _useCurrentLocation,
            icon: _loadingLocation
                ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
                : const Icon(Icons.my_location, size: 18),
            label: Text(
              _loadingLocation ? 'Getting location...' : 'Use Current Location',
            ),
            style: TextButton.styleFrom(
              foregroundColor: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  @override
  void dispose() {
    _dateRange.dispose();
    _pickup.dispose();
    _car.dispose();
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    final placeId = (args is Map && args['placeId'] != null)
        ? args['placeId'].toString()
        : '';

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
                            'Booking form',
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
                  Expanded(
                    child: ListView(
                      children: [
                        _field(
                          label: 'Select Date',
                          c: _dateRange,
                          icon: Icons.calendar_month,
                          onTap: _pickDateRange,
                          hint: 'choose date for your tour',
                        ),
                        _timeDropdown(
                          label: 'Start Time',
                          value: _startTime,
                          onChanged: (value) {
                            setState(() {
                              _startTime = value ?? '';
                            });
                          },
                        ),
                        _timeDropdown(
                          label: 'End Time',
                          value: _endTime,
                          onChanged: (value) {
                            setState(() {
                              _endTime = value ?? '';
                            });
                          },
                        ),
                        _locationField(),
                        _field(
                          label: 'Choose car',
                          c: _car,
                          icon: Icons.directions_car,
                          onTap: _chooseCar,
                          hint: 'Any specific Car?',
                          readOnly: true,
                        ),
                        _field(
                          label: 'Additional Notes',
                          c: _notes,
                          icon: Icons.edit,
                          maxLines: 6,
                          hint: 'Special Request...',
                        ),
                        const SizedBox(height: 10),
                        Center(
                          child: SizedBox(
                            width: 240,
                            height: 44,
                            child: ElevatedButton(
                              onPressed: _saving
                                  ? null
                                  : () => _saveToCart(placeId),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white.withOpacity(0.35),
                                foregroundColor: Colors.black,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: _saving
                                  ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                                  : const Text('Proceed To checkout'),
                            ),
                          ),
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