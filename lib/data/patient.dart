class Patient {
  final int id;
  final String name;
  final String nik;
  final String code;
  String address;
  String phone;
  final int subdistrictId;
  final int puskesmasId;
  int? height;
  int? weight;
  String? bloodType;
  final DateTime diagnosisDate;

  Patient({
    required this.id,
    required this.name,
    required this.nik,
    required this.code,
    required this.address,
    required this.phone,
    required this.subdistrictId,
    required this.puskesmasId,
    this.height,
    this.weight,
    this.bloodType,
    required this.diagnosisDate,
  });

  factory Patient.fromJson(Map<String, dynamic> json) {
    return Patient(
      id: json['id'],
      name: json['name'],
      nik: json['nik'],
      code: json['code'],
      address: json['address'],
      phone: json['telephone'],
      subdistrictId: json['subdistrict_id'],
      puskesmasId: json['puskesmas_id'],
      height: json['height'],
      weight: json['weight'],
      bloodType: json['blood_type'],
      diagnosisDate: DateTime.parse(json['diagnosis_date']),
    );
  }
}
