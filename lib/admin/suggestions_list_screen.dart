import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;

class SuggestionsListScreen extends StatelessWidget {
  const SuggestionsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 900;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Suggestions & Complaints', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('suggestions')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFFE53935)));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.feedback_outlined, size: 80, color: Colors.grey.shade300),
                  const SizedBox(height: 20),
                  const Text('No suggestions or complaints yet.', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                ],
              ),
            );
          }

          final messages = snapshot.data!.docs;

          return ListView.builder(
            padding: EdgeInsets.symmetric(horizontal: isDesktop ? size.width * 0.2 : 20, vertical: 30),
            itemCount: messages.length,
            itemBuilder: (context, index) {
              final data = messages[index].data() as Map<String, dynamic>;
              return _buildPremiumMessageCard(data);
            },
          );
        },
      ),
    );
  }

  Widget _buildPremiumMessageCard(Map<String, dynamic> data) {
    final String type = data['type'] ?? 'Suggestion';
    final bool isComplaint = type.toLowerCase() == 'complaint';

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isComplaint ? Colors.red.shade50 : Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    type.toUpperCase(),
                    style: TextStyle(color: isComplaint ? Colors.red : Colors.blue, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
                Text(
                  data['timestamp'] != null ? timeago.format((data['timestamp'] as Timestamp).toDate()) : 'Recently',
                  style: const TextStyle(color: Colors.black26, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              data['subject'] ?? 'No Subject',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF1F2937)),
            ),
            const SizedBox(height: 10),
            Text(
              data['message'] ?? 'No message body provided.',
              style: const TextStyle(color: Colors.black54, fontSize: 14, fontWeight: FontWeight.bold, height: 1.5),
            ),
            const SizedBox(height: 20),
            const Divider(height: 1),
            const SizedBox(height: 15),
            Row(
              children: [
                const Icon(Icons.person_outline, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text(data['userName'] ?? 'Anonymous User', style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
                const Spacer(),
                TextButton(
                  onPressed: () {},
                  child: const Text('MARK AS READ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
