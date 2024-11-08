import 'package:emergency/dashboard/view_appointment.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DoctorScreen extends StatefulWidget {
  static const routeName = '/doctor';

  const DoctorScreen({Key? key}) : super(key: key);

  @override
  _DoctorScreenState createState() => _DoctorScreenState();
}

class _DoctorScreenState extends State<DoctorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _supabase = Supabase.instance.client;
  String _doctorId = '';
  bool _isLoading = false;
  bool _isVerified = false;
  Map<String, dynamic>? _doctorInfo;

  @override
  void initState() {
    super.initState();
    _checkDoctorVerification();
  }

  Future<void> _checkDoctorVerification() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? storedDoctorId = prefs.getString('doctorId');
    setState(() {
      _doctorId = storedDoctorId;
      _isVerified = true;
    });
    await _fetchDoctorInfo();
  }

  Future<void> _fetchDoctorInfo() async {
    try {
      final response = await _supabase
          .from('doctor')
          .select('name, email, phone, specialization')
          .eq('doctorId', _doctorId)
          .single();

      if (response != null) {
        setState(() {
          _doctorInfo = response;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text('Failed to fetch doctor information: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text('Doctor Dashboard'),
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
                  labelText: 'Doctor ID',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your Doctor ID';
                  }
                  return null;
                },
                onSaved: (value) {
                  _doctorId = value!;
                },
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: _isLoading ? null : _verifyDoctorId,
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
                            'Verify Doctor ID',
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
    final screenSize = MediaQuery.of(context).size;
    if (_doctorInfo == null) {
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
            'Dr. ${_doctorInfo!['name']}',
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
                  'General Information',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 15),
                _buildInfoRow(Icons.phone, 'Phone', _doctorInfo!['phone']),
                _buildInfoRow(Icons.medical_services, 'Specialization',
                    _doctorInfo!['specialization']),
                _buildInfoRow(Icons.email, 'Email', _doctorInfo!['email']),
              ],
            ),
          ),
          SizedBox(height: 40),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      ViewAppointmentsScreen(doctorId: _doctorId),
                ),
              );
            },
            child: Container(
              height: screenSize.height * 0.07,
              width: screenSize.width * 0.9,
              alignment: Alignment.center,
              child: Text(
                "View Appointments",
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
              decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadiusDirectional.circular(16)),
            ),
          ),
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

  Future<void> _verifyDoctorId() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      setState(() {
        _isLoading = true;
      });

      try {
        final response = await _supabase
            .from('doctor')
            .select()
            .eq('doctorId', _doctorId)
            .single();

        if (response != null) {
          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setString('doctorId', _doctorId);
          setState(() {
            _isVerified = true;
          });
          await _fetchDoctorInfo();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Invalid Doctor ID')),
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
    await prefs.remove('doctorId');
    Navigator.of(context).pushReplacementNamed('/login');
  }
}
