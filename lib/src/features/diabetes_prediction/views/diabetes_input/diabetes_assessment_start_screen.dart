import 'package:flutter/material.dart';

import '../../controllers/diabetes_prediction_controller.dart';
import 'package:get/get.dart';

class DiabetesAssessmentStartScreen extends StatelessWidget {
  const DiabetesAssessmentStartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Diabetes Risk Assessment')),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            // Initialize the flow controller and start assessment
            final controller = Get.put(DiabetesPredictionController());
            controller.goToStep(0); // Start from first step
          },
          child: Text('Start Assessment'),
        ),
      ),
    );
  }
}