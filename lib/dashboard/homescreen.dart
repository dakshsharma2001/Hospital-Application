import 'dart:math';
import 'package:emergency/hospital/model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

// Assuming you have this import for the AIChatbotScreen
import 'package:emergency/dashboard/chatbot.dart';
// Assuming you have this import for the HospitalDetailsScreen
import 'package:emergency/dashboard/hospitaldetail.dart';

class HomeScreen extends StatefulWidget {
  static const routeName = '/home';
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _supabase = Supabase.instance.client;
  MapController? _mapController;
  LatLng? _currentPosition;
  List<Hospital> _hospitals = [];
  bool _isMapFullScreen = false;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _checkUserType();
    _testSupabaseConnection();
  }

  Future<void> _testSupabaseConnection() async {
    try {
      print('Testing Supabase connection...');
      final response = await _supabase.from('hospital').select().limit(1);
      print('Test query response: $response');
    } catch (e) {
      print('Error testing Supabase connection: $e');
    }
  }

  double _calculateDistance(LatLng start, LatLng end) {
    return Geolocator.distanceBetween(
          start.latitude,
          start.longitude,
          end.latitude,
          end.longitude,
        ) /
        1000; // Convert to kilometers
  }

  void _getCurrentLocation() async {
    final hasPermission = await _handleLocationPermission();
    if (!hasPermission) return;

    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        _currentPosition = LatLng(position.latitude, position.longitude);
        _mapController = MapController();
      });
      print('Current position: $_currentPosition');
      _fetchHospitals();
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  Future<bool> _handleLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              'Location services are disabled. Please enable the services')));
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permissions are denied')));
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              'Location permissions are permanently denied, we cannot request permissions.')));
      return false;
    }

    return true;
  }

  void _goToCurrentLocation() {
    if (_currentPosition != null && _mapController != null) {
      _mapController!.move(_currentPosition!, 15);
    }
  }

  Future<void> _fetchHospitals() async {
    try {
      print('Fetching hospitals...');
      final response = await _supabase
          .from('hospital')
          .select('name, departments, hospitalIdd, email');
      print('Supabase response: $response');

      if (response != null && response is List && response.isNotEmpty) {
        setState(() {
          _hospitals = response
              .map((hospital) {
                print('Processing hospital: $hospital');
                try {
                  final id = hospital['name'] as String? ?? 'Unknown Hospital';
                  final location = _generateRandomNearbyLocation();
                  final hospitalId = hospital['hospitalIdd'] as String?;
                  final email = hospital['email'] as String?;

                  print(
                      'Hospital name: $id, Hospital ID: $hospitalId, Email: $email');

                  return Hospital(
                    id: id,
                    name: hospital['name'] as String? ?? 'Unknown Hospital',
                    location: location,
                    departments:
                        (hospital['departments'] as List?)?.cast<String>() ??
                            [],
                    hospitalId: hospitalId ?? '',
                    email: email ?? '',
                  );
                } catch (e) {
                  print('Error processing hospital: $e');
                  return null;
                }
              })
              .whereType<Hospital>()
              .toList();
        });

        print('Processed ${_hospitals.length} hospitals');
        for (var hospital in _hospitals) {
          print(
              'Hospital: ${hospital.name}, ID: ${hospital.hospitalId}, Email: ${hospital.email}');
        }
      }
    } catch (e) {
      print('Error fetching hospitals: $e');
    }
  }

  LatLng _generateRandomNearbyLocation() {
    final random = Random();
    final latOffset = (random.nextDouble() - 0.5) * 0.02;
    final lngOffset = (random.nextDouble() - 0.5) * 0.02;

    final lat = _currentPosition!.latitude + latOffset;
    final lng = _currentPosition!.longitude + lngOffset;

    print('Generated nearby location: $lat, $lng');
    return LatLng(lat, lng);
  }

  Future<void> _checkUserType() async {
    String? userType = await _getUserType();
    if (userType == null) {
      await _showUserTypeDialog(context);
    }
  }

  Future<String?> _getUserType() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_type');
  }

  Future<void> _showUserTypeDialog(BuildContext context) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Select User Type'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                TextButton(
                  child: Text('Doctor'),
                  onPressed: () => _setUserType(context, 'doctor'),
                ),
                TextButton(
                  child: Text('Patient'),
                  onPressed: () => _setUserType(context, 'patient'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _setUserType(BuildContext context, String userType) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_type', userType);
    Navigator.of(context).pop();
  }

  Future<void> _sendEmergencyEmail() async {
    if (_currentPosition == null || _hospitals.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Unable to determine location or find hospitals')),
      );
      return;
    }

    Hospital nearestHospital = _hospitals.reduce((a, b) =>
        _calculateDistance(_currentPosition!, a.location) <
                _calculateDistance(_currentPosition!, b.location)
            ? a
            : b);

    if (nearestHospital.email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Nearest hospital email is not available')),
      );
      return;
    }

    // Replace these with your actual email credentials
    String username = 'gsarvesh387@gmail.com';
    String password = 'egfripivxkflstod';

    final smtpServer = gmail(username, password);

    final message = Message()
      ..from = Address(username, 'Emergency Alert System')
      ..recipients.add(nearestHospital.email)
      ..subject = 'Emergency: Immediate Assistance Required'
      ..text = 'Dear. ${nearestHospital.name}\n'
          'This is an emergency alert. Immediate assistance is required at the following location:\n'
          'Latitude: ${_currentPosition!.latitude}\n'
          'Longitude: ${_currentPosition!.longitude}\n\n'
          'Please dispatch emergency services immediately.';

    try {
      final sendReport = await send(message, smtpServer);
      print('Message sent: ' + sendReport.toString());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Emergency email sent to ${nearestHospital.name}')),
      );
    } catch (e) {
      print('Error sending message: ${e.toString()}');
      String errorMessage = 'Failed to send emergency email';
      if (e is MailerException) {
        errorMessage += ': ${e.message}';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: const Text('Nearby Hospitals',
            style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle, color: Colors.white),
            onPressed: () {
              Navigator.of(context).pushNamed('/patient');
              print('Profile icon tapped');
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () async {
              await _supabase.auth.signOut();
              Navigator.of(context).pushReplacementNamed('/login');
            },
          )
        ],
      ),
      body: Stack(
        children: [
          _buildMap(),
          _buildBottomSheet(),
          Positioned(
            top: 16,
            right: 16,
            child: FloatingActionButton(
              heroTag: "chatButton",
              backgroundColor: Colors.blue,
              child: Icon(Icons.smart_toy, color: Colors.white),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AIChatbotScreen()),
                );
              },
            ),
          ),
          Positioned(
            top: 80,
            right: 16,
            child: FloatingActionButton(
              heroTag: "emergencyButton",
              backgroundColor: Colors.red,
              child: Icon(Icons.emergency, color: Colors.white),
              onPressed: _sendEmergencyEmail,
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: "locationButton",
        backgroundColor: Colors.blue,
        onPressed: _goToCurrentLocation,
        child: const Icon(Icons.location_searching, color: Colors.white),
      ),
    );
  }

  Widget _buildMap() {
    return _currentPosition == null
        ? const Center(child: CircularProgressIndicator(color: Colors.blue))
        : FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentPosition!,
              initialZoom: 15.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    width: 80.0,
                    height: 80.0,
                    point: _currentPosition!,
                    child: const Icon(Icons.location_on, color: Colors.blue),
                  ),
                  ..._hospitals
                      .map((hospital) => Marker(
                            width: 80.0,
                            height: 80.0,
                            point: hospital.location,
                            child: GestureDetector(
                              onTap: () => _onHospitalTapped(hospital),
                              child: const Icon(Icons.local_hospital,
                                  color: Colors.red),
                            ),
                          ))
                      .toList(),
                ],
              ),
            ],
          );
  }

  Widget _buildBottomSheet() {
    return DraggableScrollableSheet(
      initialChildSize: 0.3,
      minChildSize: 0.1,
      maxChildSize: 1.0,
      builder: (BuildContext context, ScrollController scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.5),
                spreadRadius: 5,
                blurRadius: 7,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: ListView.builder(
            controller: scrollController,
            itemCount: _hospitals.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return Container(
                  height: 20,
                  child: Center(
                    child: Container(
                      width: 50,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                );
              }
              final hospital = _hospitals[index - 1];
              final distance = _currentPosition != null
                  ? _calculateDistance(_currentPosition!, hospital.location)
                  : null;
              return ListTile(
                title: Text(hospital.name),
                subtitle: Text(hospital.departments.join(', ')),
                trailing: distance != null
                    ? Text('${distance.toStringAsFixed(2)} km')
                    : null,
                onTap: () => _onHospitalTapped(hospital),
              );
            },
          ),
        );
      },
    );
  }

  void _onHospitalTapped(Hospital hospital) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HospitalDetailsScreen(hospital: hospital),
      ),
    );
  }
}
