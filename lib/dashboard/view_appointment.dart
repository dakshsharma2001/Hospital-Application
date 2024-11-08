import 'package:emergency/dashboard/prescription.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ViewAppointmentsScreen extends StatefulWidget {
  final String doctorId;

  const ViewAppointmentsScreen({Key? key, required this.doctorId})
      : super(key: key);

  @override
  _ViewAppointmentsScreenState createState() => _ViewAppointmentsScreenState();
}

class _ViewAppointmentsScreenState extends State<ViewAppointmentsScreen> {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _appointments = [];
  bool _isLoading = true;
  late SharedPreferences _prefs;

  @override
  void initState() {
    super.initState();
    _initSharedPreferences();
  }

  Future<void> _initSharedPreferences() async {
    _prefs = await SharedPreferences.getInstance();
    await _fetchAppointments();
  }

  Future<void> _fetchAppointments() async {
    try {
      final doctorResponse = await _supabase
          .from('doctor')
          .select('patientappointId')
          .eq('doctorId', widget.doctorId)
          .single();

      if (doctorResponse != null) {
        List<String> patientIds =
            List<String>.from(doctorResponse['patientappointId']);

        for (String patientId in patientIds) {
          final patientResponse = await _supabase
              .from('patients')
              .select('name, disease, appointdate, phone, appointmentdone')
              .eq('id', patientId)
              .single();

          if (patientResponse != null) {
            bool isDone = patientResponse['appointmentdone'] ?? false;

            // Fetch the latest prescription for this patient
            final prescriptionResponse = await _supabase
                .from('prescriptions')
                .select(
                    'medicines, prescription') // Changed 'medicine' to 'medicines'
                .eq('patientId', patientId)
                .order('created_at', ascending: false)
                .limit(1)
                .maybeSingle();

            _appointments.add({
              'id': patientId,
              'name': patientResponse['name'] ?? 'No name',
              'phone': patientResponse['phone'] ?? 'No phone number',
              'disease': patientResponse['disease'] ?? 'Not specified',
              'appointdate': patientResponse['appointdate'] ?? 'Not scheduled',
              'isDone': isDone,
              'medicines': prescriptionResponse?['medicines'] ?? '',
              'prescription': prescriptionResponse?['prescription'] ?? '',
            });
          }
        }

        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching appointments: $e');
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Failed to fetch appointments: ${e.toString()}')),
      );
    }
  }

  Future<void> _markAppointmentAsDone(int index) async {
    try {
      final patientId = _appointments[index]['id'];

      // Update the Supabase database
      await _supabase
          .from('patients')
          .update({'appointmentdone': true}).eq('id', patientId);

      // Update local state
      setState(() {
        _appointments[index]['isDone'] = true;
      });

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Appointment marked as done')),
      );
    } catch (e) {
      print('Error marking appointment as done: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text('Failed to mark appointment as done: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text('View Appointments'),
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
              color: Colors.blue,
            ))
          : _appointments.isEmpty
              ? Center(child: Text('No appointments found'))
              : ListView.builder(
                  itemCount: _appointments.length,
                  itemBuilder: (context, index) {
                    final appointment = _appointments[index];
                    final isDone = appointment['isDone'];
                    return GestureDetector(
                      onTap: () => _showAppointmentDialog(index),
                      child: Card(
                        color: isDone ? Colors.blue[50] : Colors.white,
                        margin:
                            EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: ListTile(
                          title: Text(
                            appointment['name'],
                            style: TextStyle(
                              color: isDone ? Colors.blue[800] : Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Phone: ${appointment['phone']}',
                                style: TextStyle(
                                  color: isDone
                                      ? Colors.blue[800]
                                      : Colors.black54,
                                ),
                              ),
                              Text(
                                'Disease: ${appointment['disease']}',
                                style: TextStyle(
                                  color: isDone
                                      ? Colors.blue[800]
                                      : Colors.black54,
                                ),
                              ),
                              Text(
                                'Date: ${appointment['appointdate']}',
                                style: TextStyle(
                                  color: isDone
                                      ? Colors.blue[800]
                                      : Colors.black54,
                                ),
                              ),
                              if (appointment['medicines'].isNotEmpty)
                                Text(
                                  'Prescription: ${appointment['prescription']}',
                                  style: TextStyle(
                                    color: isDone
                                        ? Colors.blue[800]
                                        : Colors.black54,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  void _showAppointmentDialog(int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Appointment Action'),
          content: Text('What would you like to do?'),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Mark as Done'),
              onPressed: () {
                Navigator.of(context).pop();
                _markAppointmentAsDone(index);
              },
            ),
            TextButton(
              child: Text('Prescription'),
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PrescriptionScreen(
                      patientId: _appointments[index]['id'],
                      patientName: _appointments[index]['name'],
                      existingPrescription: _appointments[index]
                          ['prescription'],
                    ),
                  ),
                ).then((_) =>
                    _fetchAppointments()); // Refresh appointments after returning from PrescriptionScreen
              },
            ),
          ],
        );
      },
    );
  }
}
