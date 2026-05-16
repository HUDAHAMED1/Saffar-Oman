import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;

class GuideRegistrationScreen extends StatefulWidget {
  const GuideRegistrationScreen({super.key});
  @override
  State<GuideRegistrationScreen> createState() =>
      _GuideRegistrationScreenState();
}

class _GuideRegistrationScreenState extends State<GuideRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _name = TextEditingController();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _phone = TextEditingController();
  final TextEditingController _pass = TextEditingController();
  final TextEditingController _confirmPass = TextEditingController();

  final ScrollController _scrollController = ScrollController();

  bool loading = false;
  String? error;

  File? _cvFile;
  File? _idFrontImage;
  File? _idBackImage;

  String? _cvUrl;
  String? _idFrontUrl;
  String? _idBackUrl;

  bool validEmail(String v) {
    return RegExp(r'^[\w\.-]+@([\w-]+\.)+[A-Za-z]{2,}$').hasMatch(v);
  }

  bool strongPass(String v) {
    return v.length >= 8 &&
        RegExp(r'[A-Za-z]').hasMatch(v) &&
        RegExp(r'\d').hasMatch(v);
  }

  bool _docsSelected() {
    return _cvFile != null && _idFrontImage != null && _idBackImage != null;
  }

  Future<File?> _pickFile({required List<String> allowedExtensions}) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: allowedExtensions,
      withData: false,
    );
    if (result == null || result.files.single.path == null) return null;
    return File(result.files.single.path!);
  }

  String _cleanNameForFile() {
    final n = _name.text.trim();
    if (n.isEmpty) return "user";
    return n.replaceAll(RegExp(r'\s+'), '_').toLowerCase();
  }

  Future<String> _uploadFile({
    required String uid,
    required File file,
    required String folder,
    required String prefix,
  }) async {
    final cleanName = _cleanNameForFile();
    final ts = DateTime.now().millisecondsSinceEpoch;
    final ext = p.extension(file.path).toLowerCase();
    final filename = "$prefix${cleanName}_$ts$ext";

    final ref = FirebaseStorage.instance
        .ref()
        .child("uploads")
        .child(uid)
        .child(folder)
        .child(filename);

    final snap = await ref.putFile(file);
    return await snap.ref.getDownloadURL();
  }

  Future<void> pickCV() async {
    if (_name.text.trim().isEmpty) {
      setState(() => error = "Please enter Full Name first.");
      return;
    }

    final file = await _pickFile(allowedExtensions: const ['pdf', 'doc', 'docx']);
    if (file == null) return;

    setState(() {
      _cvFile = file;
      error = null;
    });
  }

  Future<void> pickIdFront() async {
    if (_name.text.trim().isEmpty) {
      setState(() => error = "Please enter Full Name first.");
      return;
    }

    final file = await _pickFile(
      allowedExtensions: const ['jpg', 'jpeg', 'png', 'webp'],
    );
    if (file == null) return;

    setState(() {
      _idFrontImage = file;
      error = null;
    });
  }

  Future<void> pickIdBack() async {
    if (_name.text.trim().isEmpty) {
      setState(() => error = "Please enter Full Name first.");
      return;
    }

    final file = await _pickFile(
      allowedExtensions: const ['jpg', 'jpeg', 'png', 'webp'],
    );
    if (file == null) return;

    setState(() {
      _idBackImage = file;
      error = null;
    });
  }

  Future<void> showTopApprovalMessage() async {
    final overlay = Overlay.of(context);

    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (_) => Positioned(
        top: MediaQuery.of(context).padding.top + 12,
        left: 16,
        right: 16,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.info,
                  color: Colors.orange,
                  size: 26,
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    "Your registration request has been submitted.\nYou will receive a notification once your account is approved.",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                      height: 1.3,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => entry.remove(),
                  child: const Icon(
                    Icons.close,
                    size: 20,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    overlay.insert(entry);

    await Future.delayed(const Duration(seconds: 5));
    if (entry.mounted) entry.remove();
  }

  Future<void> registerGuide() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_docsSelected()) {
      setState(
            () => error = "Please select CV and National ID (front & back).",
      );
      return;
    }

    setState(() {
      loading = true;
      error = null;
    });

    try {
      debugPrint('Step 1: creating auth user');

      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _email.text.trim(),
        password: _pass.text.trim(),
      );

      final uid = cred.user!.uid;

      debugPrint('Step 2: uploading CV');
      final cvUrl = await _uploadFile(
        uid: uid,
        file: _cvFile!,
        folder: "cv",
        prefix: "cv_",
      );

      debugPrint('Step 3: uploading ID front');
      final idFrontUrl = await _uploadFile(
        uid: uid,
        file: _idFrontImage!,
        folder: "id_front",
        prefix: "id_front_",
      );

      debugPrint('Step 4: uploading ID back');
      final idBackUrl = await _uploadFile(
        uid: uid,
        file: _idBackImage!,
        folder: "id_back",
        prefix: "id_back_",
      );

      _cvUrl = cvUrl;
      _idFrontUrl = idFrontUrl;
      _idBackUrl = idBackUrl;

      debugPrint('Step 5: saving user data');
      await FirebaseDatabase.instance.ref("users/$uid").set({
        "name": _name.text.trim(),
        "email": _email.text.trim(),
        "phone": _phone.text.trim(),
        "role": "guide",
        "status": "pending",
        "reviewNote": null,
        "documents": {
          "cvUrl": _cvUrl,
          "idFrontUrl": _idFrontUrl,
          "idBackUrl": _idBackUrl,
        },
        "createdAt": DateTime.now().toIso8601String(),
      });

      debugPrint('Step 6: saving guide request');
      await FirebaseDatabase.instance.ref("guideRequests/$uid").set({
        "uid": uid,
        "name": _name.text.trim(),
        "email": _email.text.trim(),
        "phone": _phone.text.trim(),
        "status": "pending",
        "documents": {
          "cvUrl": _cvUrl,
          "idFrontUrl": _idFrontUrl,
          "idBackUrl": _idBackUrl,
        },
        "createdAt": DateTime.now().toIso8601String(),
      });

      if (!mounted) return;

      await showTopApprovalMessage();

      await FirebaseAuth.instance.signOut();

      if (!mounted) return;

      Navigator.pushNamedAndRemoveUntil(
        context,
        '/touristLogin',
            (route) => false,
      );
    } on FirebaseAuthException catch (e) {
      debugPrint('AUTH ERROR: ${e.code} - ${e.message}');
      setState(() => error = 'Auth error: ${e.code} - ${e.message}');
    } on FirebaseException catch (e) {
      debugPrint('FIREBASE ERROR: ${e.code} - ${e.message}');
      setState(() => error = 'Firebase error: ${e.code} - ${e.message}');
    } catch (e) {
      debugPrint('GENERAL ERROR: $e');
      setState(() => error = 'Registration failed: $e');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  bool get _busy => loading;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _pass.dispose();
    _confirmPass.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Widget _docLabel(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _docTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool selected,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.92),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.black54),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Colors.black54,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          if (selected)
            const Icon(Icons.check_circle, color: Colors.green)
          else
            const Icon(Icons.upload_file, color: Colors.black54),
        ],
      ),
    );
  }

  Widget field(
      TextEditingController c,
      String label,
      IconData icon,
      String? Function(String?) validator, {
        bool obscure = false,
        List<TextInputFormatter>? inputFormatters,
      }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          TextFormField(
            controller: c,
            obscureText: obscure,
            validator: validator,
            inputFormatters: inputFormatters,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              hintText: label,
              hintStyle: const TextStyle(color: Colors.black45),
              filled: true,
              fillColor: Colors.white.withOpacity(.92),
              prefixIcon: Icon(icon, color: Colors.black54),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String? _vName(String? v) {
    if (v == null || v.trim().isEmpty) {
      return "Full name is required";
    }

    final name = v.trim();

    if (name.length < 3) {
      return "Name must be at least 3 letters";
    }

    if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(name)) {
      return "Name must contain letters only";
    }

    return null;
  }

  String? _vEmail(String? v) =>
      v == null || !validEmail(v.trim()) ? "Invalid email" : null;

  String? _vPhone(String? v) =>
      v == null || v.length != 8 ? "Invalid phone" : null;

  String? _vPass(String? v) =>
      v == null || !strongPass(v) ? "Weak password" : null;

  String? _vConfirm(String? v) =>
      v != _pass.text ? "Password mismatch" : null;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset("images/background.jpeg", fit: BoxFit.cover),
          ),
          Positioned.fill(
            child: Container(
              color: Colors.brown.withOpacity(.55),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back, color: Colors.black),
                    ),
                  ),
                  const Text(
                    "Become A Guide",
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: Scrollbar(
                      controller: _scrollController,
                      thumbVisibility: true,
                      interactive: true,
                      child: SingleChildScrollView(
                        controller: _scrollController,
                        keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                        child: Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              field(
                                _name,
                                "Full Name",
                                Icons.person,
                                _vName,
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                    RegExp(r"[a-zA-Z\s]"),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              field(
                                _email,
                                "Email Address",
                                Icons.email,
                                _vEmail,
                              ),
                              const SizedBox(height: 12),
                              field(
                                _phone,
                                "Phone Number (8 digits)",
                                Icons.phone,
                                _vPhone,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                  LengthLimitingTextInputFormatter(8),
                                ],
                              ),
                              const SizedBox(height: 12),
                              field(
                                _pass,
                                "Password",
                                Icons.lock,
                                _vPass,
                                obscure: true,
                              ),
                              const SizedBox(height: 12),
                              field(
                                _confirmPass,
                                "Confirm Password",
                                Icons.lock,
                                _vConfirm,
                                obscure: true,
                              ),
                              const SizedBox(height: 18),
                              const Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  "Required Documents",
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),

                              _docLabel("CV/ Resume"),
                              const SizedBox(height: 6),
                              InkWell(
                                onTap: _busy ? null : pickCV,
                                borderRadius: BorderRadius.circular(10),
                                child: _docTile(
                                  title: "CV/ Resume",
                                  subtitle: _cvFile == null
                                      ? "Tap to select PDF,DOCX"
                                      : "Selected",
                                  icon: Icons.description_outlined,
                                  selected: _cvFile != null,
                                ),
                              ),
                              const SizedBox(height: 12),

                              _docLabel("National /Resident ID (Front)"),
                              const SizedBox(height: 6),
                              InkWell(
                                onTap: _busy ? null : pickIdFront,
                                borderRadius: BorderRadius.circular(10),
                                child: _docTile(
                                  title: "National /Resident ID",
                                  subtitle: _idFrontImage == null
                                      ? "Select front image"
                                      : "Selected",
                                  icon: Icons.badge_outlined,
                                  selected: _idFrontImage != null,
                                ),
                              ),
                              const SizedBox(height: 10),

                              _docLabel("National /Resident ID (Back)"),
                              const SizedBox(height: 6),
                              InkWell(
                                onTap: _busy ? null : pickIdBack,
                                borderRadius: BorderRadius.circular(10),
                                child: _docTile(
                                  title: "National /Resident ID",
                                  subtitle: _idBackImage == null
                                      ? "Select back image"
                                      : "Selected",
                                  icon: Icons.badge_outlined,
                                  selected: _idBackImage != null,
                                ),
                              ),
                              const SizedBox(height: 16),

                              SizedBox(
                                width: double.infinity,
                                height: 48,
                                child: ElevatedButton(
                                  onPressed: _busy ? null : registerGuide,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.orange[800],
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: _busy
                                      ? const CircularProgressIndicator(
                                    color: Colors.white,
                                  )
                                      : const Text(
                                    "Register",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),

                              if (error != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 12),
                                  child: Text(
                                    error!,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Colors.redAccent,
                                    ),
                                  ),
                                ),

                              const SizedBox(height: 80),
                            ],
                          ),
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
    );
  }
}
