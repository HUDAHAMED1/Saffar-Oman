import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';

class TouristEditProfile extends StatefulWidget {
  const TouristEditProfile({super.key});
  
  @override
  State<TouristEditProfile> createState() => _TouristEditProfileState();
}

class _TouristEditProfileState extends State<TouristEditProfile> {
  final _formKey = GlobalKey<FormState>();
  final _fullName = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();

  bool _loading = true;
  bool _saving = false;
  bool _uploading = false;

  String _photoUrl = '';

  final DatabaseReference _db = FirebaseDatabase.instance.ref();
  final FirebaseStorage _storage = FirebaseStorage.instance;

  User? get _user => FirebaseAuth.instance.currentUser;

  String _s(dynamic v) => (v ?? '').toString();

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final user = _user;
    if (user == null) {
      if (mounted) Navigator.pop(context);
      return;
    }

    try {
      _email.text = user.email ?? '';

      final snapshot = await _db.child('users/${user.uid}').get();

      if (snapshot.exists && snapshot.value != null) {
        final data = Map<String, dynamic>.from(
          snapshot.value as Map<Object?, Object?>,
        );

        // يدعم الحالتين: name أو fullName
        _fullName.text = _s(data['name']).isNotEmpty
            ? _s(data['name'])
            : _s(data['fullName']);

        String phoneValue = _s(data['phone']);

        // لو كان مخزن +968xxxxxxxx نخلي المعروض فقط 8 أرقام
        if (phoneValue.startsWith('+968')) {
          phoneValue = phoneValue.replaceFirst('+968', '');
        }

        _phone.text = phoneValue;
        _photoUrl = _s(data['photoUrl']);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load profile: $e')),
      );
    }

