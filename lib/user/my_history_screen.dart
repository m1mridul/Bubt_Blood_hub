import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;

class MyHistoryScreen extends StatelessWidget {
  const MyHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final isDesktop = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('My Donation History', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900)),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('donation_history')
            .where('donorId', isEqualTo: user?.uid)
            .snapshots(), // Removed orderBy to avoid index requirement
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}"));
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          
          // Get and Sort data in memory
          final List<DocumentSnapshot> docs = snapshot.data?.docs ?? [];
          docs.sort((a, b) {
            Timestamp t1 = (a.data() as Map<String, dynamic>)['timestamp'] ?? Timestamp.now();
            Timestamp t2 = (b.data() as Map<String, dynamic>)['timestamp'] ?? Timestamp.now();
            return t2.compareTo(t1); // Descending order
          });

          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history_toggle_off_rounded, size: 80, color: Colors.grey.shade300),
                  const SizedBox(height: 20),
                  const Text("No donation history found yet.", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                  const Text("Successful donations certified by hospital will appear here.", style: TextStyle(color: Colors.black26, fontSize: 12)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: EdgeInsets.symmetric(horizontal: isDesktop ? MediaQuery.of(context).size.width * 0.2 : 20, vertical: 30),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final rating = data['rating'] ?? 0;
              final bool isJustified = data['isJustified'] ?? false;

              return Container(
                margin: const EdgeInsets.only(bottom: 20),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white, 
                  borderRadius: BorderRadius.circular(25), 
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)]
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
                            color: isJustified ? Colors.green.shade50 : Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            isJustified ? "✅ CERTIFIED BY HOSPITAL" : "⌛ WAITING FOR HOSPITAL JUSTIFICATION",
                            style: TextStyle(
                              color: isJustified ? Colors.green.shade700 : Colors.orange.shade700, 
                              fontSize: 10, 
                              fontWeight: FontWeight.w900
                            ),
                          ),
                        ),
                        Text(
                          data['timestamp'] != null ? timeago.format((data['timestamp'] as Timestamp).toDate()) : "", 
                          style: const TextStyle(color: Colors.grey, fontSize: 11)
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Text("Rating & Feedback from Receiver:", style: TextStyle(color: Colors.black38, fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Row(
                      children: List.generate(5, (i) => Icon(Icons.star_rounded, color: i < rating ? Colors.amber : Colors.grey.shade200, size: 22)),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      data['comment'] ?? "No comments provided.", 
                      style: const TextStyle(fontStyle: FontStyle.italic, color: Color(0xFF374151), fontSize: 15, height: 1.4)
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
