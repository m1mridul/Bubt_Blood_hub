import 'package:blood_hub/user/live_tracking_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;

class RequestDetailsScreen extends StatefulWidget {
  final String requestId;
  final bool isAdminView;

  const RequestDetailsScreen({super.key, required this.requestId, this.isAdminView = false});

  @override
  State<RequestDetailsScreen> createState() => _RequestDetailsScreenState();
}

class _RequestDetailsScreenState extends State<RequestDetailsScreen> {
  Stream<DocumentSnapshot>? _requestStream;

  @override
  void initState() {
    super.initState();
    _requestStream = FirebaseFirestore.instance
        .collection('blood_requests')
        .doc(widget.requestId)
        .snapshots();
  }

  Color _getColorForBloodGroup(String group) {
    switch (group.toUpperCase()) {
      case 'A+': return Colors.orange.shade700;
      case 'A-': return Colors.deepOrange.shade600;
      case 'B+': return Colors.blue.shade700;
      case 'B-': return Colors.indigo.shade600;
      case 'AB+': return Colors.purple.shade600;
      case 'AB-': return Colors.deepPurple.shade700;
      case 'O+': return const Color(0xFFE53935);
      case 'O-': return Colors.red.shade900;
      default: return const Color(0xFFE53935);
    }
  }

