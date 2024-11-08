import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class Medicine {
  final String id;
  final String name;
  final double price;

  Medicine({
    required this.id,
    required this.name,
    required this.price,
  });
}

class PrescriptionScreen extends StatefulWidget {
  final String patientId;
  final String patientName;
  final String existingPrescription;

  const PrescriptionScreen({
    Key? key,
    required this.patientId,
    required this.patientName,
    required this.existingPrescription,
  }) : super(key: key);

  @override
  _PrescriptionScreenState createState() => _PrescriptionScreenState();
}

class _PrescriptionScreenState extends State<PrescriptionScreen> {
  final _supabase = Supabase.instance.client;
  late TextEditingController _prescriptionController;
  List<Medicine> _medicines = [];
  List<Medicine> _selectedMedicines = [];
  bool _isLoading = true;
  Medicine? _selectedMedicine;

  @override
  void initState() {
    super.initState();
    _prescriptionController =
        TextEditingController(text: widget.existingPrescription);
    _fetchMedicines();
  }

  Future<void> _fetchMedicines() async {
    try {
      final response =
          await _supabase.from('medicinesinventory').select('id, name, price');

      print('Fetched medicines: $response'); // Debug print

      if (response != null) {
        setState(() {
          _medicines = (response as List<dynamic>)
              .map((item) => Medicine(
                    id: item['id'].toString(),
                    name: item['name'],
                    price: (item['price'] as num).toDouble(),
                  ))
              .toList();
          _isLoading = false;
        });
        print('Processed medicines: $_medicines'); // Debug print
      } else {
        print('Response is null'); // Debug print
      }
    } catch (e) {
      print('Error fetching medicines: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to fetch medicines: ${e.toString()}')),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _addMedicine() {
    if (_selectedMedicine != null &&
        !_selectedMedicines.contains(_selectedMedicine)) {
      setState(() {
        _selectedMedicines.add(_selectedMedicine!);
        _selectedMedicine = null;
      });
    }
  }

  void _removeMedicine(Medicine medicine) {
    setState(() {
      _selectedMedicines.remove(medicine);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text('Prescription for ${widget.patientName}'),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                DropdownButton<Medicine>(
                  isExpanded: true,
                  value: _selectedMedicine,
                  hint: Text("Select a medicine"),
                  items: _medicines.map((Medicine medicine) {
                    return DropdownMenuItem<Medicine>(
                      value: medicine,
                      child: Text(medicine.name),
                    );
                  }).toList(),
                  onChanged: (Medicine? newValue) {
                    setState(() {
                      _selectedMedicine = newValue;
                    });
                  },
                ),
                SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _addMedicine,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Add Medicine',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 20),
                Text(
                  'Selected Medicines:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                ..._selectedMedicines.map((m) => ListTile(
                      title: Text(m.name),
                      subtitle: Text('Price: \₹${m.price.toStringAsFixed(2)}'),
                      trailing: IconButton(
                        icon: Icon(Icons.remove_circle_outline),
                        onPressed: () => _removeMedicine(m),
                      ),
                    )),
                SizedBox(height: 20),
                TextField(
                  controller: _prescriptionController,
                  maxLines: 10,
                  decoration: InputDecoration(
                    hintText: 'Enter prescription details...',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _savePrescription,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Save Prescription',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Future<void> _savePrescription() async {
    try {
      // Prepare the medicines array
      List<int> medicineIds = [];
      for (var medicine in _selectedMedicines) {
        try {
          medicineIds.add(int.parse(medicine.id));
        } catch (e) {
          print('Error parsing medicine ID: ${medicine.id}');
          // You might want to show an error message to the user here
        }
      }

      // Save prescription details
      await _supabase.from('prescriptions').insert({
        'patientId': widget.patientId,
        'prescription': _prescriptionController.text,
        'medicines': medicineIds,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Prescription saved successfully'),
          backgroundColor: Colors.blue,
        ),
      );
      Navigator.pop(context); // Return to previous screen
    } catch (e) {
      print('Error saving prescription: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save prescription: ${e.toString()}')),
      );
    }
  }

  @override
  void dispose() {
    _prescriptionController.dispose();
    super.dispose();
  }
}
