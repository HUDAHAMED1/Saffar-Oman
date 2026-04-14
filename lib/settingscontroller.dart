import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class SettingsController extends ChangeNotifier {
  final DatabaseReference _db = FirebaseDatabase.instance.ref();

  String _languageCode = 'en';
  bool _darkMode = false;

  bool _inApp = true;
  bool _email = false;
  bool _sms = true;

  String? _loadedUid;

  String get languageCode => _languageCode;
  bool get darkMode => _darkMode;
  bool get inApp => _inApp;
  bool get email => _email;
  bool get sms => _sms;

  void applyLocal({
    required String languageCode,
    required bool darkMode,
    required bool inApp,
    required bool email,
    required bool sms,
  }) {
    _languageCode = languageCode;
    _darkMode = darkMode;
    _inApp = inApp;
    _email = email;
    _sms = sms;
    notifyListeners();
  }

  Future<void> loadFromDb() async {
    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        resetLocalToDefaults();
        return;
      }

      final uid = user.uid;
      final snap = await _db.child('users/$uid/settings').get();

      if (!snap.exists || snap.value == null) {
        _languageCode = 'en';
        _darkMode = false;
        _inApp = true;
        _email = false;
        _sms = true;
        _loadedUid = uid;
        notifyListeners();
        return;
      }

      final data = Map<String, dynamic>.from(
        snap.value as Map<Object?, Object?>,
      );

      final savedLanguage = (data['languageCode'] ?? 'en').toString().trim();
      _languageCode = (savedLanguage == 'ar') ? 'ar' : 'en';
      _darkMode = (data['darkMode'] ?? false) == true;

      final notifRaw = data['notifications'];
      final notif = notifRaw is Map
          ? Map<String, dynamic>.from(notifRaw as Map<Object?, Object?>)
          : <String, dynamic>{};

      _inApp = (notif['inApp'] ?? true) == true;
      _email = (notif['email'] ?? false) == true;
      _sms = (notif['sms'] ?? true) == true;

      _loadedUid = uid;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading settings: $e');
      resetLocalToDefaults();
    }
  }

  Future<void> saveToDb({
    required String languageCode,
    required bool darkMode,
    required bool inApp,
    required bool email,
    required bool sms,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final safeLanguage = languageCode == 'ar' ? 'ar' : 'en';

      await _db.child('users/${user.uid}/settings').set({
        'languageCode': safeLanguage,
        'darkMode': darkMode,
        'notifications': {
          'inApp': inApp,
          'email': email,
          'sms': sms,
        },
      });

      applyLocal(
        languageCode: safeLanguage,
        darkMode: darkMode,
        inApp: inApp,
        email: email,
        sms: sms,
      );

      _loadedUid = user.uid;
    } catch (e) {
      debugPrint('Error saving settings: $e');
    }
  }

  void resetLocalToDefaults() {
    _languageCode = 'en';
    _darkMode = false;
    _inApp = true;
    _email = false;
    _sms = true;
    _loadedUid = null;
    notifyListeners();
  }

  Future<void> handleLogoutReset() async {
    resetLocalToDefaults();
  }
}