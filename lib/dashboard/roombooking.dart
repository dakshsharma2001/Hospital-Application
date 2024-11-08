import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RoomBookingScreen extends StatefulWidget {
  final String hospitalId;
  final String hospitalName;

  RoomBookingScreen({required this.hospitalId, required this.hospitalName});

  @override
  _RoomBookingScreenState createState() => _RoomBookingScreenState();
}

class _RoomBookingScreenState extends State<RoomBookingScreen> {
  final _supabase = Supabase.instance.client;
  final _patientIdController = TextEditingController();
  String? _selectedRoom;
  List<Map<String, dynamic>> _availableRooms = [];
  bool _isLoading = false;
  bool _isPatientVerified = false;

  @override
  void initState() {
    super.initState();
    _fetchAvailableRooms();
  }

  Future<void> _fetchAvailableRooms() async {
    setState(() => _isLoading = true);
    try {
      final response = await _supabase
          .from('roomsavailable')
          .select('id, name, occupied')
          .eq('hospitalId', widget.hospitalId);
      setState(
          () => _availableRooms = List<Map<String, dynamic>>.from(response));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching rooms: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _verifyPatient() async {
    setState(() => _isLoading = true);
    try {
      final patientResponse = await _supabase
          .from('patients')
          .select('id, appointdate')
          .eq('id', _patientIdController.text)
          .eq('hospitalId', widget.hospitalId)
          .single();

      if (patientResponse != null && patientResponse['appointdate'] != null) {
        setState(() => _isPatientVerified = true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Patient verified. You can now book a room.')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please book appointment first.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error verifying patient: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _bookRoom() async {
    if (_selectedRoom == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select a room')),
      );
      return;
    }

    // Check if the selected room is occupied
    final selectedRoomInfo = _availableRooms
        .firstWhere((room) => room['id'].toString() == _selectedRoom);
    if (selectedRoomInfo['occupied']) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                'This room is already occupied. Please select another room.')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      // Update patient's roomtake
      await _supabase.from('patients').update({
        'roomtake': _selectedRoom,
      }).eq('id', _patientIdController.text);

      // Update room's occupied status
      await _supabase.from('roomsavailable').update({
        'occupied': true,
      }).eq('id', _selectedRoom!);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Room booked successfully')),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error booking room: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text('Book Room at ${widget.hospitalName}'),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: _patientIdController,
                    decoration: InputDecoration(
                      labelText: 'Patient ID',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _verifyPatient,
                    child: Text('Verify Patient',
                        style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                  SizedBox(height: 24),
                  if (_isPatientVerified) ...[
                    Text(
                      'Available Rooms:',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _selectedRoom,
                      items: _availableRooms.map((room) {
                        return DropdownMenuItem<String>(
                          value: room['id'].toString(),
                          child: Text(
                              '${room['name']} ${room['occupied'] ? '(Occupied)' : ''}'),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedRoom = value;
                        });
                      },
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Select a room',
                      ),
                    ),
                    SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _bookRoom,
                      child: Text('Book Room',
                          style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        padding: EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}
