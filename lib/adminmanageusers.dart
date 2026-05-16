import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class AdminManageUsersScreen extends StatefulWidget {
  const AdminManageUsersScreen({super.key});
  
  @override
  State<AdminManageUsersScreen> createState() => _AdminManageUsersScreenState();
}

class _AdminManageUsersScreenState extends State<AdminManageUsersScreen> {
  final DatabaseReference _usersRef = FirebaseDatabase.instance.ref('users');
  final TextEditingController _searchController = TextEditingController();

  String _selectedType = 'tourist';
  String _searchText = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _showUserDialog({
    String? uid,
    Map<String, dynamic>? userData,
  }) async {
    final nameController = TextEditingController(
      text: userData?['name']?.toString() ?? '',
    );
    final emailController = TextEditingController(
      text: userData?['email']?.toString() ?? '',
    );
    final passwordController = TextEditingController();

    String role = userData?['role']?.toString() ?? _selectedType;

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(uid == null ? 'Add User' : 'Update User'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                  ),
                ),
                const SizedBox(height: 12),
                if (uid == null)
                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Password',
                    ),
                  ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: role,
                  decoration: const InputDecoration(
                    labelText: 'Role',
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'tourist',
                      child: Text('Tourist'),
                    ),
                    DropdownMenuItem(
                      value: 'guide',
                      child: Text('Guide'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      role = value;
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = nameController.text.trim();
                final email = emailController.text.trim().toLowerCase();
                final password = passwordController.text.trim();

                if (name.isEmpty || email.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please fill all fields.')),
                  );
                  return;
                }

                try {
                  if (uid == null) {
                    if (password.length < 6) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Password must be at least 6 characters.'),
                        ),
                      );
                      return;
                    }

                    final credential = await FirebaseAuth.instance
                        .createUserWithEmailAndPassword(
                      email: email,
                      password: password,
                    );

                    final newUid = credential.user!.uid;

                    await _usersRef.child(newUid).set({
                      'name': name,
                      'email': email,
                      'role': role,
                      'createdAt': ServerValue.timestamp,
                    });
                  } else {
                    await _usersRef.child(uid).update({
                      'name': name,
                      'email': email,
                      'role': role,
                    });
                  }

                  if (!mounted) return;
                  Navigator.pop(context);
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Operation failed: $e')),
                  );
                }
              },
              child: Text(uid == null ? 'Add' : 'Update'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteUser(String uid) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete User'),
          content: const Text('Are you sure you want to delete this user?'),
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
        );
      },
    );

    if (confirm != true) return;

    try {
      await _usersRef.child(uid).remove();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User deleted from database.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Delete failed: $e')),
      );
    }
  }

  List<MapEntry<String, dynamic>> _filterUsers(Map data) {
    final entries = data.entries.map((e) {
      return MapEntry<String, dynamic>(
        e.key.toString(),
        Map<String, dynamic>.from(e.value as Map),
      );
    }).toList();

    return entries.where((entry) {
      final user = entry.value;
      final role = (user['role'] ?? '').toString().toLowerCase();
      final name = (user['name'] ?? '').toString().toLowerCase();
      final email = (user['email'] ?? '').toString().toLowerCase();

      final matchesRole = role == _selectedType;
      final matchesSearch =
          name.contains(_searchText) || email.contains(_searchText);

      return matchesRole && matchesSearch;
    }).toList();
  }

  Widget _buildTab(String label, String value) {
    final selected = _selectedType == value;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedType = value;
          });
        },
        child: Container(
          height: 46,
          decoration: BoxDecoration(
            color: selected ? Colors.white : const Color(0xFFD9CABA),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _userTile(String uid, Map<String, dynamic> user) {
    final name = (user['name'] ?? 'Unknown').toString();
    final email = (user['email'] ?? '').toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 28,
            backgroundColor: Colors.white24,
            backgroundImage: AssetImage('images/man.png'),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  email,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _showUserDialog(uid: uid, userData: user),
            icon: const Icon(Icons.edit_outlined, color: Colors.black),
          ),
          IconButton(
            onPressed: () => _deleteUser(uid),
            icon: const Icon(Icons.delete_outline, color: Colors.red),
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
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
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
                        'Manage Users',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 20,
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => _showUserDialog(),
                    icon: const Icon(Icons.person_add_alt_1, color: Colors.black),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  _buildTab('Tourist', 'tourist'),
                  const SizedBox(width: 10),
                  _buildTab('Guides', 'guide'),
                ],
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
                  hintText: 'Search by name or email',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: const Color(0xFFE4D7CB),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 22),
              Expanded(
                child: StreamBuilder<DatabaseEvent>(
                  stream: _usersRef.onValue,
                  builder: (context, snapshot) {
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
                        final uid = users[index].key;
                        final user = users[index].value as Map<String, dynamic>;
                        return _userTile(uid, user);
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
