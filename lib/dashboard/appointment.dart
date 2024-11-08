import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

class AppointmentBookingScreen extends StatefulWidget {
  final String hospitalId;
  final String hospitalName;

  const AppointmentBookingScreen({
    Key? key,
    required this.hospitalId,
    required this.hospitalName,
  }) : super(key: key);

  @override
  _AppointmentBookingScreenState createState() =>
      _AppointmentBookingScreenState();
}

class _AppointmentBookingScreenState extends State<AppointmentBookingScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _diseaseController;
  late TextEditingController _appointDateController;
  Doctor? _selectedDoctor;
  List<Doctor> _doctors = [];
  bool _isLoading = false;

  final supabase = Supabase.instance.client;

  // Email configuration
  final String username = 'gsarvesh387@gmail.com'; // Replace with your email
  final String password =
      'egfripivxkflstod'; // Replace with your app password or email password

  @override
  void initState() {
    print('Hospital ID: ${widget.hospitalId}');
    print('Hospital name: ${widget.hospitalName}');
    super.initState();
    _nameController = TextEditingController();
    _emailController = TextEditingController();
    _phoneController = TextEditingController();
    _diseaseController = TextEditingController();
    _appointDateController = TextEditingController();
    _fetchDoctors();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _diseaseController.dispose();
    _appointDateController.dispose();
    super.dispose();
  }

  Future<void> _fetchDoctors() async {
    setState(() => _isLoading = true);
    try {
      print('Fetching doctors for hospital ID: ${widget.hospitalId}');
      final response = await supabase
          .from('doctor')
          .select()
          .eq('hospitalId', widget.hospitalId);

      print('Supabase doctor response: $response');

      if (response is List && response.isNotEmpty) {
        setState(() {
          _doctors = response.map((doctor) => Doctor.fromJson(doctor)).toList();
        });
        print('Fetched ${_doctors.length} doctors');
        for (var doctor in _doctors) {
          print(
              'Doctor: ID=${doctor.id}, DoctorID=${doctor.doctorId}, Name=${doctor.name}, Specialization=${doctor.specialization}, Hospital ID=${doctor.hospitalId}');
        }
      } else {
        print('No doctors found for this hospital');
      }
    } catch (e) {
      print('Error fetching doctors: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching doctors: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<bool> _verifyHospital() async {
    try {
      final response = await supabase
          .from('hospital')
          .select('id')
          .eq('id', widget.hospitalId)
          .limit(1)
          .single();

      print('Hospital verification response: $response');
      return response != null;
    } catch (e) {
      print('Error verifying hospital: $e');
      return false;
    }
  }

  Future<void> _sendConfirmationEmails({
    required String doctorEmail,
    required String patientEmail,
    required String appointmentDate,
    required String doctorName,
    required String patientName,
    required String patientPhone,
    required String doctorPhone,
    required String patientId,
  }) async {
    try {
      final smtpServer = gmail(username, password);

      // Create the doctor's email message
      final doctorMessage = Message()
        ..from = Address(username, 'Your Hospital')
        ..recipients.add(doctorEmail)
        ..subject = 'New Appointment Scheduled'
        ..html = '''
        <h1>New Appointment Scheduled</h1>
        <p>Dear Dr. $doctorName,</p>
        <p>A new appointment has been scheduled with the following details:</p>
        <ul>
          <li><strong>Patient:</strong> $patientName</li>
          <li><strong>Patient Phone:</strong> $patientPhone</li>
          <li><strong>Date:</strong> $appointmentDate</li>
      
        </ul>
        <p>Please ensure you're available at the scheduled time.</p>
        <p>Best regards,<br>Your Hospital Team</p>
      ''';

      // Create the patient's email message
      final patientMessage = Message()
        ..from = Address(username, 'Your Hospital')
        ..recipients.add(patientEmail)
        ..subject = 'Appointment Confirmation'
        ..html = '''
        <h1>Appointment Confirmation</h1>
        <p>Dear $patientName,</p>
        <p>Your appointment has been successfully scheduled with the following details:</p>
        <ul>
          <li><strong>Doctor:</strong> Dr. $doctorName</li>
          <li><strong>Doctor Phone:</strong> $doctorPhone</li>
          <li><strong>Date:</strong> $appointmentDate</li>
          <li><strong>Hospital:</strong> ${widget.hospitalName}</li>
          <li><strong>Your Patient ID:</strong> $patientId</li>
        </ul>
        <p>Please keep your Patient ID for future reference.</p>
        <p>This id is your password</p>
        <p>If you need to reschedule or cancel, please contact us at least 24 hours in advance.</p>
        <p>Best regards,<br>Your Hospital Team</p>
      ''';

      print('Attempting to send doctor email...');
      final sendDoctorReport = await send(doctorMessage, smtpServer);
      print('Doctor email sent: ' + sendDoctorReport.toString());

      print('Attempting to send patient email...');
      final sendPatientReport = await send(patientMessage, smtpServer);
      print('Patient email sent: ' + sendPatientReport.toString());
    } catch (e) {
      print('Error sending email: $e');
      if (e is MailerException) {
        for (var p in e.problems) {
          print('Problem: ${p.code}: ${p.msg}');
        }
      }
      throw Exception('Failed to send confirmation emails: $e');
    }
  }

  Future<void> _bookAppointment() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedDoctor == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select a doctor')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      print('Attempting to insert patient data');
      print(
          'Booking appointment with hospitalId: ${_selectedDoctor!.hospitalId}');
      print('Selected doctor ID: ${_selectedDoctor!.id}');
      print('Selected doctor DoctorID: ${_selectedDoctor!.doctorId}');

      if (_selectedDoctor!.hospitalId.isEmpty) {
        throw Exception('Hospital ID is empty for the selected doctor');
      }

      final patientData = {
        'name': _nameController.text,
        'email': _emailController.text,
        'phone': _phoneController.text,
        'disease': _diseaseController.text,
        'appointdate': _appointDateController.text,
        'hospitalId': _selectedDoctor!.hospitalId,
        'doctorappointId': _selectedDoctor!.doctorId,
      };
      print('Patient data: $patientData');

      final patientResponse =
          await supabase.from('patients').insert(patientData).select();

      print('Patient response: $patientResponse');

      if (patientResponse.isEmpty) throw Exception('Failed to create patient');

      final patientId = patientResponse[0]['id'];
      print('Created patient with ID: $patientId');

      print('Attempting to update doctor with patient appointment');

      // Fetch current patientappointId array
      final currentDoctorData = await supabase
          .from('doctor')
          .select('patientappointId')
          .eq('doctorId', _selectedDoctor!.doctorId)
          .single();

      List<dynamic> currentAppointments =
          currentDoctorData['patientappointId'] ?? [];
      currentAppointments.add(patientId);

      print(
          'Doctor update data: {patientappointId: $currentAppointments, doctorId: ${_selectedDoctor!.doctorId}}');

      final doctorUpdateResponse = await supabase
          .from('doctor')
          .update({
            'patientappointId': currentAppointments,
          })
          .eq('doctorId', _selectedDoctor!.doctorId)
          .select();

      print('Doctor update response: $doctorUpdateResponse');

      // Fetch doctor's email
      final doctorData = await supabase
          .from('doctor')
          .select('email, phone')
          .eq('doctorId', _selectedDoctor!.doctorId)
          .single();

      final doctorEmail = doctorData['email'] as String;
      final doctorPhone = doctorData['phone'] as String;

      // Send confirmation emails
      await _sendConfirmationEmails(
        doctorEmail: doctorEmail,
        patientEmail: _emailController.text,
        appointmentDate: _appointDateController.text,
        doctorName: _selectedDoctor!.name,
        patientName: _nameController.text,
        patientPhone: _phoneController.text,
        doctorPhone: doctorPhone,
        patientId: patientId.toString(),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                'Appointment booked successfully and confirmation emails sent!')),
      );
      Navigator.pop(context);
    } catch (e) {
      print('Error booking appointment: $e');
      if (e is PostgrestException) {
        print('Postgrest error details: ${e.details}');
        print('Postgrest error message: ${e.message}');
        print('Postgrest error code: ${e.code}');
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error booking appointment: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _appointDateController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text('Book Appointment at ${widget.hospitalName}'),
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
                      'Book Your Appointment',
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
                      keyboardType:
                          TextInputType.phone, // Set keyboard type to phone
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your phone number';
                        }
                        if (value.length < 10) {
                          return 'Phone number must be at least 10 digits';
                        }if (value.length > 10) {
                          return 'Phone number must be equal to 10 digits';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      controller: _diseaseController,
                      decoration: InputDecoration(
                        labelText: 'Disease/Condition',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: Icon(Icons.medical_services_outlined,
                            color: Colors.blue),
                      ),
                      validator: (value) => value!.isEmpty
                          ? 'Please enter your disease or condition'
                          : null,
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      controller: _appointDateController,
                      decoration: InputDecoration(
                        labelText: 'Appointment Date',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon:
                            Icon(Icons.calendar_today, color: Colors.blue),
                      ),
                      readOnly: true,
                      onTap: () => _selectDate(context),
                      validator: (value) => value!.isEmpty
                          ? 'Please select an appointment date'
                          : null,
                    ),
                    SizedBox(height: 16),
                    DropdownButtonFormField<Doctor>(
                      value: _selectedDoctor,
                      items: _doctors.map((Doctor doctor) {
                        return DropdownMenuItem<Doctor>(
                          value: doctor,
                          child:
                              Text('${doctor.name} - ${doctor.specialization}'),
                        );
                      }).toList(),
                      onChanged: (Doctor? newValue) {
                        setState(() {
                          _selectedDoctor = newValue;
                        });
                      },
                      decoration: InputDecoration(
                        labelText: 'Select Doctor',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: Icon(Icons.person, color: Colors.blue),
                      ),
                      validator: (value) =>
                          value == null ? 'Please select a doctor' : null,
                    ),
                    SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _bookAppointment,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Book Appointment',
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

class Doctor {
  final int id;
  final String name;
  final String specialization;
  final String hospitalId;
  final String doctorId;

  Doctor({
    required this.id,
    required this.name,
    required this.specialization,
    required this.hospitalId,
    required this.doctorId,
  });

  factory Doctor.fromJson(Map<String, dynamic> json) {
    return Doctor(
      id: json['id'],
      name: json['name'] ?? 'Unknown',
      specialization: json['specialization'] ?? 'Not specified',
      hospitalId: json['hospitalId']?.toString() ?? 'Unknown',
      doctorId: json['doctorId'] ?? 'Unknown',
    );
  }
}
