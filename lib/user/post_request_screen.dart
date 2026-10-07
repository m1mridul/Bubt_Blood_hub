import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:location/location.dart';

class PostRequestScreen extends StatefulWidget {
  const PostRequestScreen({super.key});

  @override
  State<PostRequestScreen> createState() => _PostRequestScreenState();
}

class _PostRequestScreenState extends State<PostRequestScreen> {
  String? _selectedBloodGroup;
  final _hospitalController = TextEditingController();
  final _specificAddressController = TextEditingController();
  final _contactController = TextEditingController();
  final _notesController = TextEditingController();
  bool _isLoading = false;
  String? _contactError;

  // Request Type
  String _selectedRequestType = 'Regular'; // Default

  // Address State
  String? _selectedDivision;
  String? _selectedDistrict;
  String? _selectedCity;
  String? _selectedArea;
  String? _selectedSubArea;

  final List<String> _bloodGroups = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];
  
  // Basic Data Structure (Can be expanded)
  final List<String> _divisions = ['Dhaka', 'Chattogram', 'Rajshahi', 'Khulna', 'Barishal', 'Sylhet', 'Rangpur', 'Mymensingh'];
  
  final Map<String, List<String>> _districts = {
    'Dhaka': ['Dhaka', 'Gazipur', 'Narayanganj', 'Tangail', 'Manikganj'],
    'Chattogram': ['Chattogram', 'Cox\'s Bazar', 'Cumilla', 'Feni'],
  };

  final Map<String, List<String>> _cities = {
    'Dhaka': ['Dhaka City', 'Savar', 'Dhamrai', 'Keraniganj'],
    'Gazipur': ['Gazipur Sadar', 'Kaliakair', 'Sreepur'],
  };

  final Map<String, List<String>> _areas = {
    'Dhaka City': ['Mirpur', 'Uttara', 'Gulshan', 'Dhanmondi', 'Mohammadpur', 'Badda', 'Motijheel'],
  };

  final Map<String, List<String>> _subAreas = {
    'Mirpur': ['Mirpur-1', 'Mirpur-2', 'Mirpur-10', 'Mirpur-11', 'Mirpur-12', 'Pallabi'],
    'Uttara': ['Sector-1', 'Sector-3', 'Sector-7', 'Sector-10', 'Sector-14'],
  };

  final List<String> _dhakaHospitals = [
    'Dhaka Medical College Hospital',
    'Bangabandhu Sheikh Mujib Medical University (BSMMU)',
    'Birdem General Hospital',
    'Square Hospital',
    'Evercare Hospital Dhaka',
    'United Hospital',
    'Labaid Specialized Hospital',
    'Sir Salimullah Medical College Hospital',
    'Holy Family Red Crescent Hospital',
    'Kurmitola General Hospital',
  ];

  Future<void> _submitRequest() async {
    String hospitalName = _hospitalController.text.trim();
    String specific = _specificAddressController.text.trim();
    String contact = _contactController.text.trim();
    
    // Validate Hierarchy
    if (_selectedBloodGroup == null || hospitalName.isEmpty || _selectedDivision == null || 
        _selectedDistrict == null || _selectedCity == null || _selectedArea == null || contact.isEmpty || _contactError != null) {
      _showError('Please fill up all required fields correctly.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user!.uid).get();
      final String username = userDoc.data()?['username'] ?? "anonymous";

      // Combine full address string
      String fullAddress = "$specific, $_selectedSubArea, $_selectedArea, $_selectedCity, $_selectedDistrict, $_selectedDivision";

      // Calculate Expiry Time
      int validityHours = _selectedRequestType == 'Very Emergency' ? 24 : 48;
      DateTime expiryTime = DateTime.now().add(Duration(hours: validityHours));

      LocationData? currentLocation;
      try { currentLocation = await Location().getLocation(); } catch (e) { }

      await FirebaseFirestore.instance.collection('blood_requests').add({
        'bloodGroup': _selectedBloodGroup,
        'hospitalName': hospitalName,
        'location': fullAddress,
        'division': _selectedDivision,
        'district': _selectedDistrict,
        'city': _selectedCity,
        'area': _selectedArea,
        'subArea': _selectedSubArea,
        'contact': contact,
        'notes': _notesController.text.trim(),
        'postedBy': user.uid,
        'username': username,
        'timestamp': FieldValue.serverTimestamp(),
        'expiryTimestamp': Timestamp.fromDate(expiryTime),
        'requestType': _selectedRequestType,
        'status': 'active',
        'requesterLatitude': currentLocation?.latitude,
        'requesterLongitude': currentLocation?.longitude,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Request posted successfully!'), backgroundColor: Colors.green));
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String msg) {
    showDialog(context: context, builder: (c) => AlertDialog(title: const Text('Missing Info'), content: Text(msg), actions: [TextButton(onPressed: () => Navigator.pop(c), child: const Text('OK'))]));
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 900;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white, elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 20), onPressed: () => Navigator.of(context).pop()),
        title: const Text('Create Urgent Request', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900)),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: isDesktop ? size.width * 0.1 : 20, vertical: 40),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 3, child: _buildMainForm()),
            if (isDesktop) ...[
              const SizedBox(width: 40),
              Expanded(flex: 2, child: _buildSideInfo()),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildMainForm() {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(25), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 30)]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Required Blood Group *', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          _buildBloodGroupGrid(),
          const SizedBox(height: 40),

          const Text('Request Type (Urgency) *', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          _buildRequestTypeSelector(),
          const SizedBox(height: 40),
          
          const Text('Hospital Details *', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          _buildAutocompleteField(_hospitalController, _dhakaHospitals, 'Hospital Name'),
          const SizedBox(height: 25),

          const Text('Location Details (Step-by-Step) *', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          _buildLocationHierarchy(),
          const SizedBox(height: 20),
          _buildInputField(_specificAddressController, 'Road, House, Flat No.', Icons.home_outlined),

          const SizedBox(height: 40),
          const Text('Contact Information *', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          _buildInputField(
            _contactController, 
            'Mobile Number', 
            Icons.phone_outlined, 
            keyboardType: TextInputType.number,
            prefixText: '+880 ',
            errorText: _contactError,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(10),
            ],
            onChanged: (val) {
              setState(() {
                if (val.isNotEmpty && val.length < 10) {
                  _contactError = "Please type valid phone number";
                } else {
                  _contactError = null;
                }
              });
            },
          ),
          const SizedBox(height: 20),
          _buildInputField(_notesController, 'Special Instructions (Optional)', Icons.notes, maxLines: 3),
          
          const SizedBox(height: 50),
          SizedBox(
            width: double.infinity, height: 65,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _submitRequest,
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE53935), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
              child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('POST URGENT REQUEST', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 1)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationHierarchy() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildDropdown('Division', _divisions, _selectedDivision, (v) => setState(() { _selectedDivision = v; _selectedDistrict = null; _selectedCity = null; _selectedArea = null; _selectedSubArea = null; }))),
            const SizedBox(width: 15),
            Expanded(child: _buildDropdown('District', _districts[_selectedDivision] ?? [], _selectedDistrict, (v) => setState(() { _selectedDistrict = v; _selectedCity = null; _selectedArea = null; _selectedSubArea = null; }))),
          ],
        ),
        const SizedBox(height: 15),
        Row(
          children: [
            Expanded(child: _buildDropdown('City/Upazila', _cities[_selectedDistrict] ?? [], _selectedCity, (v) => setState(() { _selectedCity = v; _selectedArea = null; _selectedSubArea = null; }))),
            const SizedBox(width: 15),
            Expanded(child: _buildDropdown('Area', _areas[_selectedCity] ?? [], _selectedArea, (v) => setState(() { _selectedArea = v; _selectedSubArea = null; }))),
          ],
        ),
        const SizedBox(height: 15),
        _buildDropdown('Sub-Area / Block / Sector', _subAreas[_selectedArea] ?? [], _selectedSubArea, (v) => setState(() => _selectedSubArea = v)),
      ],
    );
  }

  Widget _buildDropdown(String hint, List<String> items, String? value, ValueChanged<String?> onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(color: const Color(0xFFF9FAFB), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE5E7EB))),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true, value: value, hint: Text(hint, style: const TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.bold)),
          items: items.map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)))).toList(),
          onChanged: items.isEmpty ? null : onChanged,
        ),
      ),
    );
  }

  Widget _buildAutocompleteField(TextEditingController controller, List<String> options, String hint) {
    return Autocomplete<String>(
      optionsBuilder: (textValue) => options.where((o) => o.toLowerCase().contains(textValue.text.toLowerCase())),
      onSelected: (s) => controller.text = s,
      fieldViewBuilder: (ctx, fController, node, onSub) {
        fController.addListener(() => controller.text = fController.text);
        return Container(
          decoration: BoxDecoration(color: const Color(0xFFF9FAFB), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE5E7EB))),
          child: TextField(
            controller: fController, focusNode: node,
            decoration: InputDecoration(prefixIcon: const Icon(Icons.search, size: 20), hintText: hint, border: InputBorder.none, contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 15)),
          ),
        );
      },
    );
  }

  Widget _buildBloodGroupGrid() {
    return GridView.builder(
      shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
      itemCount: _bloodGroups.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4, crossAxisSpacing: 15, mainAxisSpacing: 15, childAspectRatio: 2.2),
      itemBuilder: (context, index) {
        final g = _bloodGroups[index];
        bool sel = _selectedBloodGroup == g;
        return InkWell(
          onTap: () => setState(() => _selectedBloodGroup = g),
          child: Container(
            decoration: BoxDecoration(color: sel ? const Color(0xFFE53935) : Colors.white, borderRadius: BorderRadius.circular(15), border: Border.all(color: sel ? Colors.red : const Color(0xFFE5E7EB))),
            child: Center(child: Text(g, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: sel ? Colors.white : Colors.black87))),
          ),
        );
      },
    );
  }

  Widget _buildRequestTypeSelector() {
    return Row(
      children: [
        _requestTypeOption('Regular', 'Valid for 48 Hours', Icons.calendar_today_outlined, Colors.blue),
        const SizedBox(width: 20),
        _requestTypeOption('Very Emergency', 'Valid for 24 Hours', Icons.bolt_rounded, Colors.red),
      ],
    );
  }

  Widget _requestTypeOption(String title, String subtitle, IconData icon, Color color) {
    bool isSelected = _selectedRequestType == title;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedRequestType = title),
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isSelected ? color.withOpacity(0.05) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: isSelected ? color : const Color(0xFFE5E7EB), width: 2),
          ),
          child: Row(
            children: [
              Icon(icon, color: isSelected ? color : Colors.grey, size: 28),
              const SizedBox(width: 15),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(color: isSelected ? color : Colors.black87, fontWeight: FontWeight.w900, fontSize: 16)),
                  Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputField(TextEditingController c, String hint, IconData i, {int maxLines = 1, TextInputType? keyboardType, String? prefixText, String? errorText, List<TextInputFormatter>? inputFormatters, Function(String)? onChanged}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF9FAFB), 
            borderRadius: BorderRadius.circular(12), 
            border: Border.all(color: errorText != null ? Colors.red : const Color(0xFFE5E7EB))
          ),
          child: TextField(
            controller: c, maxLines: maxLines, keyboardType: keyboardType,
            inputFormatters: inputFormatters,
            onChanged: onChanged,
            decoration: InputDecoration(
              prefixIcon: Icon(i, size: 20), 
              prefixText: prefixText,
              prefixStyle: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
              hintText: hint, 
              border: InputBorder.none, 
              contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 15)
            ),
          ),
        ),
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(left: 12, top: 5),
            child: Text(errorText, style: const TextStyle(color: Colors.red, fontSize: 11, fontWeight: FontWeight.bold)),
          ),
      ],
    );
  }

  Widget _buildSideInfo() {
    return Container(
      padding: const EdgeInsets.all(32), decoration: BoxDecoration(color: const Color(0xFF1F2937), borderRadius: BorderRadius.circular(25)),
      child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(Icons.info_outline, color: Color(0xFFE53935), size: 40), SizedBox(height: 20),
        Text('Instructions', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)), SizedBox(height: 15),
        Text('• Follow the location steps carefully.\n• Provide precise house and road info.\n• Double check your contact number.\n• Be specific in requirements.', style: TextStyle(color: Colors.white70, height: 1.8, fontWeight: FontWeight.bold)),
      ]),
    );
  }
}
