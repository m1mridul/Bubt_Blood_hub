import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class UpdateBloodUnitsScreen extends StatefulWidget {
  const UpdateBloodUnitsScreen({super.key});

  @override
  State<UpdateBloodUnitsScreen> createState() => _UpdateBloodUnitsScreenState();
}

class _UpdateBloodUnitsScreenState extends State<UpdateBloodUnitsScreen> {
  final List<String> _bloodGroups = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];
  final Map<String, int> _tempUnits = {}; // To store local changes before saving

  Future<void> _saveUnits(String group, int units) async {
    String status = "Stable";
    if (units < 20) status = "Critical";
    else if (units < 50) status = "Low";

    try {
      await FirebaseFirestore.instance.collection('blood_inventory').doc(group).set({
        'units': units,
        'status': status,
        'lastUpdated': FieldValue.serverTimestamp(),
      });
      setState(() {
        _tempUnits.remove(group); // Clear local temp state after successful save
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$group units updated to $units ($status)'), backgroundColor: Colors.green));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
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
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.black), onPressed: () => Navigator.pop(context)),
        title: const Text('Inventory Management', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('blood_inventory').snapshots(),
        builder: (context, snapshot) {
          Map<String, dynamic> dbData = {};
          if (snapshot.hasData) {
            for (var doc in snapshot.data!.docs) {
              dbData[doc.id] = doc.data();
            }
          }

          return SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: isDesktop ? size.width * 0.1 : 20, vertical: 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Blood Stock Control', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
                const SizedBox(height: 10),
                const Text('Increment or decrement units and click update to save.', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                const SizedBox(height: 40),
                
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _bloodGroups.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: isDesktop ? 2 : 1,
                    mainAxisSpacing: 25,
                    crossAxisSpacing: 25,
                    childAspectRatio: 3.2,
                  ),
                  itemBuilder: (context, index) {
                    final group = _bloodGroups[index];
                    final int dbUnits = dbData[group]?['units'] ?? 0;
                    // Use local temp value if user changed it, otherwise use DB value
                    final int currentDisplayUnits = _tempUnits.containsKey(group) ? _tempUnits[group]! : dbUnits;
                    
                    bool hasChanged = _tempUnits.containsKey(group) && _tempUnits[group] != dbUnits;

                    return Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(25),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 15)],
                        border: hasChanged ? Border.all(color: const Color(0xFFE53935).withOpacity(0.3), width: 1.5) : null,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 65, height: 65,
                            decoration: BoxDecoration(color: const Color(0xFFFCEBEB), borderRadius: BorderRadius.circular(18)),
                            child: Center(child: Text(group, style: const TextStyle(color: Color(0xFFE53935), fontSize: 24, fontWeight: FontWeight.w900))),
                          ),
                          const SizedBox(width: 25),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text('Available Stock', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 12)),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    _counterBtn(Icons.remove, () {
                                      setState(() {
                                        _tempUnits[group] = (currentDisplayUnits > 0) ? currentDisplayUnits - 1 : 0;
                                      });
                                    }),
                                    const SizedBox(width: 15),
                                    Text('$currentDisplayUnits', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
                                    const SizedBox(width: 15),
                                    _counterBtn(Icons.add, () {
                                      setState(() {
                                        _tempUnits[group] = currentDisplayUnits + 1;
                                      });
                                    }),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          ElevatedButton(
                            onPressed: hasChanged ? () => _saveUnits(group, currentDisplayUnits) : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1F2937), 
                              foregroundColor: Colors.white, 
                              disabledBackgroundColor: Colors.grey.shade100,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                              elevation: 0,
                            ),
                            child: Text('UPDATE', style: TextStyle(fontWeight: FontWeight.bold, color: hasChanged ? Colors.white : Colors.grey)),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _counterBtn(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 20, color: const Color(0xFF1F2937)),
      ),
    );
  }
}
