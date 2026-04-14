import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class AdminSendNotificationsScreen extends StatefulWidget {
  const AdminSendNotificationsScreen({super.key});

  @override
  State<AdminSendNotificationsScreen> createState() =>
      _AdminSendNotificationsScreenState();
}

class _AdminSendNotificationsScreenState
    extends State<AdminSendNotificationsScreen> {
  final DatabaseReference _usersRef = FirebaseDatabase.instance.ref('users');
  final DatabaseReference _notificationsRef =
  FirebaseDatabase.instance.ref('notifications');

  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _targetIdController = TextEditingController();

  String _searchText = '';
  String _selectedType = 'general';
  String? _selectedUserId;
  String? _selectedUserName;

  final List<Map<String, String>> _notificationTypes = const [
    {'value': 'general', 'label': 'General'},
    {'value': 'guide_approval', 'label': 'Guide Approval'},
    {'value': 'guide_rejection', 'label': 'Guide Rejection'},
    {'value': 'trip_accepted', 'label': 'Trip Accepted'},
    {'value': 'trip_rejected', 'label': 'Trip Rejected'},
    {'value': 'booking_update', 'label': 'Booking Update'},
  ];

  @override
  void dispose() {
    _searchController.dispose();
    _titleController.dispose();
    _messageController.dispose();
    _targetIdController.dispose();
    super.dispose();
  }

  Future<void> _sendNotification() async {
    final userId = _selectedUserId;
    final title = _titleController.text.trim();
    final message = _messageController.text.trim();
    final targetId = _targetIdController.text.trim();

    if (userId == null || userId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a user.')),
      );
      return;
    }

    if (title.isEmpty || message.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter title and message.')),
      );
      return;
    }

    try {
      final newRef = _notificationsRef.child(userId).push();

      await newRef.set({
        'title': title,
        'message': message,
        'type': _selectedType,
        'targetId': targetId,
        'read': false,
        'createdAt': ServerValue.timestamp,
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Notification sent successfully.')),
      );

      _titleController.clear();
      _messageController.clear();
      _targetIdController.clear();

      setState(() {
        _selectedType = 'general';
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send notification: $e')),
      );
    }
  }

  List<MapEntry<String, dynamic>> _filterUsers(Map raw) {
    final users = raw.entries.map((e) {
      return MapEntry<String, dynamic>(
        e.key.toString(),
        Map<String, dynamic>.from(e.value as Map),
      );
    }).toList();

    return users.where((entry) {
      final data = entry.value;
      final name = (data['name'] ?? '').toString().toLowerCase();
      final email = (data['email'] ?? '').toString().toLowerCase();
      final role = (data['role'] ?? '').toString().toLowerCase();

      return name.contains(_searchText) ||
          email.contains(_searchText) ||
          role.contains(_searchText);
    }).toList();
  }

  Widget _userTile(String uid, Map<String, dynamic> user) {
    final name = (user['name'] ?? 'Unknown').toString();
    final email = (user['email'] ?? '').toString();
    final role = (user['role'] ?? '').toString();

    final selected = _selectedUserId == uid;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedUserId = uid;
          _selectedUserName = name;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFE8D9CC) : const Color(0xFFD8C7B7),
          borderRadius: BorderRadius.circular(14),
          border: selected
              ? Border.all(color: Colors.black54, width: 1.3)
              : null,
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: Colors.brown.shade300,
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: const TextStyle(color: Colors.white, fontSize: 20),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (email.isNotEmpty)
                    Text(
                      email,
                      style: const TextStyle(color: Colors.black54),
                    ),
                  if (role.isNotEmpty)
                    Text(
                      role,
                      style: const TextStyle(color: Colors.black45),
                    ),
                ],
              ),
            ),
            if (selected) const Icon(Icons.check_circle, color: Colors.green),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bg = const Color(0xFF7A5B43);

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
                  ),
                  const Expanded(
                    child: Center(
                      child: Text(
                        'Send Notifications',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 20,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
              const SizedBox(height: 14),

              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFD8C7B7),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  children: [
                    TextField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Notification Title',
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _messageController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Message',
                      ),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: _selectedType,
                      decoration: const InputDecoration(
                        labelText: 'Notification Type',
                      ),
                      items: _notificationTypes.map((item) {
                        return DropdownMenuItem<String>(
                          value: item['value'],
                          child: Text(item['label']!),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _selectedType = value;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _targetIdController,
                      decoration: const InputDecoration(
                        labelText: 'Target ID (optional)',
                        hintText: 'Example: trip_123',
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_selectedUserName != null)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Selected user: $_selectedUserName',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: ElevatedButton(
                        onPressed: _sendNotification,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                        ),
                        child: const Text('Send Notification'),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              TextField(
                controller: _searchController,
                onChanged: (value) {
                  setState(() {
                    _searchText = value.trim().toLowerCase();
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Search user by name, email or role',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: const Color(0xFFE4D7CB),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              Expanded(
                child: StreamBuilder<DatabaseEvent>(
                  stream: _usersRef.onValue,
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          'Error loading users: ${snapshot.error}',
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
                          'No users found',
                          style: TextStyle(color: Colors.white),
                        ),
                      );
                    }

                    final raw = snapshot.data!.snapshot.value as Map;
                    final users = _filterUsers(raw);

                    if (users.isEmpty) {
                      return const Center(
                        child: Text(
                          'No users found',
                          style: TextStyle(color: Colors.white),
                        ),
                      );
                    }

                    return ListView.builder(
                      itemCount: users.length,
                      itemBuilder: (context, index) {
                        return _userTile(
                          users[index].key,
                          users[index].value as Map<String, dynamic>,
                        );
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