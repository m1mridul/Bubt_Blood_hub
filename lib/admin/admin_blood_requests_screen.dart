import 'package:blood_hub/user/request_details_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;

class AdminBloodRequestsScreen extends StatefulWidget {
  const AdminBloodRequestsScreen({super.key});

  @override
  State<AdminBloodRequestsScreen> createState() => _AdminBloodRequestsScreenState();
}

class _AdminBloodRequestsScreenState extends State<AdminBloodRequestsScreen> {
  String _selectedFilter = 'TOTAL'; // TOTAL, ACTIVE, ACCEPTED, EXPIRED, CERTIFIED

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
    final isDesktop = size.width > 900;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Request Management', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontFamily: 'Manrope')),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('blood_requests').orderBy('timestamp', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFFE53935)));
          }
          
          final now = DateTime.now();
          final allDocs = snapshot.data?.docs ?? [];
          
          // Categorization
          final activeDocs = allDocs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final Timestamp? expiry = data['expiryTimestamp'];
            bool isExpired = expiry != null && expiry.toDate().isBefore(now);
            return data['status'] == 'active' && !isExpired;
          }).toList();

          final acceptedDocs = allDocs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final String status = data['status'] ?? '';
            return status == 'accepted' || status == 'certified' || status == 'pending_certification';
          }).toList();
          
          final certifiedDocs = allDocs.where((doc) => (doc.data() as Map<String, dynamic>)['status'] == 'certified').toList();

          final expiredDocs = allDocs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final Timestamp? expiry = data['expiryTimestamp'];
            bool isExpired = expiry != null && expiry.toDate().isBefore(now);
            return data['status'] == 'active' && isExpired;
          }).toList();

          // Filter Selection
          List<QueryDocumentSnapshot> displayedRequests = [];
          if (_selectedFilter == 'ACTIVE') displayedRequests = activeDocs;
          else if (_selectedFilter == 'ACCEPTED') displayedRequests = acceptedDocs;
          else if (_selectedFilter == 'CERTIFIED') displayedRequests = certifiedDocs;
          else if (_selectedFilter == 'EXPIRED') displayedRequests = expiredDocs;
          else displayedRequests = allDocs;

          return Column(
            children: [
              _buildStatsHeader(isDesktop, allDocs.length, activeDocs.length, acceptedDocs.length, expiredDocs.length, certifiedDocs.length),
              Expanded(
                child: displayedRequests.isEmpty
                    ? Center(child: Text('No $_selectedFilter requests found.', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)))
                    : GridView.builder(
                        padding: EdgeInsets.symmetric(horizontal: isDesktop ? size.width * 0.1 : 20, vertical: 30),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: isDesktop ? 3 : 1,
                          childAspectRatio: 0.95,
                          crossAxisSpacing: 25,
                          mainAxisSpacing: 25,
                        ),
                        itemCount: displayedRequests.length,
                        itemBuilder: (context, index) {
                          final doc = displayedRequests[index];
                          final data = doc.data() as Map<String, dynamic>;
                          return _buildAdminCard(context, doc.id, data, now);
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatsHeader(bool isDesktop, int total, int active, int accepted, int expired, int certified) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: isDesktop ? 100 : 20, vertical: 25),
      decoration: BoxDecoration(color: Colors.white, border: Border(bottom: BorderSide(color: Colors.black.withOpacity(0.05)))),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _statusBadge('TOTAL', total.toString(), Colors.blue, 'TOTAL'),
            const SizedBox(width: 15),
            _statusBadge('ACTIVE', active.toString(), Colors.red, 'ACTIVE'),
            const SizedBox(width: 15),
            _statusBadge('ACCEPTED', accepted.toString(), Colors.green, 'ACCEPTED'),
            const SizedBox(width: 15),
            _statusBadge('CERTIFIED', certified.toString(), Colors.purple, 'CERTIFIED'),
            const SizedBox(width: 15),
            _statusBadge('EXPIRED', expired.toString(), Colors.orange, 'EXPIRED'),
          ],
        ),
      ),
    );
  }

  Widget _statusBadge(String label, String count, Color color, String filterType) {
    bool isActive = _selectedFilter == filterType;
    return InkWell(
      onTap: () => setState(() => _selectedFilter = filterType),
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(color: isActive ? color : color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
        child: Row(children: [
          Text(label, style: TextStyle(color: isActive ? Colors.white : color, fontSize: 11, fontWeight: FontWeight.w900)),
          const SizedBox(width: 10),
          Text(count, style: TextStyle(color: isActive ? Colors.white : color, fontSize: 16, fontWeight: FontWeight.w900)),
        ]),
      ),
    );
  }

  Widget _buildAdminCard(BuildContext context, String id, Map<String, dynamic> data, DateTime now) {
    final String bloodGroup = data['bloodGroup'] ?? 'N/A';
    final String status = data['status'] ?? 'active';
    final Timestamp? expiry = data['expiryTimestamp'];
    final Color groupColor = _getColorForBloodGroup(bloodGroup);

    bool isActuallyExpired = status == 'active' && expiry != null && expiry.toDate().isBefore(now);
    
    String timerText = "";
    if (expiry != null) {
      final diff = expiry.toDate().difference(now);
      timerText = diff.isNegative ? "Time Over" : "${diff.inHours}h ${diff.inMinutes.remainder(60)}m left";
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(25), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: isActuallyExpired ? Colors.orange : (status == 'active' ? Colors.red : (status == 'certified' ? Colors.purple : Colors.green)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(isActuallyExpired ? 'EXPIRED' : status.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w900)),
              ),
              if (status == 'active') Text(timerText, style: const TextStyle(color: Colors.black38, fontSize: 10, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Container(width: 60, height: 60, decoration: BoxDecoration(color: groupColor.withOpacity(0.1), borderRadius: BorderRadius.circular(15)), child: Center(child: Text(bloodGroup, style: TextStyle(color: groupColor, fontSize: 24, fontWeight: FontWeight.w900)))),
              const SizedBox(width: 15),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Need for $bloodGroup', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                Text('@${data['username']}', style: TextStyle(color: groupColor, fontSize: 12, fontWeight: FontWeight.bold)),
              ])),
            ],
          ),
          const SizedBox(height: 15),
          _infoLine(Icons.local_hospital_outlined, data['hospitalName'] ?? 'N/A'),
          _infoLine(Icons.location_on_outlined, data['location']?.toString() ?? 'N/A'),
          const Spacer(),
          Row(
            children: [
              Expanded(child: ElevatedButton(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (c) => RequestDetailsScreen(requestId: id, isAdminView: true))),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF3F4F6), foregroundColor: Colors.black, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: const Text('View Details'),
              )),
              const SizedBox(width: 10),
              IconButton(onPressed: () => FirebaseFirestore.instance.collection('blood_requests').doc(id).delete(), icon: const Icon(Icons.delete_outline, color: Colors.red)),
            ],
          )
        ],
      ),
    );
  }

  Widget _infoLine(IconData i, String t) => Padding(padding: const EdgeInsets.only(bottom: 6), child: Row(children: [Icon(i, size: 16, color: Colors.black38), const SizedBox(width: 10), Expanded(child: Text(t, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black54, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis))]));
}
