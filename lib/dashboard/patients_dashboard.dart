import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

class PatientsDashboard extends StatefulWidget {
  static const routeName = '/patient';

  const PatientsDashboard({Key? key}) : super(key: key);

  @override
  _PatientsDashboardState createState() => _PatientsDashboardState();
}

class _PatientsDashboardState extends State<PatientsDashboard> {
  final _formKey = GlobalKey<FormState>();
  final _supabase = Supabase.instance.client;
  String _patientId = '';
  bool _isLoading = false;
  bool _isVerified = false;
  Map<String, dynamic>? _patientInfo;
  Map<String, dynamic>? _doctorInfo;
  Map<String, dynamic>? _roomInfo;

  @override
  void initState() {
    super.initState();
    _checkPatientVerification();
  }

  Future<void> _checkPatientVerification() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? storedPatientId = prefs.getString('patientId');
    setState(() {
      _patientId = storedPatientId;
      _isVerified = true;
    });
    await _fetchPatientInfo();
  }

  Future<void> _fetchPatientInfo() async {
    try {
      final patientResponse = await _supabase
          .from('patients')
          .select('name, email, phone, disease, appointdate, roomtake')
          .eq('id', _patientId)
          .single();

      if (patientResponse != null) {
        setState(() {
          _patientInfo = patientResponse;
        });

        // Fetch doctor information
        final List<dynamic> doctorResponse = await _supabase
            .from('doctor')
            .select('name, phone, patientappointId');

        if (doctorResponse.isNotEmpty) {
          for (var doctor in doctorResponse) {
            List<dynamic> patientAppointIds = doctor['patientappointId'] ?? [];
            if (patientAppointIds.contains(_patientId)) {
              setState(() {
                _doctorInfo = {
                  'name': doctor['name'],
                  'phone': doctor['phone']
                };
              });
              break;
            }
          }
        }

        // Fetch room information if roomtake is not null
        if (patientResponse['roomtake'] != null) {
          final roomResponse = await _supabase
              .from('roomsavailable')
              .select('name, number, floor')
              .eq('id', patientResponse['roomtake'])
              .single();

          if (roomResponse != null) {
            setState(() {
              _roomInfo = roomResponse;
            });
          }
        }
      }
    } catch (e) {
      print('Error fetching patient information: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text('Failed to fetch patient information: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text('Patient Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: _isVerified ? _buildDashboard() : _buildVerificationForm(),
    );
  }

  Widget _buildVerificationForm() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircleAvatar(
                radius: 30,
                backgroundColor: Colors.blue,
                child: Icon(Icons.verified, size: 30, color: Colors.white),
              ),
              SizedBox(height: 40),
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Patient ID',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your Patient ID';
                  }
                  return null;
                },
                onSaved: (value) {
                  _patientId = value!;
                },
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: _isLoading ? null : _verifyPatientId,
                child: Container(
                  width: double.infinity,
                  height: 50,
                  decoration: BoxDecoration(
                    color: _isLoading ? Colors.grey : Colors.blue,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: _isLoading
                        ? CircularProgressIndicator(color: Colors.white)
                        : Text(
                            'Verify Patient ID',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDashboard() {
    if (_patientInfo == null) {
      return Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(height: 40),
          const CircleAvatar(
            radius: 30,
            backgroundColor: Colors.blue,
            child: Icon(Icons.person, size: 30, color: Colors.white),
          ),
          SizedBox(height: 20),
          Text(
            '${_patientInfo!['name']}',
            style: const TextStyle(
                fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue),
          ),
          SizedBox(height: 40),
          Container(
            width: double.infinity,
            margin: EdgeInsets.symmetric(horizontal: 20),
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 2,
                  blurRadius: 5,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Patient Information',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 15),
                _buildInfoRow(Icons.phone, 'Phone', _patientInfo!['phone']),
                _buildInfoRow(Icons.email, 'Email', _patientInfo!['email']),
                _buildInfoRow(Icons.medical_services, 'Disease',
                    _patientInfo!['disease']),
                _buildInfoRow(Icons.calendar_today, 'Appointment Date',
                    _patientInfo!['appointdate']),
                if (_doctorInfo != null) ...[
                  SizedBox(height: 15),
                  Text(
                    'Doctor Information',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 10),
                  _buildInfoRow(
                      Icons.person, 'Doctor Name', _doctorInfo!['name']),
                  _buildInfoRow(
                      Icons.phone, 'Doctor Phone', _doctorInfo!['phone']),
                ],
                if (_roomInfo != null) ...[
                  SizedBox(height: 15),
                  Text(
                    'Room Booked',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 10),
                  _buildInfoRow(
                      Icons.meeting_room, 'Room Name', _roomInfo!['name']),
                  _buildInfoRow(Icons.confirmation_number, 'Room Number',
                      _roomInfo!['number']),
                  _buildInfoRow(Icons.layers, 'Floor', _roomInfo!['floor']),
                ],
              ],
            ),
          ),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      PrescriptionsScreen(patientId: _patientId),
                ),
              );
            },
            child: Text('View Prescriptions and Medicine'),
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: Colors.blue,
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, color: Colors.blue, size: 20),
          SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(fontSize: 14, color: Colors.grey)),
              Text(value, style: TextStyle(fontSize: 16)),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _verifyPatientId() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      setState(() {
        _isLoading = true;
      });

      try {
        final response = await _supabase
            .from('patients')
            .select()
            .eq('id', _patientId)
            .single();

        if (response != null) {
          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setString('patientId', _patientId);
          setState(() {
            _isVerified = true;
          });
          await _fetchPatientInfo();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Invalid Patient ID')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('An error occurred: ${e.toString()}')),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _logout() async {
    await _supabase.auth.signOut();
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('patientId');
    Navigator.of(context).pushReplacementNamed('/login');
  }
}

