class MedicationRecord {
  final int id;
  final int patientTreatmentId;
  final String? photoUrl;
  final DateTime takenAt;
  String status; // 'verified', 'pending', 'rejected'
  String? notes;
  String? verifiedBy;

  MedicationRecord({
    required this.id,
    required this.patientTreatmentId,
    this.photoUrl,
    required this.takenAt,
    required this.status,
    this.notes,
    this.verifiedBy,
  });
}