    if (mounted) {
      setState(() => _loading = false);
    }
  }

  Future<void> _pickAndUploadPhoto() async {
    final user = _user;
    if (user == null) return;

    try {
      final res = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
        withData: true,
      );

      if (res == null || res.files.isEmpty) return;

      final file = res.files.first;
      final bytes = file.bytes;
      if (bytes == null) return;

      setState(() => _uploading = true);

      final ext = (file.extension ?? 'jpg').toLowerCase();
      final path =
          'users/${user.uid}/profile_${DateTime.now().millisecondsSinceEpoch}.$ext';

      final ref = _storage.ref().child(path);

      String contentType = 'image/jpeg';
      if (ext == 'png') {
        contentType = 'image/png';
      } else if (ext == 'webp') {
        contentType = 'image/webp';
      } else if (ext == 'jpg' || ext == 'jpeg') {
        contentType = 'image/jpeg';
      }

      await ref.putData(
        bytes,
        SettableMetadata(contentType: contentType),
      );

      final url = await ref.getDownloadURL();

      await _db.child('users/${user.uid}').update({
        'photoUrl': url,
      });

      if (!mounted) return;
      setState(() {
        _photoUrl = url;
        _uploading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile photo updated')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _uploading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to upload photo: $e')),
      );
    }
  }

  bool _isValidEmail(String value) {
    return RegExp(r'^[\w\.-]+@([\w-]+\.)+[A-Za-z]{2,}$').hasMatch(value);
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    final user = _user;
    if (user == null) return;

    setState(() => _saving = true);

    try {
      final newName = _fullName.text.trim();
      final newPhone = _phone.text.trim();
      final newEmail = _email.text.trim();

      final currentEmail = user.email?.trim() ?? '';

      // تحديث الإيميل في FirebaseAuth إذا تغيّر
      if (newEmail.isNotEmpty && newEmail != currentEmail) {
        await user.updateEmail(newEmail);
        await user.reload();
      }

      await _db.child('users/${user.uid}').update({
        'name': newName,
        'fullName': newName, // للتماشي مع أي شاشة قديمة
        'phone': '+968$newPhone',
        'email': newEmail,
        'photoUrl': _photoUrl,
      });

      if (!mounted) return;

      setState(() => _saving = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully')),
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      setState(() => _saving = false);

      String msg = 'Failed to update profile';

      if (e.code == 'requires-recent-login') {
        msg =
        'For security, please log out and log in again before changing your email.';
      } else if (e.code == 'email-already-in-use') {
        msg = 'This email is already in use.';
      } else if (e.code == 'invalid-email') {
        msg = 'Invalid email format.';
      } else if (e.message != null) {
        msg = e.message!;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg)),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() => _saving = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update profile: $e')),
      );
    }
  }

  @override
  void dispose() {
    _fullName.dispose();
    _phone.dispose();
    _email.dispose();
    super.dispose();
  }

  Widget _label(BuildContext context, String t) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          t,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  InputDecoration _dec(BuildContext context, IconData icon, String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.55),
        fontSize: 13,
      ),
      prefixIcon: Icon(
        icon,
        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.65),
      ),
      filled: true,
      fillColor: Theme.of(context).colorScheme.surface.withOpacity(0.92),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    );
  }

  Widget _profileCircle(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        CircleAvatar(
          radius: 50,
          backgroundColor:
          Theme.of(context).colorScheme.surface.withOpacity(0.95),
          backgroundImage:
          _photoUrl.isNotEmpty ? NetworkImage(_photoUrl) : null,
          child: _photoUrl.isEmpty
              ? Icon(
            Icons.person,
            size: 54,
            color: Theme.of(context).colorScheme.onSurface,
          )
              : null,
        ),
        Positioned(
          bottom: -2,
          right: -2,
          child: GestureDetector(
            onTap: _uploading ? null : _pickAndUploadPhoto,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.black12),
              ),
              child: _uploading
                  ? const Padding(
                padding: EdgeInsets.all(8),
                child: CircularProgressIndicator(strokeWidth: 2),
              )
                  : Icon(
                Icons.camera_alt,
                size: 18,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('images/background.jpeg', fit: BoxFit.cover),
          Container(
            color: const Color(0xFF6B4A3A).withOpacity(0.72),
          ),
          SafeArea(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(18, 10, 18, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(
                          Icons.arrow_back_ios_new,
                          color: onSurface,
                        ),
                      ),
                      Expanded(
                        child: Center(
                          child: Text(
                            'Edit Profile',
                            style: TextStyle(
                              color: onSurface,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Center(child: _profileCircle(context)),
                  const SizedBox(height: 26),
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        _label(context, 'Full Name'),
                        TextFormField(
                          controller: _fullName,
                          style: TextStyle(
                            color: onSurface,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                          decoration:
                          _dec(context, Icons.person_outline, 'Enter full name'),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Enter full name';
                            }
                            if (v.trim().length < 3) {
                              return 'Name is too short';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),
                        _label(context, 'Phone Number'),
                        TextFormField(
                          controller: _phone,
                          keyboardType: TextInputType.phone,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(8),
                          ],
                          style: TextStyle(
                            color: onSurface,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                          decoration: _dec(
                            context,
                            Icons.phone_outlined,
                            '8 digits',
                          ).copyWith(
                            prefixText: '+968 ',
                            prefixStyle: TextStyle(
                              color: onSurface,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Enter phone number';
                            }
                            if (v.trim().length != 8) {
                              return 'Phone number must be 8 digits';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),
                        _label(context, 'Email Address'),
                        TextFormField(
                          controller: _email,
                          keyboardType: TextInputType.emailAddress,
                          style: TextStyle(
                            color: onSurface,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                          decoration:
                          _dec(context, Icons.mail_outline, 'Enter email'),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Enter email';
                            }
                            if (!_isValidEmail(v.trim())) {
                              return 'Invalid email';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  Center(
                    child: GestureDetector(
                      onTap: () => Navigator.pushNamed(context, '/settings'),
                      child: Text(
                        'Appearance',
                        style: TextStyle(
                          color: onSurface,
                          fontSize: 14,
                          decoration: TextDecoration.underline,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  Center(
                    child: SizedBox(
                      width: 240,
                      height: 46,
                      child: ElevatedButton(
                        onPressed: _saving ? null : _saveChanges,
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                          Theme.of(context).colorScheme.surface,
                          foregroundColor: onSurface,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
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
                            : const Text('Save Changes'),
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
