import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

class TestBookingScreen extends StatefulWidget {
  final String hospitalId;
  final String hospitalName;

  const TestBookingScreen({
    Key? key,
    required this.hospitalId,
    required this.hospitalName,
  }) : super(key: key);

  @override
  _TestBookingScreenState createState() => _TestBookingScreenState();
}

class _TestBookingScreenState extends State<TestBookingScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  String? _selectedTest;
  List<String> _availableTests = [];
  bool _isLoading = false;

  final supabase = Supabase.instance.client;

  // Email configuration
  final String username = 'gsarvesh387@gmail.com';
  final String password = 'egfripivxkflstod';

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _emailController = TextEditingController();
    _phoneController = TextEditingController();
    _fetchAvailableTests();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _fetchAvailableTests() async {
    setState(() => _isLoading = true);
    try {
      final response = await supabase
          .from('hospital')
          .select('testavailable')
          .eq('hospitalIdd', widget.hospitalId)
          .single();

      if (response != null && response['testavailable'] != null) {
        setState(() {
          _availableTests = List<String>.from(response['testavailable']);
        });
      }
    } catch (e) {
      print('Error fetching available tests: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching available tests: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _bookTest() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final patientData = {
        'name': _nameController.text,
        'email': _emailController.text,
        'phone': _phoneController.text,
        'hospitalId': widget.hospitalId,
        'testtake': _selectedTest,
      };

      final response =
          await supabase.from('patients').insert(patientData).select();

      if (response == null || response.isEmpty) {
        throw Exception('Failed to create patient record');
      }

      final patientId = response[0]['id'];

      // Fetch hospital email
      final hospitalResponse = await supabase
          .from('hospital')
          .select('email')
          .eq('hospitalIdd', widget.hospitalId)
          .single();

      final hospitalEmail = hospitalResponse['email'] as String;

      // Send emails
      await _sendEmails(hospitalEmail, patientId);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Test booked successfully and emails sent!')),
      );
      Navigator.pop(context);
    } catch (e) {
      print('Error booking test or sending emails: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error booking test or sending emails: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _sendEmails(String hospitalEmail, int patientId) async {
    final smtpServer = gmail(username, password);

    // Create the hospital's email message
    final hospitalMessage = Message()
      ..from = Address(username, 'Test Booking System')
      ..recipients.add(hospitalEmail)
      ..subject = 'New Test Booking'
      ..html = '''
        <h1>New Test Booking</h1>
        <p>A new test has been booked with the following details:</p>
        <ul>
          <li><strong>Patient Name:</strong> ${_nameController.text}</li>
          <li><strong>Test Name:</strong> $_selectedTest</li>
          <li><strong>Email:</strong> ${_emailController.text}</li>
          <li><strong>Phone:</strong> ${_phoneController.text}</li>
          
        </ul>
        <p>Please prepare for the patient's visit.</p>
      ''';

    // Create the patient's email message
    final patientMessage = Message()
      ..from = Address(username, 'Test Booking System')
      ..recipients.add(_emailController.text)
      ..subject = 'Test Booking Confirmation'
      ..html = '''
        <h1>Test Booking Confirmation</h1>
        <p>Your test has been successfully booked at ${widget.hospitalName}.</p>
        <p><strong>Test:</strong> $_selectedTest</p>
        <p><strong>Your Patient ID:</strong> $patientId</p>
        <p>This id is your password</p>
        <p><strong>Important:</strong> Please come tomorrow for the test.</p>
        <p>If you need to reschedule or have any questions, please contact the hospital directly.</p>
      ''';

    try {
      final sendHospitalReport = await send(hospitalMessage, smtpServer);
      print('Hospital email sent: ' + sendHospitalReport.toString());

      final sendPatientReport = await send(patientMessage, smtpServer);
      print('Patient email sent: ' + sendPatientReport.toString());
    } catch (e) {
      print('Error sending email: $e');
      throw Exception('Failed to send emails: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text('Book Test at ${widget.hospitalName}'),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Book Your Test',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    SizedBox(height: 24),
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'Name',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon:
                            Icon(Icons.person_outline, color: Colors.blue),
                      ),
                      validator: (value) =>
                          value!.isEmpty ? 'Please enter your name' : null,
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon:
                            Icon(Icons.email_outlined, color: Colors.blue),
                      ),
                      validator: (value) =>
                          value!.isEmpty ? 'Please enter your email' : null,
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      controller: _phoneController,
                      decoration: InputDecoration(
                        labelText: 'Phone',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon:
                            Icon(Icons.phone_outlined, color: Colors.blue),
                      ),
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your phone number';
                        }
                        if (value.length < 10) {
                          return 'Phone number must be at least 10 digits';
                        }
                        if (value.length > 10) {
                          return 'Phone number must be equal to 10 digits';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _selectedTest,
                      items: _availableTests.map((String test) {
                        return DropdownMenuItem<String>(
                          value: test,
                          child: Text(test),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedTest = newValue;
                        });
                      },
                      decoration: InputDecoration(
                        labelText: 'Select Test',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: Icon(Icons.science, color: Colors.blue),
                      ),
                      validator: (value) =>
                          value == null ? 'Please select a test' : null,
                    ),
                    SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _bookTest,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Book Test',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white,
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
}
