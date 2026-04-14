import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class AdminManageReviewsScreen extends StatefulWidget {
  const AdminManageReviewsScreen({super.key});

  @override
  State<AdminManageReviewsScreen> createState() =>
      _AdminManageReviewsScreenState();
}

class _AdminManageReviewsScreenState extends State<AdminManageReviewsScreen> {
  final DatabaseReference _feedbackRef =
  FirebaseDatabase.instance.ref('feedback');

  final TextEditingController _searchController = TextEditingController();
  String _searchText = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<MapEntry<String, Map<String, dynamic>>> _filterFeedback(Map raw) {
    final items = raw.entries.map((e) {
      return MapEntry<String, Map<String, dynamic>>(
        e.key.toString(),
        Map<String, dynamic>.from(e.value as Map),
      );
    }).toList();

    if (_searchText.isEmpty) return items;

    return items.where((entry) {
      final item = entry.value;
      final userId = (item['userId'] ?? '').toString().toLowerCase();
      final feedback = (item['feedback'] ?? '').toString().toLowerCase();
      final adminReply = (item['adminReply'] ?? '').toString().toLowerCase();

      return userId.contains(_searchText) ||
          feedback.contains(_searchText) ||
          adminReply.contains(_searchText);
    }).toList();
  }

  String _formatDate(dynamic value) {
    if (value == null) return '';
    try {
      if (value is String) {
        final dt = DateTime.tryParse(value);
        if (dt != null) {
          final d = dt.day.toString().padLeft(2, '0');
          final m = dt.month.toString().padLeft(2, '0');
          final y = dt.year.toString();
          return '$d/$m/$y';
        }
        return value;
      }

      if (value is int) {
        final dt = DateTime.fromMillisecondsSinceEpoch(value);
        final d = dt.day.toString().padLeft(2, '0');
        final m = dt.month.toString().padLeft(2, '0');
        final y = dt.year.toString();
        return '$d/$m/$y';
      }

      return value.toString();
    } catch (_) {
      return value.toString();
    }
  }

  Future<void> _deleteReview(String feedbackId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Feedback'),
        content: const Text('Are you sure you want to delete this feedback?'),
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
      ),
    );

    if (confirm != true) return;

    try {
      await _feedbackRef.child(feedbackId).remove();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Feedback deleted successfully.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Delete failed: $e')),
      );
    }
  }

  Future<void> _showReviewDetails(
      String feedbackId,
      Map<String, dynamic> review,
      ) async {
    final replyController = TextEditingController(
      text: (review['adminReply'] ?? '').toString(),
    );

    final userId = (review['userId'] ?? '').toString();
    final feedback = (review['feedback'] ?? '').toString();
    final date = _formatDate(review['createdAt']);

    await showDialog(
      context: context,
      builder: (dialogContext) {
        bool saving = false;

        return StatefulBuilder(
          builder: (dialogContext, setLocalState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              title: const Text('Feedback Details'),
              content: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      userId.isEmpty ? 'Unknown User' : userId,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    if (date.isNotEmpty)
                      Text(
                        'Date: $date',
                        style: const TextStyle(color: Colors.black54),
                      ),
                    const SizedBox(height: 16),
                    const Text(
                      'Feedback',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        feedback.isEmpty ? 'No feedback' : feedback,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Admin Reply',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: replyController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: 'Write your reply here',
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: saving ? null : () => Navigator.pop(dialogContext),
                  child: const Text('Close'),
                ),
                ElevatedButton(
                  onPressed: saving
                      ? null
                      : () async {
                    final reply = replyController.text.trim();

                    setLocalState(() {
                      saving = true;
                    });

                    try {
                      await _feedbackRef.child(feedbackId).update({
                        'adminReply': reply,
                        'replyAt': ServerValue.timestamp,
                      });

                      if (!mounted) return;
                      Navigator.pop(dialogContext);

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Reply saved successfully.'),
                        ),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Failed to save reply: $e'),
                        ),
                      );

                      setLocalState(() {
                        saving = false;
                      });
                    }
                  },
                  child: saving
                      ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                      : const Text('Save Reply'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _reviewTile(String feedbackId, Map<String, dynamic> review) {
    final userId = (review['userId'] ?? '').toString();
    final feedback = (review['feedback'] ?? '').toString();
    final adminReply = (review['adminReply'] ?? '').toString();
    final date = _formatDate(review['createdAt']);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFD8C7B7),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: Colors.brown.shade300,
                child: Text(
                  userId.isNotEmpty ? userId[0].toUpperCase() : '?',
                  style: const TextStyle(color: Colors.white, fontSize: 20),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userId.isEmpty ? 'Unknown User' : userId,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (date.isNotEmpty)
                      Text(
                        date,
                        style: const TextStyle(color: Colors.black54),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            feedback.isEmpty ? 'No feedback' : feedback,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 15),
          ),
          if (adminReply.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white70,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Reply: $adminReply',
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              OutlinedButton(
                onPressed: () => _showReviewDetails(feedbackId, review),
                child: const Text('View / Reply'),
              ),
              const Spacer(),
              IconButton(
                onPressed: () => _deleteReview(feedbackId),
                icon: const Icon(Icons.delete_outline, color: Colors.red),
              ),
            ],
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
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
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
                        'Manage Reviews',
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
              TextField(
                controller: _searchController,
                onChanged: (value) {
                  setState(() {
                    _searchText = value.trim().toLowerCase();
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Search by user ID or feedback',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: const Color(0xFFE4D7CB),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Expanded(
                child: StreamBuilder<DatabaseEvent>(
                  stream: _feedbackRef.onValue,
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          'Error loading reviews: ${snapshot.error}',
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
                          'No reviews found',
                          style: TextStyle(color: Colors.white),
                        ),
                      );
                    }

                    final raw = snapshot.data!.snapshot.value as Map;
                    final reviews = _filterFeedback(raw);

                    if (reviews.isEmpty) {
                      return const Center(
                        child: Text(
                          'No reviews found',
                          style: TextStyle(color: Colors.white),
                        ),
                      );
                    }

                    reviews.sort((a, b) {
                      final aTime = a.value['createdAt']?.toString() ?? '';
                      final bTime = b.value['createdAt']?.toString() ?? '';
                      return bTime.compareTo(aTime);
                    });

                    return ListView.builder(
                      itemCount: reviews.length,
                      itemBuilder: (context, index) {
                        return _reviewTile(
                          reviews[index].key,
                          reviews[index].value,
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