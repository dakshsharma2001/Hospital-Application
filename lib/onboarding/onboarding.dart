import 'package:flutter/material.dart';
import 'package:flutter_onboarding_slider/flutter_onboarding_slider.dart';
import 'package:lottie/lottie.dart';

class Onboarding extends StatelessWidget {
  const Onboarding({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return OnBoardingSlider(
      headerBackgroundColor: const Color.fromARGB(255, 255, 255, 255),
      finishButtonText: 'Get Started',
      finishButtonStyle: FinishButtonStyle(
        backgroundColor: Colors.blue,
        foregroundColor: Color.fromARGB(255, 0, 0, 0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(25),
        ),
      ),
      skipTextButton: const Text('Skip',
          style: TextStyle(color: const Color.fromARGB(153, 2, 2, 2))),
      trailing: const Text('Login',
          style: TextStyle(color: const Color.fromARGB(153, 0, 0, 0))),
      background: [
        Container(color: Colors.white),
        Container(color: Colors.white),
        Container(color: Colors.white),
      ],
      totalPage: 3,
      speed: 1.8,
      controllerColor: Colors.blue,
      onFinish: () {
        Navigator.pushNamed(context, '/login');
      },
      trailingFunction: () {
        Navigator.pushNamed(context, '/login');
      },
      pageBodies: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Lottie.network(
                  "https://lottie.host/12f5d6ba-90a0-414e-b459-5a1c62bb6d20/JJ0P4JRZr3.json"),
              const SizedBox(height: 40),
              const Text(
                'Stay Safe',
                style: TextStyle(
                  color: const Color.fromARGB(255, 19, 19, 19),
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Find Your Nearest Doctor at One click!',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Color.fromARGB(179, 167, 165, 165), fontSize: 16),
              ),
            ],
          ),
        ),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              LottieBuilder.network(
                  "https://lottie.host/e29274e9-3571-41ed-942e-f1185cc51a85/Esx2nBHOUB.json"),
              const SizedBox(height: 40),
              const Text(
                'Quick Examination',
                style: TextStyle(
                  color: const Color.fromARGB(255, 19, 19, 19),
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Post! Get Diagnose instantly',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Color.fromARGB(179, 167, 165, 165), fontSize: 16),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              LottieBuilder.network(
                  "https://lottie.host/33154a1e-8913-40a1-96fd-794653027de3/1ktzqcgfa7.json"),
              const SizedBox(height: 40),
              const Text(
                ' Appointments',
                style: TextStyle(
                  color: const Color.fromARGB(255, 19, 19, 19),
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Easy and Fast Appointments',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Color.fromARGB(179, 167, 165, 165), fontSize: 16),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
