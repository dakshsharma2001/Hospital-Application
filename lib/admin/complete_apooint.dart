import 'package:emergency/admin/prescription_details.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CompletedAppointmentsScreen extends StatefulWidget {
  final String doctorId;
  final String doctorName;

  CompletedAppointmentsScreen(
      {required this.doctorId, required this.doctorName});

  @override
  _CompletedAppointmentsScreenState createState() =>
      _CompletedAppointmentsScreenState();
}

class _CompletedAppointmentsScreenState
    extends State<CompletedAppointmentsScreen> {
  final _supabase = Supabase.instance.client;
  late Future<List<Map<String, dynamic>>> _patientsFuture;

  @override
  void initState() {
    super.initState();
    _patientsFuture = _fetchDoctorAppointments();
  }

  Future<List<Map<String, dynamic>>> _fetchDoctorAppointments() async {
    try {
      final response = await _supabase
          .from('patients')
          .select(
              'id, name, disease, appointdate, appointmentdone') // Add 'id' to the select query
          .eq('doctorappointId', widget.doctorId);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching doctor appointments: $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text('Appointments - Dr. ${widget.doctorName}'),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _patientsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: Colors.blue));
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else {
            final patients = snapshot.data ?? [];
            if (patients.isEmpty) {
              return Center(child: Text('No appointments found'));
            }
            return ListView.builder(
              itemCount: patients.length,
              itemBuilder: (context, index) {
                final patient = patients[index];
                final isCompleted = patient['appointmentdone'] ==
                    true; // Check if appointment is completed

                return Card(
                  color: isCompleted
                      ? Colors.blue[50]
                      : Colors.white, // Set card color
                  margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    title: Text(
                      patient['name'] ?? 'Unknown',
                      style: TextStyle(
                          color: isCompleted
                              ? Colors.blue
                              : Colors.black), // Set text color
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Disease: ${patient['disease'] ?? 'N/A'}',
                          style: TextStyle(
                              color: isCompleted
                                  ? Colors.blue
                                  : Colors.black), // Set text color
                        ),
                        Text(
                          'Appointment Date: ${patient['appointdate'] ?? 'N/A'}',
                          style: TextStyle(
                              color: isCompleted
                                  ? Colors.blue
                                  : Colors.black), // Set text color
                        ),
                        Text(
                          'Status: ${isCompleted ? 'Completed' : 'Pending'}',
                          style: TextStyle(
                              color: isCompleted
                                  ? Colors.blue
                                  : Colors.black), // Set text color
                        ),
                      ],
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PrescriptionDetailsScreen(
                            patientId: patient['id'],
                            patientName: patient['name'] ?? 'Unknown',
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }
}
