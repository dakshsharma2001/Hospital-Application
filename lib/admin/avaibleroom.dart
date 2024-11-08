import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AvailableRoomsScreen extends StatefulWidget {
  final String hospitalId;
  final String hospitalName;

  AvailableRoomsScreen({required this.hospitalId, required this.hospitalName});

  @override
  _AvailableRoomsScreenState createState() => _AvailableRoomsScreenState();
}

class _AvailableRoomsScreenState extends State<AvailableRoomsScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> rooms = [];
  Map<String, Map<String, dynamic>> patientDetails = {};
  int occupiedRooms = 0;

  @override
  void initState() {
    super.initState();
    _fetchRooms();
  }

  Future<void> _fetchRooms() async {
    try {
      final response = await _supabase
          .from('roomsavailable')
          .select()
          .eq('hospitalId', widget.hospitalId);

      setState(() {
        rooms = List<Map<String, dynamic>>.from(response);
        occupiedRooms = rooms.where((room) => room['occupied'] == true).length;
      });
      _fetchPatientDetails();
    } catch (e) {
      print('Error fetching rooms: $e');
    }
  }

  Future<void> _fetchPatientDetails() async {
    for (var room in rooms) {
      if (room['occupied'] == true) {
        try {
          final response = await _supabase
              .from('patients')
              .select('name, phone')
              .eq('roomtake', room['id'])
              .single();

          setState(() {
            patientDetails[room['id'].toString()] = response;
          });
        } catch (e) {
          print('Error fetching patient details: $e');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Available Rooms'),
        backgroundColor: Colors.white,
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Text(
                '$occupiedRooms/${rooms.length} occupied',
                style:
                    TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: rooms.length,
        itemBuilder: (context, index) {
          final room = rooms[index];
          return RoomListItem(
            room: room,
            patientDetails: patientDetails[room['id'].toString()],
          );
        },
      ),
    );
  }
}

class RoomListItem extends StatefulWidget {
  final Map<String, dynamic> room;
  final Map<String, dynamic>? patientDetails;

  RoomListItem({required this.room, this.patientDetails});

  @override
  _RoomListItemState createState() => _RoomListItemState();
}

class _RoomListItemState extends State<RoomListItem> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      margin: EdgeInsets.all(8),
      child: Column(
        children: [
          ListTile(
            title: Text('Room: ${widget.room['name']}'),
            subtitle: Text('Floor: ${widget.room['floor']}'),
            trailing: IconButton(
              icon: Icon(_expanded ? Icons.expand_less : Icons.expand_more),
              onPressed: () {
                setState(() {
                  _expanded = !_expanded;
                });
              },
            ),
          ),
          if (_expanded &&
              widget.room['occupied'] &&
              widget.patientDetails != null)
            Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Patient Name: ${widget.patientDetails!['name']}'),
                  Text('Phone: ${widget.patientDetails!['phone']}'),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
