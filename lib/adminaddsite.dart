import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';

class AdminAddSiteScreen extends StatefulWidget {
  const AdminAddSiteScreen({super.key});

  @override
  State<AdminAddSiteScreen> createState() => _AdminAddSiteScreenState();
}

class _AdminAddSiteScreenState extends State<AdminAddSiteScreen> {
  final _name = TextEditingController();
  final _desc = TextEditingController();
  final _location = TextEditingController();

  final DatabaseReference _db = FirebaseDatabase.instance.ref();
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();

  File? _picked;
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _desc.dispose();
    _location.dispose();
    super.dispose();
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

  Future<void> _pickPhoto() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (image == null) return;

      setState(() {
        _picked = File(image.path);
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to pick image: $e')),
      );
    }
  }

  Future<String> _upload(String placeId, File file) async {
    final fileName = file.path.split('/').last;
    final ref = _storage.ref().child('places/$placeId/$fileName');

    await ref.putFile(file);
    return await ref.getDownloadURL();
  }

  Future<void> _save() async {
    final siteName = _name.text.trim();
    final description = _desc.text.trim();
    final location = _location.text.trim();

    if (siteName.isEmpty || description.isEmpty || location.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields.')),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      final key = _db.child('places').push().key!;
      String photoUrl = '';

      if (_picked != null) {
        photoUrl = await _upload(key, _picked!);
      }

      await _db.child('places/$key').set({
        'name': siteName,
        'nameLower': siteName.toLowerCase(),
        'description': description,
        'location': location,
        'photoUrl': photoUrl,
        'createdAt': ServerValue.timestamp,
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tourist site added successfully.')),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save site: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  InputDecoration _dec() {
    return InputDecoration(
      filled: true,
      fillColor: Colors.white.withAlpha(120),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
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
                        icon: const Icon(
                          Icons.arrow_back_ios_new,
                          color: Colors.black,
                        ),
                      ),
                      const Expanded(
                        child: Center(
                          child: Text(
                            'Add New Tourist Site',
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
                  const SizedBox(height: 14),
                  Expanded(
                    child: ListView(
                      children: [
                        const Text(
                          'Site Name',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _name,
                          decoration: _dec(),
                        ),
                        const SizedBox(height: 18),
                        const Text(
                          'Description',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _desc,
                          maxLines: 5,
                          decoration: _dec(),
                        ),
                        const SizedBox(height: 18),
                        const Text(
                          'Location',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _location,
                          decoration: _dec(),
                        ),
                        const SizedBox(height: 18),
                        const Text(
                          'Photos',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 10),
                        GestureDetector(
                          onTap: _pickPhoto,
                          child: Container(
                            height: 110,
                            decoration: BoxDecoration(
                              color: Colors.white.withAlpha(90),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: _picked == null
                                ? const Center(
                              child: Icon(
                                Icons.add_photo_alternate,
                                size: 70,
                                color: Colors.black,
                              ),
                            )
                                : ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.file(
                                _picked!,
                                fit: BoxFit.cover,
                                width: double.infinity,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 26),
                        Center(
                          child: SizedBox(
                            width: 240,
                            height: 44,
                            child: ElevatedButton(
                              onPressed: _saving ? null : _save,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white.withAlpha(230),
                                foregroundColor: Colors.black,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
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
                                  : const Text('Save Site'),
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
