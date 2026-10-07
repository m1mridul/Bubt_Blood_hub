import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;

class HospitalActiveRequestsScreen extends StatelessWidget {
  final String hospitalName;
  const HospitalActiveRequestsScreen({super.key, required this.hospitalName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text('Active Requests: $hospitalName', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('blood_requests')
            .where('hospitalName', isEqualTo: hospitalName)
            .where('status', isEqualTo: 'active')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No active requests for your hospital.', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final doc = snapshot.data!.docs[index];
              final data = doc.data() as Map<String, dynamic>;
              final Timestamp? timestamp = data['timestamp'];
              final String timeStr = timestamp != null ? timeago.format(timestamp.toDate()) : 'Recently';

              return Container(
                margin: const EdgeInsets.only(bottom: 15),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)]),
                child: Row(
                  children: [
                    Container(
                      width: 50, height: 50,
                      decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(12)),
                      child: Center(child: Text(data['bloodGroup'] ?? '?', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 18))),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Requested by: @${data['username']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          Text('Time: $timeStr | Location: ${data['location']}', style: const TextStyle(color: Colors.grey, fontSize: 13)),
                        ],
                      ),
                    ),
                    const Chip(label: Text('ACTIVE', style: TextStyle(color: Colors.orange, fontSize: 10, fontWeight: FontWeight.bold)), backgroundColor: Color(0xFFFFF7ED)),
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
