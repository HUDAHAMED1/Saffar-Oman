import 'package:flutter/material.dart';
import 'settingscontroller.dart';

class SettingsScreen extends StatefulWidget {
  final SettingsController controller;

  const SettingsScreen({super.key, required this.controller});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _loading = true;

  late String _languageCode;
  late bool _darkMode;
  late bool _inApp;
  late bool _email;
  late bool _sms;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await widget.controller.loadFromDb();

    _languageCode = widget.controller.languageCode;
    _darkMode = widget.controller.darkMode;
    _inApp = widget.controller.inApp;
    _email = widget.controller.email;
    _sms = widget.controller.sms;

    if (mounted) {
      setState(() => _loading = false);
    }
  }

  Widget _sectionTitle(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurface,
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _card(BuildContext context, {required Widget child}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF1F1F1F)
            : Colors.white.withOpacity(0.88),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.08)
              : Colors.black.withOpacity(0.06),
        ),
      ),
      child: child,
    );
  }

  Widget _langButton({
    required BuildContext context,
    required String text,
    required String code,
  }) {
    final selected = _languageCode == code;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _languageCode = code),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: 46,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected
                ? (isDark ? Colors.white : Colors.black)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(
            text,
            style: TextStyle(
              color: selected
                  ? (isDark ? Colors.black : Colors.white)
                  : Theme.of(context).colorScheme.onSurface,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _switchTile({
    required BuildContext context,
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF2A2A2A)
            : Colors.white.withOpacity(0.96),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Switch(
            value: value,
            onChanged: (v) => setState(() => onChanged(v)),
            activeColor: isDark ? Colors.white : Colors.black,
          ),
        ],
      ),
    );
  }

  Future<void> _saveSettings() async {
    await widget.controller.saveToDb(
      languageCode: _languageCode,
      darkMode: _darkMode,
      inApp: _inApp,
      email: _email,
      sms: _sms,
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Settings updated successfully'),
      ),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF121212) : const Color(0xFF6B4A3A);

    return Scaffold(
      body: Container(
        color: bgColor,
        child: SafeArea(
          child: _loading
              ? Center(
            child: CircularProgressIndicator(
              color: isDark ? Colors.white : Colors.white,
            ),
          )
              : Padding(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(
                        Icons.arrow_back_ios_new,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    Expanded(
                      child: Center(
                        child: Text(
                          'Settings',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
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

                _sectionTitle(context, 'Language'),
                _card(
                  context,
                  child: Row(
                    children: [
                      _langButton(
                        context: context,
                        text: 'English',
                        code: 'en',
                      ),
                      const SizedBox(width: 10),
                      _langButton(
                        context: context,
                        text: 'العربية',
                        code: 'ar',
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                _sectionTitle(context, 'Theme'),
                _card(
                  context,
                  child: _switchTile(
                    context: context,
                    title: 'Dark Mode',
                    value: _darkMode,
                    onChanged: (v) => _darkMode = v,
                  ),
                ),

                const SizedBox(height: 20),

                _sectionTitle(context, 'Notification Preferences'),
                _card(
                  context,
                  child: Column(
                    children: [
                      _switchTile(
                        context: context,
                        title: 'In-App Notifications',
                        value: _inApp,
                        onChanged: (v) => _inApp = v,
                      ),
                      _switchTile(
                        context: context,
                        title: 'Email Notifications',
                        value: _email,
                        onChanged: (v) => _email = v,
                      ),
                      _switchTile(
                        context: context,
                        title: 'SMS Notifications',
                        value: _sms,
                        onChanged: (v) => _sms = v,
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/feedback');
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor:
                      Theme.of(context).colorScheme.onSurface,
                      side: BorderSide(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.45),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text('Feedback'),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _saveSettings,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Update',
                      style: TextStyle(
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
    );
  }
}
