import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class BloodBankPostRequestScreen extends StatefulWidget {
  final String bankEmail;
  const BloodBankPostRequestScreen({super.key, required this.bankEmail});

  @override
  State<BloodBankPostRequestScreen> createState() => _BloodBankPostRequestScreenState();
}

class _BloodBankPostRequestScreenState extends State<BloodBankPostRequestScreen> {
  String? _selectedBloodGroup;
  final _bankNameController = TextEditingController();
  final _addressController = TextEditingController();
  final _mobileController = TextEditingController();
  final _requirementController = TextEditingController();
  bool _isLoading = false;

  final List<String> _bloodGroups = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];

  Future<void> _submitBankRequest() async {
    if (_selectedBloodGroup == null || _bankNameController.text.isEmpty || _mobileController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields.'), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await FirebaseFirestore.instance.collection('blood_requests').add({
        'bloodGroup': _selectedBloodGroup,
        'hospitalName': _bankNameController.text.trim(),
        'location': _addressController.text.trim(),
        'contact': _mobileController.text.trim(),
        'notes': _requirementController.text.trim(),
        'postedBy': widget.bankEmail,
        'username': 'Blood Bank Official',
        'isBankRequest': true, // Identifying as a Blood Bank request
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'active',
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bank request posted successfully!'), backgroundColor: Colors.brown),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF2F2),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Post Bank Request', style: TextStyle(color: Color(0xFF7C2D12), fontWeight: FontWeight.bold)),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 600),
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(30)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Create Official Blood Requirement', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF7C2D12))),
                const SizedBox(height: 30),
                _buildField(_bankNameController, 'Blood Bank Name', Icons.business),
                const SizedBox(height: 20),
                _buildBloodGroupGrid(),
                const SizedBox(height: 20),
                _buildField(_addressController, 'Detailed Address', Icons.location_on),
                const SizedBox(height: 20),
                _buildField(_mobileController, 'Mobile Number', Icons.phone, type: TextInputType.phone),
                const SizedBox(height: 20),
                _buildField(_requirementController, 'Special Requirements', Icons.notes, maxLines: 3),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submitBankRequest,
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF7C2D12), foregroundColor: Colors.white),
                    child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('POST REQUEST TO USERS', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField(TextEditingController c, String h, IconData i, {int maxLines = 1, TextInputType type = TextInputType.text}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(h, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.brown)),
        const SizedBox(height: 8),
        TextField(
          controller: c, maxLines: maxLines, keyboardType: type,
          decoration: InputDecoration(
            prefixIcon: Icon(i, color: Colors.brown.shade200),
            hintText: 'Enter $h',
            filled: true, fillColor: const Color(0xFFF9FAFB),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
        ),
      ],
    );
  }

  Widget _buildBloodGroupGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Required Blood Group', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.brown)),
        const SizedBox(height: 10),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _bloodGroups.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4, crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 1.8),
          itemBuilder: (context, index) {
            final group = _bloodGroups[index];
            final isSelected = _selectedBloodGroup == group;
            return InkWell(
              onTap: () => setState(() => _selectedBloodGroup = group),
              child: Container(
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF7C2D12) : const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(child: Text(group, style: TextStyle(color: isSelected ? Colors.white : Colors.brown, fontWeight: FontWeight.bold))),
              ),
            );
          },
        ),
      ],
    );
  }
}