class PrescriptionsScreen extends StatefulWidget {
  final String patientId;

  const PrescriptionsScreen({Key? key, required this.patientId})
      : super(key: key);

  @override
  _PrescriptionsScreenState createState() => _PrescriptionsScreenState();
}

class _PrescriptionsScreenState extends State<PrescriptionsScreen> {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _prescriptions = [];
  bool _isLoading = true;
  String _patientName = '';
  String _patientEmail = '';
  bool _isPurchased = false;

  @override
  void initState() {
    super.initState();
    _fetchPrescriptions();
    _fetchPatientInfo();
  }

  Future<void> _fetchPrescriptions() async {
    try {
      final response = await _supabase
          .from('prescriptions')
          .select('id, prescription, medicines')
          .eq('patientId', widget.patientId);

      setState(() {
        _prescriptions = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Failed to fetch prescriptions: ${e.toString()}')),
      );
    }
  }

  Future<void> _fetchPatientInfo() async {
    try {
      final response = await _supabase
          .from('patients')
          .select('name, email, emailsentformedicines')
          .eq('id', widget.patientId)
          .single();

      setState(() {
        _patientName = response['name'];
        _patientEmail = response['email'];
        _isPurchased = response['emailsentformedicines'] ?? false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Failed to fetch patient info: ${e.toString()}')),
      );
    }
  }

  Future<void> _purchaseMedicines() async {
    String? address = await _showAddressDialog();
    if (address != null && address.isNotEmpty) {
      double totalAmount = 0;
      List<String> medicineNames = [];

      for (var prescription in _prescriptions) {
        List<dynamic> medicineIds = prescription['medicines'];
        final medicinesResponse = await _supabase
            .from('medicinesinventory')
            .select('name, price')
            .inFilter('id', medicineIds);

        for (var medicine in medicinesResponse) {
          totalAmount += medicine['price'];
          medicineNames.add(medicine['name']);
        }
      }

      bool emailSent =
          await _sendConfirmationEmail(address, totalAmount, medicineNames);

      if (emailSent) {
        await _updatePatientRecord();
        setState(() {
          _isPurchased = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text('Purchase successful! Check your email for details.')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Purchase successful, but failed to send confirmation email.')),
        );
      }
    }
  }

  Future<String?> _showAddressDialog() async {
    TextEditingController addressController = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Enter Delivery Address'),
          content: TextField(
            controller: addressController,
            decoration: InputDecoration(hintText: "Enter your address"),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: Text('Submit'),
              onPressed: () =>
                  Navigator.of(context).pop(addressController.text),
            ),
          ],
        );
      },
    );
  }

  Future<bool> _sendConfirmationEmail(
      String address, double totalAmount, List<String> medicineNames) async {
    String username = 'gsarvesh387@gmail.com'; // Replace with your email
    String password =
        'egfripivxkflstod'; // Replace with your email password or app password

    final smtpServer = gmail(username, password);

    final message = Message()
      ..from = Address(username, 'Medicine Delivery')
      ..recipients.add(_patientEmail)
      ..subject = 'Medicine Purchase Confirmation'
      ..html = '''
        <h1>Medicine Purchase Confirmation</h1>
        <p>Dear $_patientName,</p>
        <p>Your medicine purchase has been confirmed. Details are as follows:</p>
        <ul>
          <li><strong>Medicines:</strong> ${medicineNames.join(', ')}</li>
          <li><strong>Total Amount:</strong> ₹${totalAmount.toStringAsFixed(2)}</li>
          <li><strong>Delivery Address:</strong> $address</li>
        </ul>
        <p>Your medicines will be delivered within 1 hour.</p>
        <p>Thank you for your purchase!</p>
      ''';

    try {
      final sendReport = await send(message, smtpServer);
      print('Message sent: ' + sendReport.toString());
      return true;
    } catch (e) {
      print('Error sending email: $e');
      return false;
    }
  }

  Future<void> _updatePatientRecord() async {
    try {
      await _supabase
          .from('patients')
          .update({'emailsentformedicines': true}).eq('id', widget.patientId);
    } catch (e) {
      print('Error updating patient record: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Failed to update patient record: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text('Prescriptions and Medicine'),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: _prescriptions.isEmpty
                      ? Center(child: Text('No prescriptions found.'))
                      : ListView.builder(
                          itemCount: _prescriptions.length,
                          itemBuilder: (context, index) {
                            return PrescriptionItem(
                                prescription: _prescriptions[index]);
                          },
                        ),
                ),
                if (_prescriptions.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: ElevatedButton(
                      onPressed: _isPurchased ? null : _purchaseMedicines,
                      child: Text(_isPurchased
                          ? 'Medicine will be sent'
                          : 'Purchase Medicines'),
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor:
                            _isPurchased ? Colors.grey : Colors.blue,
                        padding:
                            EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}

class PrescriptionItem extends StatefulWidget {
  final Map<String, dynamic> prescription;

  const PrescriptionItem({Key? key, required this.prescription})
      : super(key: key);

  @override
  _PrescriptionItemState createState() => _PrescriptionItemState();
}

class _PrescriptionItemState extends State<PrescriptionItem> {
  bool _isExpanded = false;
  List<Map<String, dynamic>> _medicines = [];
  final _supabase = Supabase.instance.client;

  Future<void> _fetchMedicines() async {
    if (_medicines.isNotEmpty) return; // Fetch only once

    try {
      List<dynamic> medicineIds = widget.prescription['medicines'];
      final response = await _supabase
          .from('medicinesinventory')
          .select('id, name, price')
          .inFilter('id', medicineIds);

      setState(() {
        _medicines = List<Map<String, dynamic>>.from(response);
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to fetch medicines: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      margin: EdgeInsets.all(8),
      child: Column(
        children: [
          ListTile(
            title: Text('Prescription: ${widget.prescription['prescription']}'),
            trailing: IconButton(
              icon: Icon(_isExpanded ? Icons.expand_less : Icons.expand_more),
              onPressed: () {
                setState(() {
                  _isExpanded = !_isExpanded;
                  if (_isExpanded) _fetchMedicines();
                });
              },
            ),
          ),
          if (_isExpanded) ...[
            Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Prescription: ${widget.prescription['prescription']}'),
                  SizedBox(height: 8),
                  Text('Medicines:'),
                  if (_medicines.isEmpty)
                    CircularProgressIndicator()
                  else
                    Column(
                      children: _medicines.map((medicine) {
                        return ListTile(
                          title: Text(medicine['name']),
                          subtitle: Text('Price: ₹${medicine['price']}'),
                        );
                      }).toList(),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
