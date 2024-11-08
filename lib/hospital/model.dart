import 'package:latlong2/latlong.dart';

class Hospital {
  final String id;
  final String name;
  final LatLng location;
  final String hospitalId;
  final List<String> departments;
  final String email;

  Hospital(
      {required this.id,
      required this.name,
      required this.location,
      required this.hospitalId,
      this.departments = const [],
      required this.email});

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'latitude': location.latitude,
        'longitude': location.longitude,
        'departments': departments,
        'hospitalId': hospitalId,
        'email': email
      };

  factory Hospital.fromJson(Map<String, dynamic> json) => Hospital(
      id: json['id'],
      name: json['name'],
      location: LatLng(json['latitude'], json['longitude']),
      departments: List<String>.from(json['departments']),
      hospitalId: json['hospitalId'],
      email: json['email']);
}
