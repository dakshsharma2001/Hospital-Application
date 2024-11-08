import 'package:emergency/admin/add_doctor.dart';
import 'package:emergency/admin/complete_apooint.dart';
import 'package:emergency/admin/test_screen.dart';
import 'package:emergency/admin/room_management.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DoctorListScreen extends StatefulWidget {
  final String hospitalId;
  final String hospitalName;

  DoctorListScreen({required this.hospitalId, required this.hospitalName});

  @override
  _DoctorListScreenState createState() => _DoctorListScreenState();
}

class _DoctorListScreenState extends State<DoctorListScreen> {
  final _supabase = Supabase.instance.client;
  late Future<List<Map<String, dynamic>>> _doctorsFuture;

  @override
  void initState() {
    super.initState();
    print('Hospital ID: ${widget.hospitalId}');
    _doctorsFuture = _fetchDoctorsWithAppointments();
  }

  Future<List<Map<String, dynamic>>> _fetchDoctorsWithAppointments() async {
    try {
      final response = await _supabase.from('doctor').select('''
            id,
            name,
            email,
            phone,
            specialization,
            fee,
            patientappointId,
            doctorId
          ''').eq('hospitalId', widget.hospitalId);

      List<Map<String, dynamic>> doctorsWithAppointments = [];

      for (var doctor in response) {
        final patientAppointIds = doctor['patientappointId'] as List? ?? [];

        if (patientAppointIds.isNotEmpty) {
          final patientsResponse = await _supabase
              .from('patients')
              .select('id, appointmentdone')
              .inFilter('id', patientAppointIds);

          final completedAppointments = patientsResponse
              .where((patient) => patient['appointmentdone'] == true)
              .length;

          doctorsWithAppointments.add({
            ...doctor,
            'completedAppointments': completedAppointments,
            'totalAppointments': patientAppointIds.length,
          });
        } else {
          doctorsWithAppointments.add({
            ...doctor,
            'completedAppointments': 0,
            'totalAppointments': 0,
          });
        }
      }

      return doctorsWithAppointments;
    } catch (e) {
      print('Error fetching doctors with appointments: $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text('Doctors at ${widget.hospitalName}'),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _doctorsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: Colors.blue));
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else {
            final doctors = snapshot.data ?? [];
            if (doctors.isEmpty) {
              return Center(child: Text('No doctors found for this hospital'));
            }
            return ListView.builder(
              itemCount: doctors.length,
              itemBuilder: (context, index) {
                final doctor = doctors[index];
                final patientCount = doctor['totalAppointments'];
                final completedAppointments = doctor['completedAppointments'];
                final totalAppointments = doctor['totalAppointments'];

                return Card(
                  color: Colors.white,
                  margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CompletedAppointmentsScreen(
                            doctorId: doctor['doctorId'],
                            doctorName: doctor['name'],
                          ),
                        ),
                      );
                    },
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              flex: 3,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Dr. ${doctor['name'] ?? 'Unknown'}",
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue,
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  Text('Email: ${doctor['email'] ?? 'N/A'}'),
                                  Text('Phone: ${doctor['phone'] ?? 'N/A'}'),
                                  Text('Specialization: ${doctor['specialization'] ?? 'N/A'}'),
                                  Text('Fee: ₹${doctor['fee'] ?? 'N/A'}'),
                                  Text('Total Patients: $patientCount'),
                                ],
                              ),
                            ),
                            VerticalDivider(
                              color: Colors.grey,
                              thickness: 1,
                              width: 20,
                            ),
                            Expanded(
                              flex: 2,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Appointments',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'Completed:',
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  Text('$completedAppointments / $totalAppointments'),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          }
        },
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => RoomManagementScreen(
                    hospitalId: widget.hospitalId,
                    hospitalName: widget.hospitalName,
                  ),
                ),
              );
            },
            child: Icon(
              Icons.meeting_room,
              color: Colors.white,
            ),
            backgroundColor: Colors.blue,
            heroTag: 'manageRooms',
          ),
          SizedBox(height: 16),
          FloatingActionButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddTestScreen(
                    hospitalId: widget.hospitalId,
                    hospitalName: widget.hospitalName,
                  ),
                ),
              ).then((value) {
                if (value == true) {
                  setState(() {
                    _doctorsFuture = _fetchDoctorsWithAppointments();
                  });
                }
              });
            },
            child: Icon(
              Icons.add_box,
              color: Colors.white,
            ),
            backgroundColor: Colors.blue,
            heroTag: 'addTest',
          ),
          SizedBox(height: 16),
          FloatingActionButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddDoctorScreen(hospitalId: widget.hospitalId),
                ),
              ).then((_) {
                setState(() {
                  _doctorsFuture = _fetchDoctorsWithAppointments();
                });
              });
            },
            child: Icon(
              Icons.person_add,
              color: Colors.white,
            ),
            backgroundColor: Colors.blue,
            heroTag: 'addDoctor',
          ),
        ],
      ),
    );
  }
}