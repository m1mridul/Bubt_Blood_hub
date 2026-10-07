import 'package:blood_hub/user/request_details_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;

class MyPersonalRequestsScreen extends StatelessWidget {
  const MyPersonalRequestsScreen({super.key});

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
              TextSpan(text: 'Personal ', style: TextStyle(color: Colors.black, fontSize: 24, fontWeight: FontWeight.w900, fontFamily: 'Manrope')),
              TextSpan(text: 'Dashboard', style: TextStyle(color: Color(0xFFE53935), fontSize: 24, fontWeight: FontWeight.w900, fontFamily: 'Manrope')),
            ],
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('blood_requests')
            .where('acceptedBy', isEqualTo: user?.uid) // Showing requests accepted by me
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFFE53935)));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _buildEmptyState();
          }

          final requests = snapshot.data!.docs;

          return GridView.builder(
            padding: EdgeInsets.symmetric(horizontal: isDesktop ? size.width * 0.1 : 20, vertical: 40),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: isDesktop ? 3 : 1,
              childAspectRatio: 1.4,
              crossAxisSpacing: 25,
              mainAxisSpacing: 25,
            ),
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final doc = requests[index];
              final data = doc.data() as Map<String, dynamic>;
              return _buildAcceptedCard(context, doc.id, data);
            },
          );
        },
      ),
    );
  }

  Widget _buildAcceptedCard(BuildContext context, String requestId, Map<String, dynamic> data) {
    bool isBankRequest = data['isBankRequest'] ?? false;
    final status = data['status'] ?? 'Accepted';

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 20, offset: const Offset(0, 10))],
        border: isBankRequest ? Border.all(color: Colors.brown.withOpacity(0.2), width: 1.5) : null,
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
                  color: isBankRequest ? Colors.brown.shade50 : Colors.green.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  isBankRequest ? 'BANK CONTRIBUTION' : 'INDIVIDUAL DONATION',
                  style: TextStyle(
                    color: isBankRequest ? Colors.brown : Colors.green.shade700,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const Icon(Icons.check_circle, color: Colors.green, size: 18),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            data['hospitalName'] ?? 'Location',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF1F2937)),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.opacity, size: 18, color: Color(0xFFE53935)),
              const SizedBox(width: 8),
              Text(
                'Group: ${data['bloodGroup'] ?? 'N/A'}',
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black54),
              ),
            ],
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => RequestDetailsScreen(
                      requestId: requestId,
                      isAdminView: true, // Show only details without action buttons
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: isBankRequest ? const Color(0xFF7C2D12) : const Color(0xFFE53935),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('VIEW DETAILS', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white)),
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
          const Text('No accepted requests yet', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.grey)),
          const SizedBox(height: 10),
          const Text('The requests you accept will appear here for tracking.', style: TextStyle(color: Colors.black26, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
