import 'package:blood_hub/user/chat_screen.dart';
import 'package:blood_hub/user/rating_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;

class MyRequestResponsesScreen extends StatelessWidget {
  const MyRequestResponsesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 900;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text.rich(
          const TextSpan(
            children: [
              TextSpan(text: 'Request ', style: TextStyle(color: Colors.black, fontSize: 24, fontWeight: FontWeight.w900, fontFamily: 'Manrope')),
              TextSpan(text: 'Responses', style: TextStyle(color: Color(0xFF4CAF50), fontSize: 24, fontWeight: FontWeight.w900, fontFamily: 'Manrope')),
            ],
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('blood_requests')
            .where('postedBy', isEqualTo: user?.uid)
            .where('status', isEqualTo: 'accepted')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF4CAF50)));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _buildEmptyState();
          }

          final responses = snapshot.data!.docs;

          return GridView.builder(
            padding: EdgeInsets.symmetric(horizontal: isDesktop ? size.width * 0.1 : 20, vertical: 40),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: isDesktop ? 3 : 1,
              childAspectRatio: 1.3,
              crossAxisSpacing: 25,
              mainAxisSpacing: 25,
            ),
            itemCount: responses.length,
            itemBuilder: (context, index) {
              final doc = responses[index];
              final data = doc.data() as Map<String, dynamic>;
              return _buildResponseCard(context, doc.id, data);
            },
          );
        },
      ),
    );
  }

  Widget _buildResponseCard(BuildContext context, String requestId, Map<String, dynamic> data) {
    final String donorUsername = data['donorName'] ?? 'donor';
    final Timestamp? acceptedAt = data['acceptedAt'];
    final String timeStr = acceptedAt != null ? timeago.format(acceptedAt.toDate()) : 'Recently';

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'ACCEPTED',
                  style: TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.w900),
                ),
              ),
              Row(
                children: [
                  Text(timeStr, style: const TextStyle(color: Colors.black26, fontSize: 11, fontWeight: FontWeight.bold)),
                  const SizedBox(width: 8),
                  const Icon(Icons.check_circle, color: Colors.green, size: 20),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text.rich(
            TextSpan(
              children: [
                const TextSpan(text: 'Donor ', style: TextStyle(color: Colors.black54, fontSize: 14, fontWeight: FontWeight.bold)),
                TextSpan(text: '@$donorUsername', style: const TextStyle(color: Color(0xFFE53935), fontSize: 15, fontWeight: FontWeight.w900)),
                const TextSpan(text: ' has responded to your request!', style: TextStyle(color: Colors.black54, fontSize: 14, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              const Icon(Icons.local_hospital_outlined, size: 18, color: Colors.grey),
              const SizedBox(width: 8),
              Expanded(child: Text(data['hospitalName'] ?? 'Hospital', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1F2937)))),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.opacity, size: 18, color: Color(0xFFE53935)),
              const SizedBox(width: 8),
              Text('Group: ${data['bloodGroup'] ?? 'N/A'}', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1F2937))),
            ],
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            height: 45,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => RatingScreen(
                      requestId: requestId,
                      donorId: data['acceptedBy'] ?? "",
                      donorName: data['donorName'] ?? "Donor",
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: const Text('HE/SHE SUCCESSFULLY DONATED', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12)),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 45,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChatScreen(requestId: requestId),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4CAF50),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: const Text('CONTACT DONOR', style: TextStyle(fontWeight: FontWeight.w900)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.assignment_turned_in_outlined, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 20),
          const Text('No responses yet', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.grey)),
          const SizedBox(height: 10),
          const Text('When someone accepts your requests, they will appear here.', style: TextStyle(color: Colors.black26, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
