import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class HospitalVerifyDetailScreen extends StatelessWidget {
  final String requestId;
  final Map<String, dynamic> requestData;

  const HospitalVerifyDetailScreen({
    super.key,
    required this.requestId,
    required this.requestData,
  });

  Future<void> _certifyDonation(BuildContext context) async {
    try {
      final donorId = requestData['acceptedBy'];
      
      // 1. Update donor profile stats & set 90-day block
      DateTime nextEligibleDate = DateTime.now().add(const Duration(days: 90));
      final donorRef = FirebaseFirestore.instance.collection('users').doc(donorId);
      await donorRef.update({
        'totalDonations': FieldValue.increment(1),
        'nextEligibility': 'Eligible in 90 days',
        'nextEligibilityDate': Timestamp.fromDate(nextEligibleDate),
      });

      // 2. Mark blood_request as certified instead of deleting
      await FirebaseFirestore.instance.collection('blood_requests').doc(requestId).update({
        'status': 'certified',
        'certifiedAt': FieldValue.serverTimestamp(),
      });

      // 3. Mark the history record as justified
      final historyQuery = await FirebaseFirestore.instance
          .collection('donation_history')
          .where('requestId', isEqualTo: requestId)
          .limit(1)
          .get();
      
      if (historyQuery.docs.isNotEmpty) {
        await historyQuery.docs.first.reference.update({'isJustified': true});
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Donation Certified Successfully!"), backgroundColor: Colors.green)
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    final donorId = requestData['acceptedBy'];
    final receiverId = requestData['postedBy'];

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
        title: const Text('Detailed Verification', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Column(
              children: [
                _buildHeaderSection(),
                const SizedBox(height: 30),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _buildUserSection('Donor Information', donorId, Colors.green)),
                    const SizedBox(width: 30),
                    Expanded(child: _buildUserSection('Receiver Information', receiverId, Colors.blue)),
                  ],
                ),
                const SizedBox(height: 50),
                _buildActionButtons(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 20)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Request Context', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 15),
          _rowInfo('Blood Group Required', requestData['bloodGroup'] ?? 'N/A'),
          _rowInfo('Hospital', requestData['hospitalName'] ?? 'N/A'),
          _rowInfo('Location', requestData['location'] ?? 'N/A'),
          _rowInfo('Notes', requestData['notes'] ?? 'None'),
        ],
      ),
    );
  }

  Widget _buildUserSection(String title, String? userId, Color themeColor) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(userId).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final data = snapshot.data!.data() as Map<String, dynamic>? ?? {};

        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(25),
            border: Border.all(color: themeColor.withOpacity(0.1), width: 2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: themeColor)),
              const SizedBox(height: 20),
              _userInfoRow(Icons.person, 'Name', data['fullName']),
              _userInfoRow(Icons.alternate_email, 'Username', '@${data['username']}'),
              _userInfoRow(Icons.phone, 'Phone', data['phone']),
              _userInfoRow(Icons.opacity, 'Blood Group', data['bloodGroup']),
              if (data['nidNumber'] != null) _userInfoRow(Icons.badge, 'NID', data['nidNumber']),
            ],
          ),
        );
      },
    );
  }

  Widget _userInfoRow(IconData icon, String label, String? value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
              Text(value ?? 'N/A', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            ],
          )
        ],
      ),
    );
  }

  Widget _rowInfo(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black54)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 60,
          child: ElevatedButton(
            onPressed: () => _certifyDonation(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E3A8A),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            ),
            child: const Text('CERTIFY THIS DONATION', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(height: 15),
        const Text(
          'By clicking certify, you verify that the donor has successfully provided blood to the receiver at your institution.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