  Future<void> _acceptRequest() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    try {
      // Fetch donor's username to store in the request
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(currentUser.uid).get();
      final String donorUsername = userDoc.data()?['username'] ?? "donor";

      final requestDoc = FirebaseFirestore.instance.collection('blood_requests').doc(widget.requestId);
      await requestDoc.update({
        'status': 'accepted',
        'acceptedBy': currentUser.uid,
        'donorName': donorUsername, // Storing donor username for easy display
        'acceptedAt': FieldValue.serverTimestamp(), // Storing acceptance time
      });

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => LiveTrackingScreen(requestId: widget.requestId)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed: $e"), backgroundColor: Colors.red));
      }
    }
  }

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
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Request Details', style: TextStyle(color: Colors.black, fontSize: 22, fontWeight: FontWeight.w900, fontFamily: 'Manrope')),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: _requestStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: Color(0xFFE53935)));
          if (!snapshot.hasData || !snapshot.data!.exists) return const Center(child: Text('Request not found.', style: TextStyle(fontWeight: FontWeight.bold)));

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final String bloodGroup = data['bloodGroup'] ?? 'N/A';
          final String hospital = data['hospitalName'] ?? 'N/A';
          final String requesterUsername = data['username'] ?? 'anonymous';
          final String location = data['location']?.toString() ?? 'Not specified';
          final String notes = data['notes'] ?? 'No additional notes provided.';
          final String status = data['status'] ?? 'active';
          final String contact = data['contact'] ?? 'N/A';
          final Timestamp? timestamp = data['timestamp'];
          final String timeStr = timestamp != null ? timeago.format(timestamp.toDate()) : 'Just now';
          final bool isBankRequest = data['isBankRequest'] ?? false;
          final Color themeColor = isBankRequest ? const Color(0xFF7C2D12) : _getColorForBloodGroup(bloodGroup);

          // SAFE COMPARISON
          final currentUid = FirebaseAuth.instance.currentUser?.uid;
          final isMyOwnRequest = currentUid != null && currentUid == data['postedBy'];

          return SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: isDesktop ? size.width * 0.2 : 20, vertical: 30),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(40),
                  decoration: BoxDecoration(
                    color: isBankRequest ? const Color(0xFFFFF7F7) : Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    border: isBankRequest ? Border.all(color: themeColor.withOpacity(0.2), width: 2) : null,
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 30, offset: const Offset(0, 10))],
                  ),
                  child: Column(
                    children: [
                      if (isBankRequest)
                        Container(
                          margin: const EdgeInsets.only(bottom: 20),
                          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                          decoration: BoxDecoration(color: themeColor, borderRadius: BorderRadius.circular(10)),
                          child: const Text('OFFICIAL BLOOD BANK REQUIREMENT', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
                        ),
                      _buildMainHeader(bloodGroup, timeStr, themeColor, requesterUsername),
                      const SizedBox(height: 40),
                      const Divider(color: Color(0xFFF3F4F6), height: 1),
                      const SizedBox(height: 40),
                      _buildDetailRow(isBankRequest ? Icons.business : Icons.local_hospital_outlined, isBankRequest ? 'Blood Bank' : 'Hospital', hospital, themeColor),
                      const SizedBox(height: 25),
                      _buildDetailRow(Icons.location_on_outlined, 'Address', location, themeColor),
                      const SizedBox(height: 25),
                      _buildDetailRow(Icons.phone_outlined, 'Contact', contact, themeColor),
                      const SizedBox(height: 25),
                      _buildDetailRow(Icons.description_outlined, 'Requirements', notes, themeColor, isLast: true),
                      const SizedBox(height: 50),
                      _buildActionSection(status, isMyOwnRequest, themeColor),
                    ],
                  ),
                ),
                if (isDesktop) const SizedBox(height: 40),
                if (isDesktop) _buildSecurityNotice(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMainHeader(String group, String time, Color color, String username) {
    return Row(
      children: [
        Container(
          width: 90, height: 90,
          decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(25)),
          child: Center(child: Text(group, style: TextStyle(color: color, fontSize: 36, fontWeight: FontWeight.w900))),
        ),
        const SizedBox(width: 25),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Urgent Need for $group', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF1F2937))),
              const SizedBox(height: 4),
              Text('Requested by @$username', style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 14)),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(30)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.access_time_filled, size: 14, color: Colors.grey.shade600),
                    const SizedBox(width: 8),
                    Text(time, style: TextStyle(color: Colors.grey.shade600, fontSize: 12, fontWeight: FontWeight.w900)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value, Color color, {bool isLast = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: const Color(0xFFF9FAFB), shape: BoxShape.circle),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: Colors.black38, fontSize: 13, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Text(value, style: const TextStyle(color: Color(0xFF374151), fontSize: 16, fontWeight: FontWeight.w900, height: 1.4)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionSection(String status, bool isMyOwn, Color color) {
    if (widget.isAdminView) {
      return Container(
        width: double.infinity, padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(15)),
        child: const Center(child: Text('Administrator View Only', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold))),
      );
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(FirebaseAuth.instance.currentUser?.uid).snapshots(),
      builder: (context, userSnapshot) {
        final userData = userSnapshot.data?.data() as Map<String, dynamic>?;
        final Timestamp? nextEligibleDate = userData?['nextEligibilityDate'];
        final bool isResting = nextEligibleDate != null && nextEligibleDate.toDate().isAfter(DateTime.now());
        
        String restDays = "";
        if (isResting) {
          restDays = nextEligibleDate.toDate().difference(DateTime.now()).inDays.toString();
        }

        if (status == 'completed_by_receiver') {
          return Container(
            width: double.infinity, padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(15)),
            child: const Center(child: Text('⌛ Waiting for Hospital Certification', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold))),
          );
        }
        
        if (status == 'certified') {
          return Container(
            width: double.infinity, padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(15)),
            child: const Center(child: Text('✅ Donation Certified & Completed', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold))),
          );
        }

        if (isMyOwn && status == 'accepted') {
          return SizedBox(
            width: double.infinity, height: 60,
            child: ElevatedButton(
              onPressed: () async {
                await FirebaseFirestore.instance.collection('blood_requests').doc(widget.requestId).update({'status': 'completed_by_receiver'});
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Marked as received! Waiting for hospital to certify."), backgroundColor: Colors.blue));
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
              child: const Text('SUCCESSFULLY RECEIVED BLOOD', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          );
        }

        if (isMyOwn) {
          return Container(
            width: double.infinity, padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.blue.shade100)),
            child: const Center(child: Text('ℹ️ This is your own request', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.w900, fontSize: 15))),
          );
        }

        // ELIGIBILITY CHECK
        if (isResting) {
          return Container(
            width: double.infinity, padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.orange.shade100)),
            child: Column(
              children: [
                const Icon(Icons.timer_outlined, color: Colors.orange, size: 28),
                const SizedBox(height: 10),
                Text(
                  'REST PERIOD ACTIVE', 
                  style: TextStyle(color: Colors.orange.shade900, fontWeight: FontWeight.w900, letterSpacing: 1),
                ),
                Text(
                  'You will be eligible to donate again in $restDays days.',
                  style: TextStyle(color: Colors.orange.shade800, fontSize: 13, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          );
        }

        return SizedBox(
          width: double.infinity,
          height: 60,
          child: ElevatedButton(
            onPressed: _acceptRequest,
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              elevation: 0,
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('ACCEPT REQUEST', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
                SizedBox(width: 15),
                Icon(Icons.volunteer_activism, size: 24),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSecurityNotice() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: const Color(0xFF1F2937), borderRadius: BorderRadius.circular(20)),
      child: const Row(
        children: [
          Icon(Icons.security_outlined, color: Colors.white70, size: 20),
          SizedBox(width: 15),
          Expanded(child: Text('Your safety is our priority. Please confirm all details with the hospital staff before donating.', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }
}
