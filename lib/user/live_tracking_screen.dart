import 'dart:async';
import 'package:blood_hub/user/chat_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart'; // Corrected import
import 'package:location/location.dart';

class LiveTrackingScreen extends StatefulWidget {
  final String requestId;
  const LiveTrackingScreen({super.key, required this.requestId});

  @override
  State<LiveTrackingScreen> createState() => _LiveTrackingScreenState();
}

class _LiveTrackingScreenState extends State<LiveTrackingScreen> {
  final MapController _mapController = MapController();
  final Location _location = Location();
  StreamSubscription<LocationData>? _locationSubscription;

  Map<String, dynamic>? _requestData;
  Map<String, dynamic>? _requesterData;
  Map<String, dynamic>? _donorData; 
  LatLng? _requesterLocation;
  LatLng? _donorLocation;

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchAllData();
  }

  Future<void> _fetchAllData() async {
    try {
      final requestDoc = await FirebaseFirestore.instance.collection('blood_requests').doc(widget.requestId).get();
      if (!requestDoc.exists) throw Exception("Request not found");
      
      final requestData = requestDoc.data()!;
      final requesterId = requestData['postedBy'];
      final donorId = requestData['acceptedBy'];

      final requesterUserDoc = await FirebaseFirestore.instance.collection('users').doc(requesterId).get();
      final donorUserDoc = await FirebaseFirestore.instance.collection('users').doc(donorId).get();

      if (!requesterUserDoc.exists || !donorUserDoc.exists) throw Exception("User not found");
      
      setState(() {
        _requestData = requestData;
        _requesterData = requesterUserDoc.data();
        _donorData = donorUserDoc.data();
        _requesterLocation = LatLng(requestData['requesterLatitude'] ?? 23.8103, requestData['requesterLongitude'] ?? 90.4125);
        _isLoading = false;
      });

      _listenToDonorLocation();

    } catch (e) {
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
        setState(() => _isLoading = false);
      }
    }
  }

  void _listenToDonorLocation() {
    _locationSubscription = _location.onLocationChanged.listen((LocationData currentLocation) {
      if (mounted && currentLocation.latitude != null && currentLocation.longitude != null) {
        setState(() {
          _donorLocation = LatLng(currentLocation.latitude!, currentLocation.longitude!);
        });
        _mapController.move(_donorLocation!, 14.0);
      }
    });
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    super.dispose();
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
        title: Text.rich(
          const TextSpan(
            children: [
              TextSpan(text: 'Live ', style: TextStyle(color: Colors.black, fontSize: 22, fontWeight: FontWeight.w800, fontFamily: 'Manrope')),
              TextSpan(text: 'Tracking', style: TextStyle(color: Color(0xFFE53935), fontSize: 22, fontWeight: FontWeight.w800, fontFamily: 'Manrope')),
            ],
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFE53935)))
          : Row(
              children: [
                Expanded(
                  flex: isDesktop ? 2 : 1,
                  child: Container(
                    margin: const EdgeInsets.all(20),
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20)],
                    ),
                    child: FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter: _requesterLocation ?? LatLng(23.8103, 90.4125),
                        initialZoom: 14.0,
                      ),
                      children: [
                        TileLayer(
                          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.example.blood_hub',
                        ),
                        MarkerLayer(
                          markers: [
                            if (_requesterLocation != null)
                              Marker(
                                point: _requesterLocation!,
                                width: 80,
                                height: 80,
                                child: const Icon(Icons.location_on, color: Colors.red, size: 40),
                              ),
                            if (_donorLocation != null)
                              Marker(
                                point: _donorLocation!,
                                width: 80,
                                height: 80,
                                child: const Icon(Icons.directions_bike, color: Colors.green, size: 40),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                if (isDesktop) 
                  Expanded(
                    flex: 1,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(0, 20, 30, 20),
                      child: _buildDetailsPanel(),
                    ),
                  ),
              ],
            ),
      bottomNavigationBar: !isDesktop ? Container(
        height: 350,
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: _buildDetailsPanel(),
      ) : null,
    );
  }

  Widget _buildDetailsPanel() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 30)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Contact Information', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF1F2937))),
          const SizedBox(height: 10),
          const Text('Get in touch with the requester to coordinate.', style: TextStyle(color: Colors.black38, fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 40),
          _infoTile(Icons.person_outline, 'Full Name', _requesterData?['fullName'] ?? 'N/A'),
          const SizedBox(height: 20),
          _infoTile(Icons.phone_outlined, 'Contact Number', _requestData?['contact'] ?? 'N/A'),
          const SizedBox(height: 20),
          _infoTile(Icons.local_hospital_outlined, 'Hospital', _requestData?['hospitalName'] ?? 'N/A'),
          const Spacer(),
          
          // MESSAGE PROMPT
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('chats')
                .doc(widget.requestId)
                .collection('messages')
                .orderBy('timestamp', descending: true)
                .limit(1)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                final lastMsg = snapshot.data!.docs.first.data() as Map<String, dynamic>;
                final currentUid = FirebaseAuth.instance.currentUser?.uid;
                
                // If the last message is from the other person
                if (lastMsg['senderId'] != currentUid) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 15),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFCEBEB),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE53935).withOpacity(0.2)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.mark_chat_unread_rounded, color: Color(0xFFE53935), size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            '@${_requesterData?['username'] ?? 'Requester'} messaged you. Please reply!',
                            style: const TextStyle(color: Color(0xFFE53935), fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  );
                }
              }
              return const SizedBox.shrink();
            },
          ),

          SizedBox(
            width: double.infinity,
            height: 60,
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => ChatScreen(requestId: widget.requestId)),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE53935),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                elevation: 0,
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Start Conversation', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                  SizedBox(width: 12),
                  Icon(Icons.chat_bubble_outline_rounded, size: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoTile(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: const Color(0xFFE53935), size: 22),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: Colors.black38, fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF374151))),
            ],
          ),
        ),
      ],
    );
  }
}
