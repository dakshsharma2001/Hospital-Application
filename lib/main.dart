import 'package:emergency/admin/panel.dart';
import 'package:emergency/dashboard/patients_dashboard.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:emergency/dashboard/doctor.dart';
import 'package:emergency/dashboard/homescreen.dart';
import 'package:emergency/login/login.dart';
import 'package:emergency/login/signup.dart';
import 'package:emergency/onboarding/onboarding.dart';

void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  await Supabase.initialize(
    url: 'https://eugihvomekwfqjhylacd.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImV1Z2lodm9tZWt3ZnFqaHlsYWNkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MjU5MDEyNTIsImV4cCI6MjA0MTQ3NzI1Mn0.irn2_pyfw2DnJurK_MTYUE6wJkPybe4RHm816qi08XU',
  );

  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    FlutterNativeSplash.remove();
    return MaterialApp(
      home: const AuthWrapper(),
      debugShowCheckedModeBanner: false,
      theme: ThemeData(scaffoldBackgroundColor: Colors.white),
      routes: {
        '/onboarding': (context) => const Onboarding(),
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignupScreen(),
        '/home': (context) => const HomeScreen(),
        '/doctor': (context) => const DoctorScreen(),
        '/admin': (context) => AdminPanelScreen(),
        '/patient': (context) => PatientsDashboard(),
      },
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        } else if (snapshot.hasData && snapshot.data!.session != null) {
          return FutureBuilder<String?>(
            future: _getUserType(),
            builder: (context, userTypeSnapshot) {
              if (userTypeSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(
                    child: CircularProgressIndicator(),
                  ),
                );
              } else {
                if (userTypeSnapshot.data == null) {
                  return const LoginScreen();
                } else if (userTypeSnapshot.data == 'doctor') {
                  return const DoctorScreen();
                } else {
                  return const HomeScreen();
                }
              }
            },
          );
        } else {
          return FutureBuilder<bool>(
            future: _isFirstTime(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(
                    child: CircularProgressIndicator(),
                  ),
                );
              } else {
                if (snapshot.data == true) {
                  return const Onboarding();
                } else {
                  return const LoginScreen();
                }
              }
            },
          );
        }
      },
    );
  }

  Future<bool> _isFirstTime() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool isFirstTime = prefs.getBool('is_first_time') ?? true;
    if (isFirstTime) {
      await prefs.setBool('is_first_time', false);
    }
    return isFirstTime;
  }

  Future<String?> _getUserType() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_type');
  }
}
