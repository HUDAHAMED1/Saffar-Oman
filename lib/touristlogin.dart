import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

typedef SignInFn = Future<UserCredential> Function(String email, String password);
typedef ReadUserDataFn = Future<Map<String, dynamic>?> Function(String uid);
typedef SignOutFn = Future<void> Function();

class TouristLoginScreen extends StatefulWidget {
  final SignInFn? signIn;
  final ReadUserDataFn? readUserData;
  final SignOutFn? signOut;

  const TouristLoginScreen({
    super.key,
    this.signIn,
    this.readUserData,
    this.signOut,
  });

  @override
  State<TouristLoginScreen> createState() => _TouristLoginScreenState();
}

class _TouristLoginScreenState extends State<TouristLoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _loading = false;
  String? _error;

  Future<UserCredential> _defaultSignIn(String email, String password) {
    return FirebaseAuth.instance.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<Map<String, dynamic>?> _defaultReadUserData(String uid) async {
    final snap = await FirebaseDatabase.instance.ref('users/$uid').get();

    if (!snap.exists || snap.value == null) return null;

    return Map<String, dynamic>.from(
      snap.value as Map<Object?, Object?>,
    );
  }

  Future<void> _defaultSignOut() {
    return FirebaseAuth.instance.signOut();
  }

  Future<void> _login() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final signInFn = widget.signIn ?? _defaultSignIn;
      final readUserDataFn = widget.readUserData ?? _defaultReadUserData;
      final signOutFn = widget.signOut ?? _defaultSignOut;

      final cred = await signInFn(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      final uid = cred.user?.uid;
      if (uid == null) {
        setState(() => _error = 'Login failed: user ID is missing.');
        return;
      }

      final data = await readUserDataFn(uid);

      if (data == null) {
        setState(() => _error = 'User data not found in database.');
        await signOutFn();
        return;
      }

      final role = (data['role'] ?? '').toString().toLowerCase();
      final status =
      (data['status'] ?? 'approved').toString().toLowerCase();

      if (!mounted) return;

      String routeName;

      if (role == 'admin') {
        routeName = '/adminDashboard';
      } else if (role == 'tourist') {
        routeName = '/explore';
      } else if (role == 'guide') {
        if (status != 'approved') {
          setState(() {
            _error =
            'Your guide account is pending approval. Please try again later.';
          });
          await signOutFn();
          return;
        }
        routeName = '/guideHome';
      } else {
        setState(() => _error = 'User role is invalid or missing.');
        await signOutFn();
        return;
      }

      Navigator.pushNamedAndRemoveUntil(
        context,
        routeName,
            (route) => false,
      );
    } on FirebaseAuthException catch (e) {
      setState(() => _error = e.message ?? 'Login failed');
    } catch (e) {
      setState(() => _error = 'Unexpected error: $e');
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ✅ الحقول بعد التعديل (label فوق)
  Widget _field({
    required String label,
    required TextEditingController controller,
    required Key fieldKey,
    bool obscure = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          key: fieldKey,
          controller: controller,
          obscureText: obscure,
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 14,
          ),
          decoration: InputDecoration(
            hintText: label,
            hintStyle: const TextStyle(color: Colors.black45),
            filled: true,
            fillColor: Colors.white.withOpacity(0.92),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
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
          // 🔥 الخلفية القديمة
          Positioned.fill(
            child: Image.asset(
              'images/background.jpeg',
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(
            child: Container(
              color: const Color(0xFF6B4A3A).withOpacity(0.60),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [

                  // 🔙 زر الرجوع
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                    ),
                  ),

                  const SizedBox(height: 20),

                  const Center(
                    child: Text(
                      'SAFFAR OMAN',
                      style: TextStyle(
                        color: Color(0xFF3F2B22),
                        fontSize: 22,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),

                  const SizedBox(height: 60),

                  const Text(
                    'welcome back',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white, fontSize: 26),
                  ),

                  const SizedBox(height: 6),

                  const Text(
                    'login to continue your journey',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70),
                  ),

                  const SizedBox(height: 40),

                  _field(
                    label: 'Email',
                    controller: _emailController,
                    fieldKey: const Key('emailField'),
                  ),

                  const SizedBox(height: 16),

                  _field(
                    label: 'Password',
                    controller: _passwordController,
                    obscure: true,
                    fieldKey: const Key('passwordField'),
                  ),

                  const SizedBox(height: 10),

                  // 🔗 فورجت باسورد
                  Center(
                    child: TextButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/forgotPassword');
                      },
                      child: const Text(
                        'Forget Password',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),

                  if (_error != null)
                    Text(
                      _error!,
                      key: const Key('errorText'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red),
                    ),

                  const SizedBox(height: 12),

                  // 🔘 زر اللوجن
                  ElevatedButton(
                    key: const Key('loginButton'),
                    onPressed: _loading ? null : _login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFB4572F),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: _loading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Login'),
                  ),

                  const SizedBox(height: 20),

                  // 🔗 ريجستر
                  GestureDetector(
                    onTap: () {
                      Navigator.pushNamed(context, '/touristRegister');
                    },
                    child: const Center(
                      child: Text(
                        "Don’t have an account? Register",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}