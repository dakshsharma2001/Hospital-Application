import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

class AddDoctorScreen extends StatefulWidget {
  final String hospitalId;

  AddDoctorScreen({required this.hospitalId});

  @override
  _AddDoctorScreenState createState() => _AddDoctorScreenState();
}

class _AddDoctorScreenState extends State<AddDoctorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _supabase = Supabase.instance.client;

  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _specializationController;
  late TextEditingController _feeController;
  late TextEditingController _doctorIdController;

  // Email configuration
  final String username = 'gsarvesh387@gmail.com'; // Replace with your email
  final String password = 'egfripivxkflstod'; // Replace with your app password
  bool _isLoading = false;
  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _emailController = TextEditingController();
    _phoneController = TextEditingController();
    _specializationController = TextEditingController();
    _feeController = TextEditingController();
    _doctorIdController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _specializationController.dispose();
    _feeController.dispose();
    _doctorIdController.dispose();
    super.dispose();
  }

  Future<void> _sendWelcomeEmail({
    required String doctorEmail,
    required String doctorName,
    required String doctorId,
  }) async {
    try {
      final smtpServer = gmail(username, password);

      final message = Message()
        ..from = Address(username, 'Your Hospital')
        ..recipients.add(doctorEmail)
        ..subject = 'Welcome to Our Hospital'
        ..html = '''
        <h1>Welcome Dr. $doctorName</h1>
        <p>Thank you for joining our hospital. Your account has been successfully created.</p>
        <p>Here are your login details:</p>
        <ul>
          <li><strong>Doctor ID:</strong> $doctorId</li>
        </ul>
        <p>Please use this Doctor ID to log in to our system.</p>
        <p>Best regards,<br>Your Hospital Team</p>
      ''';

      final sendReport = await send(message, smtpServer);
      print('Welcome email sent: ${sendReport.toString()}');
    } catch (e) {
      print('Error sending welcome email: $e');
      throw Exception('Failed to send welcome email: $e');
    }
  }

  Future<void> _addDoctor() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });
      try {
        final response = await _supabase.from('doctor').insert({
          'name': _nameController.text,
          'email': _emailController.text,
          'phone': _phoneController.text,
          'specialization': _specializationController.text,
          'fee': int.parse(_feeController.text),
          'doctorId': _doctorIdController.text,
          'hospitalId': widget.hospitalId,
        }).select();

        if (response != null && response.isNotEmpty) {
          // Send welcome email
          await _sendWelcomeEmail(
            doctorEmail: _emailController.text,
            doctorName: _nameController.text,
            doctorId: _doctorIdController.text,
          );

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content:
                    Text('Doctor added successfully and welcome email sent')),
          );
          Navigator.pop(context);
        } else {
          throw Exception('Failed to add doctor');
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding doctor: $e')),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text('Add New Doctor'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Add New Doctor',
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
                  prefixIcon: Icon(Icons.person_outline, color: Colors.blue),
                ),
                validator: (value) =>
                    value!.isEmpty ? 'Please enter a name' : null,
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: Icon(Icons.email_outlined, color: Colors.blue),
                ),
                validator: (value) =>
                    value!.isEmpty ? 'Please enter an email' : null,
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                decoration: InputDecoration(
                  labelText: 'Phone',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: Icon(Icons.phone_outlined, color: Colors.blue),
                ),
                validator: (value) =>
                    value!.isEmpty ? 'Please enter a phone number' : null,
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _specializationController,
                decoration: InputDecoration(
                  labelText: 'Specialization',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon:
                      Icon(Icons.medical_services_outlined, color: Colors.blue),
                ),
                validator: (value) =>
                    value!.isEmpty ? 'Please enter a specialization' : null,
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _feeController,
                decoration: InputDecoration(
                  labelText: 'Fee',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon:
                      Icon(Icons.attach_money_outlined, color: Colors.blue),
                ),
                keyboardType: TextInputType.number,
                validator: (value) =>
                    value!.isEmpty ? 'Please enter a fee' : null,
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _doctorIdController,
                decoration: InputDecoration(
                  labelText: 'Doctor ID',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: Icon(Icons.badge_outlined, color: Colors.blue),
                ),
                validator: (value) =>
                    value!.isEmpty ? 'Please enter a doctor ID' : null,
              ),
              SizedBox(height: 24),
              SizedBox(height: 24),
              SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _addDoctor,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(
                            'Add Doctor',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                            ),
                          ),
                  ))
            ],
          ),
        ),
      ),
    );
  }
}
