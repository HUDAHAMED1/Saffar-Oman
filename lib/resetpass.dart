import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _pass = TextEditingController();
  final TextEditingController _confirm = TextEditingController();

  bool _loading = false;
  String? _error;

  double strength = 0.0;
  String strengthLabel = "Weak";

  String _email = '';
  String _sessionId = '';

  @override
  void dispose() {
    _pass.dispose();
    _confirm.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;

    if (args is Map) {
      _email = (args['email'] ?? '').toString();
      _sessionId = (args['sessionId'] ?? '').toString();
    }
  }

  void _checkStrength(String v) {
    double s = 0;

    if (v.length >= 8) {
      s += 0.4;
    }
    if (RegExp(r'[A-Z]').hasMatch(v)) {
      s += 0.2;
    }
    if (RegExp(r'[a-z]').hasMatch(v)) {
      s += 0.2;
    }
    if (RegExp(r'[0-9]').hasMatch(v)) {
      s += 0.2;
    }

    setState(() {
      strength = s;
      if (s < 0.4) {
        strengthLabel = "Weak";
      } else if (s < 0.7) {
        strengthLabel = "Medium";
      } else {
        strengthLabel = "Strong";
      }
    });
  }

  Future<void> _savePassword() async {
    final formState = _formKey.currentState;
    if (formState == null) return;

    if (!formState.validate()) return;

    if (_sessionId.trim().isEmpty) {
      setState(() {
        _error = "Missing session. Please restart the reset flow.";
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final callable =
      FirebaseFunctions.instance.httpsCallable('resetPasswordWithSession');

      await callable.call({
        'sessionId': _sessionId.trim(),
        'newPassword': _pass.text.trim(),
      });

      if (!mounted) return;

      Navigator.pushNamedAndRemoveUntil(
        context,
        '/passwordSaved',
            (route) => false,
      );
    } on FirebaseFunctionsException catch (e) {
      setState(() {
        _error = e.message ?? "Failed to reset password.";
      });
    } catch (_) {
      setState(() {
        _error = "Failed to reset password.";
      });
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset("images/background.jpeg", fit: BoxFit.cover),
          ),
          Positioned.fill(
            child: Container(color: Colors.brown.withValues(alpha: 0.5)),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      "Create a new, secure password for your account.",
                      style: TextStyle(fontSize: 18, color: Colors.white),
                    ),
                    if (_email.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        _email,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white70,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),

                    TextFormField(
                      controller: _pass,
                      obscureText: true,
                      onChanged: _checkStrength,
                      decoration: InputDecoration(
                        hintText: "Enter new password",
                        filled: true,
                        fillColor: Colors.white,
                        suffixIcon: const Icon(Icons.visibility_off),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return "Password required";
                        if (v.length < 8) return "Must be at least 8 characters";
                        if (!RegExp(r'[A-Za-z]').hasMatch(v)) return "Must contain letters";
                        if (!RegExp(r'[0-9]').hasMatch(v)) return "Must contain numbers";
                        return null;
                      },
                    ),

                    const SizedBox(height: 6),

                    SizedBox(
                      height: 5,
                      child: LinearProgressIndicator(
                        value: strength,
                        color: Colors.orange,
                        backgroundColor: Colors.grey[300],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Password Strength: $strengthLabel",
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white70,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: 20),

                    TextFormField(
                      controller: _confirm,
                      obscureText: true,
                      decoration: InputDecoration(
                        hintText: "Confirm new password",
                        filled: true,
                        fillColor: Colors.white,
                        suffixIcon: const Icon(Icons.visibility_off),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return "Confirm password required";
                        if (v != _pass.text) return "Passwords do not match";
                        return null;
                      },
                    ),

                    const SizedBox(height: 14),

                    if (_error != null)
                      Center(
                        child: Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.redAccent,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),

                    const SizedBox(height: 16),

                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _savePassword,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFBF6B2F),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: _loading
                            ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                            : const Text(
                          "Save",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}