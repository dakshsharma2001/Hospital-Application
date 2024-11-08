import 'package:emergency/dashboard/appointment.dart';
import 'package:emergency/dashboard/roombooking.dart';
import 'package:emergency/dashboard/test_booking.dart';

import 'package:emergency/hospital/model.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:math';
import 'package:supabase_flutter/supabase_flutter.dart';

class HospitalDetailsScreen extends StatelessWidget {
  final Hospital hospital;
  final _supabase = Supabase.instance.client;

  HospitalDetailsScreen({Key? key, required this.hospital}) : super(key: key);

  static const List<String> hospitalImages = [
    "https://images.unsplash.com/photo-1599045118108-bf9954418b76?q=80&w=1974&auto=format&fit=crop&ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D",
    "https://images.unsplash.com/photo-1586773860418-d37222d8fce3?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=2073&q=80",
    "https://images.unsplash.com/photo-1519494026892-80bbd2d6fd0d?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=2053&q=80",
    "https://images.unsplash.com/photo-1538108149393-fbbd81895907?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=2128&q=80",
  ];

  String getRandomImageUrl() {
    final random = Random();
    return hospitalImages[random.nextInt(hospitalImages.length)];
  }

  Future<List<String>> fetchAvailableTests() async {
    final response = await _supabase
        .from('hospital')
        .select('testavailable')
        .eq('hospitalIdd', hospital.hospitalId)
        .single();
    return List<String>.from(response['testavailable'] ?? []);
  }

  Future<List<Map<String, dynamic>>> fetchAvailableMedicines() async {
    final response =
        await _supabase.from('medicinesinventory').select('name, price');
    return List<Map<String, dynamic>>.from(response);
  }

  Future<List<String>> fetchAvailableRooms() async {
    final response = await _supabase
        .from('roomsavailable')
        .select('name')
        .eq('hospitalId', hospital.hospitalId);
    return List<String>.from(response.map((room) => room['name']));
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final textScaleFactor = MediaQuery.of(context).textScaleFactor;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(hospital.name),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.all(screenSize.width * 0.04),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: screenSize.height * 0.25,
                    width: screenSize.width * 0.9,
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(255, 255, 254, 254),
                      border: Border.all(color: Colors.white),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: CachedNetworkImage(
                        imageUrl: getRandomImageUrl(),
                        fit: BoxFit.cover,
                        placeholder: (context, url) =>
                            Center(child: CircularProgressIndicator()),
                        errorWidget: (context, url, error) => Icon(Icons.error),
                      ),
                    ),
                  ),
                  SizedBox(height: screenSize.height * 0.02),
                  Text(
                    hospital.name,
                    style: TextStyle(
                      color: Colors.blue,
                      fontSize: 24 * textScaleFactor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: screenSize.height * 0.01),
                  Row(
                    children: [
                      const Icon(Icons.location_on, color: Colors.blue),
                      Expanded(
                        child: Text(
                          '${hospital.location.latitude.toStringAsFixed(6)}, ${hospital.location.longitude.toStringAsFixed(6)}',
                          style: TextStyle(color: Colors.grey),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: screenSize.height * 0.02),
                  Text(
                    'Departments:',
                    style: TextStyle(
                      fontSize: 18 * textScaleFactor,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  ...hospital.departments.map((dept) => Padding(
                        padding: EdgeInsets.only(
                          left: screenSize.width * 0.04,
                          top: screenSize.height * 0.01,
                        ),
                        child: Text(
                          '• $dept',
                          style: TextStyle(
                              color: const Color.fromARGB(255, 126, 126, 126)),
                        ),
                      )),
                  SizedBox(height: screenSize.height * 0.02),
                  Text(
                    'Available Tests:',
                    style: TextStyle(
                      fontSize: 18 * textScaleFactor,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(height: screenSize.height * 0.01),
                  FutureBuilder<List<String>>(
                    future: fetchAvailableTests(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(child: CircularProgressIndicator());
                      } else if (snapshot.hasError) {
                        return Text('Error: ${snapshot.error}');
                      } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return Text('No tests available');
                      } else {
                        return Container(
                          width: screenSize.width * 0.9,
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: snapshot.data!
                                .map((test) => Chip(
                                      label: Text(test),
                                      backgroundColor: Colors.blue[100],
                                    ))
                                .toList(),
                          ),
                        );
                      }
                    },
                  ),
                  SizedBox(height: screenSize.height * 0.02),
                  Text(
                    'Available Medicines:',
                    style: TextStyle(
                      fontSize: 18 * textScaleFactor,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(height: screenSize.height * 0.01),
                  FutureBuilder<List<Map<String, dynamic>>>(
                    future: fetchAvailableMedicines(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(child: CircularProgressIndicator());
                      } else if (snapshot.hasError) {
                        return Text('Error: ${snapshot.error}');
                      } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return Text('No medicines available');
                      } else {
                        return Container(
                          width: screenSize.width * 0.9,
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: snapshot.data!
                                .map((medicine) => Padding(
                                      padding:
                                          EdgeInsets.symmetric(vertical: 4),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                              child: Text(medicine['name'])),
                                          Text(
                                              '₹${medicine['price'].toStringAsFixed(2)}'),
                                        ],
                                      ),
                                    ))
                                .toList(),
                          ),
                        );
                      }
                    },
                  ),
                  SizedBox(height: screenSize.height * 0.02),
                  Text(
                    'Available Rooms:',
                    style: TextStyle(
                      fontSize: 18 * textScaleFactor,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(height: screenSize.height * 0.01),
                  FutureBuilder<List<String>>(
                    future: fetchAvailableRooms(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(child: CircularProgressIndicator());
                      } else if (snapshot.hasError) {
                        return Text('Error: ${snapshot.error}');
                      } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return Text('No rooms available');
                      } else {
                        return Container(
                          width: screenSize.width * 0.9,
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: snapshot.data!
                                .map((room) => Chip(
                                      label: Text(room),
                                      backgroundColor: Colors.blue[100],
                                    ))
                                .toList(),
                          ),
                        );
                      }
                    },
                  ),
                  SizedBox(height: screenSize.height * 0.2),
                  SizedBox(height: screenSize.height * 0.2),
                ],
              ),
            ),
          ),
          Positioned(
            left: screenSize.width * 0.05,
            right: screenSize.width * 0.05,
            bottom: screenSize.height * 0.02,
            child: Column(
              children: [
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => RoomBookingScreen(
                          hospitalId: hospital.hospitalId,
                          hospitalName: hospital.name,
                        ),
                      ),
                    );
                  },
                  child: Container(
                    height: screenSize.height * 0.07,
                    alignment: Alignment.center,
                    child: Text(
                      "Book Room",
                      style: TextStyle(color: Colors.white, fontSize: 18),
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
                SizedBox(height: 10),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TestBookingScreen(
                          hospitalId: hospital.hospitalId,
                          hospitalName: hospital.name,
                        ),
                      ),
                    );
                  },
                  child: Container(
                    height: screenSize.height * 0.07,
                    alignment: Alignment.center,
                    child: Text(
                      "Book Test",
                      style: TextStyle(color: Colors.white, fontSize: 18),
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
                SizedBox(height: 10),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AppointmentBookingScreen(
                          hospitalId: hospital.hospitalId,
                          hospitalName: hospital.name,
                        ),
                      ),
                    );
                  },
                  child: Container(
                    height: screenSize.height * 0.07,
                    alignment: Alignment.center,
                    child: Text(
                      "Take Appointment",
                      style: TextStyle(color: Colors.white, fontSize: 18),
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
