import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class AdminGuideRequestsScreen extends StatefulWidget {
  const AdminGuideRequestsScreen({super.key});

  @override
  State<AdminGuideRequestsScreen> createState() => _AdminGuideRequestsScreenState();
}

class _AdminGuideRequestsScreenState extends State<AdminGuideRequestsScreen> {
  final DatabaseReference _reqRef = FirebaseDatabase.instance.ref('guideRequests');

  Future<void> _setStatus({
    required String uid,
    required String status,
    String? note,
    required Map docs,
    required Map basicInfo,
  }) async {
    final now = DateTime.now().toIso8601String();

    final title = status == 'approved'
        ? 'Approved'
        : (status == 'rejected' ? 'Rejected' : 'Pending');

    final message = status == 'approved'
        ? 'Your guide account has been approved. You can now login as a guide in Saffar Oman.'
        : (status == 'rejected'
        ? ((note == null || note.trim().isEmpty)
        ? 'Your guide request was rejected.'
        : 'Your guide request was rejected: $note')
        : 'Your guide request is pending.');

    await FirebaseDatabase.instance.ref('users/$uid').update({
      'status': status,
      'reviewNote': note,
      'statusUpdatedAt': now,
      'documents': docs,
      'name': basicInfo['name'],
      'email': basicInfo['email'],
      'phone': basicInfo['phone'],
      'role': status == 'approved' ? 'guide' : 'tourist',
    });

    await FirebaseDatabase.instance.ref('guideRequests/$uid').update({
      'status': status,
      'reviewNote': note,
      'statusUpdatedAt': now,
    });

    await FirebaseDatabase.instance.ref('notifications/$uid').push().set({
      'type': 'guide_status',
      'status': status,
      'title': title,
      'message': message,
      'targetRoute': status == 'approved' ? '/guideHome' : null,
      'createdAt': now,
      'read': false,
    });
  }

  Future<void> _promptApproveReject({
    required String uid,
    required String actionStatus,
    required Map docs,
    required Map basicInfo,
  }) async {
    final TextEditingController noteCtrl = TextEditingController();

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(actionStatus == 'approved' ? 'Approve Guide' : 'Reject Guide'),
        content: TextField(
          controller: noteCtrl,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Optional note (reason, missing doc, etc.)',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(actionStatus == 'approved' ? 'Approve' : 'Reject'),
          ),
        ],
      ),
    );

    if (ok != true) return;

    await _setStatus(
      uid: uid,
      status: actionStatus,
      note: noteCtrl.text.trim().isEmpty ? null : noteCtrl.text.trim(),
      docs: docs,
      basicInfo: basicInfo,
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(actionStatus == 'approved' ? 'Approved' : 'Rejected')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Guide Requests'),
      ),
      body: StreamBuilder<DatabaseEvent>(
        stream: _reqRef.onValue,
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
            return const Center(child: Text('No requests'));
          }

          final data = snapshot.data!.snapshot.value as Map;
          final items = <Map<String, dynamic>>[];

          data.forEach((key, value) {
            if (value is Map) {
              final m = Map<String, dynamic>.from(value);
              m['uid'] = key.toString();
              items.add(m);
            }
          });

          items.sort((a, b) {
            final aT = (a['createdAt'] ?? '').toString();
            final bT = (b['createdAt'] ?? '').toString();
            return bT.compareTo(aT);
          });

          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final r = items[i];
              final uid = (r['uid'] ?? '').toString();
              final name = (r['name'] ?? '').toString();
              final email = (r['email'] ?? '').toString();
              final phone = (r['phone'] ?? '').toString();
              final status = (r['status'] ?? 'pending').toString();

              final docs = (r['documents'] is Map) ? Map.from(r['documents']) : <String, dynamic>{};

              final cvUrl = (docs['cvUrl'] ?? '').toString();
              final idFrontUrl = (docs['idFrontUrl'] ?? '').toString();
              final idBackUrl = (docs['idBackUrl'] ?? '').toString();

              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name.isEmpty ? '(No name)' : name,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 4),
                      Text(email),
                      Text(phone),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Text('Status: ', style: TextStyle(fontWeight: FontWeight.w600)),
                          Text(status),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          _DocChip(label: 'CV', url: cvUrl),
                          _DocChip(label: 'ID Front', url: idFrontUrl),
                          _DocChip(label: 'ID Back', url: idBackUrl),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: status == 'approved'
                                  ? null
                                  : () => _promptApproveReject(
                                uid: uid,
                                actionStatus: 'approved',
                                docs: docs,
                                basicInfo: {'name': name, 'email': email, 'phone': phone},
                              ),
                              child: const Text('Approve'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: status == 'rejected'
                                  ? null
                                  : () => _promptApproveReject(
                                uid: uid,
                                actionStatus: 'rejected',
                                docs: docs,
                                basicInfo: {'name': name, 'email': email, 'phone': phone},
                              ),
                              child: const Text('Reject'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _DocChip extends StatelessWidget {
  final String label;
  final String url;

  const _DocChip({required this.label, required this.url});

  @override
  Widget build(BuildContext context) {
    final has = url.trim().isNotEmpty;

    return ActionChip(
      label: Text(has ? '$label: View' : '$label: Missing'),
      onPressed: has
          ? () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => _DocViewerScreen(title: label, url: url),
          ),
        );
      }
          : null,
    );
  }
}

class _DocViewerScreen extends StatelessWidget {
  final String title;
  final String url;

  const _DocViewerScreen({required this.title, required this.url});

  @override
  Widget build(BuildContext context) {
    final isImage = url.toLowerCase().contains('.jpg') ||
        url.toLowerCase().contains('.jpeg') ||
        url.toLowerCase().contains('.png') ||
        url.toLowerCase().contains('.webp');

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: isImage
            ? InteractiveViewer(
          child: Image.network(url, fit: BoxFit.contain),
        )
            : Padding(
          padding: const EdgeInsets.all(16),
          child: SelectableText(
            url,
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
