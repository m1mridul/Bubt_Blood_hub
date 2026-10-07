import 'package:blood_hub/hospital/hospital_verify_detail_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class HospitalCertifyScreen extends StatelessWidget {
  final String hospitalName;
  const HospitalCertifyScreen({super.key, required this.hospitalName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
        title: const Text('Certification Center', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('blood_requests')
            .where('hospitalName', isEqualTo: hospitalName)
            .where('status', isEqualTo: 'pending_certification')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No pending certifications for your hospital.', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final doc = snapshot.data!.docs[index];
              final data = doc.data() as Map<String, dynamic>;
              
              final donorId = data['acceptedBy'];
              final receiverId = data['postedBy'];

              return Container(
                margin: const EdgeInsets.only(bottom: 15),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white, 
                  borderRadius: BorderRadius.circular(25), 
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)]
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: Colors.blue.shade50, 
                          child: Text(data['bloodGroup'] ?? '?', style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold))
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Robust Name Fetching
                              _buildNameRow("Donor", donorId),
                              _buildNameRow("Receiver", receiverId),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(8)),
                          child: Text('WAITING JUSTIFY', style: TextStyle(color: Colors.orange.shade700, fontSize: 10, fontWeight: FontWeight.w900)),
                        ),
                      ],
                    ),
                    const Divider(height: 40),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Review donor and receiver details:', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 13)),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => HospitalVerifyDetailScreen(requestId: doc.id, requestData: data),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1E3A8A), 
                            foregroundColor: Colors.white, 
                            elevation: 0, 
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
                          ),
                          child: const Text('VIEW DETAILS & CERTIFY'),
                        ),
                      ],
                    )
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildNameRow(String label, String? userId) {
    if (userId == null) return Text('$label: Unknown', style: const TextStyle(color: Colors.grey));
    
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(userId).get(),
      builder: (context, snapshot) {
        String username = "...";
        if (snapshot.hasData && snapshot.data!.exists) {
          username = (snapshot.data!.data() as Map<String, dynamic>)['username'] ?? "user";
        }
        return Padding(
          padding: const EdgeInsets.only(bottom: 2),
          child: Text(
            '$label: @$username', 
            style: TextStyle(
              fontWeight: label == "Donor" ? FontWeight.w900 : FontWeight.bold,
              fontSize: label == "Donor" ? 17 : 14,
              color: label == "Donor" ? Colors.black : Colors.black54,
            )
          ),
        );
      },
    );
  }
}
