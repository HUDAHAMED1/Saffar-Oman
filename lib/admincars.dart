import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';

class AdminCarsScreen extends StatefulWidget {
  const AdminCarsScreen({super.key});

  @override
  State<AdminCarsScreen> createState() => _AdminCarsScreenState();
}

class _AdminCarsScreenState extends State<AdminCarsScreen> {
  final DatabaseReference _carsRef = FirebaseDatabase.instance.ref('cars');
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();

  Future<String> _uploadCarImage(String carId, File file) async {
    final fileName = file.path.split('/').last;
    final ref = _storage.ref().child('cars/$carId/$fileName');
    await ref.putFile(file);
    return await ref.getDownloadURL();
  }

  Future<void> _showCarDialog({
    String? carId,
    Map<String, dynamic>? carData,
  }) async {
    final nameController = TextEditingController(
      text: carData?['name']?.toString() ?? '',
    );
    final descController = TextEditingController(
      text: carData?['description']?.toString() ?? '',
    );
    final seatsController = TextEditingController(
      text: carData?['seats']?.toString() ?? '',
    );
    final bagsController = TextEditingController(
      text: carData?['bags']?.toString() ?? '',
    );
    final priceController = TextEditingController(
      text: carData?['pricePerDay']?.toString() ?? '',
    );

    File? pickedImage;
    String existingImage = carData?['imageUrl']?.toString() ?? '';

    await showDialog(
      context: context,
      builder: (dialogContext) {
        bool saving = false;

        return StatefulBuilder(
          builder: (dialogContext, setLocalState) {
            Future<void> pickImage() async {
              try {
                final XFile? image = await _picker.pickImage(
                  source: ImageSource.gallery,
                  imageQuality: 85,
                );

                if (image == null) return;

                setLocalState(() {
                  pickedImage = File(image.path);
                });
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to pick image: $e')),
                );
              }
            }

            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              title: Text(carId == null ? 'Add Car' : 'Update Car'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: pickImage,
                      child: Container(
                        height: 150,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: pickedImage != null
                            ? ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.file(
                            pickedImage!,
                            fit: BoxFit.cover,
                            width: double.infinity,
                          ),
                        )
                            : existingImage.isNotEmpty
                            ? ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.network(
                            existingImage,
                            fit: BoxFit.cover,
                            width: double.infinity,
                          ),
                        )
                            : const Center(
                          child: Icon(
                            Icons.add_photo_alternate,
                            size: 50,
                            color: Colors.black54,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Car Name',
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: descController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: seatsController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Seats',
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: bagsController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Bags',
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: priceController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Price Per Day (OMR)',
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: saving ? null : () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: saving
                      ? null
                      : () async {
                    final name = nameController.text.trim();
                    final description = descController.text.trim();
                    final seats =
                        int.tryParse(seatsController.text.trim()) ?? 0;
                    final bags =
                        int.tryParse(bagsController.text.trim()) ?? 0;
                    final price =
                        double.tryParse(priceController.text.trim()) ?? 0;

                    if (name.isEmpty ||
                        description.isEmpty ||
                        seats <= 0 ||
                        bags < 0 ||
                        price <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Please complete all fields correctly.',
                          ),
                        ),
                      );
                      return;
                    }

                    setLocalState(() {
                      saving = true;
                    });

                    try {
                      final id = carId ?? _carsRef.push().key!;

                      debugPrint('Car ID: $id');

                      String imageUrl = existingImage;

                      if (pickedImage != null) {
                        debugPrint('Uploading image...');
                        imageUrl = await _uploadCarImage(id, pickedImage!);
                        debugPrint('Image uploaded: $imageUrl');
                      }

                      debugPrint('Saving car data...');

                      await _carsRef.child(id).set({
                        'name': name,
                        'nameLower': name.toLowerCase(),
                        'description': description,
                        'seats': seats,
                        'bags': bags,
                        'pricePerDay': price,
                        'imageUrl': imageUrl,
                        'createdAt': ServerValue.timestamp,
                      });

                      debugPrint('Car saved successfully.');

                      if (!mounted) return;

                      Navigator.pop(dialogContext);

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            carId == null
                                ? 'Car added successfully.'
                                : 'Car updated successfully.',
                          ),
                        ),
                      );
                    } catch (e) {
                      debugPrint('Failed to save car: $e');

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Failed to save car: $e'),
                        ),
                      );

                      setLocalState(() {
                        saving = false;
                      });
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  child: saving
                      ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                      : Text(carId == null ? 'Add' : 'Update'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _deleteCar(String carId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Car'),
        content: const Text('Are you sure you want to delete this car?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _carsRef.child(carId).remove();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Car deleted successfully.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Delete failed: $e')),
      );
    }
  }

  Widget _carTile(String carId, Map<String, dynamic> car) {
    final name = (car['name'] ?? '').toString();
    final description = (car['description'] ?? '').toString();
    final seats = (car['seats'] ?? 0).toString();
    final bags = (car['bags'] ?? 0).toString();
    final price = (car['pricePerDay'] ?? 0).toString();
    final imageUrl = (car['imageUrl'] ?? '').toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      decoration: BoxDecoration(
        color: const Color(0xFFD8C7B7),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (imageUrl.isNotEmpty)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(18),
              ),
              child: Image.network(
                imageUrl,
                width: double.infinity,
                height: 180,
                fit: BoxFit.cover,
              ),
            )
          else
            Container(
              height: 180,
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Colors.black12,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(18),
                ),
              ),
              child: const Icon(Icons.directions_car, size: 60),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: const TextStyle(fontSize: 15, color: Colors.black87),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(Icons.person, size: 18),
                    const SizedBox(width: 4),
                    Text(seats),
                    const SizedBox(width: 18),
                    const Icon(Icons.luggage, size: 18),
                    const SizedBox(width: 4),
                    Text('$bags Bags'),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Text(
                      '$price OMR /day',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => _showCarDialog(
                        carId: carId,
                        carData: car,
                      ),
                      icon: const Icon(Icons.edit_outlined),
                    ),
                    IconButton(
                      onPressed: () => _deleteCar(carId),
                      icon: const Icon(
                        Icons.delete_outline,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF7A5B43),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
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
                        'Manage Cars',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 20,
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => _showCarDialog(),
                    icon: const Icon(
                      Icons.add_circle_outline,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Expanded(
                child: StreamBuilder<DatabaseEvent>(
                  stream: _carsRef.onValue,
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          'Error loading cars: ${snapshot.error}',
                          style: const TextStyle(color: Colors.white),
                          textAlign: TextAlign.center,
                        ),
                      );
                    }

                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }

                    if (!snapshot.hasData ||
                        snapshot.data!.snapshot.value == null) {
                      return const Center(
                        child: Text(
                          'No cars added yet',
                          style: TextStyle(color: Colors.white),
                        ),
                      );
                    }

                    final raw = snapshot.data!.snapshot.value as Map;
                    final cars = raw.entries.map((e) {
                      return MapEntry<String, Map<String, dynamic>>(
                        e.key.toString(),
                        Map<String, dynamic>.from(e.value as Map),
                      );
                    }).toList();

                    cars.sort((a, b) {
                      final aName = (a.value['name'] ?? '').toString();
                      final bName = (b.value['name'] ?? '').toString();
                      return aName.compareTo(bName);
                    });

                    return ListView.builder(
                      itemCount: cars.length,
                      itemBuilder: (context, index) {
                        return _carTile(cars[index].key, cars[index].value);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}