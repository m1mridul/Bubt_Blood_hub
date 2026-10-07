import 'package:blood_hub/user/request_details_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;

class EmergencyRequestListScreen extends StatelessWidget {
  const EmergencyRequestListScreen({super.key});

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

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 1000;

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
              TextSpan(text: 'Emergency ', style: TextStyle(color: Colors.black, fontSize: 24, fontWeight: FontWeight.w800, fontFamily: 'Manrope')),
              TextSpan(text: 'Requests', style: TextStyle(color: Color(0xFFE53935), fontSize: 24, fontWeight: FontWeight.w800, fontFamily: 'Manrope')),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          _buildHeaderBanner(isDesktop, size),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('blood_requests')
                  .orderBy('timestamp', descending: true)
                  .snapshots(), // Fetch all sorted by time
              builder: (context, snapshot) {
                if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Color(0xFFE53935)));
                }

                final currentUid = FirebaseAuth.instance.currentUser?.uid;

                // Filter for 'active' and 'not expired' in-memory
                final allDocs = snapshot.data?.docs ?? [];
                final now = DateTime.now();
                
                final requests = allDocs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final Timestamp? expiry = data['expiryTimestamp'];
                  bool isExpired = expiry != null && expiry.toDate().isBefore(now);
                  return data['status'] == 'active' && !isExpired;
                }).toList();

                if (requests.isEmpty) return _buildEmptyState();

                return GridView.builder(
                  padding: EdgeInsets.symmetric(horizontal: isDesktop ? size.width * 0.08 : 20, vertical: 30),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: isDesktop ? 3 : 1,
                    childAspectRatio: 0.9,
                    crossAxisSpacing: 25,
                    mainAxisSpacing: 25,
                  ),
                  itemCount: requests.length,
                  itemBuilder: (context, index) {
                    final request = requests[index];
                    final data = request.data() as Map<String, dynamic>;
                    bool isBankRequest = data['isBankRequest'] ?? false;
                    bool isOwnRequest = currentUid != null && data['postedBy'] == currentUid;

                    if (isBankRequest) {
                      return _buildBankRequestCard(context, request.id, data, isOwnRequest);
                    } else {
                      return _buildPremiumRequestCard(context, request.id, data, isOwnRequest);
                    }
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderBanner(bool isDesktop, Size size) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: isDesktop ? 100 : 20, vertical: 30),
      decoration: BoxDecoration(color: Colors.white, border: Border(bottom: BorderSide(color: Colors.black.withOpacity(0.05)))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Live Urgent Needs', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFFE53935))),
          const SizedBox(height: 8),
          Text('Browse active requests from users and blood banks.', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey.shade600)),
        ],
      ),
    );
  }

  Widget _buildBankRequestCard(BuildContext context, String id, Map<String, dynamic> data, bool isOwnRequest) {
    final String bloodGroup = data['bloodGroup'] ?? 'N/A';
    final String bankName = data['hospitalName'] ?? 'Blood Bank';
    final Timestamp? expiry = data['expiryTimestamp'];
    
    // Calculate Remaining Time
    String remainingTime = "";
    if (expiry != null) {
      final diff = expiry.toDate().difference(DateTime.now());
      remainingTime = "${diff.inHours}h remaining";
    }

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7F7),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: const Color(0xFF7C2D12).withOpacity(0.3), width: 2),
        boxShadow: [BoxShadow(color: Colors.brown.withOpacity(0.05), blurRadius: 20)],
      ),
      child: Stack(
        children: [
          Positioned(top: 15, right: 15, child: Text(remainingTime, style: const TextStyle(color: Colors.brown, fontSize: 10, fontWeight: FontWeight.bold))),
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isOwnRequest)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 8.0),
                    child: Text('ℹ️ This is your own request', style: TextStyle(color: Colors.brown, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(color: const Color(0xFF7C2D12), borderRadius: BorderRadius.circular(10)),
                      child: const Text('BLOOD BANK REQUEST', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w900)),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(bankName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF7C2D12))),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 16, color: Colors.brown),
                    const SizedBox(width: 8),
                    Expanded(child: Text(data['location'] ?? 'Address', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.brown, fontSize: 13))),
                  ],
                ),
                const SizedBox(height: 15),
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
                  child: Row(
                    children: [
                      const Text('REQUIRED GROUP:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
                      const Spacer(),
                      Text(bloodGroup, style: const TextStyle(color: Color(0xFFE53935), fontSize: 24, fontWeight: FontWeight.w900)),
                    ],
                  ),
                ),
                const Spacer(),
                if (!isOwnRequest)
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (c) => RequestDetailsScreen(requestId: id))),
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF7C2D12), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                      child: const Text('RESPOND TO BANK', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumRequestCard(BuildContext context, String id, Map<String, dynamic> data, bool isOwnRequest) {
    final String bloodGroup = data['bloodGroup'] ?? 'N/A';
    final String hospital = data['hospitalName'] ?? 'Hospital';
    final String requesterUsername = data['username'] ?? 'user';
    final String requestType = data['requestType'] ?? 'Regular';
    final Timestamp? expiry = data['expiryTimestamp'];
    String location = data['location']?.toString() ?? 'Unknown Location';
    final Timestamp? timestamp = data['timestamp'];
    final String timeStr = timestamp != null ? timeago.format(timestamp.toDate()) : 'Just now';
    final Color groupColor = _getColorForBloodGroup(bloodGroup);

    // Calculate Remaining Time
    String remainingTime = "Expired";
    if (expiry != null) {
      final diff = expiry.toDate().difference(DateTime.now());
      if (diff.inHours > 0) {
        remainingTime = "${diff.inHours}h ${diff.inMinutes.remainder(60)}m remaining";
      } else if (diff.inMinutes > 0) {
        remainingTime = "${diff.inMinutes}m remaining";
      }
    }

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [BoxShadow(color: groupColor.withOpacity(0.05), blurRadius: 25, offset: const Offset(0, 10))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isOwnRequest)
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Text('ℹ️ This is your own request', style: TextStyle(color: groupColor, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 65, height: 65,
                  decoration: BoxDecoration(color: groupColor.withOpacity(0.1), borderRadius: BorderRadius.circular(18)),
                  child: Center(child: Text(bloodGroup, style: TextStyle(color: groupColor, fontSize: 26, fontWeight: FontWeight.w900))),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: requestType == 'Very Emergency' ? Colors.red : Colors.blue,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(requestType.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 5),
                    Text(remainingTime, style: TextStyle(color: requestType == 'Very Emergency' ? Colors.red : Colors.blue, fontSize: 10, fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text('Urgent need for $bloodGroup', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF1F2937))),
            Text('@$requesterUsername', style: TextStyle(color: groupColor, fontWeight: FontWeight.w800, fontSize: 13)),
            const SizedBox(height: 15),
            _infoRow(Icons.local_hospital_outlined, hospital),
            _infoRow(Icons.location_on_outlined, location),
            const Spacer(),
            if (!isOwnRequest)
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (c) => RequestDetailsScreen(requestId: id))),
                  style: ElevatedButton.styleFrom(backgroundColor: groupColor, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                  child: const Text('View Details', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.black38),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black54, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.bloodtype_outlined, size: 100, color: Colors.grey.shade300),
          const SizedBox(height: 20),
          Text('No active emergency requests', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.grey.shade400)),
        ],
      ),
    );
  }
}
