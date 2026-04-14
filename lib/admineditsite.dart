import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';

class AdminEditSiteScreen extends StatefulWidget {
  const AdminEditSiteScreen({super.key});

  @override
  State<AdminEditSiteScreen> createState() => _AdminEditSiteScreenState();
}

class _AdminEditSiteScreenState extends State<AdminEditSiteScreen> {
  final _name = TextEditingController();
  final _desc = TextEditingController();
  final _location = TextEditingController();
  final _price = TextEditingController();

  final DatabaseReference _db = FirebaseDatabase.instance.ref();
  final FirebaseStorage _storage = FirebaseStorage.instance;

  File? _picked;
  String _photoUrl = '';
  String _id = '';
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _desc.dispose();
    _location.dispose();
    _price.dispose();
    super.dispose();
  }

  String _s(dynamic v) => (v ?? '').toString();

  Widget _bg() {
    return Stack(
      children: [
        Positioned.fill(
          child: Image.asset('images/background.jpeg', fit: BoxFit.cover),
        ),
        Positioned.fill(
          child: Container(color: const Color(0xFF6B4A3A).withAlpha(120)),
        ),
      ],
    );
  }

  Future<void> _pickPhoto() async {
    final res = await FilePicker.platform.pickFiles(type: FileType.image);
    if (res == null || res.files.isEmpty) return;
    final path = res.files.first.path;
    if (path == null) return;

    setState(() => _picked = File(path));
  }

  Future<String> _upload(String placeId, File file) async {
    final name = file.path.split('/').last;
    final ref = _storage.ref('places/$placeId/$name');
    await ref.putFile(file);
    return await ref.getDownloadURL();
  }

  Future<void> _save() async {
    final siteName = _name.text.trim();
    final description = _desc.text.trim();
    final location = _location.text.trim();
    final priceText = _price.text.trim();

    if (_id.isEmpty) return;

    if (siteName.isEmpty ||
        description.isEmpty ||
        location.isEmpty ||
        priceText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields.')),
      );
      return;
    }

    final pricePerDay = int.tryParse(priceText);
    if (pricePerDay == null || pricePerDay <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid daily price.')),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      String photoUrl = _photoUrl;
      if (_picked != null) {
        photoUrl = await _upload(_id, _picked!);
      }

      await _db.child('places/$_id').update({
        'name': siteName,
        'nameLower': siteName.toLowerCase(),
        'description': description,
        'location': location,
        'pricePerDay': pricePerDay,
        'photoUrl': photoUrl,
        'updatedAt': ServerValue.timestamp,
      });

      if (!mounted) return;
      setState(() => _saving = false);
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save site: $e')),
      );
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
    final args = ModalRoute.of(context)?.settings.arguments;

    if (args is Map && _id.isEmpty) {
      final m = Map<String, dynamic>.from(args);
      _id = _s(m['_id']);
      _name.text = _s(m['name']);
      _desc.text = _s(m['description']);
      _location.text = _s(m['location']);
      _photoUrl = _s(m['photoUrl']);
      _price.text = _s(m['pricePerDay']);
    }

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
                            'Edit Tourist Site',
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
                          style: TextStyle(color: Colors.white, fontSize: 13),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _name,
                          decoration: _dec(),
                        ),
                        const SizedBox(height: 18),
                        const Text(
                          'Description',
                          style: TextStyle(color: Colors.white, fontSize: 13),
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
                          style: TextStyle(color: Colors.white, fontSize: 13),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _location,
                          decoration: _dec(),
                        ),
                        const SizedBox(height: 18),
                        const Text(
                          'Price Per Day (OMR)',
                          style: TextStyle(color: Colors.white, fontSize: 13),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _price,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          decoration: _dec(),
                        ),
                        const SizedBox(height: 18),
                        const Text(
                          'Photos',
                          style: TextStyle(color: Colors.white, fontSize: 13),
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
                            child: _picked != null
                                ? ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.file(
                                _picked!,
                                fit: BoxFit.cover,
                                width: double.infinity,
                              ),
                            )
                                : (_photoUrl.isNotEmpty
                                ? ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.network(
                                _photoUrl,
                                fit: BoxFit.cover,
                                width: double.infinity,
                              ),
                            )
                                : const Center(
                              child: Icon(
                                Icons.add_photo_alternate,
                                size: 70,
                                color: Colors.black,
                              ),
                            )),
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