import 'package:flutter/material.dart';

class PatientTreatment {
  final int id;
  final int patientId;
  final String patientName;
  final int treatmentTypeId;
  final String treatmentType;
  final DateTime diagnosisDate;
  final DateTime startDate;
  final DateTime endDate;
  final TimeOfDay medicationTime;
  final String? prescription;
  int status; // 1=Active, 2=Completed, 3=Failed
  final int currentDay;
  final int totalDays;
  double adherenceRate;

  PatientTreatment({
    required this.id,
    required this.patientId,
    required this.patientName,
    required this.treatmentTypeId,
    required this.treatmentType,
    required this.diagnosisDate,
    required this.startDate,
    required this.endDate,
    required this.medicationTime,
    this.prescription,
    required this.status,
    required this.currentDay,
    required this.totalDays,
    required this.adherenceRate,
  });

  int get remainingDays => totalDays - currentDay;
  double get progressPercentage => (currentDay / totalDays).clamp(0.0, 1.0);
}
